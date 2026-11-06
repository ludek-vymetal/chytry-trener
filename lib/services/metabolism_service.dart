import '../models/user_profile.dart';

enum ActivityLevel {
  sedentary,
  light,
  moderate,
  high,
}

/// Odkud je bazální metabolismus.
enum BmrSource {
  /// Změřený přístrojem (InBody) – váha od měření se skoro nezměnila.
  measured,

  /// Katch-McArdle z beztukové hmoty z InBody (váha se od měření změnila).
  leanMass,

  /// Odhad Mifflin-St Jeor z váhy, výšky, věku a pohlaví.
  estimate,
}

class MetabolismService {
  /// Bazální metabolismus.
  ///
  /// Když je v profilu čerstvé InBody (do 6 měsíců), počítá se z beztukové
  /// hmoty (Katch-McArdle: 370 + 21,6 × beztuková hmota) – přesnější
  /// u svalnatých lidí i u vyššího podílu tuku. Když se váha od měření skoro
  /// nezměnila (do 2 kg), vezme se rovnou BMR změřený přístrojem.
  /// Bez InBody odhad Mifflin-St Jeor.
  static double calculateBMR(UserProfile profile) {
    return bmrWithSource(profile).$1;
  }

  static (double, BmrSource) bmrWithSource(UserProfile profile) {
    final comp = profile.bodyComposition;
    if (comp != null && comp.isUsable()) {
      final weightChange =
          profile.weight > 0 ? (profile.weight - comp.weightKg).abs() : 0.0;
      if (comp.bmrKcal >= 800 && comp.bmrKcal <= 4000 && weightChange <= 2) {
        return (comp.bmrKcal, BmrSource.measured);
      }
      // Po změně váhy předpokládáme stejnou beztukovou hmotu (při rozumném
      // tréninku a bílkovinách se drží) – změna jde hlavně na úkor tuku.
      var lean = comp.leanMassKg;
      if (profile.weight > 0 && lean > profile.weight) lean = profile.weight;
      return (370 + 21.6 * lean, BmrSource.leanMass);
    }

    final double base = 10 * profile.weight +
        6.25 * profile.height -
        5 * profile.age;
    return (
      profile.gender == 'male' ? base + 5 : base - 161,
      BmrSource.estimate,
    );
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

  static double multiplierFor(ActivityLevel activity) {
    switch (activity) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.high:
        return 1.725;
    }
  }

  static double calculateTDEE(
    UserProfile profile,
    ActivityLevel activity,
  ) {
    return calculateBMR(profile) * multiplierFor(activity);
  }
}
