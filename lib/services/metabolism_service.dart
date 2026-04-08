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
