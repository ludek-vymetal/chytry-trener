import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/training/exercises/exercise_db.dart';
import '../../core/training/intake/training_intake.dart';
import '../../models/goal.dart';
import '../../providers/user_profile_provider.dart';

class TrainingSetupScreen extends ConsumerStatefulWidget {
  const TrainingSetupScreen({super.key});

  @override
  ConsumerState<TrainingSetupScreen> createState() =>
      _TrainingSetupScreenState();
}

class _TrainingSetupScreenState extends ConsumerState<TrainingSetupScreen> {
  int _frequency = 3;

  final Set<String> _equipment = {'bodyweight'};
  String _experience = 'beginner';

  final _squatCtrl = TextEditingController();
  final _benchCtrl = TextEditingController();
  final _deadliftCtrl = TextEditingController();

  bool _isValidNumber(String s) {
    final v = double.tryParse(s.replaceAll(',', '.'));
    return v != null && v > 0;
  }

  double? _parseDouble(String s) {
    return double.tryParse(s.replaceAll(',', '.'));
  }

  @override
  void dispose() {
    _squatCtrl.dispose();
    _benchCtrl.dispose();
    _deadliftCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    if (profile == null || profile.goal == null) {
      return const Scaffold(
        body: Center(child: Text('Nejprve nastav profil a cíl.')),
      );
    }

    final isStrengthCompetition =
        profile.goal!.type == GoalType.strength &&
        profile.goal!.reason == GoalReason.competition;

    return Scaffold(
      appBar: AppBar(title: const Text('Nastavení tréninku')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kolikrát týdně chceš trénovat?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _frequency,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                helperText: 'Vyber reálné číslo podle času a regenerace.',
              ),
              items: const [2, 3, 4, 5, 6]
                  .map(
                    (v) =>
                        DropdownMenuItem(value: v, child: Text('$v× týdně')),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _frequency = v ?? 3),
            ),
            const SizedBox(height: 20),
            const Text(
              'Jaké máš vybavení?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('bodyweight', 'Váha těla'),
                _chip('dumbbell', 'Jednoručky'),
                _chip('barbell', 'Osa'),
                _chip('rack', 'Stojan'),
                _chip('bench', 'Lavice'),
                _chip('machine', 'Stroje'),
                _chip('cardio', 'Kardio'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tip: když něco nemáš, aplikace vybere vhodnější cviky.',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            const SizedBox(height: 20),
            const Text(
              'Jaká je tvoje zkušenost?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _experience,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                helperText: 'Pomůže to nastavit vhodnou náročnost.',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'beginner',
                  child: Text('Začátečník'),
                ),
                DropdownMenuItem(
                  value: 'intermediate',
                  child: Text('Pokročilý'),
                ),
                DropdownMenuItem(
                  value: 'advanced',
                  child: Text('Velmi pokročilý'),
                ),
              ],
              onChanged: (v) => setState(() => _experience = v ?? 'beginner'),
            ),
            if (isStrengthCompetition) ...[
              const SizedBox(height: 24),
              const Text(
                'Maximálky (1 opakování maximum) – pouze pro závody',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _numberField(_squatCtrl, 'Dřep 1RM (kg)'),
              const SizedBox(height: 10),
              _numberField(_benchCtrl, 'Bench press 1RM (kg)'),
              const SizedBox(height: 10),
              _numberField(_deadliftCtrl, 'Mrtvý tah 1RM (kg)'),
              const SizedBox(height: 6),
              Text(
                'Poznámka: váhy v plánu se počítají z „tréninkového maxima“ (90 % z 1RM).',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Map<String, double> maxes = {};

                  if (isStrengthCompetition) {
                    if (!_isValidNumber(_squatCtrl.text) ||
                        !_isValidNumber(_benchCtrl.text) ||
                        !_isValidNumber(_deadliftCtrl.text)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vyplň prosím všechny maximálky (kladné číslo).',
                          ),
                        ),
                      );
                      return;
                    }

                    maxes = {
                      ExerciseIds.squat: _parseDouble(_squatCtrl.text)!,
                      ExerciseIds.bench: _parseDouble(_benchCtrl.text)!,
                      ExerciseIds.deadlift: _parseDouble(_deadliftCtrl.text)!,
                    };
                  }

                  final intake = TrainingIntake(
                    frequencyPerWeek: _frequency,
                    equipment: _equipment,
                    experienceLevel: _experience,
                    oneRMs: maxes,
                    trainingMaxPercent: 0.90,
                  );

                  ref
                      .read(userProfileProvider.notifier)
                      .setTrainingIntake(intake);
                  Navigator.pop(context);
                },
                child: const Text('Uložit nastavení'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        helperText: 'Můžeš psát i s čárkou (např. 120,5).',
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _chip(String key, String label) {
    final selected = _equipment.contains(key);

    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (v) {
        setState(() {
          if (v) {
            _equipment.add(key);
          } else {
            _equipment.remove(key);
            if (_equipment.isEmpty) {
              _equipment.add('bodyweight');
            }
          }
        });
      },
    );
  }
}