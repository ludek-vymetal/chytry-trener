import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/performance_provider.dart';
import 'add_performance_screen.dart';
import 'performance_detail_screen.dart'; // ✅ NOVÉ (místo rovnou grafu)

class PerformanceListScreen extends ConsumerWidget {
  const PerformanceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(performanceProvider);

    // unikátní názvy cviků
    final exercises = all
        .map((e) => e.exerciseName.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Výkonnost / PR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Přidat výkon',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddPerformanceScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: exercises.isEmpty
          ? const Center(
              child: Text(
                'Zatím nemáš záznamy výkonu.\n\nKlikni na + a přidej první cvik.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: exercises.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final name = exercises[i];

                // rychlá statistika: kolik záznamů
                final count =
                    all.where((e) => e.exerciseName.trim() == name).length;

                return Card(
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text('Záznamů: $count'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PerformanceDetailScreen(exerciseName: name),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddPerformanceScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
