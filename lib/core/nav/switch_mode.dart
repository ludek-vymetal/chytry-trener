import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/role/role_select_screen.dart';
import '../../providers/coach/active_client_provider.dart';
import '../../providers/user_profile_provider.dart';

Future<void> switchToRoleSelect(BuildContext context, WidgetRef ref) async {
  final profileNotifier = ref.read(userProfileProvider.notifier);
  final currentProfile = ref.read(userProfileProvider);

  print(
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

  print(
    'SWITCH TO ROLE SELECT DONE -> '
    'stateClientId=${detachedProfile?.clientId} '
    'stateGoal=${detachedProfile?.goal?.type.name}/${detachedProfile?.goal?.reason.name}',
  );

  if (!context.mounted) return;

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
    (_) => false,
  );
}