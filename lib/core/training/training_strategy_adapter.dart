import '../../models/goal.dart';
import '../phase/phase_plan.dart';
import '../phase/phase.dart';
import '../phase/plan_mode.dart';
import 'training_strategy.dart';

class TrainingStrategyAdapter {
  static TrainingStrategy from({
    required Goal goal,
    required PhasePlan activePhase,
    PlanMode mode = PlanMode.normal, // ✅ kvůli training_service.dart
  }) {
    final phase = activePhase.phase;

    // ✅ PPP / recovery: nikdy nezrychlovat (bezpečný režim)
    final safeMode = (goal.reason == GoalReason.eatingDisorderSupport)
        ? PlanMode.normal
        : mode;

    // ✅ weightGainSupport = tréninkově jako physique (hypertrofie)
    final effectiveGoalType =
        (goal.type == GoalType.weightGainSupport) ? GoalType.physique : goal.type;

    switch (effectiveGoalType) {
      case GoalType.strength:
        return _strengthByPhase(phase, safeMode, goal.reason);

      case GoalType.physique:
        return _physiqueByPhase(phase, safeMode, goal.reason);

      case GoalType.weightLoss:
        return _weightLossByPhase(phase, safeMode, goal.reason);

      case GoalType.endurance:
        return _enduranceByPhase(phase, safeMode, goal.reason);

      // sem se prakticky nedostaneme (mapujeme na physique), ale necháme pro jistotu:
      case GoalType.weightGainSupport:
        return _physiqueByPhase(phase, safeMode, goal.reason);
    }
  }

  // ==========================================================
  // PPP / recovery “softening”
  // ==========================================================
  static TrainingStrategy _applyEatingDisorderSupport(TrainingStrategy s) {
    // Konzervativnější a méně stresující nastavení:
    // - mírně menší objem
    // - víc rezervy (RIR)
    // - žádný peaking/taper tlak
    int setsMin = (s.setsMin * 0.85).round();
    int setsMax = (s.setsMax * 0.85).round();
    if (setsMin < 1) setsMin = 1;
    if (setsMax < setsMin) setsMax = setsMin;

    return TrainingStrategy(
      label: '${s.label} (bezpečný režim)',
      rationale: '${s.rationale} Bezpečný režim: konzervativní objem, vyšší rezerva.',
      repsMin: s.repsMin,
      repsMax: s.repsMax,
      setsMin: setsMin,
      setsMax: setsMax,
      rirMin: s.rirMin + 0.5,
      rirMax: s.rirMax + 0.5,
      volumeMultiplier: s.volumeMultiplier * 0.9,
      allowDeload: true,
      deloadVolume: s.deloadVolume,
      isPeaking: false,
    );
  }

  // ==========================================================
  // STRATEGIES
  // ==========================================================
  static TrainingStrategy _strengthByPhase(
    PhaseType phase,
    PlanMode mode,
    GoalReason reason,
  ) {
    late final TrainingStrategy base;

    switch (phase) {
      case PhaseType.gaining:
      case PhaseType.maintenance:
        base = const TrainingStrategy(
          label: 'Síla',
          rationale: 'Fokus na základní cviky, nižší reps, vyšší intenzita.',
          repsMin: 1,
          repsMax: 5,
          setsMin: 8,
          setsMax: 14,
          rirMin: 0.5,
          rirMax: 2.0,
          volumeMultiplier: 1.0,
          allowDeload: true,
          deloadVolume: 0.7,
          isPeaking: false,
        );
        break;

      case PhaseType.cutting:
        base = const TrainingStrategy(
          label: 'Síla (v redukci)',
          rationale: 'Udrž výkon, lehce sniž objem, drž intenzitu.',
          repsMin: 1,
          repsMax: 5,
          setsMin: 6,
          setsMax: 10,
          rirMin: 1.0,
          rirMax: 2.5,
          volumeMultiplier: 0.85,
          allowDeload: true,
          deloadVolume: 0.65,
          isPeaking: false,
        );
        break;

      case PhaseType.peaking:
        base = const TrainingStrategy(
          label: 'Síla (peaking)',
          rationale: 'Nízký objem, vysoká intenzita, taper.',
          repsMin: 1,
          repsMax: 3,
          setsMin: 4,
          setsMax: 8,
          rirMin: 0.0,
          rirMax: 1.5,
          volumeMultiplier: 0.75,
          allowDeload: false,
          isPeaking: true,
        );
        break;
    }

    if (reason == GoalReason.eatingDisorderSupport) {
      return _applyEatingDisorderSupport(base);
    }
    return base;
  }

  static TrainingStrategy _physiqueByPhase(
    PhaseType phase,
    PlanMode mode,
    GoalReason reason,
  ) {
    final isAccel = mode == PlanMode.accelerated;

    late final TrainingStrategy base;

    switch (phase) {
      case PhaseType.gaining:
        base = TrainingStrategy(
          label: isAccel ? 'Postava (objem – rychleji)' : 'Postava (objem)',
          rationale: 'Hypertrofie: reps range, objem, progres.',
          repsMin: 6,
          repsMax: 12,
          setsMin: 10,
          setsMax: 18,
          rirMin: 1.0,
          rirMax: 3.0,
          volumeMultiplier: isAccel ? 1.05 : 1.0,
          allowDeload: true,
          deloadVolume: 0.7,
          isPeaking: false,
        );
        break;

      case PhaseType.cutting:
        base = TrainingStrategy(
          label: isAccel ? 'Postava (cut – rychleji)' : 'Postava (cut)',
          rationale: 'Udržuj svaly: drž intenzitu, mírně dolů objem.',
          repsMin: 6,
          repsMax: 12,
          setsMin: 8,
          setsMax: 14,
          rirMin: 1.0,
          rirMax: 3.0,
          volumeMultiplier: isAccel ? 0.85 : 0.9,
          allowDeload: true,
          deloadVolume: 0.65,
          isPeaking: false,
        );
        break;

      case PhaseType.peaking:
        base = const TrainingStrategy(
          label: 'Postava (rýsování)',
          rationale: 'Nižší objem, drž kvalitu, více regenerace.',
          repsMin: 6,
          repsMax: 12,
          setsMin: 6,
          setsMax: 10,
          rirMin: 1.5,
          rirMax: 3.0,
          volumeMultiplier: 0.8,
          allowDeload: false,
          isPeaking: true,
        );
        break;

      case PhaseType.maintenance:
        base = const TrainingStrategy(
          label: 'Postava (udržení)',
          rationale: 'Stabilizace: střední objem, drž rutinu.',
          repsMin: 6,
          repsMax: 12,
          setsMin: 8,
          setsMax: 14,
          rirMin: 1.0,
          rirMax: 3.0,
          volumeMultiplier: 1.0,
          allowDeload: true,
          deloadVolume: 0.7,
          isPeaking: false,
        );
        break;
    }

    if (reason == GoalReason.eatingDisorderSupport) {
      return _applyEatingDisorderSupport(base);
    }
    return base;
  }

  static TrainingStrategy _weightLossByPhase(
    PhaseType phase,
    PlanMode mode,
    GoalReason reason,
  ) {
    // Pro weightLoss chceme konzervativnější objem a víc kondice řeší UI
    late final TrainingStrategy base;

    switch (phase) {
      case PhaseType.cutting:
      case PhaseType.peaking:
        base = const TrainingStrategy(
          label: 'Hubnutí',
          rationale: 'Fullbody / lower volume, konzistentní intenzita.',
          repsMin: 6,
          repsMax: 12,
          setsMin: 6,
          setsMax: 12,
          rirMin: 1.5,
          rirMax: 3.0,
          volumeMultiplier: 0.9,
          allowDeload: true,
          deloadVolume: 0.65,
          isPeaking: false,
        );
        break;

      case PhaseType.gaining:
      case PhaseType.maintenance:
        base = const TrainingStrategy(
          label: 'Hubnutí (udržovací režim)',
          rationale: 'Když planner dá maintenance, drž sílu a rutinu.',
          repsMin: 6,
          repsMax: 12,
          setsMin: 6,
          setsMax: 12,
          rirMin: 1.5,
          rirMax: 3.0,
          volumeMultiplier: 1.0,
          allowDeload: true,
          deloadVolume: 0.7,
          isPeaking: false,
        );
        break;
    }

    // PPP režim: i u hubnutí chceme “bez tlaku” (žádné zrychlení a konzervativně)
    if (reason == GoalReason.eatingDisorderSupport) {
      return _applyEatingDisorderSupport(base);
    }
    return base;
  }

  static TrainingStrategy _enduranceByPhase(
    PhaseType phase,
    PlanMode mode,
    GoalReason reason,
  ) {
    // Endurance = síla doplněk (menší objem)
    const base = TrainingStrategy(
      label: 'Vytrvalost (síla doplněk)',
      rationale: '2× týdně fullbody jako prevence zranění.',
      repsMin: 5,
      repsMax: 10,
      setsMin: 4,
      setsMax: 8,
      rirMin: 2.0,
      rirMax: 4.0,
      volumeMultiplier: 0.8,
      allowDeload: true,
      deloadVolume: 0.7,
      isPeaking: false,
    );

    if (reason == GoalReason.eatingDisorderSupport) {
      return _applyEatingDisorderSupport(base);
    }
    return base;
  }
}