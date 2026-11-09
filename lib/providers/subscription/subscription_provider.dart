import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/coach/online_coaching_service.dart';
import '../../services/license/license_code_service.dart';

/// Úroveň přístupu.
///
/// - [free]    – zkušební verze natrvalo: 1 klient a od každé funkce kousek.
/// - [trial]   – 7 dní vše odemčené. Počítá se od prvního otevření
///               Chytrého trenéra (ne od stažení aplikace kvůli SPAL).
/// - [pro]     – předplatné (z obchodu nebo aktivační kód) do [validUntil],
///               úroveň podle [tier].
/// - [coached] – klient připojený k trenérovi kódem KL-…: plný uživatelský
///               mód zdarma, dokud ho trenér neodpojí („Ukončit coaching“).
enum AppPlan { free, trial, pro, coached }

/// Druh předplatného.
/// - [klient] – Klient PRO (200 Kč/měs.): plný uživatelský mód.
/// - [trener] – Trenér PRO (500 Kč/měs.): plný trenérský mód + uživatelský.
enum AppTier { klient, trener }

AppTier tierFromString(String? s) =>
    s == 'klient' ? AppTier.klient : AppTier.trener;

class SubscriptionStatus {
  final AppPlan plan;

  /// Druh předplatného (jen [AppPlan.pro]).
  final AppTier? tier;

  /// Konec předplatného (jen [AppPlan.pro]).
  final DateTime? validUntil;

  /// Konec zkušební doby zdarma (jen [AppPlan.trial]; `null` = ještě
  /// nezačala – začne při prvním otevření Chytrého trenéra).
  final DateTime? trialEndsAt;

  /// Jméno trenéra, který klientovi dal přístup (jen [AppPlan.coached]).
  final String? coachName;

  const SubscriptionStatus({
    required this.plan,
    this.tier,
    this.validUntil,
    this.trialEndsAt,
    this.coachName,
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

  /// Plný uživatelský mód (jídelníček, programy, nákupní seznam…).
  bool get isFull => plan != AppPlan.free;
  bool get isFree => plan == AppPlan.free;

  /// Plný trenérský mód (neomezeně klientů) – jen zkušební doba
  /// nebo Trenér PRO.
  bool get coachFull =>
      plan == AppPlan.trial || (plan == AppPlan.pro && tier == AppTier.trener);

  /// Maximální počet klientů (`null` = neomezeně).
  int? get maxClients => coachFull ? null : 1;

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
        AppPlan.pro =>
          tier == AppTier.klient ? 'Klient PRO' : 'Trenér PRO',
        AppPlan.coached => coachName == null || coachName!.isEmpty
            ? 'Plná verze od trenéra'
            : 'Plná verze od trenéra ($coachName)',
      };
}

class SubscriptionController extends AsyncNotifier<SubscriptionStatus> {
  static const _keyValidUntil = 'sub_valid_until';
  static const _keyTier = 'sub_tier';
  static const _keyTrialStart = 'sub_trial_started';
  static const _keySimulateFree = 'sub_debug_simulate_free';

  /// Délka zkušební doby zdarma s plnou verzí.
  static const int trialDays = 7;

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
      return SubscriptionStatus(
        plan: AppPlan.pro,
        tier: tierFromString(prefs.getString(_keyTier)),
        validUntil: until,
      );
    }

    // Klient připojený k trenérovi: plný uživatelský mód zdarma.
    // Na pozadí se ověří, že ho trenér mezitím neodpojil (pak se propojení
    // v telefonu smaže a klient spadne do zkušební / omezené verze).
    final link = await OnlineCoachingService.localClientLink();
    if (link != null) unawaited(_overitTrenera());

    if (!paywallEnabled) {
      return const SubscriptionStatus(plan: AppPlan.pro, tier: AppTier.trener);
    }

    if (link != null) {
      return SubscriptionStatus(
        plan: AppPlan.coached,
        coachName: link.coachName,
      );
    }

    // Zkušební doba se počítá od prvního otevření Chytrého trenéra
    // ([startTrialIfNeeded]); člen SPAL, který používá jen QR ke vstupu,
    // si ji tím nespotřebuje.
    final startMs = prefs.getInt(_keyTrialStart);
    if (startMs == null) {
      return const SubscriptionStatus(plan: AppPlan.trial);
    }
    final trialEnd = DateTime.fromMillisecondsSinceEpoch(startMs)
        .add(const Duration(days: trialDays));
    if (trialEnd.isAfter(now)) {
      return SubscriptionStatus(plan: AppPlan.trial, trialEndsAt: trialEnd);
    }

    return const SubscriptionStatus(plan: AppPlan.free);
  }

  /// Spustí 7denní zkoušku, pokud ještě neběžela. Volá se při vstupu
  /// do Chytrého trenéra (RoleGate).
  Future<void> startTrialIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_keyTrialStart) != null) return;
    await prefs.setInt(_keyTrialStart, DateTime.now().millisecondsSinceEpoch);
    final cur = state.valueOrNull;
    if (cur?.plan == AppPlan.trial && cur?.trialEndsAt == null) {
      ref.invalidateSelf();
    }
  }

  /// Trenér ukončil spolupráci → klient přijde o přístup od trenéra.
  Future<void> _overitTrenera() async {
    final aktivni = await OnlineCoachingService.verifyClientLink();
    if (aktivni == false) ref.invalidateSelf();
  }

  Future<void> _setUntil(DateTime until, {AppTier tier = AppTier.trener}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyValidUntil, until.millisecondsSinceEpoch);
    await prefs.setString(_keyTier, tier.name);
    await prefs.remove(_keySimulateFree);
    state = AsyncData(
        SubscriptionStatus(plan: AppPlan.pro, tier: tier, validUntil: until));
  }

  /// Aktivační kód od trenéra/ky. Vrací `null` při úspěchu, jinak
  /// srozumitelnou chybu pro uživatele.
  Future<String?> redeemCode(String code) async {
    final result = await LicenseCodeService.redeem(code);
    if (result.error != null) return result.error;

    // Prodloužení: nové měsíce se přičtou ke zbývajícímu předplatnému.
    final current = state.valueOrNull;
    final base = current?.plan == AppPlan.pro &&
            current?.tier == result.tier &&
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
    await _setUntil(until, tier: result.tier);
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
    await prefs.remove(_keyTier);
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
      const SubscriptionStatus(plan: AppPlan.pro, tier: AppTier.trener);
});
