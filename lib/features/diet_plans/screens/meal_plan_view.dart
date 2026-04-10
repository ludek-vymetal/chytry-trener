import 'package:flutter/material.dart';

import '../models/carb_cycling_plan.dart';
import 'carb_cycling_logic.dart';

class MealPlanView extends StatelessWidget {
  final double? dailyCarbs;
  final double? dailyProtein;
  final double? dailyFats;
  final String? dayName;
  final bool isKeto;
  final PlannedDay? day;

  const MealPlanView({
    super.key,
    this.dailyCarbs,
    this.dailyProtein,
    this.dailyFats,
    this.dayName,
    this.isKeto = false,
    this.day,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final resolvedDay = day ??
        CarbCyclingCalculator.generateDayPlan(
          dayName: dayName ?? 'Den',
          carbs: isKeto ? (dailyCarbs ?? 30) : (dailyCarbs ?? 0),
          protein: dailyProtein ?? 0,
          fats: dailyFats ?? 0,
        );

    final backgroundColor = isKeto
        ? colorScheme.secondaryContainer.withValues(alpha: 0.45)
        : colorScheme.primaryContainer.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: resolvedDay.meals
            .map((meal) => _buildMealItem(context, meal))
            .toList(),
      ),
    );
  }

  Widget _buildMealItem(BuildContext context, PlannedMeal meal) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = isKeto ? colorScheme.secondary : colorScheme.primary;

    final hasStructuredMacros =
        meal.calories != null ||
            meal.protein != null ||
            meal.carbs != null ||
            meal.fats != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getMealIcon(meal.label),
            size: 20,
            color: accentColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.time != null
                      ? '${meal.time} • ${meal.label}: ${meal.name}'
                      : '${meal.label}: ${meal.name}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (meal.grams != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Porce: ${meal.grams} g',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (hasStructuredMacros) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (meal.calories != null)
                        _macroChip(
                          context,
                          label: 'kcal',
                          value: meal.calories!.round().toString(),
                        ),
                      if (meal.protein != null)
                        _macroChip(
                          context,
                          label: 'B',
                          value: '${meal.protein!.toStringAsFixed(1)} g',
                        ),
                      if (meal.carbs != null)
                        _macroChip(
                          context,
                          label: 'S',
                          value: '${meal.carbs!.toStringAsFixed(1)} g',
                        ),
                      if (meal.fats != null)
                        _macroChip(
                          context,
                          label: 'T',
                          value: '${meal.fats!.toStringAsFixed(1)} g',
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  meal.description,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroChip(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  IconData _getMealIcon(String label) {
    if (label.contains('Snídaně') || label.contains('První')) {
      return Icons.wb_sunny_outlined;
    }
    if (label.contains('Oběd')) {
      return Icons.lunch_dining;
    }
    if (label.contains('Svačina')) {
      return Icons.apple;
    }
    if (label.contains('Večeře') || label.contains('Poslední')) {
      return Icons.nightlight_round;
    }
    return Icons.restaurant_menu;
  }
}