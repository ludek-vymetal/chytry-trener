import '../../../data/keto_bank.dart';
import '../../../models/user_profile.dart';
class KetoCalculator {
  static Map<String, double> calculateMacros(UserProfile profile) {
    final double targetCalories = profile.tdee * 0.9;
    const double carbs = 30.0;
    final double protein = profile.weight * 2.0;
    final double fatCalories = targetCalories - (protein * 4) - (carbs * 4);
    final double fats = fatCalories / 9;

    return {'protein': protein, 'fats': fats, 'carbs': carbs};
  }

  static List<List<Map<String, String>>> generateWeeklyKetoMenu(
    double p,
    double f,
    double c, {
    List<String> excludedFoods = const [],
  }) {
    return List.generate(
      7,
      (index) => generateKetoMenu(
        p,
        f,
        c,
        excludedFoods: excludedFoods,
      ),
    );
  }

  static List<Map<String, String>> generateKetoMenu(
    double p,
    double f,
    double c, {
    List<String> excludedFoods = const [],
  }) {
    return [
      _buildBreakfast(p * 0.25, f * 0.25, excludedFoods),
      _buildLightSnack(p * 0.15, f * 0.20, excludedFoods),
      _buildKetoMeal('Oběd', p * 0.35, f * 0.30, excludedFoods),
      _buildKetoMeal('Večeře', p * 0.25, f * 0.25, excludedFoods),
    ];
  }

  static Map<String, String> _buildBreakfast(
    double targetP,
    double targetF,
    List<String> excluded,
  ) {
    final bank = KetoBank.items;
    final eggs = bank.firstWhere(
      (m) => m.name == 'Vejce',
      orElse: () => bank.first,
    );
    final fatAddons = bank
        .where(
          (m) =>
              m.fatsPer100g > 15 &&
              m.name != 'Vejce' &&
              !excluded.contains(m.name),
        )
        .toList()
      ..shuffle();
    final addon = fatAddons.isNotEmpty ? fatAddons.first : bank.last;

    final double eggGrams =
        (targetP / (eggs.proteinPer100g / 100)).clamp(100, 250);
    final double addonGrams = (targetF / (addon.fatsPer100g / 100)) * 0.4;

    return {
      'label': 'Snídaně',
      'name': 'Vejce + ${addon.name}',
      'description':
          '${(eggGrams / 50).round()}ks Vejce (${eggGrams.round()}g) na ${addonGrams.round()}g ${addon.name}.',
      'rawMainName': 'Vejce',
      'rawMainGrams': eggGrams.toString(),
      'rawAddonName': addon.name,
      'rawAddonGrams': addonGrams.toString(),
    };
  }

  static Map<String, String> _buildLightSnack(
    double targetP,
    double targetF,
    List<String> excluded,
  ) {
    final bank = KetoBank.items;

    final lightSources = bank
        .where(
          (m) =>
              (m.name.contains('Gouda') ||
                  m.name.contains('Mandle') ||
                  m.name.contains('Avokádo') ||
                  m.name.contains('Slanina')) &&
              !excluded.contains(m.name),
        )
        .toList()
      ..shuffle();

    final main = lightSources.isNotEmpty ? lightSources.first : bank.first;

    double grams = targetP / (main.proteinPer100g / 100);
    if (main.name.contains('Mandle')) {
      grams = 30;
    } else {
      grams = grams.clamp(50, 150);
    }

    return {
      'label': 'Svačina',
      'name': 'Lehká svačina: ${main.name}',
      'description':
          '${grams.round()}g ${main.name}. Ideální ke konzumaci za studena se zeleninou.',
      'rawMainName': main.name,
      'rawMainGrams': grams.toString(),
      'rawAddonName': 'Zelenina',
      'rawAddonGrams': '100',
    };
  }

  static Map<String, String> _buildKetoMeal(
    String type,
    double targetP,
    double targetF,
    List<String> excluded,
  ) {
    final availableItems = KetoBank.items
        .where(
          (m) =>
              !excluded.contains(m.name) &&
              m.name != 'Vejce' &&
              !m.name.contains('Mandle'),
        )
        .toList();

    final pool = availableItems.isEmpty ? KetoBank.items : availableItems;
    final proteinSources = pool.where((m) => m.proteinPer100g > 15).toList()
      ..shuffle();
    final fatAddons = pool.where((m) => m.fatsPer100g > 15).toList()
      ..shuffle();

    final main = proteinSources.first;
    final addon = fatAddons.first;

    final double mainGrams =
        (targetP / (main.proteinPer100g / 100)).clamp(100, 250);
    final double addonGrams = (targetF / (addon.fatsPer100g / 100)) * 0.5;

    return {
      'label': type,
      'name': '${main.name} + ${addon.name}',
      'description':
          '${mainGrams.round()}g ${main.name} připravené na ${addonGrams.round()}g ${addon.name}.',
      'rawMainName': main.name,
      'rawMainGrams': mainGrams.toString(),
      'rawAddonName': addon.name,
      'rawAddonGrams': addonGrams.toString(),
    };
  }

  static Map<String, double> getShoppingList(
    List<List<Map<String, String>>> weeklyMenu,
  ) {
    final Map<String, double> totals = {};

    for (final day in weeklyMenu) {
      for (final meal in day) {
        if (meal['rawMainName'] != null) {
          final name = meal['rawMainName']!;
          final grams = double.tryParse(meal['rawMainGrams']!) ?? 0;
          totals[name] = (totals[name] ?? 0) + grams;
        }

        if (meal['rawAddonName'] != null &&
            meal['rawAddonName'] != 'Zelenina') {
          final name = meal['rawAddonName']!;
          final grams = double.tryParse(meal['rawAddonGrams']!) ?? 0;
          totals[name] = (totals[name] ?? 0) + grams;
        }
      }
    }

    return totals;
  }
}