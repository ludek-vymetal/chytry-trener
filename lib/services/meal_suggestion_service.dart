import '../core/nutrition/diet_classifier.dart';
import '../features/diet_plans/logic/food_catalog.dart';
import '../features/diet_plans/logic/portion_solver.dart';
import '../models/diet_preference.dart';
import '../models/meal.dart';

class MealPortion {
  final Meal meal;
  final int grams;

  MealPortion({required this.meal, required this.grams});

  int get calories => (meal.caloriesPer100g * grams / 100).round();
  int get protein => (meal.proteinPer100g * grams / 100).round();
  int get carbs => (meal.carbsPer100g * grams / 100).round();
  int get fat => (meal.fatsPer100g * grams / 100).round();
}

class MealSuggestion {
  final String title;

  /// text pro UI (např. "Kuřecí prsa 200 g")
  final List<String> items;

  /// reálné porce pro zápis do dne
  final List<MealPortion> portions;

  /// makra jídla spočítaná z gramáží
  final int protein;
  final int carbs;
  final int fat;

  /// kcal spočítané z gramáží
  final int calories;

  MealSuggestion({
    required this.title,
    required this.items,
    required this.portions,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
  });
}

/// Dopočítání jídla do zbytku dne z potravin v databance.
///
/// Zásady:
///  - zbývající makra se rozdělí do zvoleného počtu jídel; odchylka jídla
///    (zaokrouhlení, maxima porcí) se přenáší do dalšího jídla,
///  - gramáže se počítají se VŠEMI makry potravin (PortionSolver),
///  - respektuje se stravovací omezení (vegetarián / vegan) – potraviny,
///    u kterých nejde spolehlivě určit původ, se nenabízí,
///  - hotová jídla ("HOTOVKA") se jako složky nepoužívají.
class MealSuggestionService {
  // --- kategorizace (aby se nevybíral olej jako "jídlo") ---
  static bool _isOilOrPureFat(Meal m) {
    final n = m.name.toLowerCase();
    if (n.contains('olej')) return true;
    if (n.contains('máslo')) return true;
    if (n.contains('tahini')) return true;
    if (m.fatsPer100g >= 80 && m.proteinPer100g < 5 && m.carbsPer100g < 5) {
      return true;
    }
    return false;
  }

  static bool _isPowder(Meal m) {
    final n = m.name.toLowerCase();
    return n.contains('protein') && m.proteinPer100g >= 60;
  }

  static bool _isReadyMeal(Meal m) =>
      m.name.trim().toUpperCase().startsWith('HOTOVKA');

  static bool _isVegOrLowKcal(Meal m) {
    return m.caloriesPer100g <= 60 && m.proteinPer100g < 8;
  }

  static double _scoreProtein(Meal m) {
    var score = (m.proteinPer100g * 2) - (m.fatsPer100g * 0.4) - (m.carbsPer100g * 0.2);
    if (_isOilOrPureFat(m)) score -= 999;
    if (_isVegOrLowKcal(m)) score -= 25;
    return score;
  }

  static double _scoreCarbs(Meal m) {
    var score = (m.carbsPer100g * 2) - (m.fatsPer100g * 0.35) - (m.proteinPer100g * 0.2);
    if (_isOilOrPureFat(m)) score -= 999;
    if (_isVegOrLowKcal(m)) score -= 10;
    return score;
  }

  static double _scoreFats(Meal m) {
    var score = (m.fatsPer100g * 2) - (m.carbsPer100g * 0.2);
    if (_isVegOrLowKcal(m)) score -= 20;
    return score;
  }

  static List<Meal> _top(
    List<Meal> bank,
    double Function(Meal) score, {
    required bool Function(Meal) where,
    int take = 10,
  }) {
    final filtered = bank.where(where).toList();
    filtered.sort((a, b) => score(b).compareTo(score(a)));
    return filtered.take(take).toList();
  }

  static Meal? _pick(List<Meal> list, int i, {Set<String> avoid = const {}}) {
    if (list.isEmpty) return null;
    for (var k = 0; k < list.length; k++) {
      final m = list[(i + k) % list.length];
      if (!avoid.contains(m.name)) return m;
    }
    return null;
  }

  /// Potravina z databanky → potravina pro výpočet porcí.
  static NutritionFood _asFood(Meal m) {
    final pureFat = _isOilOrPureFat(m);
    return NutritionFood(
      id: m.name,
      name: m.name,
      kcal: m.caloriesPer100g.toDouble(),
      protein: m.proteinPer100g,
      carbs: m.carbsPer100g,
      fat: m.fatsPer100g,
      maxGrams: pureFat ? 30 : 500,
      minGrams: pureFat ? 5 : 20,
    );
  }

  static List<MealSuggestion> suggest({
    required int missingProtein,
    required int missingCarbs,
    required int missingFat,
    required List<Meal> bank,
    required int mealsCount,
    DietPreference preference = DietPreference.none,
  }) {
    if (bank.isEmpty || mealsCount <= 0) return [];

    final usable = bank
        .where(
          (m) =>
              !_isReadyMeal(m) &&
              m.caloriesPer100g > 0 &&
              DietClassifier.allowsName(preference, m.name),
        )
        .toList();

    if (usable.isEmpty) return [];

    final proteinMeals = _top(
      usable,
      _scoreProtein,
      where: (m) => m.proteinPer100g >= 10 && !_isOilOrPureFat(m),
      take: 12,
    );

    final carbMeals = _top(
      usable,
      _scoreCarbs,
      where: (m) => m.carbsPer100g >= 15 && !_isOilOrPureFat(m),
      take: 12,
    );

    // Tukové zdroje: ořechy, semínka, avokádo, sýry – čistý olej/máslo
    // se jako samostatná "potravina" do jídla nenabízí.
    final fatMeals = _top(
      usable,
      _scoreFats,
      where: (m) => m.fatsPer100g >= 15 && !_isOilOrPureFat(m),
      take: 10,
    );

    final out = <MealSuggestion>[];

    var remP = missingProtein.toDouble();
    var remC = missingCarbs.toDouble();
    var remF = missingFat.toDouble();

    for (var i = 0; i < mealsCount; i++) {
      final left = mealsCount - i;
      final tP = remP > 0 ? remP / left : 0.0;
      final tC = remC > 0 ? remC / left : 0.0;
      final tF = remF > 0 ? remF / left : 0.0;

      // Dva bílkovinné zdroje (u rostlinné stravy mají zdroje bílkovin
      // hodně sacharidů/tuků, dva různé dávají víc volnosti), sacharidový
      // a tukový zdroj. Výpočet porcí rozhodne, co se opravdu použije.
      final pMeal = _pick(proteinMeals, i);
      // Druhý zdroj bílkovin – ne dva proteinové prášky v jednom jídle.
      final p2Meal = _pick(
        proteinMeals,
        i + 1,
        avoid: {
          if (pMeal != null) pMeal.name,
          if (pMeal != null && _isPowder(pMeal))
            for (final m in proteinMeals)
              if (_isPowder(m)) m.name,
        },
      );
      final cMeal = _pick(
        carbMeals,
        i,
        avoid: {
          if (pMeal != null) pMeal.name,
          if (p2Meal != null) p2Meal.name,
        },
      );
      final fMeal = _pick(
        fatMeals,
        i,
        avoid: {
          if (pMeal != null) pMeal.name,
          if (p2Meal != null) p2Meal.name,
          if (cMeal != null) cMeal.name,
        },
      );

      final components = <Meal>[
        if (pMeal != null) pMeal,
        if (p2Meal != null) p2Meal,
        if (cMeal != null && tC >= 5) cMeal,
        if (fMeal != null && tF >= 3) fMeal,
      ];

      if (components.isEmpty) continue;

      final byName = {for (final m in components) m.name: m};

      final solved = PortionSolver.solve(
        variable: components.map(_asFood).toList(),
        targetProtein: tP,
        targetCarbs: tC,
        targetFat: tF,
      );

      final portions = <MealPortion>[
        for (final s in solved)
          if (s.grams > 0)
            MealPortion(meal: byName[s.food.name]!, grams: s.grams.round()),
      ];

      if (portions.isEmpty) continue;

      final p = portions.fold<int>(0, (a, x) => a + x.protein);
      final c = portions.fold<int>(0, (a, x) => a + x.carbs);
      final f = portions.fold<int>(0, (a, x) => a + x.fat);
      final kcal = portions.fold<int>(0, (a, x) => a + x.calories);

      out.add(
        MealSuggestion(
          title: 'Jídlo ${i + 1}',
          items: [for (final x in portions) '${x.meal.name} ${x.grams} g'],
          portions: portions,
          protein: p,
          carbs: c,
          fat: f,
          calories: kcal,
        ),
      );

      remP -= p;
      remC -= c;
      remF -= f;
    }

    return out;
  }
}
