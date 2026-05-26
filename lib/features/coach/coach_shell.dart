import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav/switch_mode.dart';
import '../../l10n/app_localizations.dart';

import '../../providers/coach/coach_auth_provider.dart';
import '../../providers/theme_provider.dart';

import 'clients/client_list_screen.dart';
import 'dashboard/coach_dashboard_screen.dart';

class CoachShell extends ConsumerStatefulWidget {
  const CoachShell({
    super.key,
  });

  @override
  ConsumerState<CoachShell> createState() =>
      _CoachShellState();
}

class _CoachShellState
    extends ConsumerState<CoachShell> {
  int index = 0;

  Future<void> _signOut(
    BuildContext context,
  ) async {
    final l10n =
        AppLocalizations.of(context)!;

    final colorScheme =
        Theme.of(context).colorScheme;

    try {
      await ref
          .read(
            coachAuthControllerProvider
                .notifier,
          )
          .signOut();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.coachSignedOut,
          ),
          backgroundColor:
              colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.signOutFailed(
              e.toString(),
            ),
          ),
          backgroundColor:
              colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context)!;

    final themeMode =
        ref.watch(themeProvider);

    final pages = const [
      CoachDashboardScreen(),
      ClientListScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.coachMode,
        ),

        actions: [
          IconButton(
            tooltip:
                themeMode ==
                        ThemeMode.dark
                    ? l10n
                        .switchToLightMode
                    : l10n
                        .switchToDarkMode,

            icon: Icon(
              themeMode ==
                      ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),

            onPressed: () async {
              await ref
                  .read(
                    themeProvider
                        .notifier,
                  )
                  .toggleLightDark();
            },
          ),

          IconButton(
            tooltip:
                l10n.logoutCoach,

            icon: const Icon(
              Icons.logout,
            ),

            onPressed: () {
              _signOut(context);
            },
          ),

          IconButton(
            tooltip:
                l10n.changeMode,

            icon: const Icon(
              Icons.swap_horiz,
            ),

            onPressed: () async {
              await switchToRoleSelect(
                context,
                ref,
              );
            },
          ),
        ],
      ),

      body: pages[index],

      bottomNavigationBar:
          NavigationBar(
        selectedIndex: index,

        onDestinationSelected:
            (i) {
          setState(() {
            index = i;
          });
        },

        destinations: [
          NavigationDestination(
            icon: const Icon(
              Icons.dashboard_outlined,
            ),

            selectedIcon:
                const Icon(
              Icons.dashboard,
            ),

            label: l10n.dashboard,
          ),

          NavigationDestination(
            icon: const Icon(
              Icons.people_outline,
            ),

            selectedIcon:
                const Icon(
              Icons.people,
            ),

            label: l10n.clients,
          ),
        ],
      ),
    );
  }
}