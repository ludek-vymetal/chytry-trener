class FastingLogic {
  static Map<String, dynamic> calculateFastingWindows(
    DateTime startTime,
    String ratio,
  ) {
    var fastingHours = 16;
    var eatingHours = 8;

    if (ratio == '12:12') {
      fastingHours = 12;
      eatingHours = 12;
    } else if (ratio == '14:10') {
      fastingHours = 14;
      eatingHours = 10;
    } else if (ratio == '18:6') {
      fastingHours = 18;
      eatingHours = 6;
    } else if (ratio == '20:4') {
      fastingHours = 20;
      eatingHours = 4;
    }

    final eatingEndTime = startTime.add(Duration(hours: eatingHours));

    return {
      'startTime': startTime,
      'endTime': eatingEndTime,
      'fastingDuration': fastingHours,
      'eatingDuration': eatingHours,
    };
  }
}