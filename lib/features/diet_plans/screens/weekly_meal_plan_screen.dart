import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/pdf/diet_plan_pdf_service.dart';
import '../models/carb_cycling_food_logic.dart';
import '../models/carb_cycling_plan.dart';
import '../models/saved_meal_plan.dart';
import '../../coaching/workout_widgets.dart';
import '../logic/meal_plan_math.dart';
import '../widgets/meal_plan_actions.dart';
import 'custom_meal_plan_editor_screen.dart';
import 'saved_meal_plans_screen.dart';
import 'shopping_list_screen.dart';
import '../../paywall/paywall_screen.dart';
import '../../../providers/subscription/subscription_provider.dart';

class WeeklyMealPlanScreen extends ConsumerWidget {
  final CarbCyclingPlan? plan;
  final DietMealPlan? mealPlan;
  final String? titleOverride;
  final SavedMealPlan? savedTemplate;

  const WeeklyMealPlanScreen({
    super.key,
    this.plan,
    this.mealPlan,
    this.titleOverride,
    this.savedTemplate,
  });

  DietMealPlan _resolvePlan(AppLocalizations l10n) {
    if (mealPlan != null) return mealPlan!;
    if (plan?.mealPlan != null) return plan!.mealPlan!;

    final fallback = plan;

    if (fallback == null) {
      return const DietMealPlan(
        planType: 'Unknown',
        days: [],
        protein: 0,
        carbs: 0,
        fats: 0,
      );
    }

    final days = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];

    return DietMealPlan(
      planType: 'Vlny',
      protein: fallback.protein,
      carbs: fallback.dailyCarbs.isEmpty
          ? 0
          : fallback.dailyCarbs.first,
      fats: fallback.fats,
      days: List.generate(7, (index) {
        final carbs = fallback.dailyCarbs[index];

        final meals = MealGenerator.generateMenu(
          carbs,
          fallback.protein,
          fallback.fats,
          l10n: l10n,
          dayIndex: index,
        )
            .map((raw) => PlannedMeal.fromJson(raw))
            .toList();

        double sum(double? Function(PlannedMeal m) pick) =>
            meals.fold<double>(0, (a, m) => a + (pick(m) ?? 0.0));

        return PlannedDay(
          dayName: days[index],
          protein: sum((m) => m.protein),
          carbs: sum((m) => m.carbs),
          fats: sum((m) => m.fats),
          meals: meals,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final colorScheme = Theme.of(context).colorScheme;
    // Klient od trenéra jídelníček jen čte (neupravuje ani neukládá).
    final readOnly = ref.watch(clientLinkProvider).valueOrNull != null;
    // Vždy celé gramy a makra spočítaná z potravin.
    final resolvedPlan = MealPlanMath.normalizePlan(_resolvePlan(l10n));
    final pdfTitle = savedTemplate?.name ?? titleOverride;
    final pdfSubtitle = savedTemplate?.clientName == null
        ? null
        : 'Pro: ${savedTemplate!.clientName}';
    // Zkušební verze: první den celý, zbytek týdne zamčený.
    // Jídelníček od trenéra (online koučink) je vždy celý.
    final locked = !readOnly &&
        !ref.watch(accessProvider).fullMealPlan &&
        resolvedPlan.days.length > 1;
    final shownDays =
        locked ? resolvedPlan.days.take(1).toList() : resolvedPlan.days;
    

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titleOverride ?? l10n.weeklyMealPlan,
        ),
        actions: [
          IconButton(
            tooltip: l10n.savedMealPlans,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SavedMealPlansScreen(),
                ),
              );
            },
            icon: const Icon(Icons.bookmarks_outlined),
          ),
          if (!readOnly) ...[
            IconButton(
              tooltip: 'Upravit jídelníček',
              onPressed: () async {
                final saved = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomMealPlanEditorScreen(
                      initialPlan: resolvedPlan,
                      existing: savedTemplate,
                      suggestedName: titleOverride,
                    ),
                  ),
                );
                if (saved is SavedMealPlan && context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WeeklyMealPlanScreen(
                        mealPlan: saved.plan,
                        titleOverride: saved.name,
                        savedTemplate: saved,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Uložit s vlastním názvem',
              onPressed: () async {
                final saved = await MealPlanActions.saveDialog(
                  context,
                  ref,
                  resolvedPlan,
                  existing: savedTemplate,
                  suggestedName: titleOverride ??
                      '${resolvedPlan.planType} '
                          '${DateTime.now().day}. ${DateTime.now().month}.',
                );
                if (saved != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Uloženo jako „${saved.name}“.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save_outlined),
            ),
          ],
          IconButton(
            tooltip: l10n.printPdf,
            onPressed: () => DietPlanPdfService.printPlan(
              resolvedPlan,
              l10n,
              trainerNote: savedTemplate?.trainerNote,
              documentTitle: pdfTitle,
              subtitle: pdfSubtitle,
            ),
            icon: const Icon(Icons.print_outlined),
          ),
          IconButton(
            tooltip: l10n.sharePdf,
            onPressed: () => DietPlanPdfService.sharePlan(
              resolvedPlan,
              l10n,
              trainerNote: savedTemplate?.trainerNote,
              documentTitle: pdfTitle,
              subtitle: pdfSubtitle,
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: colorScheme.primaryContainer,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _macroChip(
                  context,
                  'Bílkoviny',
                  '${resolvedPlan.protein.round()} g',
                ),
                _macroChip(
                  context,
                  'Sacharidy',
                  '${resolvedPlan.carbs.round()} g',
                ),
                _macroChip(
                  context,
                  'Tuky',
                  '${resolvedPlan.fats.round()} g',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShoppingListScreen(
                      mealPlan: resolvedPlan,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('Nákupní seznam'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: shownDays.length + (locked ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= shownDays.length) {
                  return const LockedFeatureCard(
                    feature: 'Celý týdenní jídelníček',
                    description: 'Zbylé dny týdne, střídání jídel, levná '
                        'varianta a nákupní seznam jsou v plné verzi.',
                  );
                }
                final day = shownDays[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 0,
                  color: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: index == 0,
                      iconColor: colorScheme.primary,
                      collapsedIconColor:
                          colorScheme.onSurfaceVariant,
                      title: Text(
                        day.dayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      subtitle: Text(
                        '${MealPlanMath.dayKcal(day).round()} kcal • '
                        'B ${day.protein.round()} g • '
                        'S ${day.carbs.round()} g • '
                        'T ${day.fats.round()} g',
                      ),
                      children: day.meals.map((meal) {
                        return ListTile(
                          leading: Icon(
                            Icons.fastfood,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            meal.time != null
                                ? '${meal.time} • ${meal.label}: ${meal.name}'
                                : '${meal.label}: ${meal.name}',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.description,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (meal.calories != null)
                                Text(
                                  '${meal.calories!.round()} kcal · '
                                  'B ${(meal.protein ?? 0).round()} g · '
                                  'S ${(meal.carbs ?? 0).round()} g · '
                                  'T ${(meal.fats ?? 0).round()} g',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (meal.ingredients.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Ingredience: ${meal.ingredients.map((e) => '${e.name} (${e.formattedAmount})').join(', ')}',
                                  style: TextStyle(
                                    color:
                                        colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroChip(
    BuildContext context,
    String label,
    String value,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
