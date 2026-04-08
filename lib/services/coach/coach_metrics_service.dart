import '../../core/training/sessions/training_session.dart';

class CoachMetricsService {
  /// Compliance za posledních X dní:
  /// completed / expected, kde expected aproximujeme jako "počet dní, kdy měl trénovat"
  /// -> v MVP bereme expected = min(freqPerWeek, days)
  static double complianceForDays({
    required List<TrainingSession> history,
    required DateTime now,
    required int days,
    required int frequencyPerWeek,
  }) {
    final from = now.subtract(Duration(days: days));
    final completed = history.where((s) {
      return s.completed && !s.date.isBefore(_dayStart(from)) && !s.date.isAfter(_dayEnd(now));
    }).length;

    final expected = (frequencyPerWeek.clamp(1, 7) * (days / 7.0)).round();
    final denom = expected <= 0 ? 1 : expected;

    final value = completed / denom;
    if (value.isNaN) return 0;
    return value.clamp(0.0, 1.0);
  }

  static DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _dayEnd(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);
}