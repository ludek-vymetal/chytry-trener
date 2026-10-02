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
    'coach_passes_v1__del',
    'coach_payments_v1__del',
    'coach_appointments_v1__del',
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

  // ---------------------------------------------------------------
  // Seznamy slučované po položkách (kalendář, permanentky, platby)
  // ---------------------------------------------------------------
  //
  // Dřív platilo „co je v zařízení, přepíše cloud“ – termín zapsaný v mobilu
  // pak počítač při dalším uložení smazal. Teď se seznamy slučují podle `id`:
  //  - každá položka nese `_mt` (čas poslední změny), novější vyhrává,
  //  - smazané položky se zapisují do `<klíč>__del` (id|čas), aby se
  //    smazání propsalo i do ostatních zařízení.

  static const listKeys = <String>{
    'coach_appointments_v1',
    'coach_passes_v1',
    'coach_payments_v1',
  };

  static String deletedKey(String key) => '${key}__del';

  static bool _isDeletedKey(String key) =>
      key.endsWith('__del') && listKeys.contains(key.substring(0, key.length - 5));

  static List<Map<String, dynamic>> _parseList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final d = jsonDecode(json);
      if (d is! List) return [];
      return [
        for (final e in d)
          if (e is Map) Map<String, dynamic>.from(e),
      ];
    } catch (_) {
      return [];
    }
  }

  static String _contentOf(Map<String, dynamic> item) {
    final copy = Map<String, dynamic>.from(item)..remove('_mt');
    return jsonEncode(copy);
  }

  /// Připraví seznam k uložení: změněným a novým položkám dá čas změny,
  /// smazané zapíše do seznamu smazaných. Volají to providery při ukládání.
  static Future<String> stampList(
    SharedPreferences prefs,
    String key,
    List<Map<String, dynamic>> next,
  ) async {
    final prev = {
      for (final p in _parseList(prefs.getString(key)))
        if (p['id'] != null) p['id'].toString(): p,
    };
    final now = DateTime.now().toUtc().toIso8601String();
    final nextIds = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final raw in next) {
      final item = Map<String, dynamic>.from(raw);
      final id = item['id']?.toString();
      if (id != null) nextIds.add(id);
      final old = id == null ? null : prev[id];
      if (old != null && _contentOf(old) == _contentOf(item)) {
        item['_mt'] = old['_mt'] ?? '';
      } else {
        item['_mt'] = now;
      }
      out.add(item);
    }
    final removed = prev.keys.where((id) => !nextIds.contains(id)).toList();
    if (removed.isNotEmpty) {
      final del = prefs.getStringList(deletedKey(key)) ?? const <String>[];
      await prefs.setStringList(
        deletedKey(key),
        _pruneDeleted([...del, for (final id in removed) '$id|$now']),
      );
    }
    return jsonEncode(out);
  }

  /// Smazané starší než 180 dní už není potřeba držet.
  static List<String> _pruneDeleted(List<String> entries) {
    final limit = DateTime.now().toUtc().subtract(const Duration(days: 180));
    final byId = <String, String>{};
    for (final e in entries) {
      final i = e.lastIndexOf('|');
      final id = i < 0 ? e : e.substring(0, i);
      final at = i < 0 ? '' : e.substring(i + 1);
      final t = DateTime.tryParse(at);
      if (t != null && t.isBefore(limit)) continue;
      final cur = byId[id];
      if (cur == null || at.compareTo(cur) > 0) byId[id] = at;
    }
    return [for (final e in byId.entries) '${e.key}|${e.value}'];
  }

  static Set<String> _deletedIds(Iterable<String> entries) => {
        for (final e in entries)
          e.lastIndexOf('|') < 0 ? e : e.substring(0, e.lastIndexOf('|')),
      };

  /// Sloučí dva seznamy podle `id` (novější `_mt` vyhrává, smazané pryč).
  static String mergeListJson(String? local, String? cloud, Set<String> deleted) {
    final byId = <String, Map<String, dynamic>>{};
    final order = <String>[];
    void put(Map<String, dynamic> item) {
      final id = item['id']?.toString();
      if (id == null || deleted.contains(id)) return;
      final cur = byId[id];
      if (cur == null) {
        byId[id] = item;
        order.add(id);
        return;
      }
      final a = (cur['_mt'] ?? '').toString();
      final b = (item['_mt'] ?? '').toString();
      final cmp = b.compareTo(a);
      // Shodný čas → vždy stejná volba na všech zařízeních.
      if (cmp > 0 || (cmp == 0 && jsonEncode(item).compareTo(jsonEncode(cur)) > 0)) {
        byId[id] = item;
      }
    }

    for (final i in _parseList(local)) {
      put(i);
    }
    for (final i in _parseList(cloud)) {
      put(i);
    }
    return jsonEncode([for (final id in order) byId[id]]);
  }

  /// Stejný obsah bez ohledu na pořadí položek?
  static bool _sameList(String? a, String? b) {
    Map<String, String> m(String? s) => {
          for (final i in _parseList(s))
            (i['id'] ?? jsonEncode(i)).toString(): jsonEncode(i),
        };
    return mapEquals(m(a), m(b));
  }

  /// Klíče, které poslední [pullMissing] v zařízení změnil.
  static Set<String> lastChangedKeys = {};

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

  static bool _sameSnapshot(
    Map<String, Map<String, dynamic>> a,
    Map<String, Map<String, dynamic>> b,
  ) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      final o = b[e.key];
      if (o == null) return false;
      if (listKeys.contains(e.key)) {
        if (!_sameList(e.value['v'] as String?, o['v'] as String?)) return false;
        continue;
      }
      if (_isDeletedKey(e.key)) {
        final x = (e.value['v'] as List?)?.map((v) => v.toString()).toSet();
        final y = (o['v'] as List?)?.map((v) => v.toString()).toSet();
        if (!setEquals(x, y)) return false;
        continue;
      }
      if (e.key == _performanceKey) {
        Set<String> asSet(Object? v) {
          if (v is! String || v.isEmpty) return {};
          try {
            final d = jsonDecode(v);
            return d is List ? {for (final i in d) jsonEncode(i)} : {};
          } catch (_) {
            return {};
          }
        }

        if (!setEquals(asSet(e.value['v']), asSet(o['v']))) return false;
        continue;
      }
      if (jsonEncode(e.value['v']) != jsonEncode(o['v'])) return false;
    }
    return true;
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
    final cloudById = <String, Map<String, dynamic>>{};
    for (final c in cloudList) {
      final id = c['id'];
      if (id is! String) continue;
      final clean = _sanitize(prefs, uid, Map<String, dynamic>.from(c), ownIds);
      if (clean == null) continue;
      cloudById[id] = clean;
      // Seznamy slučované po položkách se nikdy jen nepřepisují.
      final mergedPerItem = listKeys.contains(id) || _isDeletedKey(id);
      if (localWins && !mergedPerItem && AccountDataSwitcher.isAccountKey(id)) {
        continue;
      }
      merged[id] = clean;
    }
    for (final e in local.entries) {
      if (_isDeletedKey(e.key)) {
        final a = (e.value['v'] as List?)?.cast<String>() ?? const <String>[];
        final b = (merged[e.key]?['v'] as List?)?.cast<String>() ?? const <String>[];
        merged[e.key] = {
          'id': e.key,
          't': 'l',
          'v': _pruneDeleted([...a, ...b]),
        };
        continue;
      }
      if (listKeys.contains(e.key)) {
        final delLocal = prefs.getStringList(deletedKey(e.key)) ?? const <String>[];
        final delCloud =
            (cloudById[deletedKey(e.key)]?['v'] as List?)?.cast<String>() ??
                const <String>[];
        merged[e.key] = {
          'id': e.key,
          't': 's',
          'v': mergeListJson(
            e.value['v'] as String?,
            merged[e.key]?['v'] as String?,
            _deletedIds([...delLocal, ...delCloud]),
          ),
        };
        continue;
      }
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

    // Nic nového → nezapisovat (šetří zápisy při pravidelné synchronizaci).
    if (_sameSnapshot(merged, cloudById)) {
      debugPrint('EXTRAS PUSH SKIPPED -> no change');
      return;
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
    lastChangedKeys = {};
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
    final changed = <String>{};
    List<String> cloudDeleted(String key) {
      for (final raw in cloudList) {
        if (raw['id'] == deletedKey(key)) {
          return (raw['v'] as List?)?.cast<String>() ?? const <String>[];
        }
      }
      return const <String>[];
    }

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
          changed.add(key);
        }
        continue;
      }

      if (_isDeletedKey(key)) {
        final local = prefs.getStringList(key) ?? const <String>[];
        final cloud = (item['v'] as List?)?.cast<String>() ?? const <String>[];
        final merged = _pruneDeleted([...local, ...cloud]);
        if (!setEquals(merged.toSet(), local.toSet())) {
          await prefs.setStringList(key, merged);
          changed.add(key.substring(0, key.length - 5));
        }
        continue;
      }

      if (listKeys.contains(key)) {
        final local = prefs.getString(key);
        final del = <String>[
          ...?prefs.getStringList(deletedKey(key)),
          ...cloudDeleted(key),
        ];
        final merged =
            mergeListJson(local, item['v'] as String?, _deletedIds(del));
        if (!_sameList(merged, local)) {
          await prefs.setString(key, merged);
          restored++;
          changed.add(key);
        }
        continue;
      }

      if (!prefs.containsKey(key)) {
        await _write(prefs, item);
        restored++;
        changed.add(key);
      }
    }

    // Smazání z jiného zařízení u seznamů, které se v cloudu nezměnily.
    for (final key in listKeys) {
      final local = prefs.getString(key);
      if (local == null) continue;
      final del = _deletedIds([
        ...?prefs.getStringList(deletedKey(key)),
        ...cloudDeleted(key),
      ]);
      if (del.isEmpty) continue;
      final cleaned = mergeListJson(local, null, del);
      if (!_sameList(cleaned, local)) {
        await prefs.setString(key, cleaned);
        changed.add(key);
      }
    }

    lastChangedKeys = changed;
    _pulledUid = uid;
    debugPrint('EXTRAS PULL OK -> restored=$restored');
    return restored;
  }

  /// Pravidelná synchronizace za běhu aplikace. Vrací klíče, které se
  /// v zařízení změnily (podle nich se obnoví obrazovky).
  static Future<Set<String>> liveSync() async {
    await pullMissing();
    final changed = {...lastChangedKeys};
    await push();
    return changed;
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
