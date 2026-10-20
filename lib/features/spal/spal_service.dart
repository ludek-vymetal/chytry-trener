import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'spal_config.dart';

/// Propojení se SPAL Strength Gym (vstupy, rezervace, permanentky, členství).
/// Účet SPAL je samostatný (Supabase) – nemíchá se s účtem trenéra (Firebase).
class SpalService {
  static bool _hotovo = false;

  /// Volá se při startu aplikace. Chyba nesmí shodit zbytek aplikace.
  static Future<void> init() async {
    if (_hotovo) return;
    try {
      await Supabase.initialize(url: spalSupabaseUrl, anonKey: spalSupabaseKey);
      _hotovo = true;
      Supabase.instance.client.auth.onAuthStateChange.listen((e) {
        if (e.event == AuthChangeEvent.signedOut && !_odhlasujiSam && !_overuji) {
          proc ??= 'Přihlášení ukončil server (${DateTime.now().toString().substring(11, 19)}). '
              'Pošli prosím tuto zprávu správci.';
        }
      }, onError: (Object e) {
        proc = 'Chyba přihlášení: $e';
      });
    } catch (e) {
      debugPrint('SPAL init error: $e');
    }
  }

  static bool get dostupne => _hotovo;
  static SupabaseClient get db => Supabase.instance.client;
  /// Během ověřování po přihlášení se ještě nepřepíná obrazovka (jinak by při chybě
  /// aplikace na okamžik skočila dovnitř a hned zpět na přihlášení bez vysvětlení).
  static bool _overuji = false;
  static final _zmena = StreamController<void>.broadcast();
  static Stream<void> get zmena => _zmena.stream;
  static bool get prihlasen => _hotovo && !_overuji && db.auth.currentSession != null;

  /// Proč skončilo přihlášení (ukáže se na přihlašovací obrazovce). Pro hledání chyb.
  static String? proc;
  static bool _odhlasujiSam = false;
  static String? get email => _hotovo ? db.auth.currentUser?.email : null;

  static Future<void> prihlasit(String email, String heslo) async {
    _overuji = true;
    proc = null;
    try {
      await db.auth.signInWithPassword(email: email.trim(), password: heslo);
      // účet musí být propojený se zákazníkem (role klient)
      try {
        await db.rpc('muj_spal');
      } catch (e) {
        debugPrint('SPAL prihlaseni muj_spal -> $e');
        await odhlasit();
        final text = chyba(e);
        throw AuthException(text.contains('propojen')
            ? 'Tento účet není propojený se zákazníkem SPAL. Požádej o přístup na recepci.'
            : 'Přihlášení se nepodařilo dokončit: $text');
      }
    } finally {
      _overuji = false;
      _zmena.add(null);
    }
  }

  static Future<void> zapomenuteHeslo(String email) => db.auth.resetPasswordForEmail(email.trim());
  static Future<void> zmenitHeslo(String heslo) => db.auth.updateUser(UserAttributes(password: heslo));
  static Future<void> odhlasit() async {
    _odhlasujiSam = true;
    try {
      await db.auth.signOut();
    } finally {
      _odhlasujiSam = false;
    }
  }

  static Map<String, dynamic> _m(Object? v) => Map<String, dynamic>.from(v as Map);
  static List<Map<String, dynamic>> _l(Object? v) =>
      [for (final x in (v as List? ?? const [])) Map<String, dynamic>.from(x as Map)];

  static Future<Map<String, dynamic>> prehled() async => _m(await db.rpc('muj_spal'));
  static Future<Map<String, dynamic>> info() async => _m(await db.rpc('spal_info'));
  static Future<Map<String, dynamic>> ucet() async => _m(await db.rpc('muj_ucet'));
  static Future<Map<String, dynamic>> nabidka() async => _m(await db.rpc('nabidka_web'));
  static Future<List<Map<String, dynamic>>> rezNabidka() async => _l(await db.rpc('rez_nabidka_web'));
  static Future<List<Map<String, dynamic>>> mojeRezervace() async => _l(await db.rpc('moje_rezervace'));

  static Future<List<DateTime>> volne(int objekt, DateTime den) async {
    final r = await db.rpc('rez_volne_web', params: {
      'p_objekt': objekt,
      'p_den': '${den.year}-${den.month.toString().padLeft(2, '0')}-${den.day.toString().padLeft(2, '0')}',
    });
    return [for (final x in r as List) DateTime.parse(x as String).toLocal()];
  }

  static Future<void> rezervovat(int objekt, int cinnost, DateTime zacatek, String poznamka) =>
      db.rpc('muj_rezervovat', params: {
        'p_objekt': objekt,
        'p_cinnost': cinnost,
        'p_zacatek': zacatek.toUtc().toIso8601String(),
        'p_poznamka': poznamka,
      });

  static Future<void> zrusitRezervaci(int id) => db.rpc('muj_storno_rezervace', params: {'p_id': id});

  static Future<({String kod, DateTime platiDo})> qr() async {
    final r = _m(await db.rpc('muj_qr'));
    return (kod: r['kod'] as String, platiDo: DateTime.parse(r['plati_do'] as String).toLocal());
  }

  /// Online nákup: server spočítá cenu a založí platbu u GoPay → odkaz na platební bránu.
  static Future<({int id, String url, bool testovaci})> zalozitPlatbu(Map<String, dynamic> nakup) async {
    final n = _m(await db.rpc('muj_nakup', params: {'p': nakup}));
    final id = (n['id'] as num).toInt();
    final r = await db.functions.invoke('gopay', body: {'akce': 'zaplatit', 'platba_id': id});
    final d = r.data;
    if (d is Map && d['gw_url'] is String) {
      return (id: id, url: d['gw_url'] as String, testovaci: d['testovaci'] == true);
    }
    throw Exception(d is Map ? '${d['chyba'] ?? 'Platbu se nepodařilo založit'}' : 'Platbu se nepodařilo založit');
  }

  /// nova / zaplacena / zrusena
  static Future<String> stavPlatby(int id) async =>
      '${_m(await db.rpc('muj_platba', params: {'p_id': id}))['stav']}';

  /// Sešit chyb ve fitku (recepce: Nástroje → Sešit chyb). Jen když je zákazník přihlášený
  /// do SPAL (bez přihlášení server zápis nepřijme). Nikdy nevyhodí chybu.
  static final _hlaseno = <String, DateTime>{};
  static Future<void> zapsatChybu(String zprava, {String? detail, String? kde}) async {
    try {
      if (!prihlasen) return;
      final klic = '$kde|${zprava.length > 200 ? zprava.substring(0, 200) : zprava}';
      final minule = _hlaseno[klic];
      if (minule != null && DateTime.now().difference(minule).inSeconds < 30) return;
      _hlaseno[klic] = DateTime.now();
      if (_hlaseno.length > 200) _hlaseno.clear();
      await db.rpc('chyba_zapsat', params: {
        'p_zdroj': 'aplikace',
        'p_zprava': zprava.length > 2000 ? zprava.substring(0, 2000) : zprava,
        'p_detail': detail,
        'p_kde': kde,
        'p_verze': 'Chytrý trenér',
        'p_zarizeni': kIsWeb ? 'web' : defaultTargetPlatform.name,
      });
    } catch (_) {}
  }

  /// Srozumitelná chyba ze serveru.
  static String chyba(Object e) {
    // hlášky pro zákazníka z databáze (P0001) nejsou chyby programu – ostatní do sešitu chyb
    if (!(e is PostgrestException && e.code == 'P0001') && e is! AuthException) {
      zapsatChybu(e.toString(), kde: 'SPAL v aplikaci', detail: StackTrace.current.toString());
    }
    if (e is PostgrestException) return e.message;
    if (e is AuthException) return e.message;
    if (e is FunctionException) {
      final d = e.details;
      if (d is Map && d['chyba'] != null) return '${d['chyba']}';
      return 'Platbu se nepodařilo založit, zkus to prosím znovu.';
    }
    if (e is Exception && e.toString().startsWith('Exception: ')) return e.toString().substring(11);
    return 'Něco se nepovedlo – zkontroluj připojení k internetu.';
  }
}

/// Je přihlášený účet SPAL? (mění se při přihlášení/odhlášení)
final spalPrihlasenProvider = StreamProvider<bool>((ref) {
  if (!SpalService.dostupne) return Stream.value(false);
  final c = StreamController<bool>();
  c.add(SpalService.prihlasen);
  final a = SpalService.db.auth.onAuthStateChange
      .listen((_) => c.add(SpalService.prihlasen), onError: (_) {});
  final b = SpalService.zmena.listen((_) => c.add(SpalService.prihlasen));
  ref.onDispose(() {
    a.cancel();
    b.cancel();
    c.close();
  });
  return c.stream.distinct();
});

final spalPrehledProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  ref.watch(spalPrihlasenProvider);
  return SpalService.prehled();
});
final spalInfoProvider = FutureProvider<Map<String, dynamic>>((ref) {
  ref.watch(spalPrihlasenProvider);
  return SpalService.info();
});
final spalUcetProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  ref.watch(spalPrihlasenProvider);
  return SpalService.ucet();
});
final spalRezervaceProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  ref.watch(spalPrihlasenProvider);
  return SpalService.mojeRezervace();
});

/// Po změně (rezervace, storno) obnovit přehledy.
void spalObnovit(WidgetRef ref) {
  ref.invalidate(spalPrehledProvider);
  ref.invalidate(spalUcetProvider);
  ref.invalidate(spalRezervaceProvider);
}
