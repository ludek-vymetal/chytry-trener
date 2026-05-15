import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/body_circumference.dart';
import '../../providers/user_profile_provider.dart';

class CircumferenceListScreen
    extends ConsumerWidget {
  const CircumferenceListScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final l10n =
        AppLocalizations.of(context)!;

    final profile =
        ref.watch(userProfileProvider);

    if (profile == null ||
        profile.circumferences.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.bodyCircumference,
          ),
        ),

        body: Center(
          child: Text(
            l10n.noMeasurementsYet,
          ),
        ),
      );
    }

    final List<BodyCircumference>
        historyList = [
      ...profile.circumferences,
    ]..sort(
            (a, b) =>
                b.date.compareTo(a.date),
          );

    final List<BodyCircumference>
        chartData = [
      ...profile.circumferences,
    ]..sort(
            (a, b) =>
                a.date.compareTo(b.date),
          );

    return DefaultTabController(
      length: 2,

      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.bodyCircumference,
          ),

          bottom: TabBar(
            tabs: [
              Tab(
                icon:
                    const Icon(Icons.history),
                text: l10n.history,
              ),

              Tab(
                icon: const Icon(
                  Icons.show_chart,
                ),
                text: l10n.waistChart,
              ),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            ListView.builder(
              padding:
                  const EdgeInsets.all(16),

              itemCount:
                  historyList.length,

              itemBuilder:
                  (context, index) {
                final current =
                    historyList[index];

                final previous =
                    index + 1 <
                            historyList.length
                        ? historyList[
                            index + 1]
                        : null;

                return _CircumferenceCard(
                  current: current,
                  previous: previous,
                );
              },
            ),

            _CircumferenceChartView(
              data: chartData,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircumferenceChartView
    extends StatelessWidget {
  final List<BodyCircumference> data;

  const _CircumferenceChartView({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context)!;

    return Padding(
      padding:
          const EdgeInsets.all(24),

      child: Column(
        children: [
          Text(
            l10n.waistTrend,

            style: const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 30),

          AspectRatio(
            aspectRatio: 1.5,

            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,

                  getDrawingHorizontalLine:
                      (value) => FlLine(
                    color: Colors.grey
                        .withValues(
                      alpha: 0.2,
                    ),

                    strokeWidth: 1,
                  ),
                ),

                titlesData: FlTitlesData(
                  rightTitles:
                      const AxisTitles(
                    sideTitles:
                        SideTitles(
                      showTitles: false,
                    ),
                  ),

                  topTitles:
                      const AxisTitles(
                    sideTitles:
                        SideTitles(
                      showTitles: false,
                    ),
                  ),

                  bottomTitles:
                      const AxisTitles(
                    sideTitles:
                        SideTitles(
                      showTitles: false,
                    ),
                  ),

                  leftTitles: AxisTitles(
                    sideTitles:
                        SideTitles(
                      showTitles: true,
                      reservedSize: 40,

                      getTitlesWidget:
                          (value, meta) =>
                              Text(
                        value
                            .toStringAsFixed(
                                0),

                        style:
                            const TextStyle(
                          fontSize: 10,
                          color:
                              Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),

                borderData: FlBorderData(
                  show: true,

                  border: Border.all(
                    color: Colors.grey
                        .withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),

                lineBarsData: [
                  LineChartBarData(
                    spots: data
                        .asMap()
                        .entries
                        .map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        e.value.waist,
                      );
                    }).toList(),

                    isCurved: true,

                    color:
                        Colors.deepOrange,

                    barWidth: 3,

                    isStrokeCapRound:
                        true,

                    dotData:
                        const FlDotData(
                      show: true,
                    ),

                    belowBarData:
                        BarAreaData(
                      show: true,

                      color: Colors
                          .deepOrange
                          .withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            l10n.waistChartDescription,

            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircumferenceCard
    extends StatelessWidget {
  final BodyCircumference current;

  final BodyCircumference? previous;

  const _CircumferenceCard({
    required this.current,
    this.previous,
  });

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context)!;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              _formatDate(current.date),

              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const Divider(),

            _row(
              l10n.waist,
              current.waist,
              previous?.waist,
            ),

            _row(
              l10n.chest,
              current.chest,
              previous?.chest,
            ),

            _row(
              l10n.biceps,
              current.biceps,
              previous?.biceps,
            ),

            _row(
              l10n.thigh,
              current.thigh,
              previous?.thigh,
            ),

            _row(
              l10n.neck,
              current.neck,
              previous?.neck,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    double value,
    double? prev,
  ) {
    final diff =
        prev == null
            ? null
            : (value - prev);

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

        children: [
          Text(label),

          Text(
            prev == null
                ? '${value.toStringAsFixed(1)} cm'
                : '${value.toStringAsFixed(1)} cm (${_formatDiff(diff!)})',

            style: TextStyle(
              fontWeight:
                  FontWeight.bold,

              color: diff == null
                  ? Colors.black
                  : diff > 0
                      ? Colors.red
                      : diff < 0
                          ? Colors.green
                          : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDiff(double diff) {
    if (diff > 0) {
      return '+${diff.toStringAsFixed(1)}';
    }

    if (diff < 0) {
      return diff.toStringAsFixed(1);
    }

    return '0.0';
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}