import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_profile_provider.dart';

class MeasurementHistoryScreen extends ConsumerWidget {
  const MeasurementHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    if (profile == null || profile.measurements.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historie měření')),
        body: const Center(
          child: Text('Zatím nemáš žádná měření'),
        ),
      );
    }

    final measurements = profile.measurements;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historie měření'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: measurements.length,
        itemBuilder: (context, index) {
          final current = measurements[index];
          final previous = index > 0 ? measurements[index - 1] : null;

          double diff(double value, double? prev) => prev == null ? 0 : value - prev;

          final currentMuscle = current.muscleMass ?? 0.0;
          final previousMuscle = previous?.muscleMass;

          final currentFat = current.fatMass ?? 0.0;
          final previousFat = previous?.fatMass;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                '${current.date.day}.${current.date.month}.${current.date.year}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Váha: ${current.weight} kg'
                    '${previous != null ? ' (${_fmt(diff(current.weight, previous.weight))} kg)' : ''}',
                  ),
                  Text(
                    'Svaly: ${currentMuscle.toStringAsFixed(1)} kg'
                    '${previous != null ? ' (${_fmt(diff(currentMuscle, previousMuscle))} kg)' : ''}',
                  ),
                  Text(
                    'Tuk: ${currentFat.toStringAsFixed(1)} kg'
                    '${previous != null ? ' (${_fmt(diff(currentFat, previousFat))} kg)' : ''}',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _fmt(double v) {
    final sign = v > 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(1)}';
  }
}