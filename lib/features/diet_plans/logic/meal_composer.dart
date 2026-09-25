import '../../../core/nutrition/diet_classifier.dart';
import '../../../models/diet_preference.dart';
import '../models/carb_cycling_plan.dart';
import 'food_catalog.dart';
import 'portion_solver.dart';

enum MealKind { breakfast, snack, main }

enum DietStyle { standard, keto }

/// Jedno jídlo dne a jeho podíl na denních makroživinách.
class MealSlot {
  final String label;
  final MealKind kind;
  final double proteinShare;
  final double carbsShare;
  final double fatShare;
  final String? time;

  const MealSlot({
    required this.label,
    required this.kind,
    required this.proteinShare,
    required this.carbsShare,
    required this.fatShare,
    this.time,
  });

  MealSlot withTime(String? t) => MealSlot(
        label: label,
        kind: kind,
        proteinShare: proteinShare,
        carbsShare: carbsShare,
        fatShare: fatShare,
        time: t,
      );
}

/// Sestaví konkrétní jídla (potraviny + gramáže) pro zadané denní makroživiny.
///
/// Zásady:
///  - gramáže se počítají z reálných hodnot potravin (FoodCatalog),
///  - u každého jídla i dne se zobrazují SKUTEČNÁ makra spočítaná z gramů,
///  - odchylka jídla (zaokrouhlení, maxima porcí) se přenáší do dalšího
///    jídla, takže součet dne sedí s cílem co nejpřesněji.
class MealComposer {
  /// Denní příjem, pro který platí základní maxima porcí.
  static const double _referenceKcal = 2600;

  /// Nejvyšší zvětšení porcí při vysokém příjmu.
  static const double _maxPortionScale = 1.8;

  /// Klasický den: 5 jídel.
  static List<MealSlot> standardSlots({
    required String breakfast,
    required String snack,
    required String lunch,
    required String snack2,
    required String dinner,
  }) =>
      [
        MealSlot(label: breakfast, kind: MealKind.breakfast, proteinShare: 0.25, carbsShare: 0.25, fatShare: 0.20),
        MealSlot(label: snack, kind: MealKind.snack, proteinShare: 0.15, carbsShare: 0.15, fatShare: 0.15),
        MealSlot(label: lunch, kind: MealKind.main, proteinShare: 0.30, carbsShare: 0.30, fatShare: 0.30),
        MealSlot(label: snack2, kind: MealKind.snack, proteinShare: 0.10, carbsShare: 0.10, fatShare: 0.10),
        MealSlot(label: dinner, kind: MealKind.main, proteinShare: 0.20, carbsShare: 0.20, fatShare: 0.25),
      ];

  /// Keto den: 4 jídla.
  static List<MealSlot> ketoSlots({
    required String breakfast,
    required String snack,
    required String lunch,
    required String dinner,
  }) =>
      [
        MealSlot(label: breakfast, kind: MealKind.breakfast, proteinShare: 0.25, carbsShare: 0.25, fatShare: 0.25),
        MealSlot(label: snack, kind: MealKind.snack, proteinShare: 0.15, carbsShare: 0.15, fatShare: 0.20),
        MealSlot(label: lunch, kind: MealKind.main, proteinShare: 0.35, carbsShare: 0.35, fatShare: 0.30),
        MealSlot(label: dinner, kind: MealKind.main, proteinShare: 0.25, carbsShare: 0.25, fatShare: 0.25),
      ];

  /// Přerušovaný půst: 4 jídla v jídelním okně.
  static List<MealSlot> fastingSlots({
    required String firstMeal,
    required String lunch,
    required String snack,
    required String lastMeal,
    required List<String> times,
  }) {
    String? t(int i) => i < times.length ? times[i] : null;
    return [
      MealSlot(label: firstMeal, kind: MealKind.breakfast, proteinShare: 0.30, carbsShare: 0.30, fatShare: 0.20, time: t(0)),
      MealSlot(label: lunch, kind: MealKind.main, proteinShare: 0.30, carbsShare: 0.35, fatShare: 0.30, time: t(1)),
      MealSlot(label: snack, kind: MealKind.snack, proteinShare: 0.15, carbsShare: 0.10, fatShare: 0.10, time: t(2)),
      MealSlot(label: lastMeal, kind: MealKind.main, proteinShare: 0.25, carbsShare: 0.25, fatShare: 0.40, time: t(3)),
    ];
  }

  static PlannedDay composeDay({
    required String dayName,
    required List<MealSlot> slots,
    required double protein,
    required double carbs,
    required double fats,
    DietStyle style = DietStyle.standard,
    List<String> excluded = const [],
    int dayIndex = 0,
    DietPreference preference = DietPreference.none,
  }) {
    var carryP = 0.0, carryC = 0.0, carryF = 0.0;
    final meals = <PlannedMeal>[];

    // Při vysokém denním příjmu (sportovci, objem) se úměrně zvětší
    // i maximální porce – jinak by se cíl do jídel nevešel.
    final dayKcal = protein * 4 + carbs * 4 + fats * 9;
    var maxScale = dayKcal / _referenceKcal;
    if (maxScale < 1) maxScale = 1;
    if (maxScale > _maxPortionScale) maxScale = _maxPortionScale;

    // Keto jídla jsou energeticky tuková – tukové složky (olej, máslo,
    // ořechy, avokádo) potřebují větší porce, aby se tuky vešly.
    if (style == DietStyle.keto) maxScale *= 1.5;

    var sumP = 0.0, sumC = 0.0, sumF = 0.0;

    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];

      final tP = _nonNeg(protein * slot.proteinShare + carryP);
      final tC = _nonNeg(carbs * slot.carbsShare + carryC);
      final tF = _nonNeg(fats * slot.fatShare + carryF);

      final portions = _composeMeal(
        kind: slot.kind,
        style: style,
        targetP: tP,
        targetC: tC,
        targetF: tF,
        excluded: excluded,
        rotation: dayIndex * 7 + i,
        maxScale: maxScale,
        preference: preference,
      );

      final meal = _toPlannedMeal(slot, portions);
      meals.add(meal);

      final aP = meal.protein ?? 0.0, aC = meal.carbs ?? 0.0, aF = meal.fats ?? 0.0;
      sumP += aP;
      sumC += aC;
      sumF += aF;

      carryP = tP - aP;
      carryC = tC - aC;
      carryF = tF - aF;
    }

    return PlannedDay(
      dayName: dayName,
      meals: meals,
      protein: _round1(sumP),
      carbs: _round1(sumC),
      fats: _round1(sumF),
    );
  }

  // ---------------------------------------------------------------
  // Šablony jídel
  // ---------------------------------------------------------------

  static List<FoodPortion> _composeMeal({
    required MealKind kind,
    required DietStyle style,
    required double targetP,
    required double targetC,
    required double targetF,
    required List<String> excluded,
    required int rotation,
    required double maxScale,
    required DietPreference preference,
  }) {
    // Potravina je povolená, když ji klient nevyloučil a odpovídá jeho
    // stravovacímu omezení (vegetarián / vegan).
    bool ok(NutritionFood f) =>
        !FoodCatalog.isExcluded(f, excluded) &&
        DietClassifier.allowsName(preference, f.name);

    // Rotace mezi povolenými možnostmi. Když není povolená žádná,
    // použije se bezpečná rostlinná náhrada (nikdy ne zakázaná potravina).
    NutritionFood pick(
      List<NutritionFood> options,
      int offset, {
      NutritionFood fallback = FoodCatalog.tofu,
    }) {
      final allowed = options.where(ok).toList();
      if (allowed.isEmpty) return fallback;
      return allowed[(rotation + offset) % allowed.length];
    }

    NutritionFood first(
      List<NutritionFood> options, {
      NutritionFood fallback = FoodCatalog.avocado,
    }) {
      for (final f in options) {
        if (ok(f)) return f;
      }
      return fallback;
    }

    List<FoodPortion> solve(List<NutritionFood> vars, List<FoodPortion> fixed) {
      return PortionSolver.solve(
        variable: vars,
        targetProtein: targetP,
        targetCarbs: targetC,
        targetFat: targetF,
        fixed: fixed,
        maxScale: maxScale,
      );
    }

    const veg100 = FoodPortion(FoodCatalog.vegetables, 100);
    const veg150 = FoodPortion(FoodCatalog.vegetables, 150);
    const veg200 = FoodPortion(FoodCatalog.vegetables, 200);

    final eggsOk = ok(FoodCatalog.eggs);
    final proteinPowder = first(
      const [FoodCatalog.whey, FoodCatalog.soyProtein],
      fallback: FoodCatalog.soyProtein,
    );

    // Hlavní bílkovinné zdroje podle stravovacího omezení.
    final List<NutritionFood> mainProteins;
    switch (preference) {
      case DietPreference.none:
        mainProteins = style == DietStyle.keto
            ? const [
                FoodCatalog.beefRibeye,
                FoodCatalog.salmon,
                FoodCatalog.chickenBreast,
                FoodCatalog.turkeyBreast,
              ]
            : const [
                FoodCatalog.chickenBreast,
                FoodCatalog.beefLean,
                FoodCatalog.salmon,
                FoodCatalog.turkeyBreast,
                FoodCatalog.cod,
              ];
        break;
      case DietPreference.vegetarian:
        // Keto: tempeh má moc sacharidů → jen tofu a vejce.
        mainProteins = style == DietStyle.keto
            ? const [FoodCatalog.tofu, FoodCatalog.eggs]
            : const [
                FoodCatalog.tofu,
                FoodCatalog.eggs,
                FoodCatalog.tempeh,
              ];
        break;
      case DietPreference.vegan:
        mainProteins = style == DietStyle.keto
            ? const [FoodCatalog.tofu]
            : const [
                FoodCatalog.tofu,
                FoodCatalog.tempeh,
                FoodCatalog.lentils,
                FoodCatalog.chickpeas,
              ];
        break;
    }

    // ---------------- keto ----------------
    if (style == DietStyle.keto) {
      switch (kind) {
        case MealKind.breakfast:
          if (eggsOk) {
            return solve(
              [
                FoodCatalog.eggs,
                first(const [FoodCatalog.butter, FoodCatalog.oliveOil]),
                first(const [FoodCatalog.ham, FoodCatalog.gouda, FoodCatalog.avocado]),
              ],
              [veg100],
            );
          }
          return solve(
            [
              first(const [FoodCatalog.ham, FoodCatalog.tofu], fallback: FoodCatalog.tofu),
              first(const [FoodCatalog.gouda, FoodCatalog.almonds]),
              FoodCatalog.avocado,
            ],
            [veg100],
          );
        case MealKind.snack:
          return solve(
            [
              first(const [FoodCatalog.gouda, FoodCatalog.soyProtein], fallback: FoodCatalog.soyProtein),
              FoodCatalog.almonds,
              FoodCatalog.avocado,
            ],
            [veg100],
          );
        case MealKind.main:
          return solve(
            [
              pick(mainProteins, 0),
              pick(const [FoodCatalog.oliveOil, FoodCatalog.butter], 1,
                  fallback: FoodCatalog.oliveOil),
              // Vegan keto: doplnění bílkovin bez sacharidů.
              preference == DietPreference.vegan
                  ? FoodCatalog.soyProtein
                  : FoodCatalog.avocado,
            ],
            [preference == DietPreference.vegan ? veg100 : veg150],
          );
      }
    }

    // ---------------- standardní strava ----------------
    switch (kind) {
      case MealKind.breakfast:
        if (targetC < 25) {
          if (eggsOk) {
            return solve(
              [
                FoodCatalog.eggs,
                first(const [FoodCatalog.ham, FoodCatalog.gouda, FoodCatalog.quarkLowFat]),
                FoodCatalog.wholegrainBread,
              ],
              [veg100],
            );
          }
          if (ok(FoodCatalog.quarkLowFat)) {
            return solve(
              [FoodCatalog.quarkLowFat, FoodCatalog.almonds, FoodCatalog.blueberries],
              const [],
            );
          }
          return solve(
            [FoodCatalog.tofu, FoodCatalog.wholegrainBread, FoodCatalog.avocado],
            [veg100],
          );
        }

        if (rotation.isOdd) {
          if (eggsOk) {
            return solve(
              [
                FoodCatalog.eggs,
                FoodCatalog.wholegrainBread,
                first(const [FoodCatalog.ham, FoodCatalog.gouda]),
              ],
              [veg100],
            );
          }
          if (preference == DietPreference.vegan) {
            // "tofu scramble" s chlebem a avokádem
            return solve(
              [FoodCatalog.tofu, FoodCatalog.wholegrainBread, FoodCatalog.avocado],
              [veg100],
            );
          }
        }

        return solve(
          [FoodCatalog.oats, proteinPowder, FoodCatalog.peanutButter],
          [const FoodPortion(FoodCatalog.blueberries, 80)],
        );

      case MealKind.snack:
        if (targetC >= 15) {
          if (ok(FoodCatalog.skyr)) {
            return solve(
              [FoodCatalog.skyr, FoodCatalog.banana, FoodCatalog.almonds],
              const [],
            );
          }
          return solve(
            [FoodCatalog.soyProtein, FoodCatalog.banana, FoodCatalog.almonds],
            [const FoodPortion(FoodCatalog.soyYogurt, 150)],
          );
        }
        switch (preference) {
          case DietPreference.none:
            return solve(
              [
                first(const [FoodCatalog.ham, FoodCatalog.quarkLowFat]),
                FoodCatalog.gouda,
                FoodCatalog.riceCakes,
              ],
              const [],
            );
          case DietPreference.vegetarian:
            return solve(
              [FoodCatalog.quarkLowFat, FoodCatalog.gouda, FoodCatalog.riceCakes],
              const [],
            );
          case DietPreference.vegan:
            return solve(
              [FoodCatalog.soyProtein, FoodCatalog.almonds, FoodCatalog.riceCakes],
              const [],
            );
        }

      case MealKind.main:
        final carb = pick(
          const [
            FoodCatalog.rice,
            FoodCatalog.potatoes,
            FoodCatalog.pasta,
            FoodCatalog.sweetPotato,
          ],
          2,
          fallback: FoodCatalog.rice,
        );
        return solve(
          [
            pick(mainProteins, 0),
            if (targetC >= 10) carb,
            FoodCatalog.oliveOil,
          ],
          [veg200],
        );
    }
  }

  // ---------------------------------------------------------------
  // Převod na PlannedMeal
  // ---------------------------------------------------------------

  static PlannedMeal _toPlannedMeal(MealSlot slot, List<FoodPortion> portions) {
    var p = 0.0, c = 0.0, f = 0.0, kcal = 0.0, grams = 0.0;

    final ingredients = <MealIngredient>[];
    final parts = <String>[];

    for (final portion in portions) {
      p += portion.protein;
      c += portion.carbs;
      f += portion.fat;
      kcal += portion.kcal;
      grams += portion.grams;

      final pieces = portion.pieces;
      if (pieces != null) {
        ingredients.add(
          MealIngredient(name: portion.food.name, amount: pieces.toDouble(), unit: 'ks'),
        );
        parts.add('$pieces ks ${portion.food.name} (${portion.grams.round()} g)');
      } else {
        ingredients.add(
          MealIngredient(name: portion.food.displayName, amount: portion.grams, unit: 'g'),
        );
        parts.add('${portion.grams.round()} g ${portion.food.displayName}');
      }
    }

    final mainNames = portions
        .where((x) => x.food.id != 'vegetables')
        .map((x) => x.food.name)
        .take(3)
        .toList();
    final hasVeg = portions.any((x) => x.food.id == 'vegetables');
    final name = [
      ...mainNames,
      if (hasVeg) 'zelenina',
    ].join(' + ');

    return PlannedMeal(
      label: slot.label,
      name: name,
      description: parts.join(' + '),
      calories: kcal.roundToDouble(),
      protein: _round1(p),
      carbs: _round1(c),
      fats: _round1(f),
      grams: grams.round(),
      time: slot.time,
      ingredients: ingredients,
    );
  }

  static double _nonNeg(double v) => v < 0 ? 0.0 : v;

  static double _round1(double v) => (v * 10).roundToDouble() / 10;
}
