import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';

import '../../models/goal.dart';

import '../role/role_select_screen.dart';

import 'goal_detail_screen.dart';

class OnboardingStep3
    extends ConsumerWidget {
  const OnboardingStep3({
    super.key,
  });

  void _openDetail(
    BuildContext context,
    GoalType type,
    String title,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            GoalDetailScreen(
          type: type,
          title: title,
        ),
      ),
    );
  }

  void _backToRoleSelect(
    BuildContext context,
  ) {
    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const RoleSelectScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final l10n =
        AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.changeGoal,
        ),

        leading: IconButton(
          icon: const Icon(
            Icons.swap_horiz,
          ),

          tooltip:
              l10n.changeMode,

          onPressed: () =>
              _backToRoleSelect(
            context,
          ),
        ),

        actions: [
          TextButton(
            onPressed: () =>
                _backToRoleSelect(
              context,
            ),

            child: Text(
              l10n.changeMode,
            ),
          ),
        ],
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),

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
              l10n
                  .weightGainSupportGoal,
              GoalType
                  .weightGainSupport,
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