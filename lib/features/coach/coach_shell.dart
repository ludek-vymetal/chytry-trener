import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/nav_provider.dart';
import '../common/adaptive_shell.dart';
import 'clients/client_list_screen.dart';
import 'coach_settings_screen.dart';
import 'dashboard/coach_dashboard_screen.dart';

/// Trenérský režim: Přehled · Klienti · Nastavení. Na mobilu spodní
/// lišta, na tabletu a počítači boční panel.
class CoachShell extends ConsumerWidget {
  const CoachShell({super.key});

  static const _topics = ['start', 'clients', 'settings'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final index = ref.watch(coachTabProvider);

    return AdaptiveShell(
      index: index,
      onSelect: (i) => ref.read(coachTabProvider.notifier).state = i,
      helpTopic: _topics[index],
      pages: const [
        CoachDashboardScreen(),
        ClientListScreen(),
        CoachSettingsScreen(),
      ],
      destinations: [
        ShellDestination(
            Icons.dashboard_outlined, Icons.dashboard, l10n.dashboard),
        ShellDestination(Icons.people_outline, Icons.people, l10n.clients),
        ShellDestination(
            Icons.settings_outlined, Icons.settings, l10n.settingsTitle),
      ],
    );
  }
}
