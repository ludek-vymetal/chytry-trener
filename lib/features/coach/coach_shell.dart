import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav/switch_mode.dart';
import '../../providers/coach/coach_auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'clients/client_list_screen.dart';
import 'dashboard/coach_dashboard_screen.dart';

class CoachShell extends ConsumerStatefulWidget {
  const CoachShell({super.key});

  @override
  ConsumerState<CoachShell> createState() => _CoachShellState();
}

class _CoachShellState extends ConsumerState<CoachShell> {
  int index = 0;

  Future<void> _signOut(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    try {
      await ref.read(coachAuthControllerProvider.notifier).signOut();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Trenér byl odhlášen.'),
          backgroundColor: colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Odhlášení se nepodařilo: $e'),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    final pages = const [
      CoachDashboardScreen(),
      ClientListScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Mode'),
        actions: [
          IconButton(
            tooltip: themeMode == ThemeMode.dark
                ? 'Přepnout na světlý režim'
                : 'Přepnout na tmavý režim',
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () async {
              await ref.read(themeProvider.notifier).toggleLightDark();
            },
          ),
          IconButton(
            tooltip: 'Odhlásit trenéra',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
          IconButton(
            tooltip: 'Změnit režim',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () async {
              await switchToRoleSelect(context, ref);
            },
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Klienti',
          ),
        ],
      ),
    );
  }
}