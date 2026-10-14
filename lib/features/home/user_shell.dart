import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/nav_provider.dart';
import '../common/adaptive_shell.dart';
import '../dashboard/dashboard_screen.dart';
import '../food/food_summary_screen.dart';
import '../training/training_overview_screen.dart';
import 'profile_hub_screen.dart';
import 'progress_hub_screen.dart';
import '../coaching/workout_widgets.dart';
import '../spal/spal_screen.dart';
import '../spal/spal_service.dart';

/// Hlavní obrazovka klienta: Dnes · Jídlo · Trénink · Pokrok · Profil
/// (+ Fitko, když je účet propojený se SPAL Strength Gym).
/// Na mobilu spodní lišta, na tabletu a počítači boční.
class UserShell extends ConsumerWidget {
  const UserShell({super.key});

  static const _topics = ['today', 'food', 'training', 'progress', 'settings', 'settings'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final spal = ref.watch(spalPrihlasenProvider).valueOrNull ?? SpalService.prihlasen;
    final pocet = spal ? 6 : 5;
    final index = ref.watch(userTabProvider).clamp(0, 4).toInt();
    assert(pocet >= 5);
    // Klient s trenérem vidí jen tréninky, které mu trenér poslal.
    final linked = ref.watch(clientLinkProvider).valueOrNull != null;
    final pages = <Widget>[
      const DashboardScreen(),
      const FoodSummaryScreen(),
      linked ? const ClientWorkoutsScreen() : const TrainingOverviewScreen(),
      const ProgressHubScreen(),
      const ProfileHubScreen(),
      if (spal) const SizedBox.shrink(), // Fitko se otevírá přes celou obrazovku
    ];

    return AdaptiveShell(
      index: index,
      onSelect: (i) {
        if (spal && i == 5) {
          // fitko má vlastní spodní lištu (jako Clubspire) → přes celou obrazovku
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SpalScreen()));
          return;
        }
        ref.read(userTabProvider.notifier).state = i;
      },
      helpTopic: _topics[index],
      pages: pages,
      destinations: [
        ShellDestination(Icons.home_outlined, Icons.home, l10n.navToday),
        ShellDestination(
            Icons.restaurant_outlined, Icons.restaurant, l10n.navFood),
        ShellDestination(Icons.fitness_center_outlined, Icons.fitness_center,
            l10n.navTraining),
        ShellDestination(Icons.show_chart, Icons.show_chart, l10n.navProgress),
        ShellDestination(Icons.person_outline, Icons.person, l10n.navProfile),
        if (spal) const ShellDestination(Icons.qr_code_2, Icons.qr_code_2, 'Fitko'),
      ],
    );
  }
}
