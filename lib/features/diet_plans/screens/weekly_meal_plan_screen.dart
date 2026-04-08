import 'package:flutter/material.dart';
import '../models/carb_cycling_plan.dart';
import '../models/carb_cycling_food_logic.dart';

class WeeklyMealPlanScreen extends StatelessWidget {
  final CarbCyclingPlan plan;

  const WeeklyMealPlanScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final dny = ["Pondělí", "Úterý", "Středa", "Čtvrtek", "Pátek", "Sobota", "Neděle"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Týdenní jídelníček"),
        backgroundColor: Colors.orange,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: 7,
        itemBuilder: (context, index) {
          final carbs = plan.dailyCarbs[index];
          // ✅ Tady voláme tvůj generátor
          final List<Map<String, dynamic>> meals = MealGenerator.generateMenu(carbs, plan.protein, plan.fats);

          return Card(
            margin: const EdgeInsets.only(bottom: 20), // ✅ Opraveno z .bottom na .only
            elevation: 4,
            child: ExpansionTile(
              initiallyExpanded: index == 0, // První den otevřený
              title: Text(
                "${dny[index]} - ${carbs.toStringAsFixed(0)}g S", 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)
              ),
              children: meals.map((meal) {
                // ✅ Opravený přístup k datům v Mapě pomocí ['klíče']
                return ListTile(
                  leading: const Icon(Icons.fastfood, size: 20, color: Colors.orange),
                  title: Text(meal['name'] ?? "Jídlo"),
                  subtitle: Text(meal['content'] ?? ""),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}