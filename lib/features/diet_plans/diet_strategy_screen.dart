import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/diet_preference.dart';
import '../../models/goal.dart';
import '../../providers/diet_settings_provider.dart';
import '../../providers/user_profile_provider.dart';
import 'logic/keto_calculator.dart';
import 'providers/diet_plan_provider.dart';
import 'screens/carb_cycling_logic.dart';
import 'screens/carb_cycling_result_screen.dart';
import 'screens/carb_cycling_survey_screen.dart';
import 'screens/daily_menu_screen.dart';
import 'screens/keto_result_screen.dart';

class DietStrategyScreen extends ConsumerWidget {
  const DietStrategyScreen({super.key});

  Future<void> _selectStartTime(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final profile = ref.read(userProfileProvider);

    if (profile == null) return;

    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);

    final selectedHours = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.fastingLengthQuestion),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _fastingOption(
              dialogContext,
              12,
              l10n.fastingBeginner,
            ),
            _fastingOption(
              dialogContext,
              14,
              l10n.fastingIntermediate,
            ),
            _fastingOption(
              dialogContext,
              16,
              l10n.fastingClassic,
            ),
            _fastingOption(
              dialogContext,
              18,
              l10n.fastingAdvanced,
            ),
            _fastingOption(
              dialogContext,
              20,
              l10n.fastingWarrior,
            ),
          ],
        ),
      ),
    );

    if (selectedHours == null) return;
    if (!context.mounted) return;

    final picked = await showTimePicker(
      context: context,
      initialTime:
          profile.fastingStartTime ??
          const TimeOfDay(hour: 10, minute: 0),
      helpText: l10n.fastingWindowQuestion,
    );

    if (picked != null) {
      final currentProfile = ref.read(userProfileProvider);

      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          fastingStartTime: picked,
          isFasting: true,
          selectedPlan: 'Fasting',
          fastingDuration: selectedHours,
        );

        ref
            .read(userProfileProvider.notifier)
            .updateProfile(updatedProfile);

        final fastingPlan =
            CarbCyclingCalculator.generateFastingMealPlan(
          profile: updatedProfile,
          l10n: l10n,
          excluded: ref.read(excludedIngredientsProvider),
        );

        ref.read(dietPlanProvider.notifier).state =
            fastingPlan;
      }

      if (!context.mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.fastingConfigured(
              selectedHours,
              picked.format(context),
            ),
          ),
          backgroundColor: colorScheme.primary,
        ),
      );
    }
  }

  Widget _fastingOption(
    BuildContext context,
    int hours,
    String label,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      title: Text(label),
      leading: Icon(
        Icons.timer_outlined,
        color: colorScheme.secondary,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pop(context, hours),
    );
  }

  void _showIngredientCheck(
    BuildContext context,
    WidgetRef ref,
  ) {
    final l10n = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (dialogContext, dialogRef, child) {
          final currentExcluded =
              dialogRef.watch(excludedIngredientsProvider);

          return AlertDialog(
            title: Text(l10n.ingredientsWeekTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.ingredientsExcludeTitle),

                const Divider(),

                CheckboxListTile(
                  value: currentExcluded.contains('Losos'),
                  onChanged: (_) => dialogRef
                      .read(
                        excludedIngredientsProvider.notifier,
                      )
                      .toggleIngredient('Losos'),
                  title: Text(l10n.salmonOption),
                  contentPadding: EdgeInsets.zero,
                ),

                CheckboxListTile(
                  value: currentExcluded.contains('Vejce'),
                  onChanged: (_) => dialogRef
                      .read(
                        excludedIngredientsProvider.notifier,
                      )
                      .toggleIngredient('Vejce'),
                  title: Text(l10n.eggs),
                  contentPadding: EdgeInsets.zero,
                ),

                CheckboxListTile(
                  value: currentExcluded.contains(
                    'Hovězí maso',
                  ),
                  onChanged: (_) => dialogRef
                      .read(
                        excludedIngredientsProvider.notifier,
                      )
                      .toggleIngredient('Hovězí maso'),
                  title: Text(l10n.beef),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext),
                child: Text(
                  l10n.cancel.toUpperCase(),
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  final profile =
                      dialogRef.read(userProfileProvider);

                  if (profile == null) {
                    Navigator.pop(dialogContext);
                    return;
                  }

                  final ketoMacros =
                      KetoCalculator.calculateMacros(
                    profile,
                    l10n,
                  );

                  final ketoPlan =
                      KetoCalculator.generateWeeklyKetoMealPlan(
                    protein:
                        ketoMacros['protein'] ?? 0,
                    fats:
                        ketoMacros['fats'] ?? 0,
                    carbs:
                        ketoMacros['carbs'] ?? 30,
                    excludedFoods: dialogRef.read(
                      excludedIngredientsProvider,
                    ),
                    l10n: l10n,
                    preference: profile.diet,
                    budget: profile.budget,
                  );

                  ref
                      .read(dietPlanProvider.notifier)
                      .state = ketoPlan;

                  Navigator.pop(dialogContext);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KetoResultScreen(
                        macros: ketoMacros,
                        plan: ketoPlan,
                      ),
                    ),
                  );
                },
                child: Text(
                  l10n.generatePlanButton,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _activateLinearPlan(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final current = ref.read(userProfileProvider);

    if (current == null) return;

    final linearPlan =
        CarbCyclingCalculator.createLinearPlan(
      profile: current,
      l10n: l10n,
    );

    ref.read(userProfileProvider.notifier).updateProfile(
          current.copyWith(selectedPlan: 'Linear'),
        );

    ref.read(dietPlanProvider.notifier).state =
        linearPlan.mealPlan;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CarbCyclingResultScreen(plan: linearPlan),
      ),
    );
  }

  void _activateKetoPlan(
    BuildContext context,
    WidgetRef ref,
  ) {
    final current = ref.read(userProfileProvider);

    if (current != null) {
      ref.read(userProfileProvider.notifier).updateProfile(
            current.copyWith(selectedPlan: 'Keto'),
          );
    }

    _showIngredientCheck(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final colorScheme = Theme.of(context).colorScheme;

    final profile = ref.watch(userProfileProvider);

    final isFastingSelected =
        profile?.selectedPlan == 'Fasting';

    // Podpora při poruše příjmu potravy: žádné restriktivní diety
    // (keto, přerušovaný půst).
    final restrictiveBlocked =
        profile?.goal?.reason == GoalReason.eatingDisorderSupport;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dietPlanSelection),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (profile != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dietPreferenceTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.dietPreferenceHint),
                    const SizedBox(height: 12),
                    SegmentedButton<DietPreference>(
                      segments: [
                        ButtonSegment(
                          value: DietPreference.none,
                          label: Text(l10n.dietNone),
                        ),
                        ButtonSegment(
                          value: DietPreference.vegetarian,
                          label: Text(l10n.dietVegetarian),
                        ),
                        ButtonSegment(
                          value: DietPreference.vegan,
                          label: Text(l10n.dietVegan),
                        ),
                      ],
                      selected: {profile.diet},
                      onSelectionChanged: (selection) {
                        ref.read(userProfileProvider.notifier).updateProfile(
                              profile.copyWith(
                                dietPreference: selection.first,
                              ),
                            );
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.savings_outlined),
                      title: Text(l10n.budgetMealsTitle),
                      subtitle: Text(l10n.budgetMealsHint),
                      value: profile.budget,
                      onChanged: (value) {
                        ref.read(userProfileProvider.notifier).updateProfile(
                              profile.copyWith(budgetMeals: value),
                            );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _StrategyCard(
            title: l10n.linearPlanTitle,
            description:
                l10n.linearPlanDescription,
            icon: Icons.horizontal_rule,
            isActive:
                profile?.selectedPlan == 'Linear',
            actions: [
              _fullWidthButton(
                child: FilledButton(
                  onPressed: () =>
                      _activateLinearPlan(
                    context,
                    ref,
                    l10n,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        colorScheme.secondaryContainer,
                    foregroundColor:
                        colorScheme
                            .onSecondaryContainer,
                  ),
                  child: Text(
                    l10n.activateAndOpenPlan,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _StrategyCard(
            title: l10n.carbCyclingTitle,
            description:
                l10n.carbCyclingDescription,
            icon: Icons.show_chart,
            isActive:
                profile?.selectedPlan == 'Vlny',
            isNew: true,
            actions: [
              _fullWidthButton(
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const CarbCyclingSurveyScreen(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        colorScheme.tertiaryContainer,
                    foregroundColor:
                        colorScheme
                            .onTertiaryContainer,
                  ),
                  child: Text(
                    l10n.startAnalysisAndCycling,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (restrictiveBlocked)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.restrictiveDietsHidden),
              ),
            )
          else ...[
          _StrategyCard(
            title: l10n.ketoDietTitle,
            description:
                l10n.ketoDietDescription,
            icon: Icons.ac_unit,
            isActive:
                profile?.selectedPlan == 'Keto',
            isNew: true,
            actions: [
              _fullWidthButton(
                child: FilledButton(
                  onPressed: () =>
                      _activateKetoPlan(
                    context,
                    ref,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        colorScheme.primary,
                    foregroundColor:
                        colorScheme.onPrimary,
                  ),
                  child: Text(
                    l10n.selectKetoAndPreferences,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _StrategyCard(
            title: l10n.fastingTitle,
            description:
                l10n.fastingDescription,
            icon: Icons.timer,
            isActive: isFastingSelected,
            actions: [
              _fullWidthButton(
                child: FilledButton(
                  onPressed: () =>
                      _selectStartTime(
                    context,
                    ref,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isFastingSelected
                            ? colorScheme
                                .primaryContainer
                            : colorScheme
                                .secondaryContainer,
                    foregroundColor:
                        isFastingSelected
                            ? colorScheme
                                .onPrimaryContainer
                            : colorScheme
                                .onSecondaryContainer,
                  ),
                  child: Text(
                    profile?.fastingStartTime !=
                            null
                        ? l10n.editTime(
                            profile!
                                .fastingStartTime!
                                .format(context),
                          )
                        : l10n.setMealTimes,
                  ),
                ),
              ),

              if (isFastingSelected &&
                  profile?.fastingStartTime !=
                      null) ...[
                const SizedBox(height: 12),

                _fullWidthButton(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const DailyMenuScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.restaurant_menu,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          colorScheme.inverseSurface,
                      foregroundColor:
                          colorScheme
                              .onInverseSurface,
                    ),
                    label: Text(
                      l10n.enterMealPlan,
                    ),
                  ),
                ),
              ],
            ],
          ),
          ],
        ],
      ),
    );
  }

  Widget _fullWidthButton({
    required Widget child,
  }) {
    return SizedBox(
      width: double.infinity,
      child: child,
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isActive;
  final bool isNew;
  final List<Widget> actions;

  const _StrategyCard({
    required this.title,
    required this.description,
    required this.icon,
    this.isActive = false,
    this.isNew = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
        side: BorderSide(
          color: isActive
              ? colorScheme.primary
              : colorScheme.outlineVariant,
          width: isActive ? 1.6 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme
                          .onSurfaceVariant,
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment:
                            WrapCrossAlignment
                                .center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                              color: colorScheme
                                  .onSurface,
                            ),
                          ),

                          if (isNew)
                            _newBadge(
                              context,
                              l10n,
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        description,
                        style: TextStyle(
                          color: colorScheme
                              .onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...actions,
            ],
          ],
        ),
      ),
    );
  }

  Widget _newBadge(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius:
            BorderRadius.circular(6),
      ),
      child: Text(
        l10n.newBadge,
        style: TextStyle(
          color:
              colorScheme.onTertiaryContainer,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}