import '../models/user_profile.dart';
import '../core/training/training_plan_models.dart';
import '../core/training/sessions/training_session.dart';
import 'training_plan_service.dart';

class TodayTrainingService {
  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// ✅ Zachováno: jednoduchý dnešní dayPlan
  static TrainingDayPlan? today(
    UserProfile profile, {
    Map<String, String> slotSelections = const {},
  }) {
    final weekly = TrainingPlanService.buildWeeklyPlan(
      profile,
      slotSelections: slotSelections,
    );
    if (weekly.isEmpty) return null;

    final int rawIndex = DateTime.now().weekday - 1; // 0..6
    final int index = rawIndex % weekly.length;
    return weekly[index];
  }

  /// ✅ NOVÉ: kompatibilní s tvým TodayTrainingScreen
  /// Vrátí TrainingSession pro dané datum, a pokud už existuje v historii,
  /// vrátí uloženou session (aby se neodmazaly logy).
  static TrainingSession? buildTodaySession(
    UserProfile profile,
    DateTime date, {
    List<TrainingSession> history = const [],
    Map<String, String> slotSelections = const {},
  }) {
    final weekly = TrainingPlanService.buildWeeklyPlan(
      profile,
      history: history,
      slotSelections: slotSelections,
    );
    if (weekly.isEmpty) return null;

    for (final s in history) {
      if (_sameDay(s.date, date)) return s;
    }

    final int rawIndex = date.weekday - 1;
    final int index = rawIndex % weekly.length;

    return TrainingSession(
      date: date,
      dayPlan: weekly[index],
      entries: const [],
      completed: false,
    );
  }
}