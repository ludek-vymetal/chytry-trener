import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/food_combo.dart';
import '../../../models/meal.dart';
import '../../../providers/food_bank_provider.dart';
import '../../../providers/food_combo_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../models/carb_cycling_plan.dart';
import '../models/custom_meal_plan_models.dart';
import '../providers/custom_meal_plan_templates_provider.dart';
import '../providers/saved_meal_plans_provider.dart';
import '../../../l10n/app_localizations.dart';

class WeeklyTemplateBuilderScreen extends ConsumerStatefulWidget {
  const WeeklyTemplateBuilderScreen({super.key});

  @override
  ConsumerState<WeeklyTemplateBuilderScreen> createState() =>
      _WeeklyTemplateBuilderScreenState();
}

class _WeeklyTemplateBuilderScreenState
    extends ConsumerState<WeeklyTemplateBuilderScreen> {

  List<String> _days(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];
  }

  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;

  final Map<String, String?> _selectedTemplateIds = {};

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveWeeklyPlan() async {
    final l10n = AppLocalizations.of(context)!;
    final dailyTemplates = ref.read(customMealPlanTemplatesProvider);
    final combos = ref.read(foodComboProvider);
    final bank = ref.read(foodBankProvider);
    final profile = ref.read(userProfileProvider);

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _toast(l10n.fillWeeklyMealPlanName);
      return;
    }

    final missingDays = _days(context)
        .where((day) => _selectedTemplateIds[day] == null);
    if (missingDays.isNotEmpty) {
      _toast(l10n.selectTemplateForEachDay);
      return;
    }

    final selectedTemplates = <DailyMealTemplate>[];
    for (final day in _days(context)) {
      final id = _selectedTemplateIds[day];
      final template = dailyTemplates.cast<DailyMealTemplate?>().firstWhere(
            (e) => e?.id == id,
            orElse: () => null,
          );
      if (template == null) {
        _toast(l10n.failedToLoadDailyTemplate);
        return;
      }
      selectedTemplates.add(template);
    }

    final plannedDays = <PlannedDay>[];
    for (var i = 0; i < _days(context).length; i++) {
      plannedDays.add(
        _mapTemplateToPlannedDay(
          dayName: _days(context)[i],
          template: selectedTemplates[i],
          combos: combos,
          bank: bank,
        ),
      );
    }

    final avgProtein = plannedDays.isEmpty
        ? 0.0
        : plannedDays.map((e) => e.protein).reduce((a, b) => a + b) /
            plannedDays.length;
    final avgCarbs = plannedDays.isEmpty
        ? 0.0
        : plannedDays.map((e) => e.carbs).reduce((a, b) => a + b) /
            plannedDays.length;
    final avgFats = plannedDays.isEmpty
        ? 0.0
        : plannedDays.map((e) => e.fats).reduce((a, b) => a + b) /
            plannedDays.length;

    final weeklyPlan = DietMealPlan(
      planType: 'Custom',
      days: plannedDays,
      protein: avgProtein,
      carbs: avgCarbs,
      fats: avgFats,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    final baseCalories = plannedDays.isEmpty
        ? 0.0
        : plannedDays
                .map(
                  (day) => day.meals.fold<double>(
                    0,
                    (sum, meal) => sum + (meal.calories ?? 0),
                  ),
                )
                .reduce((a, b) => a + b) /
            plannedDays.length;

    await ref.read(savedMealPlansProvider.notifier).saveTemplate(
          name: title,
          plan: weeklyPlan,
          baseWeight: profile?.weight ?? 0,
          baseCalories: baseCalories,
          durationDays: 7,
          trainerNote: _noteCtrl.text.trim(),
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.weeklyMealPlanSaved),
      ),
    );

    Navigator.pop(context);
    }

  PlannedDay _mapTemplateToPlannedDay({
    required String dayName,
    required DailyMealTemplate template,
    required List<FoodCombo> combos,
    required List<Meal> bank,
  }) {
    final meals = template.entries
        .map((entry) => _mapEntryToMeal(entry, combos, bank))
        .whereType<PlannedMeal>()
        .toList();

    final totalProtein =
        meals.fold<double>(0, (sum, meal) => sum + (meal.protein ?? 0));
    final totalCarbs =
        meals.fold<double>(0, (sum, meal) => sum + (meal.carbs ?? 0));
    final totalFats =
        meals.fold<double>(0, (sum, meal) => sum + (meal.fats ?? 0));

    return PlannedDay(
      dayName: dayName,
      meals: meals,
      protein: totalProtein,
      carbs: totalCarbs,
      fats: totalFats,
    );
  }

  PlannedMeal? _mapEntryToMeal(
    CustomMealEntry entry,
    List<FoodCombo> combos,
    List<Meal> bank,
  ) {
    if (entry.comboTitle == null || entry.comboTitle!.trim().isEmpty) {
      return null;
    }

    final combo = combos.cast<FoodCombo?>().firstWhere(
          (e) => e?.title == entry.comboTitle,
          orElse: () => null,
        );

    if (combo == null) {
      return null;
    }

    final multiplier =
        entry.portionMultiplier <= 0 ? 1.0 : entry.portionMultiplier;
    final grams = (combo.defaultGrams * multiplier).round();

    final calories = _comboCalories(combo, bank) * multiplier;
    final protein = _comboProtein(combo, bank) * multiplier;
    final carbs = _comboCarbs(combo, bank) * multiplier;
    final fats = _comboFats(combo, bank) * multiplier;

    final ingredients = combo.items
        .map(
          (item) => MealIngredient(
            name: item.mealName,
            amount: item.grams * multiplier,
            unit: 'g',
          ),
        )
        .toList();

    return PlannedMeal(
      label: _slotLabel(entry.slot),
      name: combo.title,
      description: combo.items
          .map(
            (item) =>
                '${(item.grams * multiplier).round()} g ${item.mealName}',
          )
          .join(' + '),
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      grams: grams,
      ingredients: ingredients,
    );
  }

  Meal? _findMeal(List<Meal> bank, String name) {
    final normalized = name.trim().toLowerCase();

    for (final meal in bank) {
      if (meal.name.trim().toLowerCase() == normalized) {
        return meal;
      }
    }

    return null;
  }

  double _comboCalories(FoodCombo combo, List<Meal> bank) {
    double sum = 0;
    for (final item in combo.items) {
      final meal = _findMeal(bank, item.mealName);
      if (meal == null) continue;
      sum += (meal.caloriesPer100g * item.grams) / 100.0;
    }
    return sum;
  }

  double _comboProtein(FoodCombo combo, List<Meal> bank) {
    double sum = 0;
    for (final item in combo.items) {
      final meal = _findMeal(bank, item.mealName);
      if (meal == null) continue;
      sum += (meal.proteinPer100g * item.grams) / 100.0;
    }
    return sum;
  }

  double _comboCarbs(FoodCombo combo, List<Meal> bank) {
    double sum = 0;
    for (final item in combo.items) {
      final meal = _findMeal(bank, item.mealName);
      if (meal == null) continue;
      sum += (meal.carbsPer100g * item.grams) / 100.0;
    }
    return sum;
  }

  double _comboFats(FoodCombo combo, List<Meal> bank) {
    double sum = 0;
    for (final item in combo.items) {
      final meal = _findMeal(bank, item.mealName);
      if (meal == null) continue;
      sum += (meal.fatsPer100g * item.grams) / 100.0;
    }
    return sum;
  }

  String _slotLabel(CustomMealSlot slot) {
    final l10n = AppLocalizations.of(context)!;

    switch (slot) {
      case CustomMealSlot.breakfast:
        return l10n.breakfast;

      case CustomMealSlot.snack1:
        return l10n.snack;

      case CustomMealSlot.lunch:
        return l10n.lunch;

      case CustomMealSlot.snack2:
        return l10n.snack2;

      case CustomMealSlot.dinner:
        return l10n.dinner;
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final templates = ref.watch(customMealPlanTemplatesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.buildWeeklyMealPlan),
        actions: [
          IconButton(
            onPressed: templates.isEmpty ? null : _saveWeeklyPlan,
            icon: const Icon(Icons.save),
            tooltip: l10n.saveWeek,
          ),
        ],
      ),
      body: templates.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  l10n.createDailyTemplateFirst,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 0,
                  color: colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _titleCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.weeklyMealPlanName,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: l10n.coachNote,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final day in _days(context)) ...[
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedTemplateIds[day],
                            decoration: InputDecoration(
                              labelText: l10n.selectDailyTemplate,
                              border: OutlineInputBorder(),
                            ),
                            items: templates
                                .map(
                                  (template) => DropdownMenuItem<String>(
                                    value: template.id,
                                    child: Text(
                                      template.title.isEmpty
                                          ? l10n.untitled
                                          : template.title,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTemplateIds[day] = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          if (_selectedTemplateIds[day] != null)
                            _SelectedTemplatePreview(
                              template: templates.firstWhere(
                                (e) => e.id == _selectedTemplateIds[day],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  onPressed: _saveWeeklyPlan,
                  icon: const Icon(Icons.save),
                  label: Text(l10n.saveWeeklyMealPlan),
                ),
              ],
            ),
    );
  }
}

class _SelectedTemplatePreview extends StatelessWidget {
  final DailyMealTemplate template;

  const _SelectedTemplatePreview({
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            template.phaseLabel,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${l10n.mealCount}: ${template.entries.where((e) => e.comboTitle != null && e.comboTitle!.trim().isNotEmpty).length}',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          if (template.note.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              template.note,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}