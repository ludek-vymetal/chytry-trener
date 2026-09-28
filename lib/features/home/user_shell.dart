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

/// Hlavní obrazovka klienta: Dnes · Jídlo · Trénink · Pokrok · Profil.
/// Na mobilu spodní lišta, na tabletu a počítači boční.
class UserShell extends ConsumerWidget {
  const UserShell({super.key});

  static const _pages = <Widget>[
    DashboardScreen(),
    FoodSummaryScreen(),
    TrainingOverviewScreen(),
    ProgressHubScreen(),
    ProfileHubScreen(),
  ];

  static const _topics = ['today', 'food', 'training', 'progress', 'settings'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final index = ref.watch(userTabProvider);

    return AdaptiveShell(
      index: index,
      onSelect: (i) => ref.read(userTabProvider.notifier).state = i,
      helpTopic: _topics[index],
      pages: _pages,
      destinations: [
        ShellDestination(Icons.home_outlined, Icons.home, l10n.navToday),
        ShellDestination(
            Icons.restaurant_outlined, Icons.restaurant, l10n.navFood),
        ShellDestination(Icons.fitness_center_outlined, Icons.fitness_center,
            l10n.navTraining),
        ShellDestination(Icons.show_chart, Icons.show_chart, l10n.navProgress),
        ShellDestination(Icons.person_outline, Icons.person, l10n.navProfile),
      ],
    );
  }
}
