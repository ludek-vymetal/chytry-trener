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

  Future<void> _deleteAccount(
    BuildContext context,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );

    if (password == null || password.isEmpty) return;

    try {
      await ref
          .read(coachAuthControllerProvider.notifier)
          .deleteAccount(password: password);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountDeleted)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deleteAccountFailed(e.toString())),
          backgroundColor: colorScheme.error,
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
            tooltip: l10n.deleteAccount,
            icon: const Icon(Icons.no_accounts),
            onPressed: () {
              _deleteAccount(context);
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

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _obscured = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteAccountWarning),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscured,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.deleteAccountPasswordLabel,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(
                    _obscured ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, _passwordController.text),
          child: Text(l10n.deleteAccountConfirm),
        ),
      ],
    );
  }
}
