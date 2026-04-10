import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/user_profile_provider.dart';
import '../logic/meal_plan_scaling_service.dart';
import '../models/saved_meal_plan.dart';
import '../providers/diet_plan_provider.dart';
import '../providers/saved_meal_plans_provider.dart';
import 'weekly_meal_plan_screen.dart';

class SavedMealPlansScreen extends ConsumerWidget {
  const SavedMealPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedPlans = ref.watch(savedMealPlansProvider);
    final profile = ref.watch(userProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uložené jídelníčky'),
      ),
      body: savedPlans.isEmpty
          ? const Center(
              child: Text('Zatím nemáš uložené žádné kompletní jídelníčky.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: savedPlans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = savedPlans[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _chip(context, 'Typ: ${item.planType}'),
                            _chip(context, 'Délka: ${item.durationDays} dní'),
                            _chip(
                              context,
                              'Základ: ${item.baseWeight.toStringAsFixed(1)} kg',
                            ),
                            _chip(
                              context,
                              'Kcal: ${item.baseCalories.toStringAsFixed(0)}',
                            ),
                          ],
                        ),
                        if ((item.trainerNote ?? '').isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Poznámka trenéra: ${item.trainerNote}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: () {
                                ref.read(dietPlanProvider.notifier).state =
                                    item.plan;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WeeklyMealPlanScreen(
                                      mealPlan: item.plan,
                                      titleOverride: item.name,
                                      savedTemplate: item,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.content_copy),
                              label: const Text('Použít 1:1'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: profile == null
                                  ? null
                                  : () {
                                      final scaled = MealPlanScalingService
                                          .scaleTemplateToProfile(
                                        template: item,
                                        profile: profile,
                                      );

                                      ref.read(dietPlanProvider.notifier).state =
                                          scaled;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => WeeklyMealPlanScreen(
                                            mealPlan: scaled,
                                            titleOverride:
                                                '${item.name} • ${profile.displayName}',
                                            savedTemplate: item,
                                          ),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.scale),
                              label: const Text('Přepočítat na profil'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _confirmDelete(
                                context,
                                ref,
                                item,
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Smazat'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _chip(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavedMealPlan item,
  ) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Smazat jídelníček?'),
        content: Text('Opravdu chceš smazat "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ne'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ano'),
          ),
        ],
      ),
    );

    if (approved == true) {
      await ref.read(savedMealPlansProvider.notifier).deleteTemplate(item.id);
    }
  }
}