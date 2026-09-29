import '../models/carb_cycling_plan.dart';
import 'food_catalog.dart';

/// Makroživiny jednoho jídla / dne (kcal, bílkoviny, sacharidy, tuky).
class MealMacros {
  final double kcal;
  final double protein;
  final double carbs;
  final double fats;

  const MealMacros({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  static const zero = MealMacros(kcal: 0, protein: 0, carbs: 0, fats: 0);

  MealMacros operator +(MealMacros o) => MealMacros(
        kcal: kcal + o.kcal,
        protein: protein + o.protein,
        carbs: carbs + o.carbs,
        fats: fats + o.fats,
      );
}

/// Výpočty nad jídelníčky: přepočet makroživin z potravin, rozumné
/// zaokrouhlení porcí (celé gramy / kusy) a přepočet na jiný kalorický cíl.
///
/// Pravidla zaokrouhlení:
/// * makroživiny a kalorie – vždy celá čísla (žádné 4,78 g),
/// * kusy (vejce, tortilla…) – celé kusy, minimálně 1,
/// * gramy – do 20 g po 1 g, jinak po 5 g (nebo krokem potraviny),
/// * mililitry – po 5 ml, od 50 ml po 10 ml.
class MealPlanMath {
  MealPlanMath._();

  static Map<String, NutritionFood>? _cache;

  static Map<String, NutritionFood> get _index {
    final cached = _cache;
    if (cached != null) return cached;
    final map = <String, NutritionFood>{};
    for (final f in FoodCatalog.all) {
      map.putIfAbsent(_norm(f.displayName), () => f);
      map.putIfAbsent(_norm(f.name), () => f);
    }
    return _cache = map;
  }

  static String _norm(String s) => s.trim().toLowerCase();

  /// Potravina z katalogu podle názvu ingredience (nebo null).
  static NutritionFood? foodFor(String name) => _index[_norm(name)];

  /// Název ingredience a jednotka, jak je používá generátor jídelníčků.
  static MealIngredient ingredientFor(NutritionFood food, double amount) {
    if (food.pieceGrams != null) {
      return MealIngredient(name: food.name, amount: amount, unit: 'ks');
    }
    return MealIngredient(
      name: food.displayName,
      amount: amount,
      unit: food.id == 'milk' ? 'ml' : 'g',
    );
  }

  /// Rozumná výchozí porce potraviny.
  static double defaultAmount(NutritionFood food) {
    final piece = food.pieceGrams;
    if (piece != null) return piece < 80 ? 2 : 1;
    if (food.id == 'milk') return 250;
    final g = 100.0.clamp(food.minGrams, food.maxGrams).toDouble();
    return roundAmount(g, 'g', food: food);
  }

  /// Krok pro tlačítka +/- u ingredience.
  static double stepFor(MealIngredient i) {
    switch (i.unit.trim().toLowerCase()) {
      case 'ks':
        return 1;
      case 'ml':
        return 10;
      default:
        final s = foodFor(i.name)?.step ?? 5;
        return i.amount < 20 ? 1.0 : (s < 1 ? 1.0 : s);
    }
  }

  static double gramsOf(MealIngredient i, NutritionFood food) {
    if (i.unit.trim().toLowerCase() == 'ks') {
      return i.amount * (food.pieceGrams ?? 50);
    }
    return i.amount; // g, ml (hustota ≈ 1 g/ml)
  }

  /// Makra jedné ingredience; null, když potravinu neznáme.
  static MealMacros? macrosOfIngredient(MealIngredient i) {
    final food = foodFor(i.name);
    if (food == null) return null;
    final g = gramsOf(i, food);
    return MealMacros(
      kcal: food.kcalPerG * g,
      protein: food.proteinPerG * g,
      carbs: food.carbsPerG * g,
      fats: food.fatPerG * g,
    );
  }

  /// Makra jídla spočítaná z ingrediencí. Null, když jídlo nemá
  /// ingredience nebo některou potravinu v katalogu nenajdeme
  /// (pak se použijí makra uložená u jídla).
  static MealMacros? macrosOf(List<MealIngredient> items) {
    if (items.isEmpty) return null;
    var sum = MealMacros.zero;
    for (final i in items) {
      final m = macrosOfIngredient(i);
      if (m == null) return null;
      sum = sum + m;
    }
    return sum;
  }

  static double _step(double value, double step) =>
      (value / step).round() * step;

  /// Zaokrouhlí množství podle jednotky tak, aby se dalo reálně odvážit.
  static double roundAmount(double amount, String unit, {NutritionFood? food}) {
    if (amount.isNaN || amount <= 0) return 0;
    switch (unit.trim().toLowerCase()) {
      case 'ks':
        final v = amount.roundToDouble();
        return v < 1 ? 1.0 : v;
      case 'ml':
        final v = amount < 50 ? _step(amount, 5) : _step(amount, 10);
        return v < 5 ? 5.0 : v;
      default:
        if (amount < 20) {
          final v = amount.roundToDouble();
          return v < 1 ? 1.0 : v;
        }
        final s = food?.step ?? 5;
        return _step(amount, s < 1 ? 1.0 : s);
    }
  }

  /// Popis jídla ve stejném formátu, jaký používá generátor.
  static String describe(List<MealIngredient> items) {
    return items.map((i) {
      final unit = i.unit.trim().toLowerCase();
      if (unit == 'ks') {
        final piece = foodFor(i.name)?.pieceGrams;
        final g = piece == null ? '' : ' (${(i.amount * piece).round()} g)';
        return '${i.amount.round()} ks ${i.name}$g';
      }
      return '${i.amount.round()} ${i.unit} ${i.name}';
    }).join(' + ');
  }

  /// Krátký název jídla z hlavních potravin (když ho trenér nevyplní).
  static String autoName(List<MealIngredient> items) {
    final names = items
        .where((i) => !i.name.toLowerCase().startsWith('zelenina'))
        .map((i) => i.name.replaceAll(RegExp(r'\s*\(.*\)$'), ''))
        .take(3)
        .toList();
    final veg = items.any((i) => i.name.toLowerCase().startsWith('zelenina'));
    return [...names, if (veg) 'zelenina'].join(' + ');
  }

  static double? _r(double? v) => v?.roundToDouble();

  static MealMacros macrosOfMeal(PlannedMeal m) => MealMacros(
        kcal: m.calories ??
            ((m.protein ?? 0) * 4 + (m.carbs ?? 0) * 4 + (m.fats ?? 0) * 9),
        protein: m.protein ?? 0,
        carbs: m.carbs ?? 0,
        fats: m.fats ?? 0,
      );

  /// Jídlo s makry přepočítanými z ingrediencí (je-li to možné)
  /// a zaokrouhlenými na celá čísla.
  static PlannedMeal normalizeMeal(
    PlannedMeal m, {
    bool rebuildText = false,
    bool fillName = true,
  }) {
    final calc = macrosOf(m.ingredients);
    double? grams;
    if (calc != null) {
      var sum = 0.0;
      for (final i in m.ingredients) {
        sum += gramsOf(i, foodFor(i.name)!);
      }
      grams = sum;
    }
    final p = calc?.protein ?? m.protein;
    final c = calc?.carbs ?? m.carbs;
    final f = calc?.fats ?? m.fats;
    final kcal = calc?.kcal ??
        m.calories ??
        ((p == null && c == null && f == null)
            ? null
            : (p ?? 0) * 4 + (c ?? 0) * 4 + (f ?? 0) * 9);

    final description = rebuildText && m.ingredients.isNotEmpty
        ? describe(m.ingredients)
        : m.description;
    final name = fillName && m.name.trim().isEmpty && m.ingredients.isNotEmpty
        ? autoName(m.ingredients)
        : m.name;

    return PlannedMeal(
      label: m.label,
      name: name,
      description: description,
      ingredients: m.ingredients,
      calories: _r(kcal),
      protein: _r(p),
      carbs: _r(c),
      fats: _r(f),
      grams: grams?.round() ?? m.grams,
      time: m.time,
    );
  }

  static MealMacros totalsOf(List<PlannedMeal> meals) {
    var sum = MealMacros.zero;
    for (final m in meals) {
      sum = sum + macrosOfMeal(m);
    }
    return sum;
  }

  /// Den s přepočítanými jídly; součty dne = součet jídel.
  static PlannedDay normalizeDay(PlannedDay d, {bool rebuildText = false}) {
    final meals = [
      for (final m in d.meals) normalizeMeal(m, rebuildText: rebuildText),
    ];
    if (meals.isEmpty) {
      return d.copyWith(
        protein: d.protein.roundToDouble(),
        carbs: d.carbs.roundToDouble(),
        fats: d.fats.roundToDouble(),
      );
    }
    final t = totalsOf(meals);
    return PlannedDay(
      dayName: d.dayName,
      meals: meals,
      protein: t.protein.roundToDouble(),
      carbs: t.carbs.roundToDouble(),
      fats: t.fats.roundToDouble(),
    );
  }

  /// Celý jídelníček zaokrouhlený a s makry přepočítanými z potravin.
  static DietMealPlan normalizePlan(DietMealPlan plan,
      {bool rebuildText = false}) {
    final days = [
      for (final d in plan.days) normalizeDay(d, rebuildText: rebuildText),
    ];
    if (days.isEmpty) {
      return plan.copyWith(
        protein: plan.protein.roundToDouble(),
        carbs: plan.carbs.roundToDouble(),
        fats: plan.fats.roundToDouble(),
      );
    }
    double avg(double Function(PlannedDay d) pick) =>
        days.fold<double>(0, (a, d) => a + pick(d)) / days.length;
    return DietMealPlan(
      planType: plan.planType,
      days: days,
      protein: avg((d) => d.protein).roundToDouble(),
      carbs: avg((d) => d.carbs).roundToDouble(),
      fats: avg((d) => d.fats).roundToDouble(),
      note: plan.note,
    );
  }

  static double dayKcal(PlannedDay d) {
    if (d.meals.isNotEmpty) return totalsOf(d.meals).kcal;
    return d.protein * 4 + d.carbs * 4 + d.fats * 9;
  }

  /// Průměrné denní kalorie jídelníčku.
  static double planKcal(DietMealPlan plan) {
    if (plan.days.isEmpty) {
      return plan.protein * 4 + plan.carbs * 4 + plan.fats * 9;
    }
    return plan.days.fold<double>(0, (a, d) => a + dayKcal(d)) /
        plan.days.length;
  }

  static PlannedMeal _scaleMeal(PlannedMeal m, double r) {
    final items = [
      for (final i in m.ingredients)
        i.copyWith(
          amount: roundAmount(i.amount * r, i.unit, food: foodFor(i.name)),
        ),
    ];
    double? s(double? v) => v == null ? null : v * r;
    return normalizeMeal(
      PlannedMeal(
        label: m.label,
        name: m.name,
        description: m.description,
        ingredients: items,
        calories: s(m.calories),
        protein: s(m.protein),
        carbs: s(m.carbs),
        fats: s(m.fats),
        grams: m.grams == null ? null : (m.grams! * r).round(),
        time: m.time,
      ),
      rebuildText: items.isNotEmpty,
    );
  }

  static PlannedDay scaleDay(PlannedDay d, double ratio) {
    final r = (ratio.isNaN || ratio <= 0) ? 1.0 : ratio;
    if (d.meals.isEmpty) {
      return d.copyWith(
        protein: (d.protein * r).roundToDouble(),
        carbs: (d.carbs * r).roundToDouble(),
        fats: (d.fats * r).roundToDouble(),
      );
    }
    return normalizeDay(
      d.copyWith(meals: [for (final m in d.meals) _scaleMeal(m, r)]),
    );
  }

  /// Vynásobí všechny porce poměrem a vše zaokrouhlí.
  static DietMealPlan scale(DietMealPlan plan, double ratio) {
    final r = (ratio.isNaN || ratio <= 0) ? 1.0 : ratio;
    if (plan.days.isEmpty) {
      return plan.copyWith(
        protein: (plan.protein * r).roundToDouble(),
        carbs: (plan.carbs * r).roundToDouble(),
        fats: (plan.fats * r).roundToDouble(),
      );
    }
    return normalizePlan(
      plan.copyWith(days: [for (final d in plan.days) scaleDay(d, r)]),
    );
  }

  /// Přepočítá den na cílové kalorie. Po zaokrouhlení porcí se poměr
  /// ještě dvakrát doladí, aby výsledek seděl co nejpřesněji.
  static PlannedDay scaleDayToKcal(PlannedDay day, double targetKcal) {
    final base = dayKcal(normalizeDay(day));
    if (base <= 0 || targetKcal <= 0) return normalizeDay(day);
    var ratio = targetKcal / base;
    var best = scaleDay(day, ratio);
    for (var i = 0; i < 3; i++) {
      final got = dayKcal(best);
      if (got <= 0 || (got - targetKcal).abs() / targetKcal < 0.015) break;
      ratio *= targetKcal / got;
      best = scaleDay(day, ratio);
    }
    return best;
  }

  /// Přepočítá celý jídelníček na cílové kalorie (každý den zvlášť,
  /// aby i dny s různými kaloriemi zachovaly svůj vzájemný poměr).
  static DietMealPlan scaleToKcal(DietMealPlan plan, double targetKcal) {
    final base = planKcal(normalizePlan(plan));
    if (base <= 0 || targetKcal <= 0) return normalizePlan(plan);
    final ratio = targetKcal / base;
    if (plan.days.isEmpty) return scale(plan, ratio);
    return normalizePlan(
      plan.copyWith(
        days: [
          for (final d in plan.days)
            scaleDayToKcal(d, dayKcal(normalizeDay(d)) * ratio),
        ],
      ),
    );
  }
}
