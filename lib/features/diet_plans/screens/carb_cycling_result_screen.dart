import 'package:flutter/material.dart';
import 'package:dart_application_1/l10n/app_localizations.dart';

import '../../../core/nutrition/hollywood_prep.dart';
import '../../../services/pdf/diet_plan_pdf_service.dart';
import '../models/carb_cycling_plan.dart';
import 'custom_meal_plan_editor_screen.dart';
import 'meal_plan_view.dart';
import 'shopping_list_screen.dart';
import 'weekly_meal_plan_screen.dart';


class CarbCyclingResultScreen extends StatelessWidget {
  final CarbCyclingPlan plan;

  const CarbCyclingResultScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final days = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];

    final resolvedMealPlan = plan.mealPlan;
    final bool isKeto = plan.dailyCarbs.every((grams) => grams <= 50);
    // Jídelníček tréninkového programu (Hollywood, Bikini, Kulatý zadek).
    final programName = ProgramDiets.nameFor(resolvedMealPlan?.planType);
    final bool isProgram = programName != null;
    final programNote = resolvedMealPlan?.note?.trim() ?? '';

    final accentColor = isKeto ? colorScheme.secondary : colorScheme.primary;
    final summaryBackground =
        isKeto ? colorScheme.secondaryContainer : colorScheme.primaryContainer;
    final summaryForeground = isKeto
        ? colorScheme.onSecondaryContainer
        : colorScheme.onPrimaryContainer;

    final pdfTitle = programName ??
        (isKeto
            ? l10n.ketoMealPlanPdfTitle
            : l10n.carbCyclingPdfTitle);

    // Programy: popis fáze je v poznámce plánu (tiskne se zvlášť).
    final pdfSubtitle = isProgram
        ? ''
        : isKeto
            ? l10n.ketoMealPlanPdfSubtitle
            : l10n.carbCyclingPdfSubtitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          programName ??
              (isKeto ? l10n.yourKetoMealPlan : l10n.yourPlan),
        ),
        actions: [
          if (resolvedMealPlan != null) ...[
            IconButton(
              tooltip: 'Upravit jídelníček',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomMealPlanEditorScreen(
                    initialPlan: resolvedMealPlan,
                    suggestedName: pdfTitle,
                  ),
                ),
              ),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: l10n.printPdf,
              onPressed: () => DietPlanPdfService.printPlan(
                resolvedMealPlan,
                l10n,
                documentTitle: pdfTitle,
                subtitle: pdfSubtitle,
              ),
              icon: const Icon(Icons.print_outlined),
            ),
            IconButton(
              tooltip: l10n.sharePdf,
              onPressed: () => DietPlanPdfService.sharePlan(
                resolvedMealPlan,
                l10n,
                documentTitle: pdfTitle,
                subtitle: pdfSubtitle,
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isProgram && programNote.isNotEmpty) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.movie_filter_outlined),
                  title: Text(programNote),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Card(
              color: summaryBackground,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      isKeto
                          ? l10n.dailyCarbIntake
                          : l10n.weeklyCarbBank,
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
                          l10n.proteinLabel,
                          '${plan.protein.toStringAsFixed(0)}g',
                        ),
                        _macroMini(
                          context,
                          l10n.fatsLabel,
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
              label: Text(
                l10n.shoppingList,
                style: const TextStyle(fontWeight: FontWeight.bold),
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
              label: Text(
                l10n.showFullWeeklyMealPlan,
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                l10n.dayMealBreakdown,
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
                // Refeed (vyšší sacharidy v neděli) je jen u sacharidových vln.
                final isCarbCycling = resolvedMealPlan == null ||
                    resolvedMealPlan.planType == 'Vlny';
                final isRefeed =
                    !isKeto && !isProgram && isCarbCycling && index == 6;
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
                                l10n.refeedDay,
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
                      MealPlanView(
                        day: day,
                        isKeto: isKeto,
                        onSwapMeal: (mealIndex) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomMealPlanEditorScreen(
                              initialPlan: resolvedMealPlan,
                              suggestedName: pdfTitle,
                              initialDay: index,
                              swapMealIndex: mealIndex,
                            ),
                          ),
                        ),
                      )
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
              child: Text(l10n.closeAndActivate),
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