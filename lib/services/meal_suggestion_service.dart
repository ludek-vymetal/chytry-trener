import '../models/meal.dart';

class MealPortion {
  final Meal meal;
  final int grams;

  MealPortion({required this.meal, required this.grams});
}

class MealSuggestion {
  final String title;

  /// text pro UI (např. "Kuřecí prsa 200 g")
  final List<String> items;

  /// reálné porce pro zápis do dne
  final List<MealPortion> portions;

  /// orientační makra pro 1 jídlo
  final int protein;
  final int carbs;
  final int fat;

  /// orientační kcal
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

class MealSuggestionService {
  // --- helpers ---
  static int _roundGrams(int g) {
    if (g <= 0) return 0;
    if (g < 50) return (g / 5).round() * 5;
    if (g < 200) return (g / 10).round() * 10;
    return (g / 25).round() * 25;
  }

  static int _clampGrams(int g) => g.clamp(30, 600);

  static int _gramsForMacro({
    required double macroPer100,
    required int targetMacro,
  }) {
    if (macroPer100 <= 0 || targetMacro <= 0) return 0;
    final grams = (targetMacro * 100.0 / macroPer100).round();
    return _clampGrams(_roundGrams(grams));
  }

  static int _kcalFor(Meal meal, int grams) {
    final factor = grams / 100.0;
    return (meal.caloriesPer100g * factor).round();
  }

  static int _macroFor(double per100, int grams) {
    final factor = grams / 100.0;
    return (per100 * factor).round();
  }

  // --- kategorizace (aby se nevybíral olej jako "jídlo") ---
  static bool _isOilOrPureFat(Meal m) {
    final n = m.name.toLowerCase();
    if (n.contains('olej')) return true;
    if (n.contains('máslo')) return true;
    if (n.contains('tahini')) return true;
    if (n.contains('arašídové máslo')) return true;
    if (m.fatsPer100g >= 80 && m.proteinPer100g < 5 && m.carbsPer100g < 5) {
      return true;
    }
    return false;
  }

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
    if (_isOilOrPureFat(m)) score -= 40;
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

  static Meal _pickDifferent(Meal a, List<Meal> list) {
    for (final m in list) {
      if (m.name != a.name) return m;
    }
    return a;
  }

  static Meal _pickByIndex(List<Meal> list, int i, Meal fallback) {
    if (list.isEmpty) return fallback;
    return list[i % list.length];
  }

  static MealSuggestion _buildSuggestion({
    required String title,
    required List<Meal> components,
    required int targetP,
    required int targetC,
    required int targetF,
    required bool includeFatComponent,
  }) {
    final pMeal = components[0];
    final cMeal = components.length >= 2 ? components[1] : components[0];

    final pG = _gramsForMacro(macroPer100: pMeal.proteinPer100g, targetMacro: targetP);
    final cG = _gramsForMacro(macroPer100: cMeal.carbsPer100g, targetMacro: targetC);

    int fG = 0;
    Meal? fMeal;
    if (includeFatComponent && components.length >= 3 && targetF > 0) {
      fMeal = components[2];
      fG = _gramsForMacro(macroPer100: fMeal.fatsPer100g, targetMacro: targetF);
      if (_isOilOrPureFat(fMeal) && fG > 25) fG = 25;
      if (fG < 10) fG = 0;
    }

    final portions = <MealPortion>[
      MealPortion(meal: pMeal, grams: pG),
      if (cG > 0) MealPortion(meal: cMeal, grams: cG),
      if (fMeal != null && fG > 0) MealPortion(meal: fMeal, grams: fG),
    ];

    final items = <String>[
      '${pMeal.name} $pG g',
      if (cG > 0) '${cMeal.name} $cG g',
      if (fMeal != null && fG > 0) '${fMeal.name} $fG g',
    ];

    int kcal = _kcalFor(pMeal, pG) +
        _kcalFor(cMeal, cG) +
        (fMeal != null ? _kcalFor(fMeal, fG) : 0);

    int pTot = _macroFor(pMeal.proteinPer100g, pG) +
        _macroFor(cMeal.proteinPer100g, cG) +
        (fMeal != null ? _macroFor(fMeal.proteinPer100g, fG) : 0);

    int cTot = _macroFor(pMeal.carbsPer100g, pG) +
        _macroFor(cMeal.carbsPer100g, cG) +
        (fMeal != null ? _macroFor(fMeal.carbsPer100g, fG) : 0);

    int fTot = _macroFor(pMeal.fatsPer100g, pG) +
        _macroFor(cMeal.fatsPer100g, cG) +
        (fMeal != null ? _macroFor(fMeal.fatsPer100g, fG) : 0);

    return MealSuggestion(
      title: title,
      items: items,
      portions: portions,
      protein: pTot,
      carbs: cTot,
      fat: fTot,
      calories: kcal,
    );
  }

  static List<MealSuggestion> suggest({
    required int missingProtein,
    required int missingCarbs,
    required int missingFat,
    required List<Meal> bank,
    required int mealsCount,
  }) {
    if (bank.isEmpty || mealsCount <= 0) return [];

    final targetP = (missingProtein / mealsCount).ceil();
    final targetC = (missingCarbs / mealsCount).ceil();
    final targetF = (missingFat / mealsCount).ceil();

    final proteinMeals = _top(
      bank,
      _scoreProtein,
      where: (m) => m.proteinPer100g >= 12 && !_isOilOrPureFat(m),
      take: 12,
    );

    final carbMeals = _top(
      bank,
      _scoreCarbs,
      where: (m) => m.carbsPer100g >= 15 && !_isOilOrPureFat(m),
      take: 12,
    );

    final fatMeals = _top(
      bank,
      _scoreFats,
      where: (m) => m.fatsPer100g >= 8,
      take: 10,
    );

    final fallbackProtein = proteinMeals.isNotEmpty ? proteinMeals.first : bank.first;
    final fallbackCarb = carbMeals.isNotEmpty ? carbMeals.first : _pickDifferent(fallbackProtein, bank);
    final fallbackFat = fatMeals.isNotEmpty ? fatMeals.first : _pickDifferent(fallbackCarb, bank);

    final out = <MealSuggestion>[];

    for (int i = 0; i < mealsCount; i++) {
      final pMeal = _pickByIndex(proteinMeals, i, fallbackProtein);
      final cRaw = _pickByIndex(carbMeals, i, fallbackCarb);
      final cMeal = cRaw.name == pMeal.name ? _pickDifferent(pMeal, bank) : cRaw;

      final fRaw = _pickByIndex(fatMeals, i, fallbackFat);
      final fMeal = fRaw.name == cMeal.name ? _pickDifferent(cMeal, bank) : fRaw;

      final wantFat = targetF >= 8 && (i % 2 == 1);

      out.add(
        _buildSuggestion(
          title: 'Jídlo ${i + 1}',
          components: [pMeal, cMeal, fMeal],
          targetP: targetP,
          targetC: targetC,
          targetF: targetF,
          includeFatComponent: wantFat,
        ),
      );
    }

    double dist(MealSuggestion s) {
      final dp = (s.protein - targetP).abs();
      final dc = (s.carbs - targetC).abs();
      final df = (s.fat - targetF).abs();
      return (dp * 2 + dc + df).toDouble();
    }

    out.sort((a, b) => dist(a).compareTo(dist(b)));
    return out;
  }
}