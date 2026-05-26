import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/pdf/diet_plan_pdf_service.dart';
import '../logic/keto_calculator.dart';
import '../models/carb_cycling_plan.dart';
import 'shopping_list_screen.dart';
import 'weekly_meal_plan_screen.dart';


class KetoResultScreen extends StatefulWidget {
  final Map<String, double> macros;

  const KetoResultScreen({
    super.key,
    required this.macros,
  });

  @override
  State<KetoResultScreen> createState() =>
      _KetoResultScreenState();
}

class _KetoResultScreenState
    extends State<KetoResultScreen> {
  late DietMealPlan weeklyPlan;

 @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final l10n = AppLocalizations.of(context)!;

    weeklyPlan =
        KetoCalculator.generateWeeklyKetoMealPlan(
      protein: widget.macros['protein'] ?? 0,
      fats: widget.macros['fats'] ?? 0,
      carbs: widget.macros['carbs'] ?? 30,
      l10n: l10n,
    );
}

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final l10n =
        AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.yourWeeklyKetoPlan,
        ),
        actions: [
          IconButton(
            tooltip: l10n.printPdf,
            onPressed: () {
              DietPlanPdfService.printPlan(
                weeklyPlan,
                l10n,
              );
            },
            icon: const Icon(
              Icons.print_outlined,
            ),
          ),
          IconButton(
            tooltip: l10n.sharePdf,
            onPressed: () {
              DietPlanPdfService.sharePlan(
                weeklyPlan,
                l10n,
              );
            },
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMacroHeader(context),

            const SizedBox(height: 10),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: FilledButton.icon(
                style:
                    FilledButton.styleFrom(
                  minimumSize:
                      const Size(
                    double.infinity,
                    50,
                  ),
                ),
                icon: const Icon(
                  Icons.shopping_cart,
                ),
                label: Text(
                  l10n.generateShoppingList,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ShoppingListScreen(
                        mealPlan: weeklyPlan,
                        isKeto: true,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: FilledButton.tonalIcon(
                style:
                    FilledButton.styleFrom(
                  minimumSize:
                      const Size(
                    double.infinity,
                    50,
                  ),
                ),
                icon: const Icon(
                  Icons.calendar_month,
                ),
                label: Text(
                  l10n.openFullWeek,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          WeeklyMealPlanScreen(
                        mealPlan: weeklyPlan,
                        titleOverride:
                            l10n.weeklyKetoMealPlan,
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Text(
                l10n.fullWeekMealPlan,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            ListView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount:
                  weeklyPlan.days.length,
              itemBuilder:
                  (context, dayIndex) {
                final day =
                    weeklyPlan.days[dayIndex];

                return ExpansionTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color:
                        colorScheme.secondary,
                  ),
                  title: Text(
                    day.dayName,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'B ${day.protein.round()} g • '
                    'S ${day.carbs.round()} g • '
                    'T ${day.fats.round()} g',
                  ),
                  children:
                      day.meals.map((meal) {
                    return ListTile(
                      title: Text(
                        '${meal.label}: ${meal.name}',
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            meal.description,
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            '${l10n.ingredientsLabel}: '
                            '${meal.ingredients.map(
                              (e) =>
                                  '${e.name} (${e.formattedAmount})',
                            ).join(', ')}',
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .bodySmall,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroHeader(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final l10n =
        AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      color:
          colorScheme.secondaryContainer,
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: [
          _macroColumn(
            l10n.proteinLabel,
            '${widget.macros['protein']?.round()}g',
            colorScheme.primary,
          ),

          _macroColumn(
            l10n.fatsLabel,
            '${widget.macros['fats']?.round()}g',
            colorScheme.tertiary,
          ),

          _macroColumn(
            l10n.carbsLabel,
            '${widget.macros['carbs']?.round()}g',
            colorScheme.error,
          ),
        ],
      ),
    );
  }

  Widget _macroColumn(
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style:
              const TextStyle(fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}