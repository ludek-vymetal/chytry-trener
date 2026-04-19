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

class WeeklyTemplateBuilderScreen extends ConsumerStatefulWidget {
  const WeeklyTemplateBuilderScreen({super.key});

  @override
  ConsumerState<WeeklyTemplateBuilderScreen> createState() =>
      _WeeklyTemplateBuilderScreenState();
}

class _WeeklyTemplateBuilderScreenState
    extends ConsumerState<WeeklyTemplateBuilderScreen> {
  static const List<String> _days = [
    'Pondělí',
    'Úterý',
    'Středa',
    'Čtvrtek',
    'Pátek',
    'Sobota',
    'Neděle',
  ];

  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;

  final Map<String, String?> _selectedTemplateIds = {
    for (final day in _days) day: null,
  };

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
    final dailyTemplates = ref.read(customMealPlanTemplatesProvider);
    final combos = ref.read(foodComboProvider);
    final bank = ref.read(foodBankProvider);
    final profile = ref.read(userProfileProvider);

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _toast('Vyplň název týdenního jídelníčku.');
      return;
    }

    final missingDays = _days.where((day) => _selectedTemplateIds[day] == null);
    if (missingDays.isNotEmpty) {
      _toast('Vyber šablonu pro každý den v týdnu.');
      return;
    }

    final selectedTemplates = <DailyMealTemplate>[];
    for (final day in _days) {
      final id = _selectedTemplateIds[day];
      final template = dailyTemplates.cast<DailyMealTemplate?>().firstWhere(
            (e) => e?.id == id,
            orElse: () => null,
          );
      if (template == null) {
        _toast('Nepodařilo se načíst některou denní šablonu.');
        return;
      }
      selectedTemplates.add(template);
    }

    final plannedDays = <PlannedDay>[];
    for (var i = 0; i < _days.length; i++) {
      plannedDays.add(
        _mapTemplateToPlannedDay(
          dayName: _days[i],
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
      const SnackBar(content: Text('Týdenní jídelníček byl uložen.')),
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
    switch (slot) {
      case CustomMealSlot.breakfast:
        return 'Snídaně';
      case CustomMealSlot.snack1:
        return 'Svačina';
      case CustomMealSlot.lunch:
        return 'Oběd';
      case CustomMealSlot.snack2:
        return 'Svačina 2';
      case CustomMealSlot.dinner:
        return 'Večeře';
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(customMealPlanTemplatesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sestavit týdenní jídelníček'),
        actions: [
          IconButton(
            onPressed: templates.isEmpty ? null : _saveWeeklyPlan,
            icon: const Icon(Icons.save),
            tooltip: 'Uložit týden',
          ),
        ],
      ),
      body: templates.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nejdřív si vytvoř alespoň jednu denní šablonu jídelníčku.',
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
                          decoration: const InputDecoration(
                            labelText: 'Název týdenního jídelníčku',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Poznámka trenéra',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final day in _days) ...[
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
                            decoration: const InputDecoration(
                              labelText: 'Vyber denní šablonu',
                              border: OutlineInputBorder(),
                            ),
                            items: templates
                                .map(
                                  (template) => DropdownMenuItem<String>(
                                    value: template.id,
                                    child: Text(
                                      template.title.isEmpty
                                          ? 'Bez názvu'
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
                  label: const Text('ULOŽIT TÝDENNÍ JÍDELNÍČEK'),
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
            'Počet jídel: ${template.entries.where((e) => e.comboTitle != null && e.comboTitle!.trim().isNotEmpty).length}',
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