import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/booking_provider.dart';
import '../../providers/nav_provider.dart';
import '../common/adaptive_shell.dart';
import 'clients/client_list_screen.dart';
import 'calendar/calendar_screen.dart';
import 'coach_settings_screen.dart';
import 'dashboard/coach_dashboard_screen.dart';
import '../spal/spal_screen.dart';

/// Trenérský režim: Přehled · Klienti · Kalendář · Nastavení · SPAL (fitko). Na mobilu spodní
/// lišta, na tabletu a počítači boční panel.
class CoachShell extends ConsumerWidget {
  const CoachShell({super.key});

  static const _topics = ['start', 'clients', 'calendar', 'settings', 'settings'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final index = ref.watch(coachTabProvider).clamp(0, 3).toInt();
    // Online rezervace klientů → kalendář (běží na pozadí).
    ref.watch(coachBookingSyncProvider);
    final newBookings = ref.watch(unseenBookingsProvider).length;

    return AdaptiveShell(
      index: index,
      onSelect: (i) {
        if (i == 4) {
          // fitko SPAL – vlastní obrazovka přes celou plochu
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SpalScreen()));
          return;
        }
        ref.read(coachTabProvider.notifier).state = i;
      },
      helpTopic: _topics[index],
      pages: const [
        CoachDashboardScreen(),
        ClientListScreen(),
        CalendarScreen(),
        CoachSettingsScreen(),
        SizedBox.shrink(),
      ],
      destinations: [
        ShellDestination(
            Icons.dashboard_outlined, Icons.dashboard, l10n.dashboard),
        ShellDestination(Icons.people_outline, Icons.people, l10n.clients),
        ShellDestination(Icons.calendar_month_outlined,
            Icons.calendar_month, 'Kalendář',
            badge: newBookings),
        ShellDestination(
            Icons.settings_outlined, Icons.settings, l10n.settingsTitle),
        const ShellDestination(Icons.qr_code_2, Icons.qr_code_2, 'SPAL'),
      ],
    );
  }
}
