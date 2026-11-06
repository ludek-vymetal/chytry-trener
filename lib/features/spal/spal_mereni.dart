import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/coach/coach_inbody_entry.dart';
import '../../providers/coach/app_role_provider.dart';
import '../../providers/coach/coach_inbody_controller.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/coach/coach_storage_service.dart';
import '../../services/coach/online_coaching_service.dart';
import 'spal_service.dart';
import 'spal_styl.dart';

/// Měření z váhy FitMao ve fitku SPAL → „InBody“ v Chytrém trenérovi.
///
/// Člen SPAL přihlášený v aplikaci dostane jen svoje měření (ověřuje server,
/// funkce `moje_mereni`). Převedou se jako záznamy InBody (bez duplicit podle
/// id měření), propíšou se do profilu (bazál, beztuková hmota, váha →
/// výpočet jídla) a u online klienta se synchronizují k trenérovi.
/// Ruční zápis InBody zůstává pro všechny, kdo váhu SPAL nemají.
class SpalMereniSync {
  SpalMereniSync._();

  static DateTime? _naposled;
  static bool _bezi = false;

  static const _prefix = 'spal:';

  /// Převod jednoho měření z `moje_mereni` na záznam InBody.
  /// Vrací `null`, když měření nemá použitelnou hmotnost.
  static CoachInbodyEntry? prevest(
    Map<String, dynamic> m, {
    required String clientId,
    required int heightCm,
    required String deviceId,
    DateTime? now,
  }) {
    double? n(String k) {
      final v = m[k];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.'));
      return null;
    }

    double z(String k) => n(k) ?? 0;

    final id = m['id'];
    final cas = DateTime.tryParse('${m['cas'] ?? ''}')?.toLocal();
    final vaha = z('hmotnost_kg');
    if (id == null || cas == null || vaha <= 0) return null;

    // Chybějící hodnoty dopočítat (stejně jako ruční formulář).
    var tukKg = z('tuk_kg');
    var tukPct = z('tuk_pct');
    var beztuk = z('beztukova_kg');
    if (tukKg <= 0 && tukPct > 0) tukKg = vaha * tukPct / 100;
    if (tukKg <= 0 && beztuk > 0) tukKg = vaha - beztuk;
    if (tukKg < 0) tukKg = 0;
    if (beztuk <= 0) beztuk = vaha - tukKg;
    if (tukPct <= 0) tukPct = tukKg / vaha * 100;

    final vyska = (n('vyska_cm') ?? 0) > 100 ? n('vyska_cm')!.round() : heightCm;
    var bmi = z('bmi');
    if (bmi <= 0 && vyska > 0) bmi = vaha / ((vyska / 100) * (vyska / 100));

    double? nenula(String k) {
      final v = n(k);
      return (v == null || v == 0) ? null : v;
    }

    final t = now ?? DateTime.now();
    return CoachInbodyEntry(
      entryId: const Uuid().v4(),
      clientId: clientId,
      date: cas,
      heightCm: vyska,
      weightKg: vaha,
      smmKg: z('kosterni_svaly_kg'),
      fatKg: tukKg,
      waterKg: z('voda_l'),
      leanMassKg: beztuk,
      bmi: bmi,
      bodyFatPercent: tukPct,
      whr: z('whr'),
      bmr: z('bmr_kcal'),
      // FitMao: pravá/levá paže, trup, pravá/levá noha
      muscleLeftArmKg: z('svaly_lp'),
      muscleRightArmKg: z('svaly_pp'),
      muscleTrunkKg: z('svaly_trup'),
      muscleLeftLegKg: z('svaly_ln'),
      muscleRightLegKg: z('svaly_pn'),
      fatLeftArmKg: z('tuk_lp'),
      fatRightArmKg: z('tuk_pp'),
      fatTrunkKg: z('tuk_trup'),
      fatLeftLegKg: z('tuk_ln'),
      fatRightLegKg: z('tuk_pn'),
      visceralFatLevel: nenula('visceralni'),
      inbodyScore: nenula('skore'),
      totalMuscleKg: nenula('svaly_kg'),
      proteinKg: nenula('bilkoviny_kg'),
      mineralKg: nenula('mineraly_kg'),
      bodyAge: nenula('telesny_vek'),
      waterPercent: nenula('voda_pct'),
      fatControlKg: n('uprava_tuku_kg'),
      muscleControlKg: n('uprava_svalu_kg'),
      weightControlKg: n('uprava_hmotnosti_kg'),
      source: 'spal',
      externalId: '$_prefix$id',
      createdAt: t,
      updatedAt: t,
      deletedAt: null,
      version: 1,
      updatedByDeviceId: deviceId,
    );
  }

  /// Pro koho se měření ukládají: online klient → jeho id u trenéra,
  /// jinak vlastní profil. Na zařízení trenéra jen do karty klienta, který
  /// je TOUTÉŽ osobou jako přihlášený účet SPAL (stejný e-mail, nebo
  /// jednoznačně stejné jméno) – typicky trenér, který je sám svým klientem.
  /// Cizí měření se trenérovi nepřevádějí (účet SPAL patří jen jemu).
  static Future<String?> _cilovyKlient(WidgetRef ref) async {
    if (ref.read(appRoleProvider) == AppRole.coach) return _klientTrenera();
    final link = await OnlineCoachingService.localClientLink();
    if (link != null) return link.clientId;
    final id = ref.read(userProfileProvider)?.clientId?.trim();
    return (id == null || id.isEmpty) ? 'ja' : id;
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  static Future<String?> _klientTrenera() async {
    final klienti = (await CoachStorageService.loadClients())
        .where((c) => !c.isDeleted)
        .toList();
    if (klienti.isEmpty) return null;

    final email = _norm(SpalService.email ?? '');
    if (email.isNotEmpty) {
      final podleEmailu = klienti.where((c) => _norm(c.email) == email).toList();
      if (podleEmailu.length == 1) return podleEmailu.first.clientId;
    }

    try {
      final p = await SpalService.prehled();
      final jmeno = _norm('${p['jmeno'] ?? ''} ${p['prijmeni'] ?? ''}');
      if (jmeno.isEmpty) return null;
      final podleJmena = klienti
          .where((c) => _norm('${c.firstName} ${c.lastName}') == jmeno)
          .toList();
      if (podleJmena.length == 1) return podleJmena.first.clientId;
    } catch (_) {}
    return null;
  }

  /// Načte nová měření z váhy a uloží je jako InBody.
  /// Vrací počet nově převedených měření, `null` = nic se nedělalo
  /// (nepřihlášen, zařízení trenéra, nedávno už načteno).
  static Future<int?> nacist(WidgetRef ref, {bool vynutit = false}) async {
    if (!SpalService.prihlasen || _bezi) return null;
    final ted = DateTime.now();
    if (!vynutit &&
        _naposled != null &&
        ted.difference(_naposled!) < const Duration(minutes: 30)) {
      return null;
    }

    final clientId = await _cilovyKlient(ref);
    if (clientId == null) return null;

    _bezi = true;
    try {
      final vse = await CoachStorageService.loadInbodyAll();
      final moje = vse.where((e) => e.clientId == clientId).toList();
      final znama = {
        for (final e in moje)
          if (e.externalId != null) e.externalId!,
      };

      DateTime? od;
      for (final e in moje) {
        if (e.isFromSpal && (od == null || e.date.isAfter(od))) od = e.date;
      }

      final data = await SpalService.mojeMereni(od: od);
      _naposled = ted;

      var deviceId = await CoachStorageService.loadDeviceId();
      if (deviceId == null || deviceId.trim().isEmpty) {
        deviceId = const Uuid().v4();
        await CoachStorageService.saveDeviceId(deviceId);
      }
      final profil = ref.read(userProfileProvider);
      final vyska = (profil?.height ?? 0).round();

      final nova = <CoachInbodyEntry>[];
      for (final m in data) {
        final e = prevest(
          m,
          clientId: clientId,
          heightCm: vyska,
          deviceId: deviceId,
        );
        if (e == null || !znama.add(e.externalId!)) continue;
        nova.add(e);
      }
      if (nova.isNotEmpty) {
        final ulozit = [...nova, ...vse]
          ..sort((a, b) => b.date.compareTo(a.date));
        await CoachStorageService.saveInbodyAll(ulozit);
        ref.invalidate(coachInbodyControllerProvider);
      }

      // I bez nových měření: profil mohl vzniknout až po minulém převodu.
      // U trenéra jen do profilu toho klienta (ne do otevřeného profilu).
      final trener = ref.read(appRoleProvider) == AppRole.coach;
      if (trener || ref.read(userProfileProvider) != null) {
        await ref
            .read(userProfileProvider.notifier)
            .syncBodyCompositionFromInbody(clientId, !trener);
      }
      if (nova.isNotEmpty) unawaited(OnlineCoachingService.syncNow());
      return nova.length;
    } catch (e) {
      debugPrint('SPAL MERENI SYNC ERROR -> $e');
      rethrow;
    } finally {
      _bezi = false;
    }
  }

  /// Uložená měření z váhy (pro přehled v sekci SPAL), nejnovější první.
  static Future<List<CoachInbodyEntry>> ulozena(WidgetRef ref) async {
    final clientId = await _cilovyKlient(ref);
    if (clientId == null) return const [];
    final vse = await CoachStorageService.loadInbodyAll();
    return vse.where((e) => e.clientId == clientId && !e.isDeleted).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}

/// Sekce SPAL → „Moje měření z váhy“: seznam měření převedených do
/// Chytrého trenéra a tlačítko pro načtení nových.
class SpalMereniScreen extends ConsumerStatefulWidget {
  const SpalMereniScreen({super.key});

  @override
  ConsumerState<SpalMereniScreen> createState() => _SpalMereniScreenState();
}

class _SpalMereniScreenState extends ConsumerState<SpalMereniScreen> {
  List<CoachInbodyEntry>? _mereni;
  bool _nacitam = false;
  String? _chyba;
  bool _trener = false;

  @override
  void initState() {
    super.initState();
    _trener = false;
    unawaited(_obnovit(zeServeru: true));
  }

  Future<void> _obnovit({bool zeServeru = false}) async {
    setState(() {
      _nacitam = true;
      _chyba = null;
    });
    int? nova;
    try {
      if (zeServeru && !_trener) {
        nova = await SpalMereniSync.nacist(ref, vynutit: true);
      }
    } catch (e) {
      _chyba = 'Měření se nepodařilo načíst. Zkontroluj připojení.';
    }
    final ulozena = await SpalMereniSync.ulozena(ref);
    if (!mounted) return;
    if (ref.read(appRoleProvider) == AppRole.coach &&
        await SpalMereniSync._cilovyKlient(ref) == null) {
      _chyba ??= 'V režimu trenéra se měření uloží do karty klienta, který je '
          'stejná osoba jako tento účet SPAL (stejný e-mail nebo jméno). '
          'Takového klienta jsem nenašel.';
    }
    setState(() {
      _mereni = ulozena;
      _nacitam = false;
    });
    if (nova != null && nova > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Načteno nových měření: $nova')),
      );
    }
  }

  String _c(double v, [int d = 1]) => v.toStringAsFixed(d).replaceAll('.', ',');

  String _datum(DateTime d) =>
      '${d.day}. ${d.month}. ${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final mereni = _mereni;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje měření z váhy'),
        actions: [
          if (!_trener)
            IconButton(
              tooltip: 'Načíst nová měření',
              icon: const Icon(Icons.refresh),
              onPressed: _nacitam ? null : () => _obnovit(zeServeru: true),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            _trener
                ? 'Na zařízení v režimu trenéra se měření nepřevádějí. '
                    'Klient je uvidí ve své aplikaci a k tobě se dostanou přes online coaching.'
                : 'Měření z váhy ve fitku se samy převádějí do Chytrého trenéra '
                    '(Tělo / InBody). Podle nich se počítá bazál a jídlo, a když '
                    'jsi propojený s trenérem, uvidí je i on.',
            style: const TextStyle(fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 12),
          if (_nacitam) const LinearProgressIndicator(color: spalZluta),
          if (_chyba != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_chyba!, style: const TextStyle(color: Colors.redAccent)),
            ),
          if (mereni != null && mereni.isEmpty && !_nacitam)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Zatím tu žádné měření není. Zvaž se na váze ve fitku '
                '(zadej na ní své telefonní číslo) a pak sem přijď znovu.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final e in mereni ?? const <CoachInbodyEntry>[])
            Card(
              child: ListTile(
                leading: Icon(
                  e.isFromSpal ? Icons.monitor_weight : Icons.edit_note,
                  color: spalZluta,
                ),
                title: Text(
                  '${_c(e.weightKg)} kg · tuk ${_c(e.bodyFatPercent)} %'
                  '${e.smmKg > 0 ? ' · svaly ${_c(e.smmKg)} kg' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  [
                    _datum(e.date),
                    if (e.bmr > 0) 'bazál ${e.bmr.round()} kcal',
                    if ((e.bodyAge ?? 0) > 0) 'tělesný věk ${e.bodyAge!.round()}',
                    if ((e.inbodyScore ?? 0) > 0) 'skóre ${e.inbodyScore!.round()}',
                    e.isFromSpal ? 'váha SPAL' : 'zapsáno ručně',
                  ].join(' · '),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
