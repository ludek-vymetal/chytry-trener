import 'phase.dart';
import 'phase_plan.dart';
import '../time/time_context.dart';
import 'plan_mode.dart';

class PhasePlannerService {
  static List<PhasePlan> buildPlan(TimeContext context) {
    final now = _normalize(context.now);
    final target = _normalize(context.targetDate);

    if (target.isBefore(now)) {
      throw Exception('Cílové datum je v minulosti');
    }

    final weeks = context.weeksToTarget;

    // minima – aby to mělo smysl i při accelerated
    const minPeakingWeeks = 6;
    const minCuttingWeeks = 8;

    final needsAcceleration = weeks < (minPeakingWeeks + minCuttingWeeks);

    // 🔥 Logika režimu:
    // - když je termín nereálný => accelerated (i když context říká normal)
    // - když uživatel explicitně zvolil accelerated, zachová se
    // - jinak podle context.mode
    final mode = needsAcceleration ? PlanMode.accelerated : context.mode;

    return mode == PlanMode.normal
        ? _buildNormalPlan(now, target)
        : _buildAcceleratedPlan(now, target);
  }

  // =========================
  // NORMAL MODE (kalendář)
  // =========================
  static List<PhasePlan> _buildNormalPlan(DateTime now, DateTime target) {
    final plans = <PhasePlan>[];
    DateTime cursor = now;

    // Zima / začátek roku → nabírání do 1.4.
    final gainingEnd = DateTime(now.year, 4, 1);
    if (cursor.isBefore(gainingEnd) && gainingEnd.isBefore(target)) {
      plans.add(
        PhasePlan(
          phase: PhaseType.gaining,
          start: cursor,
          end: gainingEnd,
        ),
      );
      cursor = gainingEnd;
    }

    // Jaro → shazování do 1.6. (ALE když je cíl dřív, tak do cíle)
    final cuttingAnchorEnd = DateTime(cursor.year, 6, 1);
    final cuttingEnd = target.isBefore(cuttingAnchorEnd) ? target : cuttingAnchorEnd;

    if (cursor.isBefore(cuttingEnd)) {
      plans.add(
        PhasePlan(
          phase: PhaseType.cutting,
          start: cursor,
          end: cuttingEnd,
        ),
      );
      cursor = cuttingEnd;
    }

    // Peaking jen pokud ještě něco zbývá po cuttingu
    if (cursor.isBefore(target)) {
      plans.add(
        PhasePlan(
          phase: PhaseType.peaking,
          start: cursor,
          end: target,
        ),
      );
    }

    // Edge case: když by bylo vše stejné (např. target == now), dáme aspoň maintenance 1 den
    if (plans.isEmpty) {
      plans.add(
        PhasePlan(
          phase: PhaseType.maintenance,
          start: now,
          end: target.add(const Duration(days: 1)),
        ),
      );
    }

    return plans;
  }

  // =========================
  // ACCELERATED MODE (zpětně)
  // =========================
  static List<PhasePlan> _buildAcceleratedPlan(DateTime now, DateTime target) {
    final plans = <PhasePlan>[];

    final totalWeeks = target.difference(now).inDays ~/ 7;

    // poměr pro zrychlený režim
    final peakingWeeks = (totalWeeks * 0.4).round().clamp(4, 8);
    final cuttingWeeks = (totalWeeks * 0.6).round().clamp(6, 10);

    DateTime cursor = target;

    // 1) peaking (od konce)
    final peakingStart = cursor.subtract(Duration(days: peakingWeeks * 7));
    plans.add(
      PhasePlan(
        phase: PhaseType.peaking,
        start: peakingStart,
        end: cursor,
        accelerated: true,
      ),
    );
    cursor = peakingStart;

    // 2) cutting
    final cuttingStart = cursor.subtract(Duration(days: cuttingWeeks * 7));
    plans.add(
      PhasePlan(
        phase: PhaseType.cutting,
        start: cuttingStart,
        end: cursor,
        accelerated: true,
      ),
    );

    // 3) pokud zbude prostor → gaining
    if (cuttingStart.isAfter(now)) {
      plans.add(
        PhasePlan(
          phase: PhaseType.gaining,
          start: now,
          end: cuttingStart,
          accelerated: true,
        ),
      );
    }

    return plans.reversed.toList();
  }

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}
