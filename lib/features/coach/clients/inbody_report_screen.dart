import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/body/inbody_analysis.dart';
import '../../../models/coach/coach_client.dart';
import '../../../models/coach/coach_inbody_entry.dart';
import '../../../providers/coach/coach_inbody_controller.dart';
import '../../../providers/subscription/subscription_provider.dart';
import '../../paywall/paywall_screen.dart';

/// Barva a ikona podle hodnocení – sdílené i pro kartu v detailu klienta.
({Color color, IconData icon}) inbodyStatusStyle(
  BuildContext context,
  InbodyStatus status,
) {
  final cs = Theme.of(context).colorScheme;
  final dark = Theme.of(context).brightness == Brightness.dark;
  switch (status) {
    case InbodyStatus.good:
      return (
        color: dark ? const Color(0xFF7BD88F) : const Color(0xFF1E7D34),
        icon: Icons.check_circle,
      );
    case InbodyStatus.ok:
      return (color: cs.primary, icon: Icons.radio_button_checked);
    case InbodyStatus.warn:
      return (
        color: dark ? const Color(0xFFFFC266) : const Color(0xFFB35C00),
        icon: Icons.error_outline,
      );
    case InbodyStatus.bad:
      return (color: cs.error, icon: Icons.warning_amber_rounded);
    case InbodyStatus.info:
      return (color: cs.onSurfaceVariant, icon: Icons.info_outline);
  }
}

/// Podrobný odborný rozbor měření InBody.
class InbodyReportScreen extends ConsumerStatefulWidget {
  final CoachClient client;

  const InbodyReportScreen({super.key, required this.client});

  @override
  ConsumerState<InbodyReportScreen> createState() => _InbodyReportScreenState();
}

class _InbodyReportScreenState extends ConsumerState<InbodyReportScreen> {
  /// Index vybraného měření (0 = nejnovější).
  int _index = 0;

  static String _date(DateTime d) =>
      '${d.day}. ${d.month}. ${d.year}';

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(accessProvider).inbodyDetail) {
      return const LockedFeatureScreen(
        title: 'Podrobný rozbor InBody',
        description: 'Odborný rozbor složení těla, symetrie, zdravotních '
            'rizik, cílové váhy a akční plán jsou v plné verzi.',
      );
    }
    final async = ref.watch(coachInbodyForClientProvider(widget.client.clientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Rozbor InBody')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Zatím žádné měření.'));
          }
          final i = _index.clamp(0, items.length - 1);
          final latest = items[i];
          final previous = i + 1 < items.length ? items[i + 1] : null;
          final report = InbodyAnalysis.analyze(
            latest: latest,
            previous: previous,
            gender: widget.client.gender,
            age: widget.client.age,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (items.length > 1) _datePicker(items, i),
              _header(context, latest, report),
              const SizedBox(height: 12),
              for (final s in report.sections) ...[
                _sectionCard(context, s),
                const SizedBox(height: 12),
              ],
              if (report.targets.isNotEmpty) ...[
                _targetsCard(context, report),
                const SizedBox(height: 12),
              ],
              _recommendationsCard(context, report),
              const SizedBox(height: 12),
              for (final n in report.measurementNotes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    n,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _datePicker(List<CoachInbodyEntry> items, int selected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, idx) => ChoiceChip(
            label: Text(_date(items[idx].date)),
            selected: idx == selected,
            onSelected: (_) => setState(() => _index = idx),
          ),
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    CoachInbodyEntry e,
    InbodyReport report,
  ) {
    final cs = Theme.of(context).colorScheme;

    Widget stat(String label, String value) => Expanded(
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer),
              ),
            ],
          ),
        );

    return Card(
      elevation: 0,
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.client.displayName} · ${_date(e.date)}',
              style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: 4),
            Text(
              report.bodyType,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                stat('váha', '${e.weightKg.toStringAsFixed(1)} kg'),
                stat('tuk', '${e.bodyFatPercent.toStringAsFixed(1)} %'),
                stat('svaly', '${e.smmKg.toStringAsFixed(1)} kg'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.summary,
              style: TextStyle(color: cs.onPrimaryContainer, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, InbodySection s) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final f in s.findings) _findingTile(context, f),
          ],
        ),
      ),
    );
  }

  Widget _findingTile(BuildContext context, InbodyFinding f) {
    final cs = Theme.of(context).colorScheme;
    final style = inbodyStatusStyle(context, f.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(style.icon, color: style.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        f.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        f.value,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: style.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  f.reference,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(f.explanation, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _targetsCard(BuildContext context, InbodyReport report) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cílová váha',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Při zachování současné svalové hmoty.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            for (final t in report.targets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${t.label} (${t.bodyFatPercent.toStringAsFixed(0)} % tuku)',
                      ),
                    ),
                    Text(
                      '${t.weightKg.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      width: 84,
                      child: Text(
                        '−${t.fatToLoseKg.toStringAsFixed(1)} kg tuku',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _recommendationsCard(BuildContext context, InbodyReport report) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doporučení',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            for (var n = 0; n < report.recommendations.length; n++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${n + 1}.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        report.recommendations[n],
                        style: TextStyle(color: cs.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
