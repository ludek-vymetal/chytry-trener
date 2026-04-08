class FastingLogic {
  static Map<String, dynamic> calculateFastingWindows(DateTime startTime, String ratio) {
    // Pro poměr 16:8
    int fastingHours = 16;
    int eatingHours = 8;

    if (ratio == "18:6") {
      fastingHours = 18;
      eatingHours = 6;
    }

    final DateTime eatingEndTime = startTime.add(Duration(hours: eatingHours));
    
    return {
      'startTime': startTime,
      'endTime': eatingEndTime,
      'fastingDuration': fastingHours,
      'eatingDuration': eatingHours,
    };
  }
}