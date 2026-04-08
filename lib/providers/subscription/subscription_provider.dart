import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionStatus {
  final bool clientUnlocked;
  final bool coachUnlocked;
  final DateTime? validUntil;

  const SubscriptionStatus({
    required this.clientUnlocked,
    required this.coachUnlocked,
    required this.validUntil,
  });

  // UPRAVENO: Pro testování vracíme true, pokud je cokoli odemčeno
  bool get isActive => clientUnlocked || coachUnlocked;

  SubscriptionStatus copyWith({
    bool? clientUnlocked,
    bool? coachUnlocked,
    DateTime? validUntil,
  }) {
    return SubscriptionStatus(
      clientUnlocked: clientUnlocked ?? this.clientUnlocked,
      coachUnlocked: coachUnlocked ?? this.coachUnlocked,
      validUntil: validUntil ?? this.validUntil,
    );
  }
}

class SubscriptionController extends AsyncNotifier<SubscriptionStatus> {
  static const _keyValidUntil = 'sub_valid_until';
  static const _keyClient = 'sub_client_unlocked';
  static const _keyCoach = 'sub_coach_unlocked';

  @override
  Future<SubscriptionStatus> build() async {
    // PRO TESTOVÁNÍ: Ignorujeme paměť a vracíme vše odemčené hned po startu
    return SubscriptionStatus(
      clientUnlocked: true,
      coachUnlocked: true,
      validUntil: DateTime.now().add(const Duration(days: 36500)),
    );
  }

  // Pomocná funkce pro nastavení "nekonečného" data (100 let)
  DateTime get _forever => DateTime.now().add(const Duration(days: 36500));

  Future<void> activateClientFor30Days() async {
    final prefs = await SharedPreferences.getInstance();
    final until = _forever;

    await prefs.setBool(_keyClient, true);
    await prefs.setBool(_keyCoach, false);
    await prefs.setInt(_keyValidUntil, until.millisecondsSinceEpoch);

    state = AsyncData(SubscriptionStatus(
      clientUnlocked: true, 
      coachUnlocked: false, 
      validUntil: until,
    ));
  }

  Future<void> activateCoachFor30Days() async {
    final prefs = await SharedPreferences.getInstance();
    final until = _forever;

    await prefs.setBool(_keyClient, true);
    await prefs.setBool(_keyCoach, true);
    await prefs.setInt(_keyValidUntil, until.millisecondsSinceEpoch);

    state = AsyncData(SubscriptionStatus(
      clientUnlocked: true, 
      coachUnlocked: true, 
      validUntil: until,
    ));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyClient);
    await prefs.remove(_keyCoach);
    await prefs.remove(_keyValidUntil);

    state = const AsyncData(SubscriptionStatus(
      clientUnlocked: false, 
      coachUnlocked: false, 
      validUntil: null,
    ));
  }
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionController, SubscriptionStatus>(SubscriptionController.new);