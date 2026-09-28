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
        ],
      ),
    );
  }
}
