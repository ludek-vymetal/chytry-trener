import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/coach/app_role_provider.dart';
import '../../providers/coach/active_client_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../features/coach/auth/coach_pin_gate.dart';

Future<void> switchToRoleSelect(BuildContext context, WidgetRef ref) async {
  final profileNotifier = ref.read(userProfileProvider.notifier);
  final currentProfile = ref.read(userProfileProvider);

  debugPrint(
    'SWITCH TO ROLE SELECT START -> '
    'currentClientId=${currentProfile?.clientId} '
    'currentGoal=${currentProfile?.goal?.type.name}/${currentProfile?.goal?.reason.name}',
  );

  // 1) odpoj aktivního klienta v coach flow
  await ref.read(activeClientIdProvider.notifier).clear();

  // 2) odpoj i aktuální UserProfile od klienta,
  //    ale vytvoř čistý profil bez načtení legacy dat
  await profileNotifier.switchToClient(null);

  final detachedProfile = ref.read(userProfileProvider);

  debugPrint(
    'SWITCH TO ROLE SELECT DONE -> '
    'stateClientId=${detachedProfile?.clientId} '
    'stateGoal=${detachedProfile?.goal?.type.name}/${detachedProfile?.goal?.reason.name}',
  );

  // Trenérský režim se po změně režimu znovu zamkne PINem.
  CoachPinGate.lock();

  // 3) zruš uloženou roli – aplikace se sama vrátí na výběr režimu.
  //    (Dřív se výběr jen „přidal“ nad současný režim; když pak uživatel
  //    zvolil stejný režim, role se nezměnila a nic se nestalo.)
  await ref.read(appRoleProvider.notifier).setRole(null);
}