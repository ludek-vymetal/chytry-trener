import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/user_profile_provider.dart';
import '../logic/meal_plan_scaling_service.dart';
import '../models/custom_meal_plan_models.dart';
import '../models/saved_meal_plan.dart';
import '../providers/custom_meal_plan_templates_provider.dart';
import '../providers/diet_plan_provider.dart';
import '../providers/saved_meal_plans_provider.dart';
import 'daily_meal_plan_editor_screen.dart';
import 'weekly_meal_plan_screen.dart';

class SavedMealPlansScreen extends ConsumerWidget {
  const SavedMealPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final savedPlans = ref.watch(savedMealPlansProvider);
    final dailyTemplates = ref.watch(customMealPlanTemplatesProvider);
    final profile = ref.watch(userProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final hasWeeklyPlans = savedPlans.isNotEmpty;
    final hasDailyTemplates = dailyTemplates.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.savedMealPlans),
      ),
      body: (!hasWeeklyPlans && !hasDailyTemplates)
          ? Center(
              child: Text(
                l10n.noSavedMealPlans,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.dailyTemplates ,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                if (!hasDailyTemplates)
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.noDailyTemplates,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ...dailyTemplates.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title.isEmpty
                                    ? l10n.untitled
                                    : item.title,
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
                                  _chip(
                                    context,
                                    '${l10n.phase}: ${item.phaseLabel}',
                                  ),
                                  _chip(
                                    context,
                                    '${l10n.meals}: ${item.entries.length}',
                                  ),
                                  if ((item.clientName ?? '').trim().isNotEmpty)
                                    _chip(
                                      context,
                                      '${l10n.client}: ${item.clientName}',
                                    ),
                                ],
                              ),
                              if (item.note.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  '${l10n.coachNote}: ${item.note}',
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
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              DailyMealPlanEditorScreen(
                                            initialTemplate: item,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.edit_outlined),
                                    label: Text(l10n.openEdit),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _confirmDeleteDailyTemplate(
                                      context,
                                      ref,
                                      item,
                                    ),
                                    icon: const Icon(Icons.delete_outline),
                                    label: Text(l10n.delete),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Divider(color: colorScheme.outlineVariant),
                const SizedBox(height: 16),
                Text(
                  l10n.completeMealPlans,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                if (!hasWeeklyPlans)
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.noCompleteMealPlans,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ...savedPlans.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
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
                                  _chip(context, '${l10n.type}: ${item.planType}'),
                                  _chip(
                                    context,
                                    '${l10n.duration}: ${item.durationDays} ${l10n.days}',
                                  ),
                                  _chip(
                                    context,
                                    '${l10n.baseWeight}: ${item.baseWeight.toStringAsFixed(1)} kg',
                                  ),
                                  _chip(
                                    context,
                                    '${l10n.calories}: ${item.baseCalories.toStringAsFixed(0)}',
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
                                    label: Text(l10n.useOneToOne),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: profile == null
                                        ? null
                                        : () {
                                            final scaled =
                                                MealPlanScalingService
                                                    .scaleTemplateToProfile(
                                              template: item,
                                              profile: profile,
                                              l10n: AppLocalizations.of(context)!,
                                            );

                                            ref
                                                .read(dietPlanProvider.notifier)
                                                .state = scaled;

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    WeeklyMealPlanScreen(
                                                  mealPlan: scaled,
                                                  titleOverride:
                                                      '${item.name} • ${profile.displayName}',
                                                  savedTemplate: item,
                                                ),
                                              ),
                                            );
                                          },
                                    icon: const Icon(Icons.scale),
                                    label: Text(l10n.scaleToProfile),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _confirmDeleteWeeklyPlan(
                                      context,
                                      ref,
                                      item,
                                    ),
                                    icon: const Icon(Icons.delete_outline),
                                    label: Text(l10n.delete),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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

  Future<void> _confirmDeleteWeeklyPlan(
    BuildContext context,
    WidgetRef ref,
    SavedMealPlan item,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final approved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          l10n.deleteMealPlanQuestion,
        ),
        content: Text(
          l10n.confirmDeleteTemplate(
            item.name,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: Text(
              l10n.no,
            ),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: Text(
              l10n.yes,
            ),
          ),
        ],
      ),
    );

    if (approved == true) {
      await ref
          .read(savedMealPlansProvider.notifier)
          .deleteTemplate(item.id);
    }
  }

  Future<void> _confirmDeleteDailyTemplate(
    BuildContext context,
    WidgetRef ref,
    DailyMealTemplate item,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final approved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          l10n.deleteDailyTemplateQuestion,
        ),
        content: Text(
          l10n.confirmDeleteTemplate(
            item.title.isEmpty
                ? l10n.untitled
                : item.title,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: Text(
              l10n.no,
            ),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: Text(
              l10n.yes,
            ),
          ),
        ],
      ),
    );

    if (approved == true) {
      await ref
          .read(customMealPlanTemplatesProvider.notifier)
          .remove(item.id);
    }
  }
}  