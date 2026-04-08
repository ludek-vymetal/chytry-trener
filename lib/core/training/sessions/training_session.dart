import '../training_plan_models.dart';
import 'exercise_log_entry.dart';

class TrainingSession {
  final DateTime date;
  final TrainingDayPlan dayPlan;
  final List<ExerciseLogEntry> entries;
  final bool completed;
  final DateTime updatedAt;
  final int version;

  const TrainingSession({
    required this.date,
    required this.dayPlan,
    this.entries = const [],
    this.completed = false,
    DateTime? updatedAt,
    this.version = 1,
  }) : updatedAt = updatedAt ?? date;

  TrainingSession copyWith({
    DateTime? date,
    TrainingDayPlan? dayPlan,
    List<ExerciseLogEntry>? entries,
    bool? completed,
    DateTime? updatedAt,
    int? version,
  }) {
    return TrainingSession(
      date: date ?? this.date,
      dayPlan: dayPlan ?? this.dayPlan,
      entries: entries ?? this.entries,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}