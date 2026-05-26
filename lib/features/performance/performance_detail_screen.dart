import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/performance_provider.dart';
import 'performance_chart_screen.dart';

class PerformanceDetailScreen extends ConsumerWidget {
  final String exerciseName;

  const PerformanceDetailScreen({
    super.key,
    required this.exerciseName,
  });

  String _dateLabel(DateTime d) => '${d.day}.${d.month}.${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final notifier = ref.read(performanceProvider.notifier);
    final data = notifier.byExercise(exerciseName);

    if (data.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(exerciseName)),
        body: Center(
          child: Text(
            l10n.noPerformanceRecordsForExercise,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(exerciseName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Card(
                child: ListView.separated(
                  itemCount: data.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = data[i];

                    return ListTile(
                      title: Text(
                        '${p.weight} kg × ${p.reps}',
                      ),
                      subtitle: Text(
                        _dateLabel(p.date),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.show_chart),
                label: Text(
                  l10n.showChart,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PerformanceChartScreen(
                        exerciseName: exerciseName,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}