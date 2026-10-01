import 'package:flutter/material.dart';
import '../help/help_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/coach/active_client_data_providers.dart';
import '../body/add_circumference_screen.dart';
import '../body/add_measurement_screen.dart';
import '../body/circumference_list_screen.dart';
import '../coach/clients/add_circumference_entry_screen.dart';
import '../coach/clients/coach_circumference_history_screen.dart';
import '../performance/performance_list_screen.dart';
import '../health/activity_screen.dart';

/// Pokrok: váha a složení těla, obvody, výkony – vše na jednom místě.
class ProgressHubScreen extends ConsumerWidget {
  const ProgressHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // Když trenér pracuje s klientem, obvody se ukládají ke klientovi.
    final coachClient = ref.watch(activeCoachClientProvider).asData?.value;

    void open(Widget screen) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    }

    Widget tile(IconData icon, String title, VoidCallback onTap) {
      return Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navProgress),
        actions: const [HelpButton(topic: 'progress')],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          tile(
            Icons.monitor_weight_outlined,
            l10n.addMeasurement,
            () => open(const AddMeasurementScreen()),
          ),
          tile(
            Icons.straighten,
            l10n.bodyCircumference,
            () => open(
              coachClient != null
                  ? CoachCircumferenceHistoryScreen(client: coachClient)
                  : const CircumferenceListScreen(),
            ),
          ),
          tile(
            Icons.add_circle_outline,
            l10n.addCircumference,
            () => open(
              coachClient != null
                  ? AddCircumferenceEntryScreen(clientId: coachClient.clientId)
                  : const AddCircumferenceScreen(),
            ),
          ),
          tile(
            Icons.emoji_events_outlined,
            l10n.performance,
            () => open(const PerformanceListScreen()),
          ),
          if (coachClient == null)
            tile(
              Icons.watch_outlined,
              'Aktivita a hodinky',
              () => open(const ActivityScreen()),
            ),
        ],
      ),
    );
  }
}
