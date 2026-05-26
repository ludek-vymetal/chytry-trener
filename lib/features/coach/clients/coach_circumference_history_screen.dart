import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_application_1/l10n/app_localizations.dart';

import '../../../models/coach/coach_client.dart';
import '../../../models/coach/coach_circumference_entry.dart';
import '../../../providers/coach/coach_circumference_controller.dart';

class CoachCircumferenceHistoryScreen extends ConsumerWidget {
  final CoachClient client;

  const CoachCircumferenceHistoryScreen({
    super.key,
    required this.client,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final asyncItems = ref.watch(
      coachCircumferencesForClientProvider(client.clientId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.bodyCircumference} – ${client.displayName}',
        ),
      ),
      body: asyncItems.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Text('${l10n.error}: $e'),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                l10n.noCircumferenceMeasurementsYet,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final current = items[index];

              final previous = index + 1 < items.length
                  ? items[index + 1]
                  : null;

              return _CoachCircumferenceCard(
                current: current,
                previous: previous,
              );
            },
          );
        },
      ),
    );
  }
}

class _CoachCircumferenceCard extends StatelessWidget {
  final CoachCircumferenceEntry current;
  final CoachCircumferenceEntry? previous;

  const _CoachCircumferenceCard({
    required this.current,
    this.previous,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(current.date),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Divider(),

            _row(
              l10n.waist,
              current.waistCm,
              previous?.waistCm,
            ),

            _row(
              l10n.hips,
              current.hipsCm,
              previous?.hipsCm,
            ),

            _row(
              l10n.chest,
              current.chestCm,
              previous?.chestCm,
            ),

            _row(
              l10n.arm,
              current.armCm,
              previous?.armCm,
            ),

            _row(
              l10n.thigh,
              current.thighCm,
              previous?.thighCm,
            ),

            _row(
              l10n.calf,
              current.calfCm,
              previous?.calfCm,
            ),

            _row(
              l10n.neck,
              current.neckCm,
              previous?.neckCm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    double value,
    double? previousValue,
  ) {
    final diff =
        previousValue == null ? null : value - previousValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          Text(
            previousValue == null
                ? '${value.toStringAsFixed(1)} cm'
                : '${value.toStringAsFixed(1)} cm (${_formatDiff(diff!)})',
            style: TextStyle(
              fontWeight: FontWeight.bold,
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
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}