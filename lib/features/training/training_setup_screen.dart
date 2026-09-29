import '../common/missing_goal_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/training/exercises/exercise_db.dart';
import '../../core/training/intake/training_intake.dart';
import '../../l10n/app_localizations.dart';
import '../../models/goal.dart';
import '../../providers/user_profile_provider.dart';

class TrainingSetupScreen extends ConsumerStatefulWidget {
  const TrainingSetupScreen({super.key});

  @override
  ConsumerState<TrainingSetupScreen> createState() =>
      _TrainingSetupScreenState();
}

class _TrainingSetupScreenState
    extends ConsumerState<TrainingSetupScreen> {
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
    final l10n = AppLocalizations.of(context)!;

    final profile = ref.watch(userProfileProvider);

    if (profile == null || profile.goal == null) {
      return MissingGoalScaffold(message: l10n.setupProfileAndGoalFirst);
    }

    final isStrengthCompetition =
        profile.goal!.type == GoalType.strength &&
        profile.goal!.reason == GoalReason.competition;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trainingSetupTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.trainingFrequencyQuestion,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<int>(
              initialValue: _frequency,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                helperText: l10n.trainingFrequencyHint,
              ),
              items: const [2, 3, 4, 5, 6]
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(
                        l10n.timesPerWeek(v),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() => _frequency = v ?? 3);
              },
            ),

            const SizedBox(height: 20),

            Text(
              l10n.equipmentQuestion,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('bodyweight', l10n.bodyweightEquipment),
                _chip('dumbbell', l10n.dumbbellEquipment),
                _chip('barbell', l10n.barbellEquipment),
                _chip('rack', l10n.rackEquipment),
                _chip('bench', l10n.benchEquipment),
                _chip('machine', l10n.machineEquipment),
                _chip('cardio', l10n.cardioEquipment),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              l10n.equipmentHint,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              l10n.experienceQuestion,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: _experience,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                helperText: l10n.experienceHint,
              ),
              items: [
                DropdownMenuItem(
                  value: 'beginner',
                  child: Text(l10n.beginner),
                ),
                DropdownMenuItem(
                  value: 'intermediate',
                  child: Text(l10n.intermediate),
                ),
                DropdownMenuItem(
                  value: 'advanced',
                  child: Text(l10n.advanced),
                ),
              ],
              onChanged: (v) {
                setState(() => _experience = v ?? 'beginner');
              },
            ),

            if (isStrengthCompetition) ...[
              const SizedBox(height: 24),

              Text(
                l10n.oneRepMaxTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              _numberField(
                _squatCtrl,
                l10n.squat1rm,
              ),

              const SizedBox(height: 10),

              _numberField(
                _benchCtrl,
                l10n.bench1rm,
              ),

              const SizedBox(height: 10),

              _numberField(
                _deadliftCtrl,
                l10n.deadlift1rm,
              ),

              const SizedBox(height: 6),

              Text(
                l10n.trainingMaxHint,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
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
                        SnackBar(
                          content: Text(
                            l10n.fillAllMaxes,
                          ),
                        ),
                      );
                      return;
                    }

                    maxes = {
                      ExerciseIds.squat:
                          _parseDouble(_squatCtrl.text)!,
                      ExerciseIds.bench:
                          _parseDouble(_benchCtrl.text)!,
                      ExerciseIds.deadlift:
                          _parseDouble(_deadliftCtrl.text)!,
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
                child: Text(
                  l10n.saveTrainingSetup,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(
    TextEditingController c,
    String label,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        helperText: l10n.numberInputHint,
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