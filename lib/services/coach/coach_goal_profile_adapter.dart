import '../../models/coach/coach_goal.dart';
import '../../models/goal.dart';
import '../../models/user_profile.dart';

class CoachGoalProfileAdapter {
  static UserProfile applyToProfile({
    required UserProfile profile,
    required CoachGoal? coachGoal,
  }) {
    if (coachGoal == null || coachGoal.isDeleted) {
      return profile;
    }

    final mappedGoal = _mapCoachGoal(
      coachGoal: coachGoal,
      fallbackGoal: profile.goal,
    );

    return profile.copyWith(
      goal: mappedGoal,
      clearGoal: false,
    );
  }

  static Goal _mapCoachGoal({
    required CoachGoal coachGoal,
    required Goal? fallbackGoal,
  }) {
    final now = DateTime.now();

    return Goal(
      type: _mapGoalType(coachGoal.goalType),
      reason: _mapGoalReason(coachGoal),
      startDate: fallbackGoal?.startDate ?? now,
      targetDate: fallbackGoal?.targetDate ?? now.add(const Duration(days: 112)),
      planMode: fallbackGoal?.planMode ?? _mapPlanMode(coachGoal),
      phase: fallbackGoal?.phase,
      targetWeightKg: coachGoal.targetWeightKg ?? fallbackGoal?.targetWeightKg,
      note: _mergeNotes(
        coachGoal.goalDetail,
        coachGoal.note,
        fallbackGoal?.note,
      ),
    );
  }

  static GoalType _mapGoalType(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'sila':
        return GoalType.strength;
      case 'postava':
        return GoalType.physique;
      case 'hubnuti':
        return GoalType.weightLoss;
      case 'vytrvalost':
        return GoalType.endurance;
      case 'nabirani':
      case 'podpora_prijmu':
        return GoalType.weightGainSupport;
      default:
        return GoalType.physique;
    }
  }

  static GoalReason _mapGoalReason(CoachGoal coachGoal) {
    final haystack =
        '${coachGoal.goalType} ${coachGoal.goalDetail} ${coachGoal.note}'
            .toLowerCase();

    if (_containsAny(haystack, const [
      'závod',
      'zavod',
      'soutěž',
      'soutez',
      'competition',
    ])) {
      return GoalReason.competition;
    }

    if (_containsAny(haystack, const [
      'ppp',
      'recovery',
      'porucha příjmu',
      'porucha prijmu',
      'eating disorder',
    ])) {
      return GoalReason.eatingDisorderSupport;
    }

    if (_containsAny(haystack, const [
      'forma',
      'aesthetic',
      'estetika',
      'redukce tuku',
      'léto',
      'leto',
      'summer',
    ])) {
      return GoalReason.aesthetic;
    }

    if (_containsAny(haystack, const [
      'výkon',
      'vykon',
      'performance',
      'síla',
      'sila',
      'vytrvalost',
    ])) {
      return GoalReason.performance;
    }

    if (_containsAny(haystack, const [
      'zdraví',
      'zdravi',
      'health',
    ])) {
      return GoalReason.health;
    }

    switch (_mapGoalType(coachGoal.goalType)) {
      case GoalType.strength:
        return GoalReason.performance;
      case GoalType.physique:
        return GoalReason.aesthetic;
      case GoalType.weightLoss:
        return GoalReason.health;
      case GoalType.endurance:
        return GoalReason.performance;
      case GoalType.weightGainSupport:
        return GoalReason.eatingDisorderSupport;
    }
  }

  static GoalPlanMode _mapPlanMode(CoachGoal coachGoal) {
    final haystack =
        '${coachGoal.goalDetail} ${coachGoal.note}'.toLowerCase();

    if (_containsAny(haystack, const [
      'rychle',
      'rychleji',
      'accelerated',
      'agresivně',
      'agresivne',
    ])) {
      return GoalPlanMode.accelerated;
    }

    if (_containsAny(haystack, const [
      'normal',
      'standard',
      'klidně',
      'klidne',
      'pozvolna',
    ])) {
      return GoalPlanMode.normal;
    }

    return GoalPlanMode.auto;
  }

  static bool _containsAny(String haystack, List<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(needle)) {
        return true;
      }
    }
    return false;
  }

  static String? _mergeNotes(
    String goalDetail,
    String coachNote,
    String? fallbackNote,
  ) {
    final parts = <String>[
      if (goalDetail.trim().isNotEmpty) goalDetail.trim(),
      if (coachNote.trim().isNotEmpty) coachNote.trim(),
      if (fallbackNote != null && fallbackNote.trim().isNotEmpty)
        fallbackNote.trim(),
    ];

    if (parts.isEmpty) return null;
    return parts.join(' | ');
  }
}