import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/performance_provider.dart';
import 'add_performance_screen.dart';
import 'performance_detail_screen.dart';

class PerformanceListScreen extends ConsumerWidget {
  const PerformanceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final all = ref.watch(performanceProvider);

    final exercises = all
        .map((e) => e.exerciseName.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList()
      ..sort(
        (a, b) =>
            a.toLowerCase().compareTo(
                  b.toLowerCase(),
                ),
      );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.performancePr),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addPerformance,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AddPerformanceScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: exercises.isEmpty
          ? Center(
              child: Text(
                l10n.noPerformanceRecords,
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: exercises.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final name = exercises[i];

                final count = all
                    .where(
                      (e) =>
                          e.exerciseName.trim() ==
                          name,
                    )
                    .length;

                return Card(
                  child: ListTile(
                    title: Text(name),

                    subtitle: Text(
                      '${l10n.records}: $count',
                    ),

                    trailing: const Icon(
                      Icons.chevron_right,
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PerformanceDetailScreen(
                            exerciseName: name,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AddPerformanceScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}