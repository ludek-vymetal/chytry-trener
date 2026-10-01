import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account_data_switcher.dart';
import 'coach_storage_service.dart';
import 'online_coaching_service.dart';

/// Záloha všeho, co není v hlavních trenérských datech:
/// profily klientů (cíl, makra, zvolený jídelníček, data závodů),
/// výkony u cviků, uložené jídelníčky, vlastní jídla a nastavení.
///
/// Ukládá se jako jeden snapshot `app_extras_v1` pod účtem trenéra.
/// Pravidla slučování jsou opatrná – nic se nepřepíše naslepo:
///  - výkony u cviků se SLUČUJÍ (sjednocení obou stran),
///  - ostatní položky: co je jen v cloudu, doplní se do zařízení;
///    co je v zařízení, má přednost a nahraje se.
class ExtraBackupService {
  ExtraBackupService._();

  static const snapshotKey = 'app_extras_v1';

  static const _performanceKey = 'exercise_performance_storage';

  static const _plainKeys = <String>[
    'saved_meal_plans_v1',
    'custom_food_combos_v1',
    'custom_foods_v1',
    'coach_passes_v1',
    'coach_payments_v1',
    'coach_appointments_v1',
    'exercise_videos_v1',
    'chat_quick_replies_coach_v1',
    'food_bank_v1',
    'pdf_author_line',
    'pdf_contact_phone',
    'pdf_contact_email',
    'pdf_contact_instagram',
    'pdf_contact_web',
    'pdf_logo_b64',
    'app_accent',
    'theme_mode',
  ];

  /// Účet, pro který už v tomto běhu aplikace proběhlo [pullMissing].
  /// Pak platí, že co v zařízení chybí, bylo smazané – a smaže se i v cloudu.
  static String? _pulledUid;

  static bool _isBackedUp(String key) =>
      key == 'user_profile_storage' ||
      key.startsWith('user_profile_storage_') ||
      key == _performanceKey ||
      _plainKeys.contains(key);

  // ---------------------------------------------------------------
  // Místní data
  // ---------------------------------------------------------------

  static Map<String, dynamic>? _encode(String key, Object? value) {
    if (value == null) return null;
    final String type;
    if (value is String) {
      type = 's';
    } else if (value is int) {
      type = 'i';
    } else if (value is double) {
      type = 'd';
    } else if (value is bool) {
      type = 'b';
    } else if (value is List<String>) {
      type = 'l';
    } else {
      return null;
    }
    return {'id': key, 't': type, 'v': value};
  }

  static Future<void> _write(SharedPreferences prefs, Map<String, dynamic> item) async {
    final key = item['id'] as String;
    final v = item['v'];
    switch (item['t']) {
      case 's':
        await prefs.setString(key, v as String);
      case 'i':
        await prefs.setInt(key, (v as num).toInt());
      case 'd':
        await prefs.setDouble(key, (v as num).toDouble());
      case 'b':
        await prefs.setBool(key, v as bool);
      case 'l':
        await prefs.setStringList(key, (v as List).cast<String>());
    }
  }

  static Future<Map<String, Map<String, dynamic>>> _collectLocal(
    SharedPreferences prefs,
    Set<String> ownIds,
  ) async {
    final result = <String, Map<String, dynamic>>{};
    for (final key in prefs.getKeys()) {
      if (!_isBackedUp(key)) continue;
      final item = _encode(key, prefs.get(key));
      if (item == null) continue;
      final clean = _onlyOwnClients(item, ownIds);
      if (clean != null) result[key] = clean;
    }
    return result;
  }

  /// Profily klientů a výkony jen klientů TOHOTO trenéra
  /// (na sdíleném zařízení mohou ležet i data klientů jiného trenéra).
  static Map<String, dynamic>? _onlyOwnClients(
    Map<String, dynamic> item,
    Set<String> ownIds,
  ) {
    final key = item['id'];
    final v = item['v'];
    if (key is! String || v is! String) return item;
    if (key.startsWith('user_profile_storage_')) {
      final id = key.substring('user_profile_storage_'.length);
      return ownIds.contains(id) ? item : null;
    }
    if (key == 'user_profile_storage') {
      try {
        final d = jsonDecode(v);
        final id = d is Map ? d['clientId']?.toString() : null;
        if (id != null && id.isNotEmpty && !ownIds.contains(id)) return null;
      } catch (_) {}
      return item;
    }
    if (key == _performanceKey) {
      return {...item, 'v': AccountDataSwitcher.filterForCoach(v, ownIds)};
    }
    return item;
  }

  /// Zruší naplánované nahrání (např. při přepnutí na jiný účet).
  static void cancelPending() {
    _timer?.cancel();
    _timer = null;
  }

  /// Sloučí dva JSON seznamy výkonů (bez duplicit).
  static String mergePerformances(String? a, String? b) =>
      _mergePerformances(a, b);

  static String _mergePerformances(String? a, String? b) {
    List<dynamic> parse(String? s) {
      if (s == null || s.isEmpty) return const [];
      try {
        final d = jsonDecode(s);
        return d is List ? d : const [];
      } catch (_) {
        return const [];
      }
    }

    final seen = <String>{};
    final out = <dynamic>[];
    for (final e in [...parse(a), ...parse(b)]) {
      if (e is! Map) continue;
      final k = '${e['clientId']}|${e['exerciseName']}|${e['date']}|'
          '${e['weight']}|${e['reps']}';
      if (seen.add(k)) out.add(e);
    }
    return jsonEncode(out);
  }

  // ---------------------------------------------------------------
  // Cloud
  // ---------------------------------------------------------------

  /// Nahraje místní data (sloučená s tím, co už v cloudu je).
  /// Očistí položku zálohy od dat jiného trenéra (sdílené zařízení).
  static Map<String, dynamic>? _sanitize(
    SharedPreferences prefs,
    String uid,
    Map<String, dynamic> item,
    Set<String> ownIds,
  ) {
    final key = item['id'];
    if (key is! String) return item;
    if (!AccountDataSwitcher.isAccountKey(key)) {
      return _onlyOwnClients(item, ownIds);
    }
    if (AccountDataSwitcher.belongsToOtherAccount(prefs, uid, key, item['v'])) {
      return null;
    }
    if (AccountDataSwitcher.clientBoundKeys.contains(key) &&
        item['v'] is String) {
      return {
        ...item,
        'v': AccountDataSwitcher.filterForCoach(item['v'] as String, ownIds),
      };
    }
    return item;
  }

  static Future<void> push() async {
    final uid = CoachStorageService.currentCoachUid();
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    // Data v zařízení patří jinému účtu (probíhá přepnutí) → nic nenahrávat.
    final owner = prefs.getString(AccountDataSwitcher.ownerKey);
    if (owner != null && owner != uid) {
      debugPrint('EXTRAS PUSH SKIPPED -> device data belong to $owner');
      return;
    }
    final ownIds = AccountDataSwitcher.clientIdsOf(prefs, uid);
    final local = await _collectLocal(prefs, ownIds);
    final cloudList =
        await CoachStorageService.readCloudSnapshot(uid: uid, key: snapshotKey) ??
            const <Map<String, dynamic>>[];
    // Po načtení z cloudu platí zařízení: smazané logo, kontakt, barva…
    // se smažou i v cloudu (jinak by se při dalším přihlášení vrátily).
    final localWins = _pulledUid == uid;

    final merged = <String, Map<String, dynamic>>{};
    for (final c in cloudList) {
      final id = c['id'];
      if (id is! String) continue;
      if (localWins && AccountDataSwitcher.isAccountKey(id)) continue;
      final clean = _sanitize(prefs, uid, Map<String, dynamic>.from(c), ownIds);
      if (clean != null) merged[id] = clean;
    }
    for (final e in local.entries) {
      if (e.key == _performanceKey) {
        merged[e.key] = {
          'id': e.key,
          't': 's',
          'v': _mergePerformances(
            e.value['v'] as String?,
            merged[e.key]?['v'] as String?,
          ),
        };
      } else {
        merged[e.key] = e.value;
      }
    }

    await CoachStorageService.writeCloudSnapshot(
      uid: uid,
      key: snapshotKey,
      items: merged.values.toList(),
      deviceId: await CoachStorageService.loadDeviceId() ?? 'unknown_device',
      now: DateTime.now(),
    );
    debugPrint('EXTRAS PUSH OK -> items=${merged.length}');
  }

  /// Doplní do zařízení, co v něm chybí (nový telefon, reinstalace).
  /// Vrací počet obnovených položek.
  static Future<int> pullMissing() async {
    final uid = CoachStorageService.currentCoachUid();
    if (uid == null) return 0;

    final cloudList =
        await CoachStorageService.readCloudSnapshot(uid: uid, key: snapshotKey);
    if (cloudList == null) {
      _pulledUid = uid;
      return 0;
    }

    final prefs = await SharedPreferences.getInstance();
    final owner = prefs.getString(AccountDataSwitcher.ownerKey);
    if (owner != null && owner != uid) return 0;
    final ownIds = AccountDataSwitcher.clientIdsOf(prefs, uid);
    var restored = 0;
    for (final raw in cloudList) {
      final key = raw['id'];
      if (key is! String || !_isBackedUp(key)) continue;
      final item = _sanitize(prefs, uid, raw, ownIds);
      if (item == null) continue;

      if (key == _performanceKey) {
        final local = prefs.getString(key);
        final merged = _mergePerformances(local, item['v'] as String?);
        if (merged != (local ?? '')) {
          await prefs.setString(key, merged);
          restored++;
        }
        continue;
      }

      if (!prefs.containsKey(key)) {
        await _write(prefs, item);
        restored++;
      }
    }
    _pulledUid = uid;
    debugPrint('EXTRAS PULL OK -> restored=$restored');
    return restored;
  }

  /// Obě strany: doplnit chybějící, pak nahrát.
  static Future<void> reconcile() async {
    await pullMissing();
    await push();
  }

  // ---------------------------------------------------------------
  // Automatické nahrání po změně
  // ---------------------------------------------------------------

  static Timer? _timer;

  /// Nahraje zálohu pár sekund po poslední změně (víc změn za sebou =
  /// jedno nahrání). Bez přihlášeného trenéra nic nedělá.
  static void schedulePush() {
    // Propojení s klientem / trenérem (online coaching).
    OnlineCoachingService.scheduleSync();
    if (CoachStorageService.currentCoachUid() == null) return;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 8), () async {
      try {
        await push();
      } catch (e) {
        debugPrint('EXTRAS AUTO PUSH ERROR -> $e');
      }
    });
  }
}
