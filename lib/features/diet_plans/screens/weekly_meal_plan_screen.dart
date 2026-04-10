import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/user_profile_provider.dart';
import '../../../services/pdf/diet_plan_pdf_service.dart';
import '../models/carb_cycling_food_logic.dart';
import '../models/carb_cycling_plan.dart';
import '../models/saved_meal_plan.dart';
import '../providers/saved_meal_plans_provider.dart';
import 'saved_meal_plans_screen.dart';
import 'shopping_list_screen.dart';

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

  DietMealPlan _resolvePlan() {
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
      "Pondělí",
      "Úterý",
      "Středa",
      "Čtvrtek",
      "Pátek",
      "Sobota",
      "Neděle",
    ];

    return DietMealPlan(
      planType: 'Vlny',
      protein: fallback.protein,
      carbs: fallback.dailyCarbs.isEmpty ? 0 : fallback.dailyCarbs.first,
      fats: fallback.fats,
      days: List.generate(7, (index) {
        final carbs = fallback.dailyCarbs[index];
        final meals = MealGenerator.generateMenu(
          carbs,
          fallback.protein,
          fallback.fats,
        );

        return PlannedDay(
          dayName: days[index],
          protein: fallback.protein,
          carbs: carbs,
          fats: fallback.fats,
          meals: meals
              .map(
                (raw) => PlannedMeal(
                  label: (raw['name'] ?? 'Jídlo').toString(),
                  name: (raw['name'] ?? 'Jídlo').toString(),
                  description: (raw['content'] ?? '').toString(),
                  ingredients: const [],
                ),
              )
              .toList(),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = ref.watch(userProfileProvider);
    final resolvedPlan = _resolvePlan();

    return Scaffold(
      appBar: AppBar(
        title: Text(titleOverride ?? "Týdenní jídelníček"),
        actions: [
          IconButton(
            tooltip: 'Uložené jídelníčky',
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
          IconButton(
            tooltip: 'Uložit šablonu',
            onPressed: () => _showSaveDialog(
              context,
              ref,
              resolvedPlan,
              profile,
            ),
            icon: const Icon(Icons.save_outlined),
          ),
          IconButton(
            tooltip: 'Tisk / PDF',
            onPressed: () => DietPlanPdfService.printPlan(
              resolvedPlan,
              trainerNote: savedTemplate?.trainerNote,
            ),
            icon: const Icon(Icons.print_outlined),
          ),
          IconButton(
            tooltip: 'Sdílet PDF',
            onPressed: () => DietPlanPdfService.sharePlan(
              resolvedPlan,
              trainerNote: savedTemplate?.trainerNote,
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
                    builder: (_) => ShoppingListScreen(mealPlan: resolvedPlan),
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
              itemCount: resolvedPlan.days.length,
              itemBuilder: (context, index) {
                final day = resolvedPlan.days[index];

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
                        '${day.dayName} - ${day.carbs.toStringAsFixed(0)} g S',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      subtitle: Text(
                        'B ${day.protein.round()} g • T ${day.fats.round()} g',
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
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.description,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (meal.ingredients.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Ingredience: ${meal.ingredients.map((e) => '${e.name} (${e.formattedAmount})').join(', ')}',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
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

  Widget _macroChip(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
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

  Future<void> _showSaveDialog(
    BuildContext context,
    WidgetRef ref,
    DietMealPlan plan,
    dynamic profile,
  ) async {
    final nameController = TextEditingController(
      text: '${plan.planType} • ${DateTime.now().day}.${DateTime.now().month}.',
    );
    final trainerNoteController = TextEditingController(
      text: 'Další kontrola a vážení za 30 dní.',
    );
    final durationController = TextEditingController(
      text: plan.days.length.toString(),
    );

    final approved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Uložit kompletní jídelníček'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Název jídelníčku',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Počet dní',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: trainerNoteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Poznámka trenéra',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Uložit'),
          ),
        ],
      ),
    );

    if (approved == true) {
      await ref.read(savedMealPlansProvider.notifier).saveTemplate(
            name: nameController.text.trim().isEmpty
                ? 'Jídelníček'
                : nameController.text.trim(),
            plan: plan.copyWith(note: trainerNoteController.text.trim()),
            baseWeight: (profile?.weight as double?) ?? 0,
            baseCalories: (profile?.tdee as double?) ?? 0,
            durationDays: int.tryParse(durationController.text.trim()) ??
                plan.days.length,
            trainerNote: trainerNoteController.text.trim(),
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jídelníček byl uložen do databanky plánů.'),
          ),
        );
      }
    }
  }
}