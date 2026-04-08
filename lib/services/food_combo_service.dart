import '../models/food_combo.dart';

class FoodComboService {
  static List<FoodCombo> filter(
    List<FoodCombo> all, {
    required ComboMealTime time,
    required ComboTaste taste,
  }) {
    return all.where((c) {
      if (c.time != time) return false;

      // u snídaní a svačin respektuj sladké/slané
      if (time == ComboMealTime.breakfast || time == ComboMealTime.snack) {
        if (taste == ComboTaste.any) return true;
        return c.taste == taste;
      }

      // u oběd/večeře/vegan ignorujeme taste
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
