import 'package:flutter/material.dart';

import 'carb_cycling_logic.dart';

class MealPlanView extends StatelessWidget {
  final double dailyCarbs;
  final double dailyProtein;
  final double dailyFats;
  final String dayName;
  final bool isKeto;

  const MealPlanView({
    super.key,
    required this.dailyCarbs,
    required this.dailyProtein,
    required this.dailyFats,
    required this.dayName,
    this.isKeto = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final meals = CarbCyclingCalculator.generateDailyMenu(
      carbs: dailyCarbs,
      protein: dailyProtein,
      fats: dailyFats,
      isKeto: isKeto,
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
        children: meals.map((meal) => _buildMealItem(context, meal)).toList(),
      ),
    );
  }

  Widget _buildMealItem(BuildContext context, Map<String, dynamic> meal) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = isKeto ? colorScheme.secondary : colorScheme.primary;

    final description = (meal['description'] ?? '').toString();

    final calories = _readDouble(meal, ['calories', 'kcal']);
    final protein = _readDouble(meal, ['protein']);
    final carbs = _readDouble(meal, ['carbs', 'sacharidy']);
    final fats = _readDouble(meal, ['fats', 'tuky']);
    final grams = _readInt(meal, ['grams', 'gramy']);

    final hasStructuredMacros =
        calories != null || protein != null || carbs != null || fats != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getMealIcon((meal['label'] ?? '').toString()),
            size: 20,
            color: accentColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${meal['label']}: ${meal['name']}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (grams != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Porce: $grams g',
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
                      if (calories != null)
                        _macroChip(
                          context,
                          label: 'kcal',
                          value: calories.round().toString(),
                        ),
                      if (protein != null)
                        _macroChip(
                          context,
                          label: 'B',
                          value: '${protein.toStringAsFixed(1)} g',
                        ),
                      if (carbs != null)
                        _macroChip(
                          context,
                          label: 'S',
                          value: '${carbs.toStringAsFixed(1)} g',
                        ),
                      if (fats != null)
                        _macroChip(
                          context,
                          label: 'T',
                          value: '${fats.toStringAsFixed(1)} g',
                        ),
                    ],
                  ),
                ] else if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
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

  double? _readDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  int? _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.round();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  IconData _getMealIcon(String label) {
    if (label.contains('Snídaně')) {
      return Icons.wb_sunny_outlined;
    }
    if (label.contains('Oběd')) {
      return Icons.lunch_dining;
    }
    if (label.contains('Svačina')) {
      return Icons.apple;
    }
    return Icons.restaurant_menu;
  }
}