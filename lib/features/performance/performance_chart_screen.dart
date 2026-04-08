import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/performance_provider.dart';

class PerformanceChartScreen extends ConsumerWidget {
  final String exerciseName;

  const PerformanceChartScreen({
    super.key,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref
        .read(performanceProvider.notifier)
        .byExercise(exerciseName);

    if (data.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(exerciseName)),
        body: const Center(
          child: Text('Žádná data pro zobrazení grafu'),
        ),
      );
    }

    final spots = <FlSpot>[];

    for (var i = 0; i < data.length; i++) {
      spots.add(
        FlSpot(
          i.toDouble(),
          data[i].weight,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$exerciseName – vývoj'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: true),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.length) {
                      return const SizedBox();
                    }
                    final d = data[index].date;
                    return Text(
                      '${d.day}.${d.month}',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 3,
                dotData: FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
