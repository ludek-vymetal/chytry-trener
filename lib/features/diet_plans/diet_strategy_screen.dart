import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/diet_settings_provider.dart';
import '../../providers/user_profile_provider.dart';
import 'logic/keto_calculator.dart';
import 'providers/diet_plan_provider.dart';
import 'screens/carb_cycling_logic.dart';
import 'screens/carb_cycling_result_screen.dart';
import 'screens/carb_cycling_survey_screen.dart';
import 'screens/daily_menu_screen.dart';
import 'screens/keto_result_screen.dart';
import 'screens/saved_meal_plans_screen.dart';

class DietStrategyScreen extends ConsumerWidget {
  const DietStrategyScreen({super.key});

  Future<void> _selectStartTime(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;

    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);

    final selectedHours = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Jak dlouhý půst preferuješ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _fastingOption(dialogContext, 12, 'Začátečník (12:12)'),
            _fastingOption(dialogContext, 14, 'Mírně pokročilý (14:10)'),
            _fastingOption(dialogContext, 16, 'Klasika (16:8)'),
            _fastingOption(dialogContext, 18, 'Pokročilý (18:6)'),
            _fastingOption(dialogContext, 20, 'Warrior (20:4)'),
          ],
        ),
      ),
    );

    if (selectedHours == null) return;
    if (!context.mounted) return;

    final picked = await showTimePicker(
      context: context,
      initialTime:
          profile.fastingStartTime ?? const TimeOfDay(hour: 10, minute: 0),
      helpText: 'KDY TI ZAČÍNÁ OKNO JÍDLA?',
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

        ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);

        final fastingPlan = CarbCyclingCalculator.generateFastingMealPlan(
          profile: updatedProfile,
          excluded: ref.read(excludedIngredientsProvider),
        );

        ref.read(dietPlanProvider.notifier).state = fastingPlan;
      }

      if (!context.mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Nastaveno $selectedHours h půstu od ${picked.format(context)}',
          ),
          backgroundColor: colorScheme.primary,
        ),
      );
    }
  }

  Widget _fastingOption(BuildContext context, int hours, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      title: Text(label),
      leading: Icon(Icons.timer_outlined, color: colorScheme.secondary),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pop(context, hours),
    );
  }

  void _showIngredientCheck(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (dialogContext, dialogRef, child) {
          final currentExcluded = dialogRef.watch(excludedIngredientsProvider);

          return AlertDialog(
            title: const Text('Tento týden budeme vařit z:'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Označ suroviny, které NECHCEŠ:'),
                const Divider(),
                CheckboxListTile(
                  value: currentExcluded.contains('Losos'),
                  onChanged: (_) => dialogRef
                      .read(excludedIngredientsProvider.notifier)
                      .toggleIngredient('Losos'),
                  title: const Text('Losos (nemám rád ryby)'),
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: currentExcluded.contains('Vejce'),
                  onChanged: (_) => dialogRef
                      .read(excludedIngredientsProvider.notifier)
                      .toggleIngredient('Vejce'),
                  title: const Text('Vejce'),
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: currentExcluded.contains('Hovězí maso'),
                  onChanged: (_) => dialogRef
                      .read(excludedIngredientsProvider.notifier)
                      .toggleIngredient('Hovězí maso'),
                  title: const Text('Hovězí maso'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('ZRUŠIT'),
              ),
              ElevatedButton(
                onPressed: () {
                  final profile = dialogRef.read(userProfileProvider);
                  if (profile == null) {
                    Navigator.pop(dialogContext);
                    return;
                  }

                  final ketoMacros = KetoCalculator.calculateMacros(profile);
                  final ketoPlan = KetoCalculator.generateWeeklyKetoMealPlan(
                    protein: ketoMacros['protein'] ?? 0,
                    fats: ketoMacros['fats'] ?? 0,
                    carbs: ketoMacros['carbs'] ?? 30,
                    excludedFoods: dialogRef.read(excludedIngredientsProvider),
                  );

                  ref.read(dietPlanProvider.notifier).state = ketoPlan;

                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KetoResultScreen(macros: ketoMacros),
                    ),
                  );
                },
                child: const Text('TO JE V POHODĚ, GENERUJ!'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _activateLinearPlan(BuildContext context, WidgetRef ref) {
    final current = ref.read(userProfileProvider);
    if (current == null) return;

    final linearPlan = CarbCyclingCalculator.createLinearPlan(profile: current);

    ref.read(userProfileProvider.notifier).updateProfile(
          current.copyWith(selectedPlan: 'Linear'),
        );

    ref.read(dietPlanProvider.notifier).state = linearPlan.mealPlan;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarbCyclingResultScreen(plan: linearPlan),
      ),
    );
  }

  void _activateKetoPlan(BuildContext context, WidgetRef ref) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final profile = ref.watch(userProfileProvider);
    final isFastingSelected = profile?.selectedPlan == 'Fasting';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Výběr dietního plánu'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StrategyCard(
            title: 'Uložené jídelníčky',
            description:
                'Načti si vlastní kompletní týdenní nebo měsíční šablony a použij je znovu.',
            icon: Icons.bookmarks_outlined,
            actions: [
              _fullWidthButton(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SavedMealPlansScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('OTEVŘÍT DATABANKU JÍDELNÍČKŮ'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StrategyCard(
            title: 'Konstantní příjem (Linear)',
            description:
                'Každý den stejná makra. Nejjednodušší cesta pro stabilní růst svalů.',
            icon: Icons.horizontal_rule,
            isActive: profile?.selectedPlan == 'Linear',
            actions: [
              _fullWidthButton(
                child: FilledButton(
                  onPressed: () => _activateLinearPlan(context, ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                  ),
                  child: const Text('AKTIVOVAT A OTEVŘÍT PLÁN'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StrategyCard(
            title: 'Sacharidové vlny',
            description: 'Cyklování sacharidů pro spalování tuku.',
            icon: Icons.show_chart,
            isActive: profile?.selectedPlan == 'Vlny',
            isNew: true,
            actions: [
              _fullWidthButton(
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CarbCyclingSurveyScreen(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.tertiaryContainer,
                    foregroundColor: colorScheme.onTertiaryContainer,
                  ),
                  child: const Text('SPUSTIT ANALÝZU A VLNY'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StrategyCard(
            title: 'Keto dieta',
            description: 'Vysoký obsah tuků, minimum sacharidů.',
            icon: Icons.ac_unit,
            isActive: profile?.selectedPlan == 'Keto',
            isNew: true,
            actions: [
              _fullWidthButton(
                child: FilledButton(
                  onPressed: () => _activateKetoPlan(context, ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: const Text('VYBRAT KETO A UPRAVIT CHUTĚ'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StrategyCard(
            title: 'Přerušovaný půst',
            description:
                'Časově omezené okno pro jídlo. Zlepšuje regeneraci.',
            icon: Icons.timer,
            isActive: isFastingSelected,
            actions: [
              _fullWidthButton(
                child: FilledButton(
                  onPressed: () => _selectStartTime(context, ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: isFastingSelected
                        ? colorScheme.primaryContainer
                        : colorScheme.secondaryContainer,
                    foregroundColor: isFastingSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSecondaryContainer,
                  ),
                  child: Text(
                    profile?.fastingStartTime != null
                        ? 'UPRAVIT ČAS (${profile!.fastingStartTime!.format(context)})'
                        : 'NASTAVIT ČASY JÍDLA',
                  ),
                ),
              ),
              if (isFastingSelected && profile?.fastingStartTime != null) ...[
                const SizedBox(height: 12),
                _fullWidthButton(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyMenuScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.restaurant_menu),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.inverseSurface,
                      foregroundColor: colorScheme.onInverseSurface,
                    ),
                    label: const Text('VSTOUPIT DO JÍDELNÍČKU'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _fullWidthButton({required Widget child}) {
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
          width: isActive ? 1.6 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (isNew) _newBadge(context),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
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

  Widget _newBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'NOVINKA',
        style: TextStyle(
          color: colorScheme.onTertiaryContainer,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}