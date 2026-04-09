import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/sacharidove_vlny_bank.dart';
import '../../../providers/user_profile_provider.dart';
import 'carb_cycling_logic.dart';

final weeklyMenuProvider =
    StateProvider<List<List<Map<String, String>>>>((ref) => []);

class DailyMenuScreen extends ConsumerWidget {
  const DailyMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = ref.watch(userProfileProvider);
    final menuState = ref.watch(weeklyMenuProvider);

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final baseTdee = profile.tdee;
    final targetCalories = baseTdee - 300;

    final fastingProtein = profile.weight * 2.0;
    final fastingFats = profile.weight * 0.8;
    final fastingCarbs =
        (targetCalories - (fastingProtein * 4) - (fastingFats * 9)) / 4;

    final plan = CarbCyclingCalculator.calculate(profile: profile);

    if (menuState.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateInitialMenu(ref);
      });

      return const Scaffold(
        body: Center(child: Text('Připravuji tvůj plán...')),
      );
    }

    final menu = menuState[0];

    final isFastingActive =
        profile.selectedPlan == 'Fasting' || profile.isFasting;

    final startTime =
        profile.fastingStartTime ?? const TimeOfDay(hour: 10, minute: 0);

    final fastingDuration = profile.fastingDuration;
    final eatingWindow = 24 - fastingDuration;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tvůj jídelníček'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: isFastingActive
                ? colorScheme.secondaryContainer
                : colorScheme.primaryContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroInfo(
                  context,
                  'Bílkoviny',
                  '${isFastingActive ? fastingProtein.round() : plan.protein.round()}g',
                  colorScheme.primary,
                ),
                _buildMacroInfo(
                  context,
                  'Tuky',
                  '${isFastingActive ? fastingFats.round() : plan.fats.round()}g',
                  colorScheme.tertiary,
                ),
                _buildMacroInfo(
                  context,
                  'Sacharidy',
                  '${isFastingActive ? fastingCarbs.round() : plan.dailyCarbs[0].round()}g',
                  colorScheme.error,
                ),
              ],
            ),
          ),
          if (isFastingActive)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Chip(
                    label: Text(
                      'Režim: ${fastingDuration}h půst / ${eatingWindow}h jídlo (-300 kcal)',
                    ),
                    backgroundColor: colorScheme.secondaryContainer,
                    labelStyle: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                    ),
                    avatar: Icon(
                      Icons.bolt,
                      size: 18,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    'Okno jídla: ${_formatTime(startTime)} - ${_formatTime(startTime, addHours: eatingWindow)}',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: menu.length,
              itemBuilder: (context, index) {
                final meal = menu[index];

                final mealType = meal['label'] ?? 'Jídlo';
                final mealName = meal['name'] ?? '';
                final mealContent = meal['description'] ?? '';

                final mealTime = isFastingActive
                    ? _calculateMealTime(
                        startTime,
                        index,
                        menu.length,
                        fastingDuration,
                      )
                    : '';

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 72,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    _getMealColor(context, mealType),
                                child: Icon(
                                  Icons.restaurant,
                                  color: colorScheme.onPrimary,
                                  size: 18,
                                ),
                              ),
                              if (isFastingActive) ...[
                                const SizedBox(height: 6),
                                Text(
                                  mealTime,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$mealType: $mealName',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                mealContent,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: colorScheme.secondary,
                          ),
                          onPressed: () => _shuffleSingleMeal(ref, 0, index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _showShoppingPreview(context, menuState),
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Zobrazit nákupní seznam na týden'),
            ),
          ),
        ],
      ),
    );
  }

  void _generateInitialMenu(WidgetRef ref) {
    final allMeals = SacharidoveVlnyBank.items;
    if (allMeals.isEmpty) {
      return;
    }

    final fullWeek = List.generate(7, (dayIndex) {
      return List.generate(5, (mealIndex) {
        final randomMeal = allMeals[Random().nextInt(allMeals.length)];
        return {
          'label': _getLabel(mealIndex),
          'name': randomMeal.name,
          'description': _buildMealDescription(randomMeal),
          'ingredients': randomMeal.name,
        };
      });
    });

    ref.read(weeklyMenuProvider.notifier).state = fullWeek;
  }

  void _shuffleSingleMeal(WidgetRef ref, int dayIndex, int mealIndex) {
    final allMeals = SacharidoveVlnyBank.items;
    final newMeal = allMeals[Random().nextInt(allMeals.length)];

    final current = ref.read(weeklyMenuProvider);
    final newState = [...current];
    final newDay = [...newState[dayIndex]];

    newDay[mealIndex] = {
      ...newDay[mealIndex],
      'name': newMeal.name,
      'description': _buildMealDescription(newMeal),
      'ingredients': newMeal.name,
    };

    newState[dayIndex] = newDay;
    ref.read(weeklyMenuProvider.notifier).state = newState;
  }

  String _buildMealDescription(dynamic meal) {
    final calories = meal.caloriesPer100g;
    final protein = meal.proteinPer100g;
    final carbs = meal.carbsPer100g;
    final fats = meal.fatsPer100g;
    final grams = meal.defaultGrams;

    return 'Porce: ${grams} g | kcal: $calories | '
        'Bílkoviny: ${protein.toStringAsFixed(1)} g | '
        'Sacharidy: ${carbs.toStringAsFixed(1)} g | '
        'Tuky: ${fats.toStringAsFixed(1)} g';
  }

  String _getLabel(int i) {
    if (i == 0) {
      return 'První jídlo (Start)';
    }
    if (i == 4) {
      return 'Poslední jídlo (Konec)';
    }
    if (i == 2) {
      return 'Hlavní jídlo';
    }
    return 'Svačina';
  }

  void _showShoppingPreview(
    BuildContext context,
    List<List<Map<String, String>>> weeklyMenu,
  ) {
    final shoppingItems = <String>{};

    for (final daily in weeklyMenu) {
      for (final meal in daily) {
        final ing = meal['ingredients'];
        if (ing != null) {
          shoppingItems.add(ing);
        }
      }
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: shoppingItems.map((e) => ListTile(title: Text(e))).toList(),
      ),
    );
  }

  String _formatTime(TimeOfDay time, {int addHours = 0}) {
    final hour = (time.hour + addHours) % 24;
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _calculateMealTime(
    TimeOfDay start,
    int index,
    int totalMeals,
    int fastingDuration,
  ) {
    final eatingWindow = 24 - fastingDuration;

    if (totalMeals <= 1) {
      return _formatTime(start);
    }

    final gap = eatingWindow / (totalMeals - 1);
    final minutes = (index * gap * 60).round();

    final totalStartMinutes = start.hour * 60 + start.minute;
    final totalMinutes = (totalStartMinutes + minutes) % (24 * 60);
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMacroInfo(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getMealColor(BuildContext context, String type) {
    final colorScheme = Theme.of(context).colorScheme;

    if (type.contains('První')) {
      return colorScheme.primary;
    }
    if (type.contains('Poslední')) {
      return colorScheme.tertiary;
    }
    return colorScheme.secondary;
  }
}