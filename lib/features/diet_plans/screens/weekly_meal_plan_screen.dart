import 'package:flutter/material.dart';
import '../models/carb_cycling_plan.dart';
import '../models/carb_cycling_food_logic.dart';

class WeeklyMealPlanScreen extends StatelessWidget {
  final CarbCyclingPlan plan;

  const WeeklyMealPlanScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dny = [
      "Pondělí",
      "Úterý",
      "Středa",
      "Čtvrtek",
      "Pátek",
      "Sobota",
      "Neděle",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Týdenní jídelníček"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: 7,
        itemBuilder: (context, index) {
          final carbs = plan.dailyCarbs[index];
          final List<Map<String, dynamic>> meals = MealGenerator.generateMenu(
            carbs,
            plan.protein,
            plan.fats,
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            elevation: 0,
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                initiallyExpanded: index == 0,
                iconColor: colorScheme.primary,
                collapsedIconColor: colorScheme.onSurfaceVariant,
                title: Text(
                  "${dny[index]} - ${carbs.toStringAsFixed(0)}g S",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                children: meals.map((meal) {
                  return ListTile(
                    leading: Icon(
                      Icons.fastfood,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    title: Text(
                      meal['name'] ?? "Jídlo",
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      meal['content'] ?? "",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}