import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/diet_plans/logic/custom_food_store.dart';
import '../../features/diet_plans/logic/meal_plan_math.dart';
import '../pdf/pdf_author.dart';
import 'extra_backup_service.dart';

/// Data, která patří jednomu trenérskému účtu (kalendář, permanentky,
/// platby, jídelníčky, značka v PDF…).
///
/// Když se na stejném zařízení přihlásí jiný trenér, data předchozího
/// účtu se odloží (`acct_<uid>_<klíč>`) a načtou se data nového účtu.
/// Díky tomu druhý trenér nikdy neuvidí kalendář ani platby první.
class AccountDataSwitcher {
  AccountDataSwitcher._();

  static const ownerKey = 'account_data_owner_v1';

  /// Klíče vázané na trenérský účet.
  static const keys = <String>[
    'saved_meal_plans_v1',
    'custom_foods_v1',
    'coach_passes_v1',
    'coach_payments_v1',
    'coach_appointments_v1',
    // Smazané položky kalendáře, permanentek a plateb (synchronizace).
    'coach_passes_v1__del',
    'coach_payments_v1__del',
    'coach_appointments_v1__del',
    'exercise_videos_v1',
    'chat_quick_replies_coach_v1',
    'custom_daily_meal_templates_v1',
    'pdf_author_line',
    'pdf_contact_phone',
    'pdf_contact_email',
    'pdf_contact_instagram',
    'pdf_contact_web',
    'pdf_logo_b64',
    // Vzhled a vlastní data trenéra.
    'app_accent',
    'theme_mode',
    'custom_food_combos_v1',
    'food_bank_v1',
    // Naposledy otevřený klient – jiný trenér ho nesmí „zdědit“.
    'active_client_id_v1',
    'booking_seen_v1',
  ];

  /// Seznamy, jejichž položky mají `clientId`.
  static const clientBoundKeys = <String>{
    'saved_meal_plans_v1',
    'coach_passes_v1',
    'coach_payments_v1',
    'coach_appointments_v1',
  };

  static String stashKey(String uid, String key) => 'acct_${uid}_$key';

  static bool isAccountKey(String key) => keys.contains(key);

  /// ID klientů trenéra (z jeho seznamu klientů v zařízení).
  static Set<String> clientIdsOf(SharedPreferences prefs, String uid) {
    final raw = prefs.getString('coach_${uid}_coach_clients_v1');
    if (raw == null || raw.isEmpty) return {};
    try {
      final d = jsonDecode(raw);
      if (d is! List) return {};
      return {
        for (final e in d)
          if (e is Map && e['clientId'] != null) e['clientId'].toString(),
      };
    } catch (_) {
      return {};
    }
  }

  static Set<String> _referencedClientIds(SharedPreferences prefs) {
    final ids = <String>{};
    for (final k in clientBoundKeys) {
      final raw = prefs.getString(k);
      if (raw == null || raw.isEmpty) continue;
      try {
        final d = jsonDecode(raw);
        if (d is! List) continue;
        for (final e in d) {
          final id = e is Map ? e['clientId'] : null;
          if (id != null && id.toString().isNotEmpty) ids.add(id.toString());
        }
      } catch (_) {}
    }
    return ids;
  }

  /// Komu patří data, která už v zařízení jsou (podle jejich klientů).
  static String? _guessOwner(SharedPreferences prefs) {
    final refs = _referencedClientIds(prefs);
    if (refs.isEmpty) return null;
    final re = RegExp(r'^coach_(.+)_coach_clients_v1$');
    String? best;
    var bestCount = 0;
    for (final k in prefs.getKeys()) {
      final m = re.firstMatch(k);
      if (m == null) continue;
      final uid = m.group(1)!;
      final n = clientIdsOf(prefs, uid).intersection(refs).length;
      if (n > bestCount) {
        best = uid;
        bestCount = n;
      }
    }
    return best;
  }

  static Future<void> _move(
    SharedPreferences prefs,
    String from,
    String to,
  ) async {
    final v = prefs.get(from);
    if (v == null) return;
    if (v is String) {
      await prefs.setString(to, v);
    } else if (v is List) {
      await prefs.setStringList(to, v.cast<String>());
    } else if (v is bool) {
      await prefs.setBool(to, v);
    } else if (v is int) {
      await prefs.setInt(to, v);
    } else if (v is double) {
      await prefs.setDouble(to, v);
    }
    await prefs.remove(from);
  }

  /// Připraví data pro přihlášeného trenéra. Vrací `true`, když se data
  /// vyměnila (je potřeba znovu načíst obrazovky).
  static Future<bool> ensureFor(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    var owner = prefs.getString(ownerKey);
    if (owner == uid) return false;

    if (owner == null) {
      owner = _guessOwner(prefs) ?? uid;
      if (owner == uid) {
        await prefs.setString(ownerKey, uid);
        return false;
      }
    }

    debugPrint('ACCOUNT DATA SWITCH -> $owner => $uid');
    // Rozpracované nahrání zálohy předchozího účtu už neplatí.
    ExtraBackupService.cancelPending();
    for (final k in keys) {
      // Odložit data předchozího účtu…
      await prefs.remove(stashKey(owner, k));
      await _move(prefs, k, stashKey(owner, k));
      // …a načíst data nového účtu.
      await _move(prefs, stashKey(uid, k), k);
    }
    await prefs.setString(ownerKey, uid);

    // Mezipaměti v paměti aplikace.
    await CustomFoodStore.load();
    MealPlanMath.resetIndex();
    await PdfAuthor.loadBrand();
    return true;
  }

  /// Je hodnota shodná s daty jiného účtu odloženými v zařízení?
  /// (Pojistka proti tomu, aby se cizí data vrátila ze zálohy.)
  static bool belongsToOtherAccount(
    SharedPreferences prefs,
    String uid,
    String key,
    Object? value,
  ) {
    if (value == null) return false;
    final mine = stashKey(uid, key);
    for (final k in prefs.getKeys()) {
      if (!k.startsWith('acct_') || !k.endsWith('_$key') || k == mine) {
        continue;
      }
      final other = prefs.get(k);
      if (other is String && value is String && other == value) return true;
      if (other is List && value is List && listEquals(other, value)) {
        return true;
      }
    }
    return false;
  }

  /// Ze seznamu s klienty ponechá jen položky klientů tohoto trenéra
  /// (a položky bez klienta).
  static String filterForCoach(String json, Set<String> ownIds) {
    try {
      final d = jsonDecode(json);
      if (d is! List) return json;
      return jsonEncode([
        for (final e in d)
          if (e is! Map ||
              e['clientId'] == null ||
              e['clientId'].toString().isEmpty ||
              ownIds.contains(e['clientId'].toString()))
            e,
      ]);
    } catch (_) {
      return json;
    }
  }
}
