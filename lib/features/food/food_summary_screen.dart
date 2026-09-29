import '../common/missing_goal_view.dart';
import 'package:flutter/material.dart';
import '../help/help_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nutrition/budget_classifier.dart';
import '../../models/daily_intake.dart';
import '../../models/diet_preference.dart';
import '../../models/food_combo.dart';
import '../../providers/daily_history_provider.dart';
import '../../providers/daily_intake_provider.dart';
import '../../providers/food_bank_provider.dart';
import '../../providers/food_combo_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/food_combo_service.dart';
import '../diet_plans/diet_strategy_screen.dart';
import '../diet_plans/widgets/trainer_meal_plans_card.dart';
import '../../services/macro_service.dart';
import '../../services/meal_suggestion_service.dart';
import '../../services/metabolism_service.dart';
import 'food_entry_screen.dart';
import '../../models/meal.dart';
import 'package:dart_application_1/l10n/app_localizations.dart';

enum HelpMode { items, combos }

enum _MealSlot { breakfast, snack, lunch, dinner }

String _slotLabel(BuildContext context, _MealSlot s) {
  final l10n = AppLocalizations.of(context)!;
  switch (s) {
    case _MealSlot.breakfast:
      return l10n.breakfast;
    case _MealSlot.snack:
      return l10n.snack;
    case _MealSlot.lunch:
      return l10n.lunch;
    case _MealSlot.dinner:
      return l10n.dinner;
  }
}

ComboMealTime _slotToComboTime(_MealSlot s) {
  switch (s) {
    case _MealSlot.breakfast:
      return ComboMealTime.breakfast;
    case _MealSlot.snack:
      return ComboMealTime.snack;
    case _MealSlot.lunch:
      return ComboMealTime.lunch;
    case _MealSlot.dinner:
      return ComboMealTime.dinner;
  }
}

List<_MealSlot> _defaultSlotsForMealCount(int n) {
  switch (n) {
    case 1:
      return [_MealSlot.lunch];
    case 2:
      return [_MealSlot.lunch, _MealSlot.dinner];
    case 3:
      return [_MealSlot.breakfast, _MealSlot.lunch, _MealSlot.dinner];
    default:
      return [
        _MealSlot.breakfast,
        _MealSlot.snack,
        _MealSlot.lunch,
        _MealSlot.dinner,
      ];
  }
}

class _Macros {
  int p, c, f;
  _Macros(this.p, this.c, this.f);

  bool get isZero => p <= 0 && c <= 0 && f <= 0;
}

class _PerGram {
  final double p;
  final double c;
  final double f;
  final double kcal;

  const _PerGram({
    required this.p,
    required this.c,
    required this.f,
    required this.kcal,
  });
}

class _ComboFilter {
  final ComboMealTime time;
  final ComboTaste taste;
  final DietPreference diet;

  /// Úsporná varianta – jen jídla z levných surovin.
  final bool budget;

  _ComboFilter({
    required this.time,
    required this.taste,
    this.diet = DietPreference.none,
    this.budget = false,
  });
}

class _ChosenCombo {
  final _MealSlot slot;
  final _ComboFilter filter;
  final FoodCombo combo;

  int grams;

  _ChosenCombo({
    required this.slot,
    required this.filter,
    required this.combo,
    required this.grams,
  });
}

class FoodSummaryScreen extends ConsumerWidget {
  const FoodSummaryScreen({super.key});

  int _missingInt(int target, int eaten) => (target - eaten).clamp(0, 999999);

  Future<int?> _pickMealsCount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.mealsCountQuestion,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [1, 2, 3, 4].map((n) {
                    return SizedBox(
                      width: 80,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, n),
                        child: Text('$n×'),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<HelpMode?> _pickHelpMode(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<HelpMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.howDoYouWantSuggestions,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.list_alt),
                  title: Text(l10n.singleItemsFromBank),
                  onTap: () => Navigator.pop(ctx, HelpMode.items),
                ),
                ListTile(
                  leading: const Icon(Icons.restaurant),
                  title: Text(l10n.completeMeals),
                  onTap: () => Navigator.pop(ctx, HelpMode.combos),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // ignore: unused_element
  Future<List<_MealSlot>?> _pickSlotsMulti(
    BuildContext context, {
    required int mealsCount,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    final initial = _defaultSlotsForMealCount(mealsCount);
    final selected = <_MealSlot>{...initial};

    return showModalBottomSheet<List<_MealSlot>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.selectMealsTotal(mealsCount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._MealSlot.values.map((s) {
                      final checked = selected.contains(s);
                      return CheckboxListTile(
                        value: checked,
                        title: Text(_slotLabel(context, s)),
                        onChanged: (v) {
                          setLocal(() {
                            if (v == true) {
                              if (selected.length < mealsCount) {
                                selected.add(s);
                              }
                            } else {
                              selected.remove(s);
                            }
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${l10n.selected}: ${selected.length}/$mealsCount',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: selected.length == mealsCount
                              ? () {
                                  final list = selected.toList()
                                    ..sort((a, b) => a.index.compareTo(b.index));
                                  Navigator.pop(ctx, list);
                                }
                              : null,
                          child: Text(l10n.continueText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<_ComboFilter?> _pickComboFilterForSlot(
    BuildContext context, {
    required _MealSlot slot,
    DietPreference initialDiet = DietPreference.none,
    bool initialBudget = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    final baseTime = _slotToComboTime(slot);

    final hasTaste =
        baseTime == ComboMealTime.breakfast || baseTime == ComboMealTime.snack;

    var diet = initialDiet;
    var budget = initialBudget;
    ComboTaste taste = ComboTaste.any;

    return showModalBottomSheet<_ComboFilter>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_slotLabel(context, slot)} – ${l10n.selectType}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.dietNone),
                          selected: diet == DietPreference.none,
                          onSelected: (_) =>
                              setLocal(() => diet = DietPreference.none),
                        ),
                        ChoiceChip(
                          label: Text(l10n.dietVegetarian),
                          selected: diet == DietPreference.vegetarian,
                          onSelected: (_) =>
                              setLocal(() => diet = DietPreference.vegetarian),
                        ),
                        ChoiceChip(
                          label: Text(l10n.dietVegan),
                          selected: diet == DietPreference.vegan,
                          onSelected: (_) =>
                              setLocal(() => diet = DietPreference.vegan),
                        ),
                        FilterChip(
                          avatar: const Icon(Icons.savings_outlined, size: 18),
                          label: Text(l10n.budgetShort),
                          selected: budget,
                          onSelected: (value) =>
                              setLocal(() => budget = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (hasTaste)
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(l10n.savory),
                            selected: taste == ComboTaste.savory,
                            onSelected: (_) =>
                                setLocal(() => taste = ComboTaste.savory),
                          ),
                          ChoiceChip(
                            label: Text(l10n.sweet),
                            selected: taste == ComboTaste.sweet,
                            onSelected: (_) =>
                                setLocal(() => taste = ComboTaste.sweet),
                          ),
                          ChoiceChip(
                            label: Text(l10n.anything),
                            selected: taste == ComboTaste.any,
                            onSelected: (_) =>
                                setLocal(() => taste = ComboTaste.any),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            ctx,
                            _ComboFilter(
                              time: baseTime,
                              taste: taste,
                              diet: diet,
                              budget: budget,
                            ),
                          );
                        },
                        child: Text(l10n.continueText),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<FoodCombo?> _pickOneComboFromList(
    BuildContext context,
    List<FoodCombo> list, {
    required String title,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    return showDialog<FoodCombo?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final c = list[i];
                return ListTile(
                  title: Text(c.name),
                  subtitle: Text('${c.defaultGrams} g default'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(ctx, c),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  FoodLogItem _buildLogItemFromComboUsingBank({
    required FoodCombo combo,
    required int grams,
    required Map<String, Meal> bankByName,
  }) {
    final baseWeight = combo.items.fold<int>(0, (s, x) => s + x.grams);

    if (baseWeight <= 0) {
      return FoodLogItem(
        name: combo.name,
        grams: grams,
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
      );
    }

    double baseCalories = 0;
    double baseProtein = 0;
    double baseCarbs = 0;
    double baseFat = 0;

    for (final it in combo.items) {
      final meal = bankByName[it.mealName] ??
          bankByName[it.mealName.trim().toLowerCase()];
      if (meal == null) {
        continue;
      }

      final f = it.grams / 100.0;
      baseCalories += meal.caloriesPer100g * f;
      baseProtein += meal.proteinPer100g * f;
      baseCarbs += meal.carbsPer100g * f;
      baseFat += meal.fatsPer100g * f;
    }

    final scale = grams / baseWeight;

    return FoodLogItem(
      name: combo.name,
      grams: grams,
      calories: (baseCalories * scale).round(),
      protein: (baseProtein * scale).round(),
      carbs: (baseCarbs * scale).round(),
      fat: (baseFat * scale).round(),
    );
  }
  // ignore: unused_element
  _PerGram _comboPerGram({
    required FoodCombo combo,
    required Map<String, Meal> bankByName,
  }) {
    final baseWeight = combo.items.fold<int>(0, (s, x) => s + x.grams);
    if (baseWeight <= 0) {
      return const _PerGram(p: 0, c: 0, f: 0, kcal: 0);
    }

    double kcal = 0;
    double p = 0;
    double c = 0;
    double f = 0;

    for (final it in combo.items) {
      final meal = bankByName[it.mealName];
      if (meal == null) {
        continue;
      }
      final factor = it.grams / 100.0;
      kcal += meal.caloriesPer100g * factor;
      p += meal.proteinPer100g * factor;
      c += meal.carbsPer100g * factor;
      f += meal.fatsPer100g * factor;
    }

    return _PerGram(
      kcal: kcal / baseWeight,
      p: p / baseWeight,
      c: c / baseWeight,
      f: f / baseWeight,
    );
  }

  void _addLogToSelectedDay(WidgetRef ref, FoodLogItem item) {
    final date = ref.read(selectedFoodDateProvider);
    ref.read(dailyHistoryProvider.notifier).addFood(date, item);
    ref.read(dailyIntakeProvider.notifier).refreshForSelectedDate();
  }

  void _addComboToDay(
    WidgetRef ref,
    FoodCombo combo,
    int grams,
    Map<String, Meal> bankByName,
  ) {
    final item = _buildLogItemFromComboUsingBank(
      combo: combo,
      grams: grams,
      bankByName: bankByName,
    );
    _addLogToSelectedDay(ref, item);
  }

  Future<int?> _askGrams(BuildContext context, int initial) async {
  final l10n = AppLocalizations.of(context)!;

  final ctrl = TextEditingController(
    text: initial.toString(),
  );

  final res = await showDialog<int?>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.howManyGrams),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: (l10n.grams),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, null),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final g = int.tryParse(ctrl.text.trim());

            if (g == null || g < 10 || g > 3000) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.enterValidGramRange,
                  ),
                ),
              );
              return;
            }

            Navigator.pop(ctx, g);
          },
          child: Text(l10n.ok),
        ),
      ],
    ),
  );

  // Uvolnit až po animaci zavření dialogu (jinak pád).
  Future<void>.delayed(const Duration(milliseconds: 500), ctrl.dispose);
  return res;
}

  _Macros _missingForSelectedDay(WidgetRef ref) {
    final profile = ref.read(userProfileProvider);
    if (profile == null) {
      return _Macros(0, 0, 0);
    }

    final date = ref.read(selectedFoodDateProvider);
    final day = ref.read(dailyHistoryProvider).intakeFor(date);

    final tdee = MetabolismService.calculateTDEE(
      profile,
      MetabolismService.activityFor(profile),
    );
    final macro = MacroService.calculate(profile, tdee);

    final mp = _missingInt(macro.protein, day.protein);
    final mc = _missingInt(macro.carbs, day.carbs);
    final mf = _missingInt(macro.fat, day.fat);

    return _Macros(mp, mc, mf);
  }

  _Macros _allocateForSlot({
    required _Macros missing,
    required _MealSlot currentSlot,
    required List<_MealSlot> remainingSlotsIncludingCurrent,
  }) {
    final n = remainingSlotsIncludingCurrent.length.clamp(1, 9999);
    return _Macros(
      (missing.p / n).round(),
      (missing.c / n).round(),
      (missing.f / n).round(),
    );
  }

  /// Gramáž jídla, při které nejlépe sedí VŠECHNY tři makroživiny
  /// (nejmenší čtverce v kcal: B a S × 4, T × 9), ne jen bílkoviny.
  int _suggestGramsForCombo({
    required FoodLogItem baseItem,
    required int baseGrams,
    required _Macros slotTarget,
  }) {
    if (baseItem.calories <= 0 || baseGrams <= 0) {
      return baseGrams;
    }

    final scale = _bestScale(baseItem, slotTarget);
    if (scale <= 0) return baseGrams;

    final grams = (baseGrams * scale / 10).round() * 10;
    return grams.clamp(60, 900);
  }

  /// Optimální násobek porce pro cíl (vážené nejmenší čtverce).
  double _bestScale(FoodLogItem item, _Macros target) {
    const wP = 16.0, wC = 16.0, wF = 81.0;
    final numerator = wP * item.protein * target.p +
        wC * item.carbs * target.c +
        wF * item.fat * target.f;
    final denominator = wP * item.protein * item.protein +
        wC * item.carbs * item.carbs +
        wF * item.fat * item.fat;
    if (denominator <= 0) return 0;
    return numerator / denominator;
  }

  /// Chyba jídla po optimálním naškálování (v kcal).
  double _scaledError(FoodLogItem item, _Macros target) {
    final k = _bestScale(item, target).clamp(0.2, 3.0).toDouble();
    final dp = (target.p - item.protein * k) * 4;
    final dc = (target.c - item.carbs * k) * 4;
    final df = (target.f - item.fat * k) * 9;
    return dp.abs() + dc.abs() + df.abs();
  }

  double _loss({
    required double tp,
    required double tc,
    required double tf,
    required double ap,
    required double ac,
    required double af,
  }) {
    final dp = tp - ap;
    final dc = tc - ac;
    final df = tf - af;

    return (dp * dp * 2.0) + (dc * dc * 1.0) + (df * df * 1.2);
  }
  // ignore: unused_element
  List<int> _solveGramsForCombos({
    required List<_PerGram> perGram,
    required List<int> startGrams,
    required int targetP,
    required int targetC,
    required int targetF,
    int minG = 60,
    int maxG = 900,
  }) {
    final n = perGram.length;
    if (n == 0) {
      return [];
    }

    final grams = startGrams.toList();
    int clamp(int g) => g.clamp(minG, maxG);

    double totalP() {
      double s = 0;
      for (int i = 0; i < n; i++) {
        s += perGram[i].p * grams[i];
      }
      return s;
    }

    double totalC() {
      double s = 0;
      for (int i = 0; i < n; i++) {
        s += perGram[i].c * grams[i];
      }
      return s;
    }

    double totalF() {
      double s = 0;
      for (int i = 0; i < n; i++) {
        s += perGram[i].f * grams[i];
      }
      return s;
    }

    double ap = totalP();
    double ac = totalC();
    double af = totalF();

    final tp = targetP.toDouble();
    final tc = targetC.toDouble();
    final tf = targetF.toDouble();

    double best = _loss(tp: tp, tc: tc, tf: tf, ap: ap, ac: ac, af: af);

    final steps = [40, 20, 10, 5];

    for (final step in steps) {
      for (int iter = 0; iter < 180; iter++) {
        bool improved = false;

        for (int i = 0; i < n; i++) {
          final gPlus = clamp(grams[i] + step);
          final dPlus = gPlus - grams[i];
          if (dPlus != 0) {
            final ap2 = ap + perGram[i].p * dPlus;
            final ac2 = ac + perGram[i].c * dPlus;
            final af2 = af + perGram[i].f * dPlus;
            final l2 = _loss(
              tp: tp,
              tc: tc,
              tf: tf,
              ap: ap2,
              ac: ac2,
              af: af2,
            );
            if (l2 + 1e-9 < best) {
              grams[i] = gPlus;
              ap = ap2;
              ac = ac2;
              af = af2;
              best = l2;
              improved = true;
            }
          }

          final gMinus = clamp(grams[i] - step);
          final dMinus = gMinus - grams[i];
          if (dMinus != 0) {
            final ap2 = ap + perGram[i].p * dMinus;
            final ac2 = ac + perGram[i].c * dMinus;
            final af2 = af + perGram[i].f * dMinus;
            final l2 = _loss(
              tp: tp,
              tc: tc,
              tf: tf,
              ap: ap2,
              ac: ac2,
              af: af2,
            );
            if (l2 + 1e-9 < best) {
              grams[i] = gMinus;
              ap = ap2;
              ac = ac2;
              af = af2;
              best = l2;
              improved = true;
            }
          }
        }

        if (!improved) {
          break;
        }
      }
    }

    return grams;
  }
  // ignore: unused_element
  Future<bool> _reviewAndConfirmPlan(
    BuildContext context, {
    required List<_ChosenCombo> chosen,
    required Map<String, Meal> bankByName,
    required _Macros target,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    int sumP() {
      int s = 0;
      for (final x in chosen) {
        final it = _buildLogItemFromComboUsingBank(
          combo: x.combo,
          grams: x.grams,
          bankByName: bankByName,
        );
        s += it.protein;
      }
      return s;
    }

    int sumC() {
      int s = 0;
      for (final x in chosen) {
        final it = _buildLogItemFromComboUsingBank(
          combo: x.combo,
          grams: x.grams,
          bankByName: bankByName,
        );
        s += it.carbs;
      }
      return s;
    }

    int sumF() {
      int s = 0;
      for (final x in chosen) {
        final it = _buildLogItemFromComboUsingBank(
          combo: x.combo,
          grams: x.grams,
          bankByName: bankByName,
        );
        s += it.fat;
      }
      return s;
    }

    int sumKcal() {
      int s = 0;
      for (final x in chosen) {
        final it = _buildLogItemFromComboUsingBank(
          combo: x.combo,
          grams: x.grams,
          bankByName: bankByName,
        );
        s += it.calories;
      }
      return s;
    }

    return (await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, setLocal) {
                final p = sumP();
                final c = sumC();
                final f = sumF();
                final kcal = sumKcal();

                return AlertDialog(
                  title: Text(l10n.planSummary),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cíl (zbytek dne): B ${target.p} | S ${target.c} | T ${target.f}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Plán pokryje: B $p | S $c | T $f | $kcal kcal',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                          const Divider(height: 18),
                          ...chosen.map((x) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${_slotLabel(context, x.slot)}: ${x.combo.name}',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${x.grams} g'),
                                  IconButton(
                                    tooltip: l10n.editGrams,
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () async {
                                      final g = await _askGrams(ctx, x.grams);
                                      if (g == null) {
                                        return;
                                      }
                                      setLocal(() => x.grams = g);
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 6),
                          Text(
                            l10n.manualOverrideHint,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.addAll),
                    ),
                  ],
                );
              },
            );
          },
        )) ??
        false;
  }

  Future<void> _showItemsSuggestions(
    
    BuildContext context,
    WidgetRef ref, {
    required int mealsCount,
    required int missingP,
    required int missingC,
    required int missingF,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final bank = ref.read(foodBankProvider);

    final suggestions = MealSuggestionService.suggest(
      missingProtein: missingP,
      missingCarbs: missingC,
      missingFat: missingF,
      bank: bank,
      mealsCount: mealsCount,
      preference: ref.read(userProfileProvider)?.diet ?? DietPreference.none,
      budget: ref.read(userProfileProvider)?.budget ?? false,
    );

    final totalP = suggestions.fold<int>(0, (a, s) => a + s.protein);
    final totalC = suggestions.fold<int>(0, (a, s) => a + s.carbs);
    final totalF = suggestions.fold<int>(0, (a, s) => a + s.fat);

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.mealSuggestions(mealsCount)),
              const SizedBox(height: 6),
              Text(
                l10n.remainderCoverage(
                  missingP,
                  missingC,
                  missingF,
                  totalP,
                  totalC,
                  totalF,
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: suggestions.isEmpty
                ? Text(l10n.noMealsAvailable)
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final s = suggestions[i];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...s.items.map((x) => Text('• $x')),
                            const SizedBox(height: 10),
                            Text(
                              l10n.approxMacros(
                                s.protein,
                                s.carbs,
                                s.fat,
                                s.calories,
                              ),
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.add),
                                label: Text(l10n.addToDay),
                                onPressed: () {
                                  for (final portion in s.portions) {
                                    _addLogToSelectedDay(
                                      ref,
                                      FoodLogItem(
                                        name: portion.meal.name,
                                        grams: portion.grams,
                                        calories: portion.calories,
                                        protein: portion.protein,
                                        carbs: portion.carbs,
                                        fat: portion.fat,
                                      ),
                                    );
                                  }
                                  Navigator.pop(ctx);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  /// Počet jídel podle zbývající energie (kcal).
  int _autoMealsCountFromMissing(_Macros m) {
    final kcal = m.p * 4 + m.c * 4 + m.f * 9;
    if (kcal <= 350) {
      return 1;
    }
    if (kcal <= 800) {
      return 2;
    }
    if (kcal <= 1300) {
      return 3;
    }
    return 4;
  }

  Future<void> _recalculateRemainderAuto(
    BuildContext context,
    WidgetRef ref, {
    int? mealsCount,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    final profile = ref.read(userProfileProvider);
    if (profile == null || profile.goal == null) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    final missing = _missingForSelectedDay(ref);
    if (missing.isZero) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.completed)),
      );
      return;
    }

    final count = mealsCount ?? _autoMealsCountFromMissing(missing);
    final pickedSlots = _defaultSlotsForMealCount(count);

    final allCombos = ref.read(foodComboProvider);
    final bankList = ref.read(foodBankProvider);
    final bankByName = <String, Meal>{
      for (final m in bankList) m.name: m,
      for (final m in bankList) m.name.trim().toLowerCase(): m,
    };

    var diet = profile.diet;
    var budget = profile.budget;

    for (int i = 0; i < pickedSlots.length; i++) {
      final slot = pickedSlots[i];

      final m = _missingForSelectedDay(ref);
      if (m.isZero) {
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.completed)),
        );
        return;
      }

      final remaining = pickedSlots.sublist(i);
      final slotTarget = _allocateForSlot(
        missing: _Macros(m.p, m.c, m.f),
        currentSlot: slot,
        remainingSlotsIncludingCurrent: remaining,
      );

      final filter = await _pickComboFilterForSlot(
        context,
        slot: slot,
        initialDiet: diet,
        initialBudget: budget,
      );
      if (!context.mounted) return;
      if (filter == null) {
        return;
      }
      diet = filter.diet;
      budget = filter.budget;

      // Jen jídla odpovídající stravovacímu omezení a jen ta, jejichž
      // všechny suroviny jsou v databance (jinak by makra nebyla úplná).
      final filtered = FoodComboService.filter(
        allCombos,
        time: filter.time,
        taste: filter.taste,
        diet: filter.diet,
      )
          .where((c) => c.missingItemsForBank(bankList).isEmpty)
          .where((c) => !filter.budget || BudgetClassifier.isCheapCombo(c))
          .toList();

      if (filtered.isEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n.noMealsInCategory(
                FoodComboService.timeLabel(filter.time),
              ),
            ),
          ),
        );
        return;
      }

      // Řazení podle toho, jak dobře jde jídlo naškálovat na cíl slotu
      // (poměr B/S/T), ne podle výchozí porce.
      double dist(FoodCombo c) {
        final item = _buildLogItemFromComboUsingBank(
          combo: c,
          grams: c.defaultGrams,
          bankByName: bankByName,
        );
        return _scaledError(item, slotTarget);
      }

      final sorted = filtered.toList()
        ..sort((a, b) => dist(a).compareTo(dist(b)));

      final shortlist = sorted.take(25).toList();

      final pickedCombo = await _pickOneComboFromList(
        context,
        shortlist,
        title: l10n.selectMeal(
          _slotLabel(context, slot),
          FoodComboService.timeLabel(filter.time),
        ),
      );

      if (!context.mounted) return;

      if (pickedCombo == null) {
        return;
      }

      final baseItem = _buildLogItemFromComboUsingBank(
        combo: pickedCombo,
        grams: pickedCombo.defaultGrams,
        bankByName: bankByName,
      );

      final suggested = _suggestGramsForCombo(
        baseItem: baseItem,
        baseGrams: pickedCombo.defaultGrams,
        slotTarget: slotTarget,
      );

      final grams = await _askGrams(context, suggested);

      if (!context.mounted) return;

      if (grams == null) {
        return;
      }

      _addComboToDay(ref, pickedCombo, grams, bankByName);

            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  l10n.addedMeal(
                    pickedCombo.name,
                    grams,
                  ),
                ),
              ),
            );
          }
        }
  Future<void> _helpFlowCombos(
    BuildContext context,
    WidgetRef ref, {
    required int mealsCount,
  }) async {
    await _recalculateRemainderAuto(
      context,
      ref,
      mealsCount: mealsCount,
    );
  }

      Future<void> _handleHelpMe(
        BuildContext context,
        WidgetRef ref,
      ) async {
        final l10n = AppLocalizations.of(context)!;

        final profile = ref.read(userProfileProvider);

        if (profile == null || profile.goal == null) {
          return;
        }

        final messenger = ScaffoldMessenger.of(context);

        final date = ref.read(selectedFoodDateProvider);
        final day = ref.read(dailyHistoryProvider).intakeFor(date);

        final tdee = MetabolismService.calculateTDEE(
          profile,
          MetabolismService.activityFor(profile),
        );

        final macro = MacroService.calculate(profile, tdee);

        final missingP = _missingInt(
          macro.protein,
          day.protein,
        );

        final missingC = _missingInt(
          macro.carbs,
          day.carbs,
        );

        final missingF = _missingInt(
          macro.fat,
          day.fat,
        );

        if (missingP == 0 &&
            missingC == 0 &&
            missingF == 0) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.completed),
            ),
          );
          return;
        }

        final mode = await _pickHelpMode(context);

        if (!context.mounted) return;

        if (mode == null) {
          return;
        }

        final mealsCount = await _pickMealsCount(context);

        if (!context.mounted) return;

        if (mealsCount == null) {
          return;
        }

        if (mode == HelpMode.items) {
          await _showItemsSuggestions(
            context,
            ref,
            mealsCount: mealsCount,
            missingP: missingP,
            missingC: missingC,
            missingF: missingF,
          );

          if (!context.mounted) return;
        } else {
          await _helpFlowCombos(
            context,
            ref,
            mealsCount: mealsCount,
          );

          if (!context.mounted) return;
        }
      }

@override
Widget build(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;

  final profile = ref.watch(userProfileProvider);

  if (profile == null || profile.goal == null) {
    return MissingGoalScaffold(title: l10n.todayFood);
  }

  final date = ref.watch(selectedFoodDateProvider);
  final intake = ref.watch(dailyIntakeProvider);

  final tdee = MetabolismService.calculateTDEE(
    profile,
    MetabolismService.activityFor(profile),
  );

  final macro = MacroService.calculate(profile, tdee);

  final missingP = _missingInt(macro.protein, intake.protein);
  final missingC = _missingInt(macro.carbs, intake.carbs);
  final missingF = _missingInt(macro.fat, intake.fat);

  return Scaffold(
    appBar: AppBar(
      title: Text(l10n.todayFood),
      actions: [
        const HelpButton(topic: 'food'),
        // Jídelníček (celý týden, nákupní seznam, styl stravy).
        IconButton(
          tooltip: l10n.myMealPlan,
          icon: const Icon(Icons.menu_book_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DietStrategyScreen(),
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.selectDate,
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now().subtract(
                const Duration(days: 365),
              ),
              lastDate: DateTime.now().add(
                const Duration(days: 365),
              ),
            );

            if (!context.mounted) return;

            if (picked != null) {
              ref.read(selectedFoodDateProvider.notifier).state =
                  DateTime(
                picked.year,
                picked.month,
                picked.day,
              );

              ref
                  .read(dailyIntakeProvider.notifier)
                  .refreshForSelectedDate();
            }
          },
        ),

        IconButton(
          tooltip: l10n.copyYesterday,
          icon: const Icon(Icons.copy),
          onPressed: () {
            ref
                .read(dailyHistoryProvider.notifier)
                .copyYesterdayTo(date);

            ref
                .read(dailyIntakeProvider.notifier)
                .refreshForSelectedDate();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.yesterdayCopied),
              ),
            );
          },
        ),

        IconButton(
          tooltip: l10n.resetDay,
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref
                .read(dailyHistoryProvider.notifier)
                .resetDay(date);

            ref
                .read(dailyIntakeProvider.notifier)
                .refreshForSelectedDate();
          },
        ),
      ],
    ),

    floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FoodEntryScreen(),
          ),
        );
      },
      icon: const Icon(Icons.add),
      label: Text(l10n.addFood),
    ),

    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const TrainerMealPlansCard(),

        _HeaderCard(date: date),

        const SizedBox(height: 12),

        _CaloriesCard(
          eaten: intake.calories,
          target: macro.targetCalories,
        ),

        const SizedBox(height: 12),

        _MacroBarsCard(
          intakeP: intake.protein,
          intakeC: intake.carbs,
          intakeF: intake.fat,
          targetP: macro.protein,
          targetC: macro.carbs,
          targetF: macro.fat,
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.remainingForToday,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'B $missingP g | S $missingC g | T $missingF g',
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 12),

                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _handleHelpMe(context, ref),
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(
                          l10n.helpWithRemainingFood,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _recalculateRemainderAuto(
                          context,
                          ref,
                        ),
                        icon: const Icon(Icons.replay),
                        label: Text(
                          l10n.recalculateRemainingDay,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        _ItemsCard(
          title: '${l10n.foods} (${intake.items.length})',
          child: intake.items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l10n.noFoodYet),
                )
              : ListView.separated(
                  physics:
                      const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: intake.items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final it = intake.items[i];

                    return ListTile(
                      title: Text(it.name),
                      subtitle: Text(
                        '${it.grams} g • ${it.calories} kcal • '
                        'B ${it.protein} / S ${it.carbs} / T ${it.fat}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          ref
                              .read(
                                dailyHistoryProvider.notifier,
                              )
                              .removeAt(date, i);

                          ref
                              .read(
                                dailyIntakeProvider.notifier,
                              )
                              .refreshForSelectedDate();
                        },
                      ),
                    );
                  },
                ),
        ),

        const SizedBox(height: 90),
      ],
    ),
  );
}
}
class _HeaderCard extends StatelessWidget {
  final DateTime date;

  const _HeaderCard({
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 12),
            Text(
              '${date.day}.${date.month}.${date.year}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaloriesCard extends StatelessWidget {
  final int eaten;
  final int target;

  const _CaloriesCard({
    required this.eaten,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        target <= 0 ? 0.0 : (eaten / target).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Calories',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            Text('$eaten / $target kcal'),
          ],
        ),
      ),
    );
  }
}

class _MacroBarsCard extends StatelessWidget {
  final int intakeP;
  final int intakeC;
  final int intakeF;

  final int targetP;
  final int targetC;
  final int targetF;

  const _MacroBarsCard({
    required this.intakeP,
    required this.intakeC,
    required this.intakeF,
    required this.targetP,
    required this.targetC,
    required this.targetF,
  });

  Widget _buildBar(
    String label,
    int value,
    int target,
  ) {
    final progress =
        target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value / $target g'),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: progress),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBar('Protein', intakeP, targetP),
            const SizedBox(height: 12),
            _buildBar('Carbs', intakeC, targetC),
            const SizedBox(height: 12),
            _buildBar('Fat', intakeF, targetF),
          ],
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ItemsCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}