import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/measurement.dart';
import '../../providers/user_profile_provider.dart';

class AddMeasurementScreen extends ConsumerStatefulWidget {
  const AddMeasurementScreen({super.key});

  @override
  ConsumerState<AddMeasurementScreen> createState() =>
      _AddMeasurementScreenState();
}

class _AddMeasurementScreenState
    extends ConsumerState<AddMeasurementScreen> {
  DateTime selectedDate = DateTime.now();

  final _weightController = TextEditingController();
  final _muscleController = TextEditingController();
  final _fatController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _muscleController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _save() {
    final weight = double.tryParse(_weightController.text);
    final muscle = double.tryParse(_muscleController.text);
    final fat = double.tryParse(_fatController.text);

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zadej platnou váhu')),
      );
      return;
    }

    final measurement = Measurement(
      date: selectedDate, // 🔥 POVINNÉ PRO POROVNÁNÍ
      weight: weight,
      muscleMass: muscle,
      fatMass: fat,
    );

    ref.read(userProfileProvider.notifier).addMeasurement(measurement);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nové měření'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 📅 DATUM – ZÁKLAD VŠECH POROVNÁNÍ
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

            const SizedBox(height: 16),

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
              controller: _muscleController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Svalová hmota (kg) – volitelné',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _fatController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tuková hmota (kg) – volitelné',
                border: OutlineInputBorder(),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Uložit měření'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
