import 'dart:math' as math;

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

  /// Varianta jídelníčku pro aktuální týden – každý týden jiné pořadí
  /// jídel, v rámci týdne stabilní (plán se nemění při každém otevření).
  static int currentVariant([DateTime? now]) {
    final d = now ?? DateTime.now();
    final days = DateTime.utc(d.year, d.month, d.day)
        .difference(DateTime.utc(2024, 1, 1))
        .inDays;
    return days ~/ 7;
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

    /// Varianta pořadí jídel. Bez zadání = aktuální týden, takže každý
    /// týden vyjde jiný jídelníček, ale v rámci týdne je stabilní.
    int? variant,

    /// Úsporná varianta: levné suroviny a večeře ze stejného vaření jako
    /// oběd (jen jiná gramáž).
    bool budget = false,
  }) {
    final v = variant ?? currentVariant();
    var carryP = 0.0, carryC = 0.0, carryF = 0.0;
    final meals = List<PlannedMeal?>.filled(slots.length, null);

    // Při vysokém denním příjmu (sportovci, objem) se úměrně zvětší
    // i maximální porce – jinak by se cíl do jídel nevešel.
    final dayKcal = protein * 4 + carbs * 4 + fats * 9;
    var maxScale = dayKcal / _referenceKcal;
    if (maxScale < 1) maxScale = 1;
    if (maxScale > _maxPortionScale) maxScale = _maxPortionScale;

    // Keto jídla jsou energeticky tuková – tukové složky (olej, máslo,
    // ořechy, avokádo) potřebují větší porce, aby se tuky vešly.
    if (style == DietStyle.keto) maxScale *= 1.5;

    // Kolik jídel daného druhu je ve dni (např. 2 svačiny, 2 hlavní jídla).
    // Výběr jídla = varianta + den × počet + pořadí → během týdne se
    // postupně vystřídají všechny možnosti a dvě svačiny v jednom dni
    // nejsou stejné.
    final kindCount = <MealKind, int>{};
    for (final s in slots) {
      kindCount[s.kind] = (kindCount[s.kind] ?? 0) + 1;
    }
    final kindOrdinal = <MealKind, int>{};

    // Úsporná varianta: oběd, ze kterého se udělá i večeře.
    _Tpl? cookedMain;
    List<FoodPortion>? cookedPortions;

    var sumP = 0.0, sumC = 0.0, sumF = 0.0;

    // Výběr jídla pro každý slot (v pořadí dne).
    final choices = <int>[];
    for (final slot in slots) {
      final ordinal = kindOrdinal[slot.kind] ?? 0;
      kindOrdinal[slot.kind] = ordinal + 1;
      // Úsporná varianta vybírá jen oběd (večeře je z něj), proto se
      // hlavní jídlo posouvá o 1 za den, aby se vystřídaly všechny možnosti.
      final perDay = (budget && slot.kind == MealKind.main)
          ? 1
          : (kindCount[slot.kind] ?? 1);
      choices.add(v + dayIndex * perDay + ordinal);
    }

    // Pořadí výpočtu. Úsporná varianta: večeře (stejné jídlo jako oběd,
    // jen jiná porce) se počítá hned po obědě, aby její odchylku mohla
    // vyrovnat svačina mezi nimi – jinak by chyba zůstala na konci dne.
    final order = List<int>.generate(slots.length, (i) => i);
    if (budget) {
      final mains = [
        for (var i = 0; i < slots.length; i++)
          if (slots[i].kind == MealKind.main) i,
      ];
      if (mains.length >= 2) {
        order
          ..removeWhere((i) => mains.skip(1).contains(i))
          ..insertAll(order.indexOf(mains.first) + 1, mains.skip(1));
      }
    }

    for (final i in order) {
      final slot = slots[i];
      final choice = choices[i];

      final tP = _nonNeg(protein * slot.proteinShare + carryP);
      final tC = _nonNeg(carbs * slot.carbsShare + carryC);
      final tF = _nonNeg(fats * slot.fatShare + carryF);

      // Úsporná varianta: druhé hlavní jídlo dne je ze stejných surovin
      // jako první (vaří se jednou), gramáže se spočítají pro jeho makra.
      final reuse =
          (budget && slot.kind == MealKind.main) ? cookedMain : null;
      final template = reuse ??
          _chooseTemplate(
            kind: slot.kind,
            style: style,
            targetC: tC,
            excluded: excluded,
            choice: choice,
            preference: preference,
            budget: budget,
            // Poslední počítané jídlo dne už nemá kam přenést odchylku –
            // z možností (v pořadí střídání) se vezme první, která cíl
            // opravdu trefí.
            fit: i == order.last ? _Fit(tP, tC, tF, maxScale) : null,
          );
      if (budget && slot.kind == MealKind.main) cookedMain ??= template;

      final lunch = cookedPortions;
      final portions = (reuse != null && lunch != null)
          ? _scaleLeftover(lunch, reuse, tP, tC, tF, maxScale)
          : PortionSolver.solve(
              variable: template.vars,
              targetProtein: tP,
              targetCarbs: tC,
              targetFat: tF,
              fixed: template.fixed,
              maxScale: maxScale,
            );
      if (budget && slot.kind == MealKind.main) cookedPortions ??= portions;

      final meal = _toPlannedMeal(slot, portions, leftover: reuse != null);
      meals[i] = meal;

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
      meals: meals.whereType<PlannedMeal>().toList(),
      protein: _round1(sumP),
      carbs: _round1(sumC),
      fats: _round1(sumF),
    );
  }

  // ---------------------------------------------------------------
  // Šablony jídel
  // ---------------------------------------------------------------

  static _Tpl _chooseTemplate({
    required MealKind kind,
    required DietStyle style,
    required double targetC,
    required List<String> excluded,
    required int choice,
    required DietPreference preference,
    required bool budget,
    _Fit? fit,
  }) {
    // Potravina je povolená, když ji klient nevyloučil a odpovídá jeho
    // stravovacímu omezení (vegetarián / vegan).
    bool ok(NutritionFood f) =>
        !FoodCatalog.isExcluded(f, excluded) &&
        DietClassifier.allowsName(preference, f.name);

    // Šablona je použitelná, jen když jsou povolené VŠECHNY její potraviny.
    _Tpl? tpl(List<NutritionFood> vars, [List<FoodPortion> fixed = const []]) {
      if (!vars.every(ok)) return null;
      if (!fixed.every((p) => ok(p.food))) return null;
      return _Tpl(vars, fixed);
    }

    // Výběr z povolených možností podle [choice] (s krokem [stride]).
    NutritionFood pick(
      List<NutritionFood> options, {
      int stride = 1,
      int offset = 0,
      NutritionFood fallback = FoodCatalog.tofu,
    }) {
      final allowed = options.where(ok).toList();
      if (allowed.isEmpty) return fallback;
      final idx = (choice * stride + offset) % allowed.length;
      return allowed[idx < 0 ? idx + allowed.length : idx];
    }

    _Tpl choose(List<_Tpl?> candidates, _Tpl fallback) {
      final valid = candidates.whereType<_Tpl>().toList();
      if (valid.isEmpty) return fallback;
      if (fit == null) return valid[choice % valid.length];

      _Tpl? best;
      var bestErr = double.infinity;
      for (var k = 0; k < valid.length; k++) {
        final t = valid[(choice + k) % valid.length];
        final err = fit.errorOf(t);
        if (err <= _Fit.tolerance) return t;
        if (err < bestErr) {
          bestErr = err;
          best = t;
        }
      }
      return best ?? valid[choice % valid.length];
    }

    const veg100 = FoodPortion(FoodCatalog.vegetables, 100);
    const veg200 = FoodPortion(FoodCatalog.vegetables, 200);

    final proteinPowder =
        ok(FoodCatalog.whey) ? FoodCatalog.whey : FoodCatalog.soyProtein;

    // Sójový izolát jen tam, kde nejde whey (vegan / vyloučený whey) –
    // aby na nákupním seznamu nebyly dva různé proteinové prášky.
    final soyOk = !ok(FoodCatalog.whey);

    // Hlavní bílkovinné zdroje a přílohy podle stravovacího omezení.
    final List<NutritionFood> mainProteins;
    switch (preference) {
      case DietPreference.none:
        mainProteins = style == DietStyle.keto
            ? const [
                FoodCatalog.beefRibeye,
                FoodCatalog.salmon,
                FoodCatalog.chickenBreast,
                FoodCatalog.porkTenderloin,
                FoodCatalog.turkeyBreast,
                FoodCatalog.groundBeef5,
                FoodCatalog.shrimp,
              ]
            : const [
                FoodCatalog.chickenBreast,
                FoodCatalog.beefLean,
                FoodCatalog.salmon,
                FoodCatalog.porkTenderloin,
                FoodCatalog.turkeyBreast,
                FoodCatalog.cod,
                FoodCatalog.groundBeef5,
                FoodCatalog.tuna,
                FoodCatalog.shrimp,
              ];
        break;
      case DietPreference.vegetarian:
        // Keto: luštěniny a tempeh mají moc sacharidů.
        mainProteins = style == DietStyle.keto
            ? const [FoodCatalog.tofu, FoodCatalog.eggs, FoodCatalog.mozzarellaLight]
            : const [
                FoodCatalog.tofu,
                FoodCatalog.eggs,
                FoodCatalog.tempeh,
                FoodCatalog.mozzarellaLight,
                FoodCatalog.lentils,
                FoodCatalog.chickpeas,
              ];
        break;
      case DietPreference.vegan:
        mainProteins = style == DietStyle.keto
            ? const [FoodCatalog.tofu, FoodCatalog.seitan]
            : const [
                FoodCatalog.tofu,
                FoodCatalog.tempeh,
                FoodCatalog.seitan,
                FoodCatalog.lentils,
                FoodCatalog.chickpeas,
                FoodCatalog.redBeans,
              ];
        break;
    }

    const mainCarbs = [
      FoodCatalog.rice,
      FoodCatalog.potatoes,
      FoodCatalog.pasta,
      FoodCatalog.sweetPotato,
      FoodCatalog.couscous,
      FoodCatalog.bulgur,
      FoodCatalog.quinoa,
      FoodCatalog.buckwheat,
    ];

    // ---------------- úsporná varianta ----------------
    // Levné a běžně dostupné suroviny: vejce, tvaroh, jogurt, mléko,
    // kuřecí stehna, vepřová kýta, luštěniny, vločky, rýže, brambory,
    // těstoviny, chléb, banán, jablko, řepkový olej, levná zelenina.
    if (budget) {
      const vegB80 = FoodPortion(FoodCatalog.vegetablesBudget, 80);
      const vegB100 = FoodPortion(FoodCatalog.vegetablesBudget, 100);
      const vegB200 = FoodPortion(FoodCatalog.vegetablesBudget, 200);
      const apple100 = FoodPortion(FoodCatalog.apple, 100);
      const banana100 = FoodPortion(FoodCatalog.banana, 100);
      const milk200 = FoodPortion(FoodCatalog.milk, 200);

      // Zdroje bílkovin k obědu (a tedy i večeři). Luštěniny samy nemají
      // dost bílkovin, proto jsou v páru s vejci / tofu (např. čočka
      // s vejcem).
      final List<List<NutritionFood>> cheapMains;
      if (style == DietStyle.keto) {
        cheapMains = preference == DietPreference.none
            ? const [
                [FoodCatalog.chickenThigh],
                [FoodCatalog.porkLeg],
                [FoodCatalog.eggs],
              ]
            : const [
                [FoodCatalog.eggs],
                [FoodCatalog.tofu],
              ];
      } else {
        switch (preference) {
          case DietPreference.none:
            cheapMains = const [
              [FoodCatalog.chickenThigh],
              [FoodCatalog.porkLeg],
              [FoodCatalog.chickenBreast],
              [FoodCatalog.lentils, FoodCatalog.eggs],
            ];
            break;
          case DietPreference.vegetarian:
            cheapMains = const [
              [FoodCatalog.lentils, FoodCatalog.eggs],
              [FoodCatalog.tofu],
              [FoodCatalog.redBeans, FoodCatalog.eggs],
              [FoodCatalog.eggs],
              [FoodCatalog.chickpeas, FoodCatalog.tofu],
            ];
            break;
          case DietPreference.vegan:
            cheapMains = const [
              [FoodCatalog.lentils, FoodCatalog.tofu],
              [FoodCatalog.tofu],
              [FoodCatalog.chickpeas, FoodCatalog.tofu],
              [FoodCatalog.redBeans, FoodCatalog.tofu],
            ];
            break;
        }
      }
      final allowedMains =
          cheapMains.where((combo) => combo.every(ok)).toList();
      final mainProtein = allowedMains.isEmpty
          ? const [FoodCatalog.tofu]
          : allowedMains[choice % allowedMains.length];

      // Tofu a sójový izolát na snídani / svačinu jen pro vegany – ostatní
      // mají levnější a libovější zdroje (tvaroh, vejce, jogurt).
      final veganOnly = preference == DietPreference.vegan;

      if (style == DietStyle.keto) {
        switch (kind) {
          case MealKind.breakfast:
            return choose(
              [
                tpl([FoodCatalog.eggs, FoodCatalog.butter], [vegB80]),
                tpl([FoodCatalog.eggs, FoodCatalog.gouda, FoodCatalog.butter], [vegB80]),
                if (veganOnly) tpl([FoodCatalog.tofu, FoodCatalog.rapeseedOil], [vegB80]),
              ],
              const _Tpl([FoodCatalog.tofu, FoodCatalog.rapeseedOil], [vegB80]),
            );
          case MealKind.snack:
            return choose(
              [
                tpl([FoodCatalog.eggs, FoodCatalog.gouda]),
                tpl([FoodCatalog.quarkLowFat, FoodCatalog.peanutButter]),
                if (veganOnly) tpl([FoodCatalog.tofu, FoodCatalog.peanutButter]),
              ],
              const _Tpl([FoodCatalog.tofu, FoodCatalog.peanutButter]),
            );
          case MealKind.main:
            final vegan = preference == DietPreference.vegan;
            return _Tpl(
              [
                ...mainProtein,
                pick(const [FoodCatalog.rapeseedOil, FoodCatalog.butter],
                    offset: 1, fallback: FoodCatalog.rapeseedOil),
                if (!vegan) FoodCatalog.gouda,
              ],
              const [FoodPortion(FoodCatalog.vegetablesBudget, 120)],
            );
        }
      }

      switch (kind) {
        case MealKind.breakfast:
          if (targetC < 25) {
            return choose(
              [
                tpl([FoodCatalog.eggs, FoodCatalog.wholegrainBread, FoodCatalog.butter], [vegB100]),
                tpl([FoodCatalog.quarkLowFat, FoodCatalog.peanutButter], [apple100]),
                if (veganOnly) tpl([FoodCatalog.tofu, FoodCatalog.wholegrainBread], [vegB100]),
              ],
              const _Tpl([FoodCatalog.tofu, FoodCatalog.wholegrainBread], [vegB100]),
            );
          }
          return choose(
            [
              tpl([FoodCatalog.oats, FoodCatalog.quarkLowFat, FoodCatalog.peanutButter], [milk200]),
              tpl([FoodCatalog.eggs, FoodCatalog.wholegrainBread, FoodCatalog.butter], [vegB100]),
              tpl([FoodCatalog.quarkLowFat, FoodCatalog.wholegrainBread, FoodCatalog.butter], [vegB100]),
              tpl([FoodCatalog.whiteYogurt, FoodCatalog.oats, FoodCatalog.quarkLowFat], [apple100]),
              if (veganOnly) tpl([FoodCatalog.tofu, FoodCatalog.wholegrainBread, FoodCatalog.peanutButter], [vegB100]),
              if (veganOnly) tpl([FoodCatalog.oats, FoodCatalog.soyProtein, FoodCatalog.peanutButter], [banana100]),
            ],
            const _Tpl([FoodCatalog.oats, FoodCatalog.soyProtein, FoodCatalog.peanutButter], [banana100]),
          );
        case MealKind.snack:
          if (targetC >= 15) {
            return choose(
              [
                tpl([FoodCatalog.quarkLowFat, FoodCatalog.banana, FoodCatalog.peanutButter]),
                tpl([FoodCatalog.eggs, FoodCatalog.wholegrainBread], [vegB100]),
                tpl([FoodCatalog.whiteYogurt, FoodCatalog.oats, FoodCatalog.peanutButter]),
                tpl([FoodCatalog.quarkLowFat, FoodCatalog.wholegrainBread, FoodCatalog.butter]),
                if (veganOnly) tpl([FoodCatalog.tofu, FoodCatalog.wholegrainBread, FoodCatalog.peanutButter]),
                if (veganOnly) tpl([FoodCatalog.soyProtein, FoodCatalog.banana, FoodCatalog.peanutButter]),
              ],
              const _Tpl([FoodCatalog.tofu, FoodCatalog.wholegrainBread, FoodCatalog.peanutButter]),
            );
          }
          return choose(
            [
              tpl([FoodCatalog.quarkLowFat, FoodCatalog.peanutButter]),
              tpl([FoodCatalog.eggs, FoodCatalog.gouda], [vegB100]),
              tpl([FoodCatalog.whiteYogurt, FoodCatalog.quarkLowFat, FoodCatalog.peanutButter]),
              if (veganOnly) tpl([FoodCatalog.tofu, FoodCatalog.peanutButter], [vegB100]),
            ],
            const _Tpl([FoodCatalog.tofu, FoodCatalog.peanutButter], [vegB100]),
          );
        case MealKind.main:
          return _Tpl(
            [
              ...mainProtein,
              if (targetC >= 10)
                pick(
                  const [FoodCatalog.rice, FoodCatalog.potatoes, FoodCatalog.pasta],
                  offset: 1,
                  fallback: FoodCatalog.rice,
                ),
              FoodCatalog.rapeseedOil,
            ],
            [vegB200],
          );
      }
    }

    // ---------------- keto ----------------
    if (style == DietStyle.keto) {
      // Keto: menší pevné porce zeleniny (sacharidy ze zeleniny by jinak
      // samy spotřebovaly většinu denního limitu), svačiny bez zeleniny.
      const veg80 = FoodPortion(FoodCatalog.vegetables, 80);
      const veg120 = FoodPortion(FoodCatalog.vegetables, 120);
      switch (kind) {
        case MealKind.breakfast:
          return choose(
            [
              tpl([FoodCatalog.eggs, FoodCatalog.butter, FoodCatalog.ham], [veg80]),
              tpl([FoodCatalog.eggs, FoodCatalog.avocado, FoodCatalog.gouda], [veg80]),
              tpl([FoodCatalog.eggs, FoodCatalog.oliveOil, FoodCatalog.mozzarellaLight], [veg80]),
              tpl([FoodCatalog.tofu, FoodCatalog.avocado, FoodCatalog.almonds], [veg80]),
              tpl([FoodCatalog.tofu, FoodCatalog.oliveOil, FoodCatalog.walnuts], [veg80]),
            ],
            _Tpl(const [FoodCatalog.tofu, FoodCatalog.avocado, FoodCatalog.almonds], const [veg80]),
          );
        case MealKind.snack:
          return choose(
            [
              tpl([FoodCatalog.gouda, FoodCatalog.almonds, FoodCatalog.avocado]),
              tpl([FoodCatalog.cottage, FoodCatalog.walnuts]),
              tpl([FoodCatalog.ham, FoodCatalog.mozzarellaLight, FoodCatalog.oliveOil]),
              if (soyOk) tpl([FoodCatalog.soyProtein, FoodCatalog.almonds, FoodCatalog.avocado]),
              if (soyOk) tpl([FoodCatalog.soyProtein, FoodCatalog.walnuts]),
            ],
            _Tpl(const [FoodCatalog.soyProtein, FoodCatalog.almonds, FoodCatalog.avocado]),
          );
        case MealKind.main:
          final vegan = preference == DietPreference.vegan;
          return _Tpl(
            [
              pick(mainProteins, stride: 1),
              pick(const [FoodCatalog.oliveOil, FoodCatalog.butter],
                  offset: 1, fallback: FoodCatalog.oliveOil),
              // Vegan keto: doplnění bílkovin bez sacharidů.
              vegan ? FoodCatalog.soyProtein : FoodCatalog.avocado,
            ],
            [vegan ? veg100 : veg120],
          );
      }
    }

    // ---------------- standardní strava ----------------
    switch (kind) {
      case MealKind.breakfast:
        if (targetC < 25) {
          return choose(
            [
              tpl([FoodCatalog.eggs, FoodCatalog.ham, FoodCatalog.wholegrainBread], [veg100]),
              tpl([FoodCatalog.cottage, FoodCatalog.walnuts, FoodCatalog.strawberries]),
              tpl([FoodCatalog.eggs, FoodCatalog.gouda, FoodCatalog.ryeBread], [veg100]),
              tpl([FoodCatalog.quarkLowFat, FoodCatalog.almonds, FoodCatalog.blueberries]),
              tpl([FoodCatalog.tofu, FoodCatalog.wholegrainBread, FoodCatalog.avocado], [veg100]),
            ],
            _Tpl(const [FoodCatalog.tofu, FoodCatalog.wholegrainBread, FoodCatalog.avocado], const [veg100]),
          );
        }
        return choose(
          [
            tpl([FoodCatalog.oats, proteinPowder, FoodCatalog.peanutButter],
                [const FoodPortion(FoodCatalog.blueberries, 80)]),
            tpl([FoodCatalog.eggs, FoodCatalog.wholegrainBread, FoodCatalog.ham], [veg100]),
            tpl([FoodCatalog.greekYogurt, FoodCatalog.oats, FoodCatalog.walnuts],
                [const FoodPortion(FoodCatalog.strawberries, 100)]),
            tpl([FoodCatalog.cottage, FoodCatalog.ryeBread, FoodCatalog.avocado], [veg100]),
            tpl([FoodCatalog.eggs, FoodCatalog.tortilla, FoodCatalog.gouda], [veg100]),
            tpl([FoodCatalog.skyr, FoodCatalog.oats, FoodCatalog.almonds],
                [const FoodPortion(FoodCatalog.apple, 100)]),
            tpl([FoodCatalog.tofu, FoodCatalog.wholegrainBread, FoodCatalog.avocado], [veg100]),
            if (soyOk)
              tpl([FoodCatalog.soyProtein, FoodCatalog.oats, FoodCatalog.walnuts],
                [const FoodPortion(FoodCatalog.strawberries, 100)]),
          ],
          _Tpl(const [FoodCatalog.oats, FoodCatalog.soyProtein, FoodCatalog.peanutButter],
              const [FoodPortion(FoodCatalog.blueberries, 80)]),
        );

      case MealKind.snack:
        if (targetC >= 15) {
          return choose(
            [
              tpl([FoodCatalog.skyr, FoodCatalog.banana, FoodCatalog.almonds]),
              tpl([FoodCatalog.greekYogurt, FoodCatalog.apple, FoodCatalog.walnuts]),
              tpl([FoodCatalog.cottage, FoodCatalog.riceCakes, FoodCatalog.strawberries]),
              tpl([proteinPowder, FoodCatalog.banana, FoodCatalog.peanutButter]),
              tpl([FoodCatalog.quarkLowFat, FoodCatalog.blueberries, FoodCatalog.cashews]),
              tpl([FoodCatalog.ham, FoodCatalog.wholegrainBread, FoodCatalog.avocado], [veg100]),
              if (soyOk)
                tpl([FoodCatalog.soyProtein, FoodCatalog.apple, FoodCatalog.walnuts],
                  [const FoodPortion(FoodCatalog.soyYogurt, 150)]),
            ],
            _Tpl(const [FoodCatalog.soyProtein, FoodCatalog.banana, FoodCatalog.almonds],
                const [FoodPortion(FoodCatalog.soyYogurt, 150)]),
          );
        }
        return choose(
          [
            tpl([FoodCatalog.ham, FoodCatalog.gouda, FoodCatalog.riceCakes]),
            tpl([FoodCatalog.cottage, FoodCatalog.walnuts], [veg100]),
            tpl([FoodCatalog.tuna, FoodCatalog.riceCakes, FoodCatalog.avocado]),
            tpl([FoodCatalog.eggs, FoodCatalog.mozzarellaLight], [veg100]),
            tpl([FoodCatalog.quarkLowFat, FoodCatalog.almonds, FoodCatalog.riceCakes]),
            if (soyOk) tpl([FoodCatalog.soyProtein, FoodCatalog.almonds, FoodCatalog.riceCakes]),
            tpl([FoodCatalog.tofu, FoodCatalog.cashews], [veg100]),
          ],
          _Tpl(const [FoodCatalog.soyProtein, FoodCatalog.almonds, FoodCatalog.riceCakes]),
        );

      case MealKind.main:
        // Oběd a večeře téhož dne mají různé maso i přílohu (sousední
        // [choice]); přílohy se střídají s jiným krokem než maso, takže
        // kombinace se během týdnů neopakují ve stejném pořadí.
        final protein = pick(mainProteins, stride: 1);
        final carb = pick(mainCarbs, stride: 3, offset: 1, fallback: FoodCatalog.rice);
        return _Tpl(
          [
            protein,
            if (targetC >= 10) carb,
            FoodCatalog.oliveOil,
          ],
          [veg200],
        );
    }
  }

  /// Úsporná varianta – večeře ze stejného vaření jako oběd.
  ///
  /// Všechny suroviny oběda (kromě tuku na vaření a zeleniny) se vynásobí
  /// JEDNÍM společným poměrem, takže je to opravdu stejné jídlo, jen jiná
  /// porce. Olej / máslo se dopočítá zvlášť (večeře má jiný podíl tuků),
  /// zelenina zůstává stejná porce.
  static List<FoodPortion> _scaleLeftover(
    List<FoodPortion> lunch,
    _Tpl template,
    double tP,
    double tC,
    double tF,
    double maxScale,
  ) {
    bool isVeg(NutritionFood f) => f.id.startsWith('vegetables');
    bool isFat(NutritionFood f) => f.fat >= 80;

    final dish = [
      for (final x in lunch)
        if (!isVeg(x.food) && !isFat(x.food) && x.grams > 0) x,
    ];
    final veg = [for (final x in lunch) if (isVeg(x.food)) x];
    final fats = [for (final f in template.vars) if (isFat(f)) f];

    final total = dish.fold<double>(0, (a, x) => a + x.grams);
    if (total <= 0) {
      return PortionSolver.solve(
        variable: template.vars,
        targetProtein: tP,
        targetCarbs: tC,
        targetFat: tF,
        fixed: template.fixed,
        maxScale: maxScale,
      );
    }

    // Oběd (bez oleje a zeleniny) jako jedna "potravina" – hledá se jen
    // velikost porce.
    const dishId = 'leftover_dish';
    final dishFood = NutritionFood(
      id: dishId,
      name: dishId,
      kcal: dish.fold<double>(0, (a, x) => a + x.kcal) / total * 100,
      protein: dish.fold<double>(0, (a, x) => a + x.protein) / total * 100,
      carbs: dish.fold<double>(0, (a, x) => a + x.carbs) / total * 100,
      fat: dish.fold<double>(0, (a, x) => a + x.fat) / total * 100,
      maxGrams: total * 3,
      step: 1,
    );

    final first = PortionSolver.solve(
      variable: [dishFood, ...fats],
      targetProtein: tP,
      targetCarbs: tC,
      targetFat: tF,
      fixed: veg,
      maxScale: maxScale,
    );
    final dishGrams = first
        .where((x) => x.food.id == dishId)
        .fold<double>(0, (a, x) => a + x.grams);
    final ratio = dishGrams / total;

    // Suroviny v poměru oběda, zaokrouhlené na kuchyňské kroky / kusy.
    final scaled = <FoodPortion>[];
    for (final x in dish) {
      final raw = x.grams * ratio;
      final pg = x.food.pieceGrams;
      double grams;
      if (pg != null && pg > 0) {
        final n = (raw / pg).round();
        grams = (n < 1 ? 1 : n) * pg;
      } else {
        final st = x.food.step;
        grams = (raw / st).round() * st;
        if (grams < st) grams = st;
      }
      scaled.add(FoodPortion(x.food, grams));
    }

    // Tuk na vaření se doladí až po zaokrouhlení surovin.
    final withFat = PortionSolver.solve(
      variable: fats,
      targetProtein: tP,
      targetCarbs: tC,
      targetFat: tF,
      fixed: [...scaled, ...veg],
      maxScale: maxScale,
    );
    final fatPortions = withFat.where((x) => isFat(x.food));

    return [...scaled, ...fatPortions, ...veg];
  }

  // ---------------------------------------------------------------
  // Převod na PlannedMeal
  // ---------------------------------------------------------------

  static PlannedMeal _toPlannedMeal(
    MealSlot slot,
    List<FoodPortion> portions, {
    bool leftover = false,
  }) {
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
        // Mléko se nakupuje a odměřuje v ml (hustota ≈ 1 g/ml).
        final unit = portion.food.id == 'milk' ? 'ml' : 'g';
        ingredients.add(
          MealIngredient(name: portion.food.displayName, amount: portion.grams, unit: unit),
        );
        parts.add('${portion.grams.round()} $unit ${portion.food.displayName}');
      }
    }

    final mainNames = portions
        .where((x) => !x.food.id.startsWith('vegetables'))
        .map((x) => x.food.name)
        .take(3)
        .toList();
    final hasVeg = portions.any((x) => x.food.id.startsWith('vegetables'));
    final baseName = [
      ...mainNames,
      if (hasVeg) 'zelenina',
    ].join(' + ');
    // Úsporná varianta: večeře je ze stejného vaření jako oběd.
    final name = leftover ? '$baseName (uvařeno s obědem)' : baseName;

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

/// Cíl posledního jídla dne – pro výběr šablony, která ho trefí.
class _Fit {
  final double protein;
  final double carbs;
  final double fat;
  final double maxScale;

  /// Přijatelná odchylka jídla v kcal (≈ 5 g bílkovin nebo 2 g tuku).
  static const double tolerance = 20;

  const _Fit(this.protein, this.carbs, this.fat, this.maxScale);

  /// Odchylka v kcal (stejná váha jako ve výpočtu porcí).
  double errorOf(_Tpl t) {
    final portions = PortionSolver.solve(
      variable: t.vars,
      targetProtein: protein,
      targetCarbs: carbs,
      targetFat: fat,
      fixed: t.fixed,
      maxScale: maxScale,
    );
    var p = 0.0, c = 0.0, f = 0.0;
    for (final x in portions) {
      p += x.protein;
      c += x.carbs;
      f += x.fat;
    }
    final dp = (p - protein) * 4, dc = (c - carbs) * 4, df = (f - fat) * 9;
    return math.sqrt(dp * dp + dc * dc + df * df);
  }
}

/// Šablona jídla: potraviny s dopočítávanou gramáží + pevné porce.
class _Tpl {
  final List<NutritionFood> vars;
  final List<FoodPortion> fixed;

  const _Tpl(this.vars, [this.fixed = const []]);
}
