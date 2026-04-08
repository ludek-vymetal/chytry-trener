import 'package:flutter/material.dart';

import '../../core/training/exercises/exercise.dart';
import '../../core/training/exercises/exercise_db.dart';
import '../../core/training/slots/exercise_slot.dart';
import '../../core/training/slots/exercise_slot_selector.dart';

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
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  String _query = '';
  bool _showAllExercises = false;

  @override
  Widget build(BuildContext context) {
    final recommended = ExerciseSlotSelector.getOptionsForSlot(
      widget.slot,
      availableEquipment: widget.availableEquipment,
    );

    final source = _showAllExercises
        ? ExerciseDB.all.where((e) {
            final hasEquipment =
                e.equipment.any((eq) => widget.availableEquipment.contains(eq));
            return hasEquipment;
          }).toList()
        : recommended;

    final filtered = source.where((e) {
      if (_query.trim().isEmpty) return true;

      final q = _query.trim().toLowerCase();
      return e.name.toLowerCase().contains(q) ||
          (e.czName?.toLowerCase().contains(q) ?? false) ||
          e.displayName.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vyber cvik'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Hledat cvik',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SwitchListTile(
            value: _showAllExercises,
            title: const Text('Zobrazit všechny cviky'),
            subtitle: const Text(
              'Když je vypnuto, zobrazí se jen doporučené cviky pro tento slot.',
            ),
            onChanged: (v) => setState(() => _showAllExercises = v),
          ),
          if (!_showAllExercises && recommended.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'Pro tento slot nebyl nalezen vhodný cvik podle tvého vybavení a filtrů. '
                'Zapni „Zobrazit všechny cviky“ nebo uprav vybavení v nastavení tréninku.',
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _showAllExercises
                          ? 'Nenalezen žádný cvik podle hledání.'
                          : 'Nenalezen žádný vhodný cvik pro tento slot.',
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final ex = filtered[index];
                      final selected = ex.id == widget.preselectedExerciseId;

                      return Card(
                        child: ListTile(
                          title: Text(ex.displayName),
                          subtitle: Text(
                            'Anglicky: ${ex.name}\nVybavení: ${ex.equipment.join(', ')}',
                          ),
                          trailing:
                              selected ? const Icon(Icons.check_circle) : null,
                          onTap: () {
                            Navigator.pop<Exercise>(context, ex);
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