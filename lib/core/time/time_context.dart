import '../phase/plan_mode.dart';

/// jednotný časový kontext pro CELÝ projekt
class TimeContext {
  final DateTime now;
  final DateTime targetDate;
  final PlanMode mode;

  TimeContext({
    required this.now,
    required this.targetDate,
    this.mode = PlanMode.normal,
  });

  int get daysToTarget => targetDate.difference(now).inDays;

  int get weeksToTarget => (daysToTarget / 7).floor();
}
