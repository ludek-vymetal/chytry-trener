import '../core/nutrition/diet_classifier.dart';
import '../models/diet_preference.dart';
import '../models/food_combo.dart';

class FoodComboService {
  /// Výběr kompletních jídel pro daný slot.
  ///
  /// - [time]: snídaně / svačina / oběd / večeře. Jídla ze starší kategorie
  ///   "Veganské" jsou hlavní jídla, nabízí se proto u oběda a večeře.
  /// - [diet]: stravovací omezení – rozhoduje SLOŽENÍ jídla (suroviny),
  ///   ne kategorie. Jídla, u kterých nejde původ surovin spolehlivě určit,
  ///   se vegetariánům a veganům nenabízí.
  static List<FoodCombo> filter(
    List<FoodCombo> all, {
    required ComboMealTime time,
    required ComboTaste taste,
    DietPreference diet = DietPreference.none,
  }) {
    final isMainMeal =
        time == ComboMealTime.lunch || time == ComboMealTime.dinner;

    return all.where((c) {
      if (!DietClassifier.allowsCombo(diet, c)) return false;

      final timeMatches =
          c.time == time || (isMainMeal && c.time == ComboMealTime.vegan);
      if (!timeMatches) return false;

      // u snídaní a svačin respektuj sladké/slané
      if (time == ComboMealTime.breakfast || time == ComboMealTime.snack) {
        if (taste == ComboTaste.any) return true;
        return c.taste == taste;
      }

      return true;
    }).toList();
  }

  static String timeLabel(ComboMealTime t) {
    switch (t) {
      case ComboMealTime.breakfast:
        return 'Snídaně';
      case ComboMealTime.snack:
        return 'Svačina';
      case ComboMealTime.lunch:
        return 'Oběd';
      case ComboMealTime.dinner:
        return 'Večeře';
      case ComboMealTime.vegan:
        return 'Veganské';
    }
  }

  static String tasteLabel(ComboTaste t) {
    switch (t) {
      case ComboTaste.savory:
        return 'Slané';
      case ComboTaste.sweet:
        return 'Sladké';
      case ComboTaste.any:
        return 'Cokoliv';
    }
  }
}
