import 'package:flutter/material.dart';

import '../models/carb_cycling_plan.dart';
import 'meal_plan_view.dart';
import 'shopping_list_screen.dart';
import 'weekly_meal_plan_screen.dart';

class CarbCyclingResultScreen extends StatelessWidget {
  final CarbCyclingPlan plan;

  const CarbCyclingResultScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final days = [
      'Pondělí',
      'Úterý',
      'Středa',
      'Čtvrtek',
      'Pátek',
      'Sobota',
      'Neděle',
    ];

    final bool isKeto = plan.dailyCarbs.every((grams) => grams <= 50);
    final Color themeColor = isKeto ? Colors.indigo : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Text(isKeto ? 'Tvůj Keto jídelníček' : 'Tvůj plán vln'),
        backgroundColor: themeColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: isKeto ? Colors.indigo.shade50 : Colors.orange.shade50,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      isKeto
                          ? 'DENNÍ PŘÍJEM SACHARIDŮ'
                          : 'TVŮJ TÝDENNÍ BANK SACHARIDŮ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(isKeto ? plan.dailyCarbs[0] : plan.weeklyBank).toStringAsFixed(0)} g',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _macroMini(
                          'Bílkoviny',
                          '${plan.protein.toStringAsFixed(0)}g',
                        ),
                        _macroMini(
                          'Tuky',
                          '${plan.fats.toStringAsFixed(0)}g',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.shopping_basket, color: Colors.white),
              label: const Text(
                'GENEROVAT NÁKUPNÍ SEZNAM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShoppingListScreen(plan: plan),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.calendar_month, color: Colors.white),
              label: const Text(
                'ZOBRAZIT CELÝ TÝDENNÍ JÍDELNÍČEK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeeklyMealPlanScreen(plan: plan),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Rozpis a jídelníček na dny:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 7,
              itemBuilder: (context, index) {
                final grams = plan.dailyCarbs[index];
                final isRefeed = !isKeto && index == 6;

                return Column(
                  children: [
                    Card(
                      margin: const EdgeInsets.only(bottom: 0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isRefeed
                              ? Colors.green
                              : themeColor.withValues(alpha: 0.2),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        title: Text(
                          days[index],
                          style: TextStyle(
                            fontWeight: isRefeed
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: Text(
                          '${grams.toStringAsFixed(0)} g',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: themeColor,
                          ),
                        ),
                        subtitle: isRefeed
                            ? const Text(
                                'REFEED DEN 🚀',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                ),
                              )
                            : null,
                      ),
                    ),
                    MealPlanView(
                      dailyCarbs: grams,
                      dailyProtein: plan.protein,
                      dailyFats: plan.fats,
                      dayName: days[index],
                      isKeto: isKeto,
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.black87,
              ),
              child: const Text(
                'ZAVŘÍT A AKTIVOVAT',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _macroMini(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}