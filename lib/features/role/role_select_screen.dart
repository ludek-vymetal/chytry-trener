import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/coach/active_client_provider.dart';
import '../../providers/coach/app_role_provider.dart';
import '../../providers/subscription/subscription_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../paywall/paywall_screen.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  bool _switching = false;

  void _openPaywall(BuildContext context, PaywallTarget target) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaywallScreen(target: target)),
    );
  }

  Future<void> _prepareForUserMode() async {
    final currentProfile = ref.read(userProfileProvider);

    debugPrint(
      'ROLE PREP USER START -> '
      'currentClientId=${currentProfile?.clientId} '
      'currentGoal=${currentProfile?.goal?.type.name}/${currentProfile?.goal?.reason.name}',
    );

    await ref.read(activeClientIdProvider.notifier).clear();
    await ref.read(userProfileProvider.notifier).switchToClient(null);

    final detachedProfile = ref.read(userProfileProvider);

    debugPrint(
      'ROLE PREP USER DONE -> '
      'stateClientId=${detachedProfile?.clientId} '
      'stateGoal=${detachedProfile?.goal?.type.name}/${detachedProfile?.goal?.reason.name}',
    );
  }

  Future<void> _prepareForCoachMode() async {
    final currentProfile = ref.read(userProfileProvider);

    debugPrint(
      'ROLE PREP COACH START -> '
      'currentClientId=${currentProfile?.clientId} '
      'currentGoal=${currentProfile?.goal?.type.name}/${currentProfile?.goal?.reason.name}',
    );

    await ref.read(activeClientIdProvider.notifier).clear();
    await ref.read(userProfileProvider.notifier).switchToClient(null);

    final detachedProfile = ref.read(userProfileProvider);

    debugPrint(
      'ROLE PREP COACH DONE -> '
      'stateClientId=${detachedProfile?.clientId} '
      'stateGoal=${detachedProfile?.goal?.type.name}/${detachedProfile?.goal?.reason.name}',
    );
  }

  Future<void> _switchToUser(bool clientLocked) async {
    if (_switching) return;

    debugPrint('ROLE BUTTON USER CLICK');

    if (clientLocked) {
      debugPrint('USER LOCKED -> PAYWALL');
      _openPaywall(context, PaywallTarget.client);
      return;
    }

    setState(() => _switching = true);

    try {
      await _prepareForUserMode();

      debugPrint('SETTING ROLE USER');
      await ref.read(appRoleProvider.notifier).setRole(AppRole.user);
      debugPrint('ROLE USER SET DONE');
    } finally {
      if (mounted) {
        setState(() => _switching = false);
      }
    }
  }

  Future<void> _switchToCoach(bool coachLocked) async {
    if (_switching) return;

    debugPrint('ROLE BUTTON COACH CLICK');

    if (coachLocked) {
      debugPrint('COACH LOCKED -> PAYWALL');
      _openPaywall(context, PaywallTarget.coach);
      return;
    }

    setState(() => _switching = true);

    try {
      await _prepareForCoachMode();

      debugPrint('SETTING ROLE COACH');
      await ref.read(appRoleProvider.notifier).setRole(AppRole.coach);
      debugPrint('ROLE COACH SET DONE');
    } finally {
      if (mounted) {
        setState(() => _switching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chytrý trenér')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: subAsync.when(
                  loading: () => const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SizedBox(
                    height: 220,
                    child: Center(child: Text('Chyba předplatného: $e')),
                  ),
                  data: (sub) {
                    final active = sub.isActive;
                    final clientLocked = !active || !sub.clientUnlocked;
                    final coachLocked = !active || !sub.coachUnlocked;

                    String statusText() {
                      if (!active) return 'Předplatné není aktivní.';
                      if (sub.coachUnlocked) {
                        return 'Aktivní: Coach + Client ✅';
                      }
                      if (sub.clientUnlocked) {
                        return 'Aktivní: Client ✅ (Coach zamčený)';
                      }
                      return 'Bez přístupu';
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Vyber režim',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          statusText(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Běžný uživatel = onboarding + AI plán.\n'
                          'Trenérský mód = správa klientů.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              clientLocked ? Icons.lock : Icons.person,
                            ),
                            label: _switching
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    clientLocked
                                        ? 'Běžný uživatel (zamčeno)'
                                        : 'Běžný uživatel',
                                  ),
                            onPressed: _switching
                                ? null
                                : () => _switchToUser(clientLocked),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              coachLocked
                                  ? Icons.lock
                                  : Icons.admin_panel_settings,
                            ),
                            label: _switching
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    coachLocked
                                        ? 'Trenérský mód (zamčeno)'
                                        : 'Trenérský mód',
                                  ),
                            onPressed: _switching
                                ? null
                                : () => _switchToCoach(coachLocked),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!active) ...[
                          TextButton(
                            onPressed: () =>
                                _openPaywall(context, PaywallTarget.client),
                            child: const Text('Odemknout Client (Paywall)'),
                          ),
                        ] else if (sub.clientUnlocked && !sub.coachUnlocked) ...[
                          TextButton(
                            onPressed: () =>
                                _openPaywall(context, PaywallTarget.coach),
                            child: const Text('Odemknout Coach (upgrade)'),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}