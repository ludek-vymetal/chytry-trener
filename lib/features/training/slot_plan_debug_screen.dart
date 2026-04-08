import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_profile_provider.dart';
import '../../providers/slot_selection_provider.dart';
import '../../services/training_slot_plan_service.dart';
import '../../core/training/training_plan_models.dart';
import '../../core/training/slots/exercise_slot.dart';
import '../../core/training/exercises/exercise_db.dart';
import 'exercise_picker_screen.dart';

class SlotPlanDebugScreen extends ConsumerWidget {
  const SlotPlanDebugScreen({super.key});

  String _roleLabel(ExerciseRole role) {
    switch (role) {
      case ExerciseRole.mainSquat:
        return 'Hlavní dřepový cvik';
      case ExerciseRole.mainPress:
        return 'Hlavní tlakový cvik';
      case ExerciseRole.mainHinge:
        return 'Hlavní tahový cvik (hip hinge)';
      case ExerciseRole.chestPress:
        return 'Hrudník (tlaky)';
      case ExerciseRole.verticalPull:
        return 'Záda (vertikální tah)';
      case ExerciseRole.horizontalPull:
        return 'Záda (horizontální tah)';
      case ExerciseRole.quads:
        return 'Kvadricepsy';
      case ExerciseRole.hamstrings:
        return 'Zadní stehna (hamstringy)';
      case ExerciseRole.glutes:
        return 'Hýždě';
      case ExerciseRole.shoulders:
        return 'Ramena';
      case ExerciseRole.triceps:
        return 'Triceps';
      case ExerciseRole.biceps:
        return 'Biceps';
      case ExerciseRole.core:
        return 'Střed těla';
      case ExerciseRole.conditioning:
        return 'Kondice';
    }
  }

  String _patternLabel(String patternName) {
    switch (patternName) {
      case 'squat':
        return 'Dřepový pohyb';
      case 'hinge':
        return 'Tahový pohyb (hip hinge)';
      case 'press':
        return 'Tlakový pohyb';
      case 'pull':
        return 'Tah (vertikální)';
      case 'row':
        return 'Přítah (horizontální)';
      case 'core':
        return 'Střed těla';
      case 'locomotion':
        return 'Pohyb / kondice';
      default:
        return patternName;
    }
  }

  String _modalityLabel(String modalityName) {
    switch (modalityName) {
      case 'strength':
        return 'Síla';
      case 'hypertrophy':
        return 'Svaly / postava';
      case 'endurance':
        return 'Vytrvalost';
      case 'conditioning':
        return 'Kondice';
      default:
        return modalityName;
    }
  }

  String _slotKey(String dayLabel, int slotIndex) => '$dayLabel|$slotIndex';

  String? _exerciseNameById(String id) {
    try {
      return ExerciseDB.all.firstWhere((e) => e.id == id).name;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    if (profile == null || profile.goal == null) {
      return const Scaffold(
        body: Center(child: Text('Nejprve nastav profil a cíl.')),
      );
    }

    if (profile.trainingIntake == null) {
      return const Scaffold(
        body: Center(child: Text('Chybí nastavení tréninku (dotazník).')),
      );
    }

    final selectedMap = ref.watch(slotSelectionProvider);
    final equipment = profile.trainingIntake!.equipment;

    final List<SlotTrainingDayPlan> plan =
        TrainingSlotPlanService.buildWeeklySlotPlan(profile);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Výběr cviků (test)'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: plan.length,
        itemBuilder: (context, index) {
          final day = plan[index];

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.dayLabel} – ${day.focus}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...day.slots.asMap().entries.map((entry) {
                    final slotIndex = entry.key;
                    final s = entry.value;

                    final key = _slotKey(day.dayLabel, slotIndex);
                    final selectedExerciseId = selectedMap[key];
                    final selectedName = selectedExerciseId == null
                        ? null
                        : _exerciseNameById(selectedExerciseId);

                    final modalityText = s.modalities
                        .map((m) => _modalityLabel(m.name))
                        .join(', ');

                    return Card(
                      child: ListTile(
                        title: Text(_roleLabel(s.role)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Typ pohybu: ${_patternLabel(s.pattern.name)}'),
                            Text('Zaměření: $modalityText'),
                            const SizedBox(height: 6),
                            Text('Předpis: ${s.sets} × ${s.reps} | RIR ${s.rir}'),
                            const SizedBox(height: 6),
                            Text(
                              selectedName == null
                                  ? 'Vybraný cvik: (zatím nevybráno)'
                                  : 'Vybraný cvik: $selectedName',
                              style: TextStyle(
                                fontWeight: selectedName == null
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: () async {
                          final chosen = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExercisePickerScreen(
                                slot: s,
                                availableEquipment: equipment,
                                preselectedExerciseId: selectedExerciseId,
                              ),
                            ),
                          );

                          if (chosen != null) {
                            // chosen je Exercise (vracíme ho z pickeru)
                            ref
                                .read(slotSelectionProvider.notifier)
                                .setSelection(key, chosen.id);
                          }
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: 8),
                  Text(
                    'Testovací obrazovka: slot = role + typ pohybu + zaměření + série/opakování/RIR.\nKlikni na slot a vyber cvik.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
