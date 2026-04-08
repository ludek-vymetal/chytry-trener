import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/coach/coach_client.dart';
import '../../providers/coach/active_client_data_providers.dart';
import '../../providers/user_profile_provider.dart';

class ActiveClientProfileSync extends ConsumerStatefulWidget {
  final Widget child;

  const ActiveClientProfileSync({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ActiveClientProfileSync> createState() =>
      _ActiveClientProfileSyncState();
}

class _ActiveClientProfileSyncState
    extends ConsumerState<ActiveClientProfileSync> {
  ProviderSubscription<AsyncValue<CoachClient?>>? _sub;

  String? _lastSyncedClientId;

  @override
  void initState() {
    super.initState();

    _sub = ref.listenManual<AsyncValue<CoachClient?>>(
      activeCoachClientProvider,
      (prev, next) async {
        final c = next.asData?.value;
        if (c == null) return;

        final notifier = ref.read(userProfileProvider.notifier);
        final currentProfile = ref.read(userProfileProvider);

        print(
          'ACTIVE CLIENT SYNC -> incomingClientId=${c.clientId} '
          'currentProfileClientId=${currentProfile?.clientId} '
          'currentGoal=${currentProfile?.goal?.type.name}/${currentProfile?.goal?.reason.name}',
        );

        /// 🔴 KLÍČOVÝ FIX:
        /// Pokud přepínáme klienta, MUSÍME nejdřív načíst jeho uložený profil
        /// (včetně goal), jinak ho přepíšeme základními daty z CoachClient.
        if (_lastSyncedClientId != c.clientId) {
          _lastSyncedClientId = c.clientId;

          print('ACTIVE CLIENT SYNC -> switching client, loading full profile');

          await notifier.switchToClient(c.clientId);
        }

        /// 🔴 Druhý fix:
        /// Nevolat setProfileBasics slepě pokaždé.
        /// Pouze pokud:
        /// - profil ještě není inicializovaný
        /// - nebo jde o jiného klienta
        /// - nebo chybí základní data
        final shouldUpdateBasics =
            currentProfile == null ||
            currentProfile.clientId != c.clientId ||
            currentProfile.firstName.isEmpty ||
            currentProfile.height == 0 ||
            currentProfile.weight == 0;

        if (shouldUpdateBasics) {
          print('ACTIVE CLIENT SYNC -> applying profile basics');

          await notifier.setProfileBasics(
            clientId: c.clientId,
            firstName: c.firstName,
            lastName: c.lastName,
            age: c.age,
            gender: c.gender,
            heightCm: c.heightCm,
            weightKg: c.weightKg,
          );
        } else {
          print(
            'ACTIVE CLIENT SYNC -> SKIPPED basics update (prevent overwrite)',
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}