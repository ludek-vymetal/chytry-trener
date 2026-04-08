import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logic/keto_calculator.dart';
import 'screens/carb_cycling_survey_screen.dart';
import 'screens/daily_menu_screen.dart';
import 'screens/keto_result_screen.dart';

import '../../providers/diet_settings_provider.dart';
import '../../providers/user_profile_provider.dart';

class DietStrategyScreen extends ConsumerWidget {
  const DietStrategyScreen({super.key});

  Future<void> _selectStartTime(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;

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
        ref.read(userProfileProvider.notifier).updateProfile(
              currentProfile.copyWith(
                fastingStartTime: picked,
                isFasting: true,
                selectedPlan: 'Fasting',
                fastingDuration: selectedHours,
              ),
            );
      }

      if (!context.mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Nastaveno $selectedHours h půstu od ${picked.format(context)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _fastingOption(BuildContext context, int hours, String label) {
    return ListTile(
      title: Text(label),
      leading: const Icon(Icons.timer_outlined, color: Colors.indigo),
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
                ),
                CheckboxListTile(
                  value: currentExcluded.contains('Vejce'),
                  onChanged: (_) => dialogRef
                      .read(excludedIngredientsProvider.notifier)
                      .toggleIngredient('Vejce'),
                  title: const Text('Vejce'),
                ),
                CheckboxListTile(
                  value: currentExcluded.contains('Hovězí maso'),
                  onChanged: (_) => dialogRef
                      .read(excludedIngredientsProvider.notifier)
                      .toggleIngredient('Hovězí maso'),
                  title: const Text('Hovězí maso'),
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
                  final navigator = Navigator.of(dialogContext);

                  navigator.pop();

                  navigator.push(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            title: 'Konstantní příjem (Linear)',
            description:
                'Každý den stejná makra. Nejjednodušší cesta pro stabilní růst svalů.',
            icon: Icons.horizontal_rule,
            isActive: profile?.selectedPlan == 'Linear',
            actionButton: ElevatedButton(
              onPressed: () {
                final current = ref.read(userProfileProvider);
                if (current != null) {
                  ref.read(userProfileProvider.notifier).updateProfile(
                        current.copyWith(selectedPlan: 'Linear'),
                      );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
              ),
              child: const Text('AKTIVOVAT KONSTANTNÍ PLÁN'),
            ),
          ),
          const SizedBox(height: 16),
          _StrategyCard(
            title: 'Sacharidové vlny',
            description: 'Cyklování sacharidů pro spalování tuku.',
            icon: Icons.show_chart,
            isActive: profile?.selectedPlan == 'Vlny',
            isNew: true,
            actionButton: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CarbCyclingSurveyScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('SPUSTIT ANALÝZU A VLNY'),
            ),
          ),
          const SizedBox(height: 16),
          _StrategyCard(
            title: 'Keto dieta',
            description: 'Vysoký obsah tuků, minimum sacharidů.',
            icon: Icons.ac_unit,
            isActive: profile?.selectedPlan == 'Keto',
            isNew: true,
            actionButton: ElevatedButton(
              onPressed: () {
                final current = ref.read(userProfileProvider);
                if (current != null) {
                  ref.read(userProfileProvider.notifier).updateProfile(
                        current.copyWith(selectedPlan: 'Keto'),
                      );
                }
                _showIngredientCheck(context, ref);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('VYBRAT KETO A UPRAVIT CHUTĚ'),
            ),
          ),
          const SizedBox(height: 16),
          _StrategyCard(
            title: 'Přerušovaný půst',
            description:
                'Časově omezené okno pro jídlo. Zlepšuje regeneraci.',
            icon: Icons.timer,
            isActive: isFastingSelected,
            actionButton: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _selectStartTime(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFastingSelected
                        ? Colors.green
                        : Colors.indigo[300],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    profile?.fastingStartTime != null
                        ? 'UPRAVIT ČAS (${profile!.fastingStartTime!.format(context)})'
                        : 'NASTAVIT ČASY JÍDLA',
                  ),
                ),
                if (isFastingSelected && profile?.fastingStartTime != null) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyMenuScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('VSTOUPIT DO JÍDELNÍČKU'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[900],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isActive;
  final bool isNew;
  final Widget? actionButton;

  const _StrategyCard({
    required this.title,
    required this.description,
    required this.icon,
    this.isActive = false,
    this.isNew = false,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isActive ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? Colors.orange : Colors.transparent,
          width: 2,
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
                  size: 40,
                  color: isActive ? Colors.orange : Colors.blueGrey,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isNew) ...[
                            const SizedBox(width: 8),
                            _newBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (actionButton != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: actionButton,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _newBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'NOVINKA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}