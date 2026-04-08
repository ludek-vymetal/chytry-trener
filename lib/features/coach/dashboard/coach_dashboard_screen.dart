import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/coach/coach_circumference_controller.dart';
import '../../../providers/coach/coach_client_details_controller.dart';
import '../../../providers/coach/coach_clients_controller.dart';
import '../../../providers/coach/coach_diagnostic_controller.dart';
import '../../../providers/coach/coach_goal_controller.dart';
import '../../../providers/coach/coach_inbody_controller.dart';
import '../../../providers/coach/coach_notes_controller.dart';
import '../../../providers/coach/coach_setup_provider.dart';
import '../../../providers/daily_history_provider.dart';
import '../../../providers/daily_intake_provider.dart';
import '../../../providers/training_session_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../services/coach/coach_cloud_sync_service.dart';
import '../../help/widgets/help_and_reset_actions.dart';

class CoachDashboardScreen extends ConsumerStatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  ConsumerState<CoachDashboardScreen> createState() =>
      _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen> {
  bool _syncBusy = false;

  Future<void> _reloadCoachData() async {
    ref.invalidate(coachClientsControllerProvider);
    ref.invalidate(coachNotesControllerProvider);
    ref.invalidate(coachInbodyControllerProvider);
    ref.invalidate(coachCircumferenceControllerProvider);
    ref.invalidate(coachDiagnosticControllerProvider);
    ref.invalidate(coachGoalControllerProvider);
    ref.invalidate(trainingSessionProvider);
    ref.invalidate(dailyHistoryProvider);
    ref.invalidate(dailyIntakeProvider);
    ref.invalidate(coachSetupProvider);
    ref.invalidate(coachClientDetailsControllerProvider);

    await ref.read(coachClientsControllerProvider.notifier).reload();
    await ref.read(coachNotesControllerProvider.notifier).reload();
    await ref.read(coachInbodyControllerProvider.notifier).reload();
    await ref.read(coachCircumferenceControllerProvider.notifier).reload();
  }

  Future<void> _pushToCloud() async {
    if (_syncBusy) return;

    setState(() => _syncBusy = true);

    try {
      final report = await CoachCloudSyncService.safePushAllFromLocal();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            report.success
                ? 'Záloha do cloudu hotová. Nahrané sekce: ${report.processedKeys.length}'
                : 'Záloha se nepodařila: ${report.warnings.join(' | ')}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chyba při záloze do cloudu: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _syncBusy = false);
      }
    }
  }

  Future<void> _pullFromCloud() async {
    if (_syncBusy) return;

    setState(() => _syncBusy = true);

    try {
      final report = await CoachCloudSyncService.safePullMergeToLocal();
      await _reloadCoachData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            report.success
                ? 'Načtení z cloudu hotové. Načtené sekce: ${report.processedKeys.length}'
                : 'Načtení z cloudu se nepodařilo: ${report.warnings.join(' | ')}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chyba při načítání z cloudu: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _syncBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(coachClientsControllerProvider);
    final coachSetupAsync = ref.watch(coachSetupProvider);

    final coachFirstName = coachSetupAsync.asData?.value?.firstName.trim();
    final coachTitle = (coachFirstName != null && coachFirstName.isNotEmpty)
        ? 'Trenér $coachFirstName'
        : 'Coach Dashboard';

    return Scaffold(
      appBar: AppBar(
        title: Text(coachTitle),
        actions: const [
          HelpAndResetActions(),
        ],
      ),
      body: clientsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Chyba: $e'),
          ),
        ),
        data: (clients) {
          final warnings = clients.where((c) => c.compliance7d < 0.5).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                coachFirstName != null && coachFirstName.isNotEmpty
                    ? 'Přehled trenéra $coachFirstName'
                    : 'Přehled',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _StatCard(
                title: 'Počet klientů',
                value: clients.length.toString(),
                icon: Icons.people,
              ),
              const SizedBox(height: 12),
              _StatCard(
                title: 'Varování (7d compliance < 50%)',
                value: warnings.toString(),
                icon: Icons.warning_amber,
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Cloud záloha',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ručně nahraje nebo stáhne data mezi zařízeními.',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _syncBusy ? null : _pushToCloud,
                            icon: _syncBusy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload),
                            label: const Text('Zálohovat do cloudu'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _syncBusy ? null : _pullFromCloud,
                            icon: const Icon(Icons.cloud_download),
                            label: const Text('Načíst z cloudu'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                child: ListTile(
                  title: const Text('Přidat sebe jako klienta (MVP)'),
                  subtitle: const Text('Lokální demo bez backendu'),
                  trailing: const Icon(Icons.add),
                  onTap: () async {
                    final profile = ref.read(userProfileProvider);

                    if (profile == null) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Nejdřív dokonči Client onboarding (věk/pohlaví/výška/váha), pak půjde přidat sebe jako klienta.',
                          ),
                        ),
                      );
                      return;
                    }

                    await ref
                        .read(coachClientsControllerProvider.notifier)
                        .addCurrentUserAsClient();

                    await ref
                        .read(coachClientsControllerProvider.notifier)
                        .reload();

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Klient přidán/aktualizován.'),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}