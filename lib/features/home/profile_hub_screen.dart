import '../common/about_app.dart';
import 'package:flutter/material.dart';
import '../help/help_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../core/nav/switch_mode.dart';
import '../../providers/locale_provider.dart';
import '../settings/appearance_card.dart';
import '../paywall/paywall_screen.dart';
import '../onboarding/onboarding_goal_screen.dart';
import '../coaching/coaching_widgets.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/client_data_deletion_service.dart';

/// Profil: cíl, jazyk, vzhled a změna režimu.
class ProfileHubScreen extends ConsumerWidget {
  const ProfileHubScreen({super.key});

  Future<void> _changeGoal(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.changeGoal),
        content: Text(l10n.changeGoalDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingGoalScreen()),
    );
  }

  void _changeMode(BuildContext context, WidgetRef ref) {
    switchToRoleSelect(context, ref);
  }

  /// Smazání všech dat klienta – dvojí potvrzení.
  Future<void> _deleteMyData(BuildContext context, WidgetRef ref) async {
    final cs = Theme.of(context).colorScheme;

    // 1. potvrzení: co se smaže
    final first = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: cs.error, size: 36),
        title: const Text('Smazat všechna moje data?'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Smaže se:'),
              SizedBox(height: 8),
              Text('• profil, cíl, zapsané jídlo, tréninky a měření v tomto telefonu'),
              Text('• data z hodinek (kroky, spánek, tep) – i ta odeslaná trenérovi'),
              Text('• propojení s trenérem a tvůj účet v aplikaci'),
              SizedBox(height: 12),
              Text(
                'Záznamy, které o tobě vede trenér (karta klienta, '
                'odcvičené tréninky), zůstanou u trenéra. O jejich smazání '
                'požádej trenéra.',
              ),
              SizedBox(height: 12),
              Text(
                'Používáš-li v tomto zařízení i trenérský režim, budeš '
                'odhlášen/a – trenérská data v cloudu zůstanou.',
              ),
              SizedBox(height: 12),
              Text(
                'Tuto akci nejde vrátit.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Pokračovat'),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    // 2. potvrzení: napsat SMAZAT
    final ctrl = TextEditingController();
    final second = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setState) {
          final ok = ctrl.text.trim().toUpperCase() == 'SMAZAT';
          return AlertDialog(
            title: const Text('Opravdu smazat?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pro potvrzení napiš slovo SMAZAT.'),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'SMAZAT',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Zrušit'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                ),
                onPressed: ok ? () => Navigator.pop(d, true) : null,
                child: const Text('Smazat navždy'),
              ),
            ],
          );
        },
      ),
    );
    ctrl.dispose();
    if (second != true || !context.mounted) return;

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(width: 16),
              Expanded(child: Text('Mažu data…')),
            ],
          ),
        ),
      ),
    );

    try {
      await ClientDataDeletionService.deleteAll();
      rootNavigator.pop();
      ref.invalidate(userProfileProvider);
      if (context.mounted) await switchToRoleSelect(context, ref);
      messenger.showSnackBar(
        const SnackBar(content: Text('Všechna tvoje data byla smazána.')),
      );
    } catch (e) {
      rootNavigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Smazání se nepodařilo dokončit: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    final languageLabel = locale == null
        ? l10n.automatic
        : (locale.languageCode == 'cs' ? l10n.czech : l10n.english);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navProfile),
        actions: const [HelpButton(topic: 'settings')],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ClientCoachCard(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.changeGoal),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _changeGoal(context),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(languageLabel),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.arrow_drop_down),
                onSelected: (code) {
                  ref.read(localeProvider.notifier).state =
                      code == 'auto' ? null : Locale(code);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'auto', child: Text(l10n.automatic)),
                  PopupMenuItem(value: 'cs', child: Text(l10n.czech)),
                  PopupMenuItem(value: 'en', child: Text(l10n.english)),
                ],
              ),
            ),
          ),
          const PlanStatusCard(),
          const SizedBox(height: 8),
          const AppearanceCard(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(l10n.changeMode),
              onTap: () => _changeMode(context, ref),
            ),
          ),
          const AboutAppTile(),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Smazat moje data',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: const Text(
                'Profil, záznamy, data z hodinek a propojení s trenérem',
              ),
              onTap: () => _deleteMyData(context, ref),
            ),
          ),
          const AuthorFooter(),
        ],
      ),
    );
  }
}
