import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/daily_intake_provider.dart';
import '../food/food_entry_screen.dart';

class TodayFoodScreen extends ConsumerWidget {
  const TodayFoodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intake = ref.watch(dailyIntakeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dnešní jídlo'),
        actions: [
          IconButton(
            tooltip: 'Reset dne',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dailyIntakeProvider.notifier).resetDay(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FoodEntryScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryCard(
            calories: intake.calories,
            protein: intake.protein,
            carbs: intake.carbs,
            fat: intake.fat,
          ),
          const SizedBox(height: 16),
          const Text(
            'Jídla dnes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (intake.items.isEmpty)
            const _EmptyState()
          else
            ...List.generate(intake.items.length, (i) {
              final item = intake.items[i];

              return Dismissible(
                key: ValueKey('${item.createdAt.millisecondsSinceEpoch}-$i'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  ref.read(dailyIntakeProvider.notifier).removeFoodAt(i);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Smazáno: ${item.name}')),
                  );
                },
                child: Card(
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text('${item.grams} g • ${item.calories} kcal'),
                    trailing: Text(
                      'B ${item.protein} / S ${item.carbs} / T ${item.fat}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Součet dne',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Kalorie: $calories kcal'),
            Text('Bílkoviny: $protein g'),
            Text('Sacharidy: $carbs g'),
            Text('Tuky: $fat g'),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Text(
        'Zatím tu nic není.\nKlikni na + a přidej první jídlo.',
        textAlign: TextAlign.center,
      ),
    );
  }
}