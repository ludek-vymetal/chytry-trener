import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:dart_application_1/l10n/app_localizations.dart';

import '../../../models/coach/coach_client.dart';
import '../../../models/coach/coach_circumference_entry.dart';
import '../../../models/coach/coach_inbody_entry.dart';
import '../../../models/exercise_performance.dart';
import '../../../providers/coach/coach_circumference_controller.dart';
import '../../../providers/coach/coach_inbody_controller.dart';
import '../../../providers/performance_provider.dart';
import '../../../services/pdf/client_report_pdf_service.dart';
import '../../../providers/subscription/subscription_provider.dart';

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

    _dateTo = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    );

    // Výchozí je celé období spolupráce – při měření jednou měsíčně
    // by kratší období obsahovalo jen jedno měření a nebylo by s čím
    // porovnávat. Minulý měsíc zvlášť ukazuje sloupec „Od minula“.
    _applyPreset(0);
  }

  /// Rychlá volba období: 0 = od začátku, jinak počet měsíců zpět.
  int _preset = 0;

  /// Černobílý tisk (pro černobílé tiskárny, šetří toner).
  bool _blackAndWhite = false;

  void _applyPreset(int months) {
    final now = DateTime.now();
    final linked = widget.client.linkedAt;
    final start = DateTime(linked.year, linked.month, linked.day);
    var from = months == 0
        ? start
        : DateTime(now.year, now.month - months, now.day);
    if (from.isBefore(start)) from = start;
    _preset = months;
    _dateFrom = from;
    _dateTo = DateTime(now.year, now.month, now.day, 23, 59, 59);
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
        _preset = -1;
        _dateFrom = DateTime(
          picked.year,
          picked.month,
          picked.day,
        );
      });
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTo,
      firstDate: _dateFrom,
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (picked != null) {
      setState(() {
        _preset = -1;
        _dateTo = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        );
      });
    }
  }

  Future<void> _exportPdf({
    required List<CoachInbodyEntry> inbody,
    required List<CoachCircumferenceEntry> circs,
    required List<ExercisePerformance> performances,
    bool share = false,
  }) async {
    final pdf = await ClientReportPdfService.generate(
      client: widget.client,
      from: _dateFrom,
      to: _dateTo,
      inbody: inbody,
      circs: circs,
      performances: performances,
      blackAndWhite: _blackAndWhite,
      trialWatermark: !ref.read(accessProvider).cleanPdf,
    );

    final name = '${widget.client.displayName.trim().replaceAll(' ', '_')}'
        '_souhrn_${_dateTo.year}-${_dateTo.month.toString().padLeft(2, '0')}'
        '-${_dateTo.day.toString().padLeft(2, '0')}.pdf';

    if (share) {
      await Printing.sharePdf(bytes: await pdf.save(), filename: name);
      return;
    }

    // Systémový dialog tisku – nabízí i „Uložit jako PDF“.
    await Printing.layoutPdf(
      name: name,
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final inbodyAsync =
        ref.watch(
      coachInbodyForClientProvider(
        widget.client.clientId,
      ),
    );

    final circsAsync =
        ref.watch(
      coachCircumferencesForClientProvider(
        widget.client.clientId,
      ),
    );

    final performances =
        ref.watch(
      performancesForClientProvider(
        widget.client.clientId,
      ),
    );

    final inbodyItems =
        inbodyAsync.valueOrNull ??
            const <CoachInbodyEntry>[];

    final circItems =
        circsAsync.valueOrNull ??
            const <CoachCircumferenceEntry>[];

    final filteredInbody =
        _filterRange(inbodyItems, (e) => e.date);

    final filteredCircs =
        _filterRange(circItems, (e) => e.date);

    final filteredPerformances =
        _filterRange(performances, (e) => e.date);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clientAnalysis),
        actions: [
          IconButton(
            tooltip: 'Sdílet PDF',
            icon: const Icon(Icons.share),
            onPressed: () async {
              await _exportPdf(
                inbody: filteredInbody,
                circs: filteredCircs,
                performances: filteredPerformances,
                share: true,
              );
            },
          ),
          IconButton(
            tooltip: l10n.exportPdf,
            icon: const Icon(Icons.print),
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
            context,
            l10n.clientAndPeriod,
            [
              _row(
                context,
                l10n.name,
                _clientName(widget.client),
              ),

              _row(
                context,
                l10n.age,
                '${widget.client.age}',
              ),

              _row(
                context,
                l10n.height,
                '${widget.client.heightCm} cm',
              ),

              _row(
                context,
                l10n.gender,
                _genderLabel(
                  context,
                  widget.client.gender,
                ),
              ),

              _row(
                context,
                l10n.registered,
                _fmtDate(widget.client.linkedAt),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in const [
                    (0, 'Od začátku'),
                    (6, 'Půl roku'),
                    (3, '3 měsíce'),
                    (1, 'Poslední měsíc'),
                  ])
                    ChoiceChip(
                      label: Text(o.$2),
                      selected: _preset == o.$1,
                      onSelected: (_) => setState(() => _applyPreset(o.$1)),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFromDate,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        '${l10n.from}: ${_fmtDate(_dateFrom)}',
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickToDate,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        '${l10n.to}: ${_fmtDate(_dateTo)}',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.print_outlined),
                title: const Text('Černobílý tisk'),
                subtitle: const Text(
                  'Pro černobílou tiskárnu – bez barevných ploch, šetří toner.',
                ),
                value: _blackAndWhite,
                onChanged: (v) => setState(() => _blackAndWhite = v),
              ),
            ],
          ),

          const SizedBox(height: 16),

          inbodyAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => _errorCard(
              context,
              l10n.inbodyBodyComposition,
              e,
            ),
            data: (items) =>
                _buildInbodySection(
              context,
              items,
            ),
          ),

          const SizedBox(height: 16),

          circsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => _errorCard(
              context,
              l10n.bodyCircumferences,
              e,
            ),
            data: (items) =>
                _buildCircumferenceSection(
              context,
              items,
            ),
          ),

          const SizedBox(height: 16),

          _buildPerformanceSection(
            context,
            performances,
          ),

          const SizedBox(height: 16),

          _section(
            context,
            l10n.coachSummary,
            [
              Text(
                _buildSummaryText(
                  context,
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

  Widget _buildInbodySection(
    BuildContext context,
    List<CoachInbodyEntry> items,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final filtered =
        _filterRange(items, (e) => e.date);

    if (filtered.isEmpty) {
      return _section(
        context,
        l10n.inbodyBodyComposition,
        [
          Text(l10n.noInbodyDataInPeriod),
        ],
      );
    }

    final start = filtered.first;
    final end = filtered.last;

    return _section(
      context,
      l10n.inbodyBodyComposition,
      [
        _comparisonRow(
          context,
          l10n.weight,
          start.weightKg,
          end.weightKg,
          'kg',
        ),

        _comparisonRow(
          context,
          l10n.muscles,
          start.skeletalMuscleMassKg,
          end.skeletalMuscleMassKg,
          'kg',
        ),

        _comparisonRow(
          context,
          l10n.fat,
          start.percentBodyFat,
          end.percentBodyFat,
          '%',
        ),

        _comparisonRow(
          context,
          'BMI',
          start.bmi,
          end.bmi,
          '',
        ),
      ],
    );
  }

  Widget _buildCircumferenceSection(
    BuildContext context,
    List<CoachCircumferenceEntry> items,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final filtered =
        _filterRange(items, (e) => e.date);

    if (filtered.isEmpty) {
      return _section(
        context,
        l10n.bodyCircumferences,
        [
          Text(l10n.noCircumferencesInPeriod),
        ],
      );
    }

    final start = filtered.first;
    final end = filtered.last;

    return _section(
      context,
      l10n.bodyCircumferences,
      [
        _comparisonRow(
          context,
          l10n.arms,
          start.armCm,
          end.armCm,
          'cm',
        ),

        _comparisonRow(
          context,
          l10n.chest,
          start.chestCm,
          end.chestCm,
          'cm',
        ),

        _comparisonRow(
          context,
          l10n.waist,
          start.waistCm,
          end.waistCm,
          'cm',
        ),

        _comparisonRow(
          context,
          l10n.hips,
          start.hipsCm,
          end.hipsCm,
          'cm',
        ),

        _comparisonRow(
          context,
          l10n.thigh,
          start.thighCm,
          end.thighCm,
          'cm',
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(
    BuildContext context,
    List<ExercisePerformance> performances,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final filtered =
        _filterRange(performances, (e) => e.date);

    if (filtered.isEmpty) {
      return _section(
        context,
        l10n.exercisePerformance,
        [
          Text(l10n.noPerformancesInPeriod),
        ],
      );
    }

    return _section(
      context,
      l10n.exercisePerformance,
      [
        _smallInfo(
          context,
          '${l10n.numberOfRecords}: ${filtered.length}',
        ),
      ],
    );
  }

  List<T> _filterRange<T>(
    List<T> items,
    DateTime Function(T) getDate,
  ) {
    final filtered = items.where((e) {
      final d = getDate(e);

      return !d.isBefore(_dateFrom) &&
          !d.isAfter(_dateTo);
    }).toList();

    filtered.sort(
      (a, b) =>
          getDate(a).compareTo(getDate(b)),
    );

    return filtered;
  }

  String _buildSummaryText(
    BuildContext context,
    List<CoachInbodyEntry> inbody,
    List<CoachCircumferenceEntry> circs,
    List<ExercisePerformance> performances,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (inbody.isEmpty &&
        circs.isEmpty &&
        performances.isEmpty) {
      return l10n.noDataForSummary;
    }

    return l10n.summaryGenerated;
  }

  Widget _section(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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

  Widget _row(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonRow(
    BuildContext context,
    String label,
    double? first,
    double? last,
    String unit,
  ) {
    if (first == null || last == null) {
      return _row(context, label, '—');
    }

    return _row(
      context,
      label,
      '${first.toStringAsFixed(1)} → ${last.toStringAsFixed(1)} $unit',
    );
  }

  Widget _smallInfo(
    BuildContext context,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _errorCard(
    BuildContext context,
    String title,
    Object error,
  ) {
    return _section(
      context,
      title,
      [
        Text('Error: $error'),
      ],
    );
  }

  String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${d.year}';
  }

  String _genderLabel(
    BuildContext context,
    String g,
  ) {
    final l10n = AppLocalizations.of(context)!;

    switch (g.toLowerCase()) {
      case 'male':
        return l10n.male;

      case 'female':
        return l10n.female;

      default:
        return l10n.other;
    }
  }

  String _clientName(CoachClient client) {
    final full =
        '${client.firstName} ${client.lastName}'
            .trim();

    if (full.isNotEmpty) {
      return full;
    }

    return client.displayName;
  }
}