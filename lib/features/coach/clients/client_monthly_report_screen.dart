import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../models/coach/coach_client.dart';
import '../../../models/coach/coach_circumference_entry.dart';
import '../../../models/coach/coach_inbody_entry.dart';
import '../../../models/exercise_performance.dart';
import '../../../providers/coach/coach_circumference_controller.dart';
import '../../../providers/coach/coach_inbody_controller.dart';
import '../../../providers/performance_provider.dart';
import '../../../services/pdf/client_report_pdf_service.dart';

class ClientMonthlyReportScreen extends ConsumerStatefulWidget {
  final CoachClient client;

  const ClientMonthlyReportScreen({
    super.key,
    required this.client,
  });

  @override
  ConsumerState<ClientMonthlyReportScreen> createState() =>
      _ClientMonthlyReportScreenState();
}

class _ClientMonthlyReportScreenState
    extends ConsumerState<ClientMonthlyReportScreen> {
  late DateTime _dateFrom;
  late DateTime _dateTo;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _dateTo = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final linkedAt = widget.client.linkedAt;
    final suggestedFrom = DateTime(now.year, now.month - 1, now.day);

    _dateFrom = linkedAt.isAfter(suggestedFrom)
        ? DateTime(linkedAt.year, linkedAt.month, linkedAt.day)
        : suggestedFrom;
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFrom,
      firstDate: DateTime(2020),
      lastDate: _dateTo,
    );

    if (picked != null) {
      setState(() {
        _dateFrom = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTo,
      firstDate: _dateFrom,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dateTo = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  Future<void> _exportPdf({
    required List<CoachInbodyEntry> inbody,
    required List<CoachCircumferenceEntry> circs,
    required List<ExercisePerformance> performances,
  }) async {
    final pdf = await ClientReportPdfService.generate(
      client: widget.client,
      from: _dateFrom,
      to: _dateTo,
      inbody: inbody,
      circs: circs,
      performances: performances,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inbodyAsync =
        ref.watch(coachInbodyForClientProvider(widget.client.clientId));
    final circsAsync =
        ref.watch(coachCircumferencesForClientProvider(widget.client.clientId));
    final performances =
        ref.watch(performancesForClientProvider(widget.client.clientId));

    final inbodyItems = inbodyAsync.valueOrNull ?? const <CoachInbodyEntry>[];
    final circItems =
        circsAsync.valueOrNull ?? const <CoachCircumferenceEntry>[];

    final filteredInbody = _filterRange(inbodyItems, (e) => e.date);
    final filteredCircs = _filterRange(circItems, (e) => e.date);
    final filteredPerformances = _filterRange(performances, (e) => e.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analýza klienta'),
        actions: [
          IconButton(
            tooltip: 'Exportovat PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              await _exportPdf(
                inbody: filteredInbody,
                circs: filteredCircs,
                performances: filteredPerformances,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            'Klient a období',
            [
              _row('Jméno', _clientName(widget.client)),
              _row('Věk', '${widget.client.age} let'),
              _row('Výška', '${widget.client.heightCm} cm'),
              _row('Pohlaví', _genderLabel(widget.client.gender)),
              _row('Registrován', _fmtDate(widget.client.linkedAt)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFromDate,
                      icon: const Icon(Icons.date_range),
                      label: Text('Od: ${_fmtDate(_dateFrom)}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickToDate,
                      icon: const Icon(Icons.date_range),
                      label: Text('Do: ${_fmtDate(_dateTo)}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          inbodyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _errorCard('InBody / tělesná kompozice', e),
            data: (items) => _buildInbodySection(items),
          ),
          const SizedBox(height: 16),
          circsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _errorCard('Obvody těla', e),
            data: (items) => _buildCircumferenceSection(items),
          ),
          const SizedBox(height: 16),
          _buildPerformanceSection(performances),
          const SizedBox(height: 16),
          _section(
            'Shrnutí pro trenéra',
            [
              Text(
                _buildSummaryText(
                  inbodyItems,
                  circItems,
                  performances,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInbodySection(List<CoachInbodyEntry> items) {
    final filtered = _filterRange(items, (e) => e.date);

    if (filtered.isEmpty) {
      return _section(
        'InBody / tělesná kompozice',
        const [
          Text('V tomto období nejsou žádná InBody data.'),
        ],
      );
    }

    final start = filtered.first;
    final end = filtered.last;
    final hasProgress = filtered.length >= 2;

    return _section(
      'InBody / tělesná kompozice',
      [
        if (!hasProgress) ...[
          _row('Poslední váha', '${end.weightKg.toStringAsFixed(1)} kg'),
          _row(
            'Poslední svaly',
            '${end.skeletalMuscleMassKg.toStringAsFixed(1)} kg',
          ),
          _row(
            'Poslední tuk',
            '${end.percentBodyFat.toStringAsFixed(1)} %',
          ),
          _row('BMI', end.bmi.toStringAsFixed(1)),
          const SizedBox(height: 12),
          _smallInfo('V období je pouze 1 InBody měření.'),
        ] else ...[
          _comparisonRow('Váha', start.weightKg, end.weightKg, 'kg'),
          _comparisonRow(
            'Svaly',
            start.skeletalMuscleMassKg,
            end.skeletalMuscleMassKg,
            'kg',
          ),
          _comparisonRow(
            'Tuk',
            start.percentBodyFat,
            end.percentBodyFat,
            '%',
          ),
          _comparisonRow('BMI', start.bmi, end.bmi, ''),
          const SizedBox(height: 12),
          _smallInfo('Počet InBody měření v období: ${filtered.length}'),
          _smallInfo(
            'Sledované období měření: ${_fmtDate(start.date)} -> ${_fmtDate(end.date)}',
          ),
        ],
      ],
    );
  }

  Widget _buildCircumferenceSection(List<CoachCircumferenceEntry> items) {
    final filtered = _filterRange(items, (e) => e.date);

    if (filtered.isEmpty) {
      return _section(
        'Obvody těla',
        const [
          Text('V tomto období nejsou žádné obvody.'),
        ],
      );
    }

    final start = filtered.first;
    final end = filtered.last;
    final hasProgress = filtered.length >= 2;

    return _section(
      'Obvody těla',
      [
        if (!hasProgress) ...[
          _row('Paže', '${end.armCm.toStringAsFixed(1)} cm'),
          _row('Hrudník', '${end.chestCm.toStringAsFixed(1)} cm'),
          _row('Pas', '${end.waistCm.toStringAsFixed(1)} cm'),
          _row('Boky', '${end.hipsCm.toStringAsFixed(1)} cm'),
          _row('Stehno', '${end.thighCm.toStringAsFixed(1)} cm'),
          _row('Lýtko', '${end.calfCm.toStringAsFixed(1)} cm'),
          _row('Krk', '${end.neckCm.toStringAsFixed(1)} cm'),
          const SizedBox(height: 12),
          _smallInfo('V období je pouze 1 měření obvodů.'),
        ] else ...[
          _comparisonRow('Paže', start.armCm, end.armCm, 'cm'),
          _comparisonRow('Hrudník', start.chestCm, end.chestCm, 'cm'),
          _comparisonRow('Pas', start.waistCm, end.waistCm, 'cm'),
          _comparisonRow('Boky', start.hipsCm, end.hipsCm, 'cm'),
          _comparisonRow('Stehno', start.thighCm, end.thighCm, 'cm'),
          _comparisonRow('Lýtko', start.calfCm, end.calfCm, 'cm'),
          _comparisonRow('Krk', start.neckCm, end.neckCm, 'cm'),
          const SizedBox(height: 12),
          _smallInfo('Počet měření obvodů v období: ${filtered.length}'),
          _smallInfo(
            'Sledované období měření: ${_fmtDate(start.date)} -> ${_fmtDate(end.date)}',
          ),
        ],
      ],
    );
  }

  Widget _buildPerformanceSection(List<ExercisePerformance> performances) {
    final filtered = _filterRange(performances, (e) => e.date);

    final grouped = <String, List<ExercisePerformance>>{};
    for (final item in filtered) {
      final key = item.exerciseName.trim().isEmpty
          ? 'Bez názvu cviku'
          : item.exerciseName.trim();
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final exerciseNames = grouped.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return _section(
      'Výkon cviků',
      [
        if (filtered.isEmpty)
          const Text('V tomto období nejsou žádné výkony.')
        else ...[
          for (final name in exerciseNames)
            Builder(
              builder: (_) {
                final list = [...grouped[name]!]
                  ..sort((a, b) => a.date.compareTo(b.date));

                final first = list.first;
                final last = list.last;
                final best = [...list]
                  ..sort((a, b) => b.weight.compareTo(a.weight));

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _row(
                          'První výkon',
                          '${first.weight.toStringAsFixed(1)} kg × ${first.reps}',
                        ),
                        _row(
                          'Poslední výkon',
                          '${last.weight.toStringAsFixed(1)} kg × ${last.reps}',
                        ),
                        _row(
                          'Nejlepší váha',
                          '${best.first.weight.toStringAsFixed(1)} kg × ${best.first.reps}',
                        ),
                        _row(
                          'Změna váhy',
                          _formatDelta(last.weight - first.weight, 'kg'),
                        ),
                        _row('Počet záznamů', '${list.length}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          _smallInfo('Počet záznamů výkonu v období: ${filtered.length}'),
        ],
      ],
    );
  }

  List<T> _filterRange<T>(List<T> items, DateTime Function(T) getDate) {
    final filtered = items.where((e) {
      final d = getDate(e);
      return !d.isBefore(_dateFrom) && !d.isAfter(_dateTo);
    }).toList();

    filtered.sort((a, b) => getDate(a).compareTo(getDate(b)));
    return filtered;
  }

  String _buildSummaryText(
    List<CoachInbodyEntry> inbody,
    List<CoachCircumferenceEntry> circs,
    List<ExercisePerformance> performances,
  ) {
    final inbodyFiltered = _filterRange(inbody, (e) => e.date);
    final circFiltered = _filterRange(circs, (e) => e.date);
    final perfFiltered = _filterRange(performances, (e) => e.date);

    final lines = <String>[];

    if (inbodyFiltered.isNotEmpty) {
      final first = inbodyFiltered.first;
      final last = inbodyFiltered.last;

      if (inbodyFiltered.length == 1) {
        lines.add(
          'V období je 1 InBody měření: váha ${last.weightKg.toStringAsFixed(1)} kg, '
          'svaly ${last.skeletalMuscleMassKg.toStringAsFixed(1)} kg, '
          'tuk ${last.percentBodyFat.toStringAsFixed(1)} %.',
        );
      } else {
        lines.add(
          'Váha: ${first.weightKg.toStringAsFixed(1)} -> ${last.weightKg.toStringAsFixed(1)} kg '
          '(${_formatDelta(last.weightKg - first.weightKg, 'kg')}).',
        );
        lines.add(
          'Svaly: ${first.skeletalMuscleMassKg.toStringAsFixed(1)} -> ${last.skeletalMuscleMassKg.toStringAsFixed(1)} kg.',
        );
        lines.add(
          'Tuk: ${first.percentBodyFat.toStringAsFixed(1)} -> ${last.percentBodyFat.toStringAsFixed(1)} %.',
        );
      }
    }

    if (circFiltered.isNotEmpty) {
      final first = circFiltered.first;
      final last = circFiltered.last;

      if (circFiltered.length == 1) {
        lines.add(
          'K dispozici je 1 měření obvodů: pas ${last.waistCm.toStringAsFixed(0)} cm, '
          'paže ${last.armCm.toStringAsFixed(0)} cm, '
          'hrudník ${last.chestCm.toStringAsFixed(0)} cm.',
        );
      } else {
        lines.add(
          'Pas: ${first.waistCm.toStringAsFixed(0)} -> ${last.waistCm.toStringAsFixed(0)} cm.',
        );
        lines.add(
          'Paže: ${first.armCm.toStringAsFixed(0)} -> ${last.armCm.toStringAsFixed(0)} cm.',
        );
        lines.add(
          'Hrudník: ${first.chestCm.toStringAsFixed(0)} -> ${last.chestCm.toStringAsFixed(0)} cm.',
        );
      }
    }

    if (perfFiltered.isNotEmpty) {
      final grouped = <String, List<ExercisePerformance>>{};
      for (final item in perfFiltered) {
        final key = item.exerciseName.trim().isEmpty
            ? 'Bez názvu cviku'
            : item.exerciseName.trim();
        grouped.putIfAbsent(key, () => []).add(item);
      }

      final names = grouped.keys.take(3);
      for (final name in names) {
        final list = [...grouped[name]!]
          ..sort((a, b) => a.date.compareTo(b.date));
        final first = list.first;
        final last = list.last;

        if (list.length == 1) {
          lines.add(
            '$name: 1 záznam ${last.weight.toStringAsFixed(1)} kg × ${last.reps}.',
          );
        } else {
          lines.add(
            '$name: ${first.weight.toStringAsFixed(1)} -> ${last.weight.toStringAsFixed(1)} kg.',
          );
        }
      }
    }

    if (lines.isEmpty) {
      return 'Ve zvoleném období zatím nejsou data pro vytvoření shrnutí.';
    }

    return lines.join('\n');
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonRow(
    String label,
    double? first,
    double? last,
    String unit,
  ) {
    if (first == null || last == null) {
      return _row(label, '—');
    }

    final firstText = first.toStringAsFixed(1);
    final lastText = last.toStringAsFixed(1);
    final unitSuffix = unit.isEmpty ? '' : ' $unit';

    if ((first - last).abs() < 0.0001) {
      return _row(label, '$lastText$unitSuffix');
    }

    return _row(
      label,
      '$firstText$unitSuffix -> $lastText$unitSuffix (${_formatDelta(last - first, unit)})',
    );
  }

  Widget _smallInfo(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _errorCard(String title, Object error) {
    return _section(
      title,
      [
        Text('Chyba: $error'),
      ],
    );
  }

  String _formatDelta(double value, String unit) {
    final prefix = value >= 0 ? '+' : '';
    final unitSuffix = unit.isEmpty ? '' : ' $unit';
    return '$prefix${value.toStringAsFixed(1)}$unitSuffix';
  }

  String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${d.year}';
  }

  String _genderLabel(String g) {
    switch (g.toLowerCase()) {
      case 'male':
        return 'Muž';
      case 'female':
        return 'Žena';
      default:
        return 'Jiné';
    }
  }

  String _clientName(CoachClient client) {
    final full = '${client.firstName} ${client.lastName}'.trim();
    if (full.isNotEmpty) return full;
    return client.displayName.trim().isNotEmpty ? client.displayName : 'Klient';
  }
}