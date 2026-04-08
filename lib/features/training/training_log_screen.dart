import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/training/actual_set.dart';
import '../../core/training/sessions/training_session.dart';
import '../../core/training/training_plan_models.dart';
import '../../core/training/training_set.dart';
import '../../services/training_log_service.dart';

class TrainingLogScreen extends ConsumerStatefulWidget {
  final TrainingSession todaySession;
  final PlannedExercise exercise;

  const TrainingLogScreen({
    super.key,
    required this.todaySession,
    required this.exercise,
  });

  @override
  ConsumerState<TrainingLogScreen> createState() => _TrainingLogScreenState();
}

class _TrainingLogScreenState extends ConsumerState<TrainingLogScreen> {
  late final String exerciseKey;
  late final List<PlannedSet> planned;
  late List<_Row> rows;

  @override
  void initState() {
    super.initState();
    exerciseKey = widget.exercise.exerciseId ?? widget.exercise.name;

    planned = _resolvePlannedSets(widget.exercise);

    rows = planned.map((p) {
      return _Row(
        weightCtrl: TextEditingController(
          text: p.weightKg?.toStringAsFixed(1) ?? '',
        ),
        repsCtrl: TextEditingController(
          text: p.reps > 0 ? p.reps.toString() : '',
        ),
      );
    }).toList();

    if (rows.isEmpty) {
      rows = [
        _Row(
          weightCtrl: TextEditingController(),
          repsCtrl: TextEditingController(),
        ),
      ];
    }
  }

  @override
  void dispose() {
    for (final r in rows) {
      r.weightCtrl.dispose();
      r.repsCtrl.dispose();
    }
    super.dispose();
  }

  List<PlannedSet> _resolvePlannedSets(PlannedExercise ex) {
    if (ex.plannedSets != null && ex.plannedSets!.isNotEmpty) {
      return ex.plannedSets!;
    }

    final setsCount = _firstInt(ex.sets) ?? 0;
    final reps = _firstInt(ex.reps) ?? 0;

    return List.generate(setsCount, (_) {
      return PlannedSet(
        weightKg: ex.weightKg,
        reps: reps,
        note: ex.note,
      );
    });
  }

  int? _firstInt(String s) {
    final m = RegExp(r'\d+').firstMatch(s);
    if (m == null) {
      return null;
    }
    return int.tryParse(m.group(0)!);
  }

  void _addSet() {
    setState(() {
      rows.add(
        _Row(
          weightCtrl: TextEditingController(),
          repsCtrl: TextEditingController(),
        ),
      );
    });
  }

  void _removeSet(int i) {
    setState(() {
      rows[i].weightCtrl.dispose();
      rows[i].repsCtrl.dispose();
      rows.removeAt(i);
    });
  }

  void _save() {
    final actualSets = <ActualSet>[];

    for (final r in rows) {
      final w = double.tryParse(r.weightCtrl.text.trim().replaceAll(',', '.'));
      final repsParsed = int.tryParse(r.repsCtrl.text.trim());

      if (repsParsed == null || repsParsed <= 0) {
        continue;
      }

      actualSets.add(
        ActualSet(
          weightKg: w,
          reps: repsParsed,
        ),
      );
    }

    if (actualSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zadej alespoň opakování pro minimálně 1 sérii.'),
        ),
      );
      return;
    }

    final decision = TrainingLogService.saveExerciseLog(
      ref: ref,
      todayBaseSession: widget.todaySession,
      exerciseKey: exerciseKey,
      plannedSets: planned,
      actualSets: actualSets,
    );

    Navigator.of(context).pop(decision ?? true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log: ${widget.exercise.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (planned.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Plán',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              for (final p in planned)
                Text(
                  '${p.weightKg?.toStringAsFixed(1) ?? '-'} kg × ${p.reps > 0 ? p.reps : '-'} ${p.note != null ? "(${p.note})" : ""}',
                ),
              const SizedBox(height: 16),
            ],
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Skutečnost',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: rows[i].weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'kg'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: rows[i].repsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'opakování',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: rows.length > 1 ? () => _removeSet(i) : null,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  );
                },
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _addSet,
                  icon: const Icon(Icons.add),
                  label: const Text('Přidat sérii'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Uložit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row {
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;

  _Row({
    required this.weightCtrl,
    required this.repsCtrl,
  });
}