import 'package:flutter/material.dart';

import '../../../services/pdf/diet_plan_pdf_service.dart';
import '../models/carb_cycling_plan.dart';
import 'meal_plan_view.dart';
import 'shopping_list_screen.dart';
import 'weekly_meal_plan_screen.dart';

class CarbCyclingResultScreen extends StatelessWidget {
  final CarbCyclingPlan plan;

  const CarbCyclingResultScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final days = [
      'Pondělí',
      'Úterý',
      'Středa',
      'Čtvrtek',
      'Pátek',
      'Sobota',
      'Neděle',
    ];

    final resolvedMealPlan = plan.mealPlan;
    final bool isKeto = plan.dailyCarbs.every((grams) => grams <= 50);

    final accentColor = isKeto ? colorScheme.secondary : colorScheme.primary;
    final summaryBackground =
        isKeto ? colorScheme.secondaryContainer : colorScheme.primaryContainer;
    final summaryForeground = isKeto
        ? colorScheme.onSecondaryContainer
        : colorScheme.onPrimaryContainer;

    return Scaffold(
      appBar: AppBar(
        title: Text(isKeto ? 'Tvůj Keto jídelníček' : 'Tvůj plán'),
        actions: [
          if (resolvedMealPlan != null) ...[
            IconButton(
              tooltip: 'Tisk / PDF',
              onPressed: () => DietPlanPdfService.printPlan(resolvedMealPlan),
              icon: const Icon(Icons.print_outlined),
            ),
            IconButton(
              tooltip: 'Sdílet PDF',
              onPressed: () => DietPlanPdfService.sharePlan(resolvedMealPlan),
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: summaryBackground,
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
                        color: summaryForeground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(isKeto ? plan.dailyCarbs[0] : plan.weeklyBank).toStringAsFixed(0)} g',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: summaryForeground,
                      ),
                    ),
                    Divider(color: summaryForeground.withValues(alpha: 0.25)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _macroMini(
                          context,
                          'Bílkoviny',
                          '${plan.protein.toStringAsFixed(0)}g',
                        ),
                        _macroMini(
                          context,
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
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.tertiaryContainer,
                foregroundColor: colorScheme.onTertiaryContainer,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.shopping_basket),
              label: const Text(
                'GENEROVAT NÁKUPNÍ SEZNAM',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: resolvedMealPlan == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShoppingListScreen(
                            mealPlan: resolvedMealPlan,
                            isKeto: isKeto,
                          ),
                        ),
                      );
                    },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.calendar_month),
              label: const Text(
                'ZOBRAZIT CELÝ TÝDENNÍ JÍDELNÍČEK',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: resolvedMealPlan == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WeeklyMealPlanScreen(
                            mealPlan: resolvedMealPlan,
                          ),
                        ),
                      );
                    },
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Rozpis a jídelníček na dny:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
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
                final day = resolvedMealPlan?.days[index];

                return Column(
                  children: [
                    Card(
                      margin: const EdgeInsets.only(bottom: 0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isRefeed
                              ? colorScheme.tertiaryContainer
                              : accentColor.withValues(alpha: 0.18),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isRefeed
                                  ? colorScheme.onTertiaryContainer
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        title: Text(
                          days[index],
                          style: TextStyle(
                            fontWeight: isRefeed
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        trailing: Text(
                          '${grams.toStringAsFixed(0)} g',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: accentColor,
                          ),
                        ),
                        subtitle: isRefeed
                            ? Text(
                                'REFEED DEN 🚀',
                                style: TextStyle(
                                  color: colorScheme.tertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (day != null)
                      MealPlanView(day: day, isKeto: isKeto)
                    else
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
            FilledButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: colorScheme.inverseSurface,
                foregroundColor: colorScheme.onInverseSurface,
              ),
              child: const Text('ZAVŘÍT A AKTIVOVAT'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _macroMini(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}