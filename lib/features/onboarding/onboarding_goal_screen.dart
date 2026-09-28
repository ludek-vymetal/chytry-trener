import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav/switch_mode.dart';
import '../../l10n/app_localizations.dart';
import '../../models/goal.dart';

import 'goal_detail_screen.dart';

class OnboardingGoalScreen
    extends ConsumerWidget {
  const OnboardingGoalScreen({
    super.key,
  });

  void _openDetail(
    BuildContext context,
    GoalType type,
    String title,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GoalDetailScreen(
          type: type,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final l10n =
        AppLocalizations.of(context)!;

    // Otevřeno z jiné obrazovky (změna cíle, trenér u klienta) → normální
    // šipka zpět; přepínač režimu jen při prvním nastavení.
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.changeGoal,
        ),
        leading: canPop
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.swap_horiz,
                ),
                tooltip: l10n.changeMode,
                onPressed: () =>
                    switchToRoleSelect(
                  context,
                  ref,
                ),
              ),
        actions: [
          if (!canPop)
          TextButton(
            onPressed: () =>
                switchToRoleSelect(
              context,
              ref,
            ),
            child: Text(
              l10n.changeMode,
            ),
          ),
        ],
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            _goal(
              l10n.strengthGoal,
              GoalType.strength,
              context,
            ),

            _goal(
              l10n.physiqueGoal,
              GoalType.physique,
              context,
            ),

            _goal(
              l10n.weightLossGoal,
              GoalType.weightLoss,
              context,
            ),

            _goal(
              l10n.enduranceGoal,
              GoalType.endurance,
              context,
            ),

            _goal(
              l10n.weightGainSupportGoal,
              GoalType.weightGainSupport,
              context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _goal(
    String title,
    GoalType type,
    BuildContext context,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(
          Icons.arrow_forward_ios,
        ),
        onTap: () =>
            _openDetail(
          context,
          type,
          title,
        ),
      ),
    );
  }
}