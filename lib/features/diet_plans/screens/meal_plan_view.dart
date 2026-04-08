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
    final meals = CarbCyclingCalculator.generateDailyMenu(
      carbs: dailyCarbs,
      protein: dailyProtein,
      fats: dailyFats,
      isKeto: isKeto,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isKeto
            ? Colors.indigo.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: meals.map((meal) => _buildMealItem(meal)).toList(),
      ),
    );
  }

  Widget _buildMealItem(Map<String, dynamic> meal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getMealIcon(meal['label']),
            size: 20,
            color: isKeto ? Colors.indigo : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${meal['label']}: ${meal['name']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  meal['description'],
                  style: TextStyle(
                    color: Colors.grey[600],
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