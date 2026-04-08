import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exercise_performance.dart';
import '../../providers/performance_provider.dart';
import '../../providers/coach/active_client_provider.dart';

class AddPerformanceScreen extends ConsumerStatefulWidget {
  const AddPerformanceScreen({super.key});

  @override
  ConsumerState<AddPerformanceScreen> createState() =>
      _AddPerformanceScreenState();
}

class _AddPerformanceScreenState extends ConsumerState<AddPerformanceScreen> {
  final _exerciseController = TextEditingController();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();

  DateTime selectedDate = DateTime.now();

  @override
  void dispose() {
    _exerciseController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _exerciseController.text.trim();
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);

    if (name.isEmpty || weight == null || reps == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vyplň všechna pole')),
      );
      return;
    }

    final clientId = ref.read(activeClientIdProvider).value;

    final performance = ExercisePerformance(
      exerciseName: name,
      date: selectedDate,
      weight: weight,
      reps: reps,
      clientId: clientId,
    );

    ref.read(performanceProvider.notifier).addPerformance(performance);
    Navigator.pop(context);
  }

  List<String> _exerciseSuggestions() {
    final all = ref.read(performanceProvider);

    // unikátní názvy, normalizace mezer
    final set = <String>{};
    for (final e in all) {
      final n = e.exerciseName.trim();
      if (n.isNotEmpty) set.add(n);
    }

    final list = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    // watch kvůli rebuildům při přidání výkonu (aby se návrhy aktualizovaly)
    ref.watch(performanceProvider);
    final suggestions = _exerciseSuggestions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nový výkon'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text('Datum'),
              subtitle: Text(
                '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
            ),
            const SizedBox(height: 12),

            // ✅ AUTOCOMPLETE CVIKŮ Z HISTORIE
            RawAutocomplete<String>(
              textEditingController: _exerciseController,
              focusNode: FocusNode(),
              optionsBuilder: (TextEditingValue value) {
                final q = value.text.trim().toLowerCase();
                if (q.isEmpty) return const Iterable<String>.empty();

                // začíná na q
                final starts = suggestions.where(
                  (s) => s.toLowerCase().startsWith(q),
                );

                // když nic nezačíná, tak fallback: obsahuje q
                if (starts.isNotEmpty) return starts.take(8);

                final contains = suggestions.where(
                  (s) => s.toLowerCase().contains(q),
                );

                return contains.take(8);
              },
              onSelected: (String selected) {
                _exerciseController.text = selected;
                _exerciseController.selection = TextSelection.fromPosition(
                  TextPosition(offset: selected.length),
                );
              },
              fieldViewBuilder: (
                context,
                controller,
                focusNode,
                onFieldSubmitted,
              ) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Cvik (např. Bench press)',
                    border: OutlineInputBorder(),
                    hintText: 'Začni psát… nabídnu existující cviky',
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => onFieldSubmitted(),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final opt = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            title: Text(opt),
                            onTap: () => onSelected(opt),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Váha (kg)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Opakování',
                border: OutlineInputBorder(),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Uložit výkon'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}