import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/license/license_code_service.dart';

/// Úroveň přístupu.
///
/// - [free]  – zkušební verze natrvalo: 1 klient a od každé funkce kousek.
/// - [trial] – prvních [SubscriptionController.trialDays] dní vše odemčené.
/// - [pro]   – předplatné (z obchodu nebo aktivační kód) do [validUntil].
enum AppPlan { free, trial, pro }

class SubscriptionStatus {
  final AppPlan plan;

  /// Konec předplatného (jen [AppPlan.pro]).
  final DateTime? validUntil;

  /// Konec zkušební doby zdarma (jen [AppPlan.trial]).
  final DateTime? trialEndsAt;

  const SubscriptionStatus({
    required this.plan,
    this.validUntil,
    this.trialEndsAt,
  });

  // ---------------------------------------------------------------
  // Kompatibilita se starším kódem: oba režimy jsou vždy dostupné,
  // bezplatná verze jen omezuje rozsah funkcí.
  // ---------------------------------------------------------------
  bool get clientUnlocked => true;
  bool get coachUnlocked => true;
  bool get isActive => true;

  // ---------------------------------------------------------------
  // Co je odemčené
  // ---------------------------------------------------------------
  bool get isFull => plan != AppPlan.free;
  bool get isFree => plan == AppPlan.free;

  /// Maximální počet klientů (`null` = neomezeně).
  int? get maxClients => isFull ? null : 1;

  bool get fullMealPlan => isFull;
  bool get shoppingList => isFull;
  bool get fullPrograms => isFull;
  bool get inbodyDetail => isFull;
  bool get cleanPdf => isFull;

  int? get daysLeft {
    final end = plan == AppPlan.pro ? validUntil : trialEndsAt;
    if (end == null) return null;
    return end.difference(DateTime.now()).inDays + 1;
  }

  String get label => switch (plan) {
        AppPlan.free => 'Zkušební verze',
        AppPlan.trial => 'Plná verze zdarma na zkoušku',
        AppPlan.pro => 'Plná verze',
      };
}

class SubscriptionController extends AsyncNotifier<SubscriptionStatus> {
  static const _keyValidUntil = 'sub_valid_until';
  static const _keyTrialStart = 'sub_trial_started';
  static const _keySimulateFree = 'sub_debug_simulate_free';

  /// Délka zkušební doby zdarma s plnou verzí.
  static const int trialDays = 14;

  /// Placená verze zapnutá?
  ///
  /// `false` = beta: vše odemčené (plná verze pro všechny).
  /// `true`  = ostrý provoz: zkušební doba → zkušební verze, plná verze
  ///           s předplatným nebo aktivačním kódem.
  static const bool paywallEnabled = false;

  @override
  Future<SubscriptionStatus> build() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Vývojářské testování omezené verze.
    if (kDebugMode && (prefs.getBool(_keySimulateFree) ?? false)) {
      return const SubscriptionStatus(plan: AppPlan.free);
    }

    final untilMs = prefs.getInt(_keyValidUntil);
    final until =
        untilMs == null ? null : DateTime.fromMillisecondsSinceEpoch(untilMs);
    if (until != null && until.isAfter(now)) {
      return SubscriptionStatus(plan: AppPlan.pro, validUntil: until);
    }

    if (!paywallEnabled) {
      return const SubscriptionStatus(plan: AppPlan.pro);
    }

    // Zkušební doba se počítá od prvního spuštění.
    var startMs = prefs.getInt(_keyTrialStart);
    if (startMs == null) {
      startMs = now.millisecondsSinceEpoch;
      await prefs.setInt(_keyTrialStart, startMs);
    }
    final trialEnd = DateTime.fromMillisecondsSinceEpoch(startMs)
        .add(const Duration(days: trialDays));
    if (trialEnd.isAfter(now)) {
      return SubscriptionStatus(plan: AppPlan.trial, trialEndsAt: trialEnd);
    }

    return const SubscriptionStatus(plan: AppPlan.free);
  }

  Future<void> _setUntil(DateTime until) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyValidUntil, until.millisecondsSinceEpoch);
    await prefs.remove(_keySimulateFree);
    state = AsyncData(SubscriptionStatus(plan: AppPlan.pro, validUntil: until));
  }

  /// Aktivační kód od trenéra/ky. Vrací `null` při úspěchu, jinak
  /// srozumitelnou chybu pro uživatele.
  Future<String?> redeemCode(String code) async {
    final result = await LicenseCodeService.redeem(code);
    if (result.error != null) return result.error;

    // Prodloužení: nové měsíce se přičtou ke zbývajícímu předplatnému.
    final current = state.valueOrNull;
    final base = current?.plan == AppPlan.pro &&
            current?.validUntil != null &&
            current!.validUntil!.isAfter(DateTime.now())
        ? current.validUntil!
        : DateTime.now();
    final until = DateTime(
      base.year,
      base.month + result.months,
      base.day,
      23,
      59,
    );
    await _setUntil(until);
    return null;
  }

  // ---------------------------------------------------------------
  // Jen pro testování ve vývojové verzi
  // ---------------------------------------------------------------

  Future<void> activateClientFor30Days() => activateTestFor30Days();
  Future<void> activateCoachFor30Days() => activateTestFor30Days();

  Future<void> activateTestFor30Days() =>
      _setUntil(DateTime.now().add(const Duration(days: 30)));

  /// Přepne na omezenou zkušební verzi (jen debug) – pro vyzkoušení zámků.
  Future<void> simulateFree(bool on) async {
    final prefs = await SharedPreferences.getInstance();
    if (on) {
      await prefs.setBool(_keySimulateFree, true);
      await prefs.remove(_keyValidUntil);
    } else {
      await prefs.remove(_keySimulateFree);
    }
    ref.invalidateSelf();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyValidUntil);
    await prefs.remove(_keySimulateFree);
    ref.invalidateSelf();
  }
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionController, SubscriptionStatus>(
  SubscriptionController.new,
);

/// Aktuální přístup synchronně (během načítání = plná verze, ať se nic
/// zbytečně nezamyká).
final accessProvider = Provider<SubscriptionStatus>((ref) {
  return ref.watch(subscriptionProvider).valueOrNull ??
      const SubscriptionStatus(plan: AppPlan.pro);
});
