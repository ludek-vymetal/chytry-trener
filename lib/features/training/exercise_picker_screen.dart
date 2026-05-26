import 'package:flutter/material.dart';

import '../../core/training/exercises/exercise.dart';
import '../../core/training/exercises/exercise_db.dart';
import '../../core/training/slots/exercise_slot.dart';
import '../../core/training/slots/exercise_slot_selector.dart';
import '../../l10n/app_localizations.dart';

class ExercisePickerScreen extends StatefulWidget {
  final ExerciseSlot slot;
  final Set<String> availableEquipment;
  final String? preselectedExerciseId;

  const ExercisePickerScreen({
    super.key,
    required this.slot,
    required this.availableEquipment,
    this.preselectedExerciseId,
  });

  @override
  State<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState
    extends State<ExercisePickerScreen> {
  String _query = '';
  bool _showAllExercises = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final recommended =
        ExerciseSlotSelector.getOptionsForSlot(
      widget.slot,
      availableEquipment:
          widget.availableEquipment,
    );

    final source = _showAllExercises
        ? ExerciseDB.all.where((e) {
            final hasEquipment = e.equipment.any(
              (eq) => widget.availableEquipment
                  .contains(eq),
            );

            return hasEquipment;
          }).toList()
        : recommended;

    final filtered = source.where((e) {
      if (_query.trim().isEmpty) {
        return true;
      }

      final q = _query.trim().toLowerCase();

      return e.name
              .toLowerCase()
              .contains(q) ||
          (e.czName
                  ?.toLowerCase()
                  .contains(q) ??
              false) ||
          e.displayName
              .toLowerCase()
              .contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.selectExercise,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              8,
            ),
            child: TextField(
              decoration: InputDecoration(
                labelText:
                    l10n.searchExercise,
                border:
                    const OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() => _query = v);
              },
            ),
          ),

          SwitchListTile(
            value: _showAllExercises,
            title: Text(
              l10n.showAllExercises,
            ),
            subtitle: Text(
              l10n.showAllExercisesDescription,
            ),
            onChanged: (v) {
              setState(
                () => _showAllExercises = v,
              );
            },
          ),

          if (!_showAllExercises &&
              recommended.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Text(
                l10n.noRecommendedExerciseFound,
              ),
            ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _showAllExercises
                          ? l10n
                              .noExerciseFoundBySearch
                          : l10n
                              .noExerciseFoundForSlot,
                    ),
                  )
                : ListView.builder(
                    itemCount:
                        filtered.length,
                    itemBuilder:
                        (context, index) {
                      final ex =
                          filtered[index];

                      final selected =
                          ex.id ==
                              widget
                                  .preselectedExerciseId;

                      return Card(
                        child: ListTile(
                          title: Text(
                            ex.displayName,
                          ),
                          subtitle: Text(
                            '${l10n.englishLabel}: ${ex.name}\n'
                            '${l10n.equipmentLabel}: ${ex.equipment.join(', ')}',
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons
                                      .check_circle,
                                )
                              : null,
                          onTap: () {
                            Navigator.pop<
                                Exercise>(
                              context,
                              ex,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}