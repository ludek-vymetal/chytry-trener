import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_profile_provider.dart';
import '../../services/macro_service.dart';
import '../../services/metabolism_service.dart';

class MacrosScreen extends ConsumerWidget {
  const MacrosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    if (profile == null || profile.goal == null) {
      return const Scaffold(
        body: Center(child: Text('Profil nebo cíl nenalezen')),
      );
    }

    final tdee = MetabolismService.calculateTDEE(
      profile,
      ActivityLevel.moderate,
    );

    final target = MacroService.calculate(profile, tdee);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Denní makra'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${target.strategyLabel} • ${target.phaseLabel} • ${target.planModeLabel}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      target.rationale,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Týdnů do cíle: ${target.weeksToTarget}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _macroCard('Kalorie', target.targetCalories.toDouble(), 'kcal'),
            _macroCard('Bílkoviny', target.protein.toDouble(), 'g'),
            _macroCard('Sacharidy', target.carbs.toDouble(), 'g'),
            _macroCard('Tuky', target.fat.toDouble(), 'g'),
            const SizedBox(height: 16),
            Text(
              'TDEE: ${tdee.toStringAsFixed(0)} kcal / den',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pozn.: TDEE je výdej. Cílové kalorie a makra se řídí cílem + fází + datem.',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroCard(String title, double value, String unit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              '${value.toStringAsFixed(0)} $unit',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}