import '../models/user_profile.dart';

enum ActivityLevel {
  sedentary,
  light,
  moderate,
  high,
}

class MetabolismService {
  static double calculateBMR(UserProfile profile) {
    if (profile.gender == 'male') {
      return 10 * profile.weight +
          6.25 * profile.height -
          5 * profile.age +
          5;
    } else {
      return 10 * profile.weight +
          6.25 * profile.height -
          5 * profile.age -
          161;
    }
  }

  /// Úroveň aktivity odvozená z počtu tréninků týdně (TrainingIntake).
  /// Když uživatel ještě nevyplnil tréninkový vstup, zůstává původní
  /// výchozí hodnota `moderate`.
  static ActivityLevel activityFor(UserProfile profile) {
    final freq = profile.trainingIntake?.frequencyPerWeek;
    if (freq == null) return ActivityLevel.moderate;

    if (freq <= 1) return ActivityLevel.sedentary;
    if (freq == 2) return ActivityLevel.light;
    if (freq <= 4) return ActivityLevel.moderate;
    return ActivityLevel.high;
  }

  static double calculateTDEE(
    UserProfile profile,
    ActivityLevel activity,
  ) {
    final bmr = calculateBMR(profile);

    switch (activity) {
      case ActivityLevel.sedentary:
        return bmr * 1.2;
      case ActivityLevel.light:
        return bmr * 1.375;
      case ActivityLevel.moderate:
        return bmr * 1.55;
      case ActivityLevel.high:
        return bmr * 1.725;
    }
  }
}
