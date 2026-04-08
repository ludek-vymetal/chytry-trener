import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/food/food_strategy_adapter.dart';
import '../../core/phase/phase_plan.dart';
import '../../core/phase/phase_planner_service.dart';
import '../../core/phase/phase_resolver.dart';
import '../../core/phase/plan_mode.dart';
import '../../core/time/time_context.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/macro_service.dart';
import '../../services/metabolism_service.dart';

class PhaseTestScreen extends ConsumerWidget {
  const PhaseTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    if (profile == null || profile.goal == null) {
      return const Scaffold(
        body: Center(
          child: Text('Není nastaven profil nebo cíl'),
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
        current.accelerated ? PlanMode.accelerated : PlanMode.normal;

    final strategy = FoodStrategyAdapter.from(
      goal: goal,
      activePhase: current.activePlan,
      mode: activeMode,
    );

    final macros = MacroService.calculate(profile, tdee);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TEST LOGIKY FÁZÍ (CORE)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _title('ZDROJ DAT'),
            _row('Aktuální váha', '${profile.weight} kg'),
            _row('TDEE', '${tdee.round()} kcal'),
            const SizedBox(height: 16),

            _title('CÍL'),
            _row('Typ', goal.type.toString().split('.').last),
            _row('Důvod', goal.reason.toString().split('.').last),
            _row('Datum cíle', _d(goal.targetDate)),
            _row('Týdnů do cíle (ctx)', '${ctx.weeksToTarget}'),
            const SizedBox(height: 16),

            _title('AKTUÁLNÍ VYHODNOCENÍ'),
            _row('Aktuální fáze', current.phase.name),
            _row('Fáze label', _phaseLabel(current.phase.name)),
            _row('Režim', activeMode.name),
            _row('Aktivní segment', _segmentText(current.activePlan)),
            const SizedBox(height: 16),

            _title('FOOD STRATEGY'),
            _row('Strategie', strategy.label),
            _row('Důvod', strategy.rationale),
            _row(
              'Kcal multiplier',
              strategy.calorieMultiplier.toStringAsFixed(2),
            ),
            _row(
              'Protein',
              '${strategy.proteinGPerKg.toStringAsFixed(2)} g/kg',
            ),
            _row(
              'Tuky',
              '${strategy.fatGPerKg.toStringAsFixed(2)} g/kg',
            ),
            _row('High carbs', strategy.preferHighCarbs ? 'ANO' : 'NE'),
            const SizedBox(height: 16),

            _title('PHASE PLAN (celý plán)'),
            ...plans.map(
              (plan) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_phaseLabel(plan.phase.name)}${plan.accelerated ? ' (ACCEL)' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(_segmentText(plan)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _title('VÝSLEDNÁ MAKRA'),
            _row('Kalorie', '${macros.targetCalories}'),
            _row('Protein', '${macros.protein} g'),
            _row('Sacharidy', '${macros.carbs} g'),
            _row('Tuky', '${macros.fat} g'),
            const SizedBox(height: 24),

            Text(
              'Vše je řízené datem přes Core engine.',
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
      padding: const EdgeInsets.only(bottom: 6),
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}