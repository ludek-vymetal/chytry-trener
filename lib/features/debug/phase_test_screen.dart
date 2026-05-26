import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/food/food_strategy_adapter.dart';
import '../../core/phase/phase_plan.dart';
import '../../core/phase/phase_planner_service.dart';
import '../../core/phase/phase_resolver.dart';
import '../../core/phase/plan_mode.dart';
import '../../core/time/time_context.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/macro_service.dart';
import '../../services/metabolism_service.dart';

class PhaseTestScreen extends ConsumerWidget {
  const PhaseTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final profile = ref.watch(userProfileProvider);

    if (profile == null || profile.goal == null) {
      return Scaffold(
        body: Center(
          child: Text(
            l10n.profileOrGoalNotSet,
          ),
        ),
      );
    }

    final goal = profile.goal!;
    final now = DateTime.now();

    final tdee = MetabolismService.calculateTDEE(
      profile,
      ActivityLevel.moderate,
    );

    final ctx = TimeContext(
      now: now,
      targetDate: goal.targetDate,
      mode: PlanMode.normal,
    );

    final plans = PhasePlannerService.buildPlan(ctx);

    final current = PhaseResolver.resolveCurrentPhase(
      plans: plans,
      date: now,
    );

    final activeMode =
        current.accelerated
            ? PlanMode.accelerated
            : PlanMode.normal;

    final strategy = FoodStrategyAdapter.from(
      goal: goal,
      activePhase: current.activePlan,
      mode: activeMode,
    );

    final macros = MacroService.calculate(
      profile,
      tdee,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.phaseLogicCoreTest,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _title(l10n.dataSource),

            _row(
              l10n.currentWeight,
              '${profile.weight} kg',
            ),

            _row(
              l10n.tdee,
              '${tdee.round()} kcal',
            ),

            const SizedBox(height: 16),

            _title(l10n.goal),

            _row(
              l10n.type,
              goal.type.toString().split('.').last,
            ),

            _row(
              l10n.reason,
              goal.reason.toString().split('.').last,
            ),

            _row(
              l10n.goalDate,
              _d(goal.targetDate),
            ),

            _row(
              l10n.weeksToGoal,
              '${ctx.weeksToTarget}',
            ),

            const SizedBox(height: 16),

            _title(l10n.currentEvaluation),

            _row(
              l10n.currentPhase,
              current.phase.name,
            ),

            _row(
              l10n.phaseLabel,
              _phaseLabel(current.phase.name),
            ),

            _row(
              l10n.mode,
              activeMode.name,
            ),

            _row(
              l10n.activeSegment,
              _segmentText(current.activePlan),
            ),

            const SizedBox(height: 16),

            _title(l10n.foodStrategy),

            _row(
              l10n.strategy,
              strategy.labelKey,
            ),

            _row(
              l10n.reason,
              strategy.labelKey,
            ),

            _row(
              l10n.calorieMultiplier,
              strategy.calorieMultiplier
                  .toStringAsFixed(2),
            ),

            _row(
              l10n.protein,
              '${strategy.proteinGPerKg.toStringAsFixed(2)} g/kg',
            ),

            _row(
              l10n.fats,
              '${strategy.fatGPerKg.toStringAsFixed(2)} g/kg',
            ),

            _row(
              l10n.highCarbs,
              strategy.preferHighCarbs
                  ? l10n.yes
                  : l10n.no,
            ),

            const SizedBox(height: 16),

            _title(l10n.phasePlan),

            ...plans.map(
              (plan) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_phaseLabel(plan.phase.name)}${plan.accelerated ? ' (ACCEL)' : ''}',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _segmentText(plan),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            _title(l10n.finalMacros),

            _row(
              l10n.calories,
              '${macros.targetCalories}',
            ),

            _row(
              l10n.protein,
              '${macros.protein} g',
            ),

            _row(
              l10n.carbs,
              '${macros.carbs} g',
            ),

            _row(
              l10n.fats,
              '${macros.fat} g',
            ),

            const SizedBox(height: 24),

            Text(
              l10n.coreEngineInfo,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _segmentText(PhasePlan plan) {
    return '${_d(plan.start)} → ${_d(plan.end)} (${plan.durationInWeeks} týd.)';
  }

  String _d(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _phaseLabel(String phaseName) {
    switch (phaseName) {
      case 'build':
        return 'Build';

      case 'cut':
        return 'Cut';

      case 'peak':
        return 'Peak';

      case 'dietBreak':
        return 'Diet break';

      case 'maintain':
        return 'Maintain';

      default:
        return phaseName;
    }
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 6,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 2,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}