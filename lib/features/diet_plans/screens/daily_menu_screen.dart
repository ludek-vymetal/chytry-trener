import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/diet_settings_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../services/pdf/diet_plan_pdf_service.dart';
import '../providers/diet_plan_provider.dart';
import 'carb_cycling_logic.dart';
import 'shopping_list_screen.dart';
import 'weekly_meal_plan_screen.dart';

class DailyMenuScreen extends ConsumerWidget {
  const DailyMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = ref.watch(userProfileProvider);
    final excluded = ref.watch(excludedIngredientsProvider);

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final generatedPlan = CarbCyclingCalculator.generateFastingMealPlan(
      profile: profile,
      excluded: excluded,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dietPlanProvider.notifier).state = generatedPlan;
    });

    final startTime =
        profile.fastingStartTime ?? const TimeOfDay(hour: 10, minute: 0);
    final fastingDuration = profile.fastingDuration;
    final eatingWindow = 24 - fastingDuration;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tvůj fasting jídelníček'),
        actions: [
          IconButton(
            tooltip: 'Tisk / PDF',
            onPressed: () => DietPlanPdfService.printPlan(generatedPlan),
            icon: const Icon(Icons.print_outlined),
          ),
          IconButton(
            tooltip: 'Sdílet PDF',
            onPressed: () => DietPlanPdfService.sharePlan(generatedPlan),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.secondaryContainer,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacroInfo(
                      context,
                      'Bílkoviny',
                      '${generatedPlan.protein.round()}g',
                      colorScheme.primary,
                    ),
                    _buildMacroInfo(
                      context,
                      'Tuky',
                      '${generatedPlan.fats.round()}g',
                      colorScheme.tertiary,
                    ),
                    _buildMacroInfo(
                      context,
                      'Sacharidy',
                      '${generatedPlan.carbs.round()}g',
                      colorScheme.error,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Chip(
                  label: Text(
                    'Režim: ${fastingDuration}h půst / ${eatingWindow}h jídlo (-300 kcal)',
                  ),
                  backgroundColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                  ),
                  avatar: Icon(
                    Icons.bolt,
                    size: 18,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShoppingListScreen(
                            mealPlan: generatedPlan,
                            isFasting: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Nákup'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WeeklyMealPlanScreen(
                            mealPlan: generatedPlan,
                            titleOverride: 'Týdenní fasting plán',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Celý týden'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: generatedPlan.days.length,
              itemBuilder: (context, dayIndex) {
                final day = generatedPlan.days[dayIndex];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ExpansionTile(
                    initiallyExpanded: dayIndex == 0,
                    title: Text(
                      day.dayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'B ${day.protein.round()} g • S ${day.carbs.round()} g • T ${day.fats.round()} g',
                    ),
                    children: day.meals.map((meal) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getMealColor(context, meal.label),
                          child: Icon(
                            Icons.restaurant,
                            color: colorScheme.onPrimary,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          meal.time != null
                              ? '${meal.time} • ${meal.label}: ${meal.name}'
                              : '${meal.label}: ${meal.name}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              meal.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ingredience: ${meal.ingredients.map((e) => '${e.name} (${e.formattedAmount})').join(', ')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time, {int addHours = 0}) {
    final hour = (time.hour + addHours) % 24;
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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