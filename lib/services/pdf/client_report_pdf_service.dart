import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/coach/coach_circumference_entry.dart';
import '../../models/coach/coach_client.dart';
import '../../models/coach/coach_inbody_entry.dart';
import '../../models/exercise_performance.dart';

class ClientReportPdfService {
  static Future<pw.Document> generate({
    required CoachClient client,
    required DateTime from,
    required DateTime to,
    required List<CoachInbodyEntry> inbody,
    required List<CoachCircumferenceEntry> circs,
    required List<ExercisePerformance> performances,
  }) async {
    final pdf = pw.Document();

    final regularFontData =
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldFontData =
        await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');

    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);

    final theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
    );

    final sortedInbody = [...inbody]..sort((a, b) => a.date.compareTo(b.date));
    final sortedCircs = [...circs]..sort((a, b) => a.date.compareTo(b.date));
    final sortedPerf = [...performances]
      ..sort((a, b) => a.date.compareTo(b.date));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        theme: theme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Analýza klienta',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              _headerBox(client, from, to),
              pw.SizedBox(height: 10),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _compactInbodySection(sortedInbody),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: _compactCircSection(sortedCircs),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              _compactPerformanceSection(sortedPerf),
              pw.SizedBox(height: 10),
              _compactSummarySection(sortedInbody, sortedCircs, sortedPerf),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _headerBox(
    CoachClient client,
    DateTime from,
    DateTime to,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _clientName(client),
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Věk: ${client.age} let',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Výška: ${client.heightCm} cm',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Pohlaví: ${_genderLabel(client.gender)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Registrován: ${_fmtDate(client.linkedAt)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Období reportu: ${_fmtDate(from)} – ${_fmtDate(to)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _compactInbodySection(List<CoachInbodyEntry> inbody) {
    if (inbody.isEmpty) {
      return _section(
        'InBody',
        [
          pw.Text(
            'Žádná data v daném období.',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      );
    }

    final first = inbody.first;
    final last = inbody.last;

    final children = <pw.Widget>[
      pw.Text(
        'Počet měření: ${inbody.length}',
        style: const pw.TextStyle(fontSize: 10),
      ),
    ];

    if (inbody.length == 1) {
      children.addAll([
        _smallLine('Váha', '${last.weightKg.toStringAsFixed(1)} kg'),
        _smallLine('Svaly', '${last.skeletalMuscleMassKg.toStringAsFixed(1)} kg'),
        _smallLine('Tuk', '${last.percentBodyFat.toStringAsFixed(1)} %'),
        _smallLine('BMI', last.bmi.toStringAsFixed(1)),
      ]);
    } else {
      children.addAll([
        _smallLine(
          'Váha',
          '${first.weightKg.toStringAsFixed(1)} -> ${last.weightKg.toStringAsFixed(1)} kg',
        ),
        _smallLine(
          'Svaly',
          '${first.skeletalMuscleMassKg.toStringAsFixed(1)} -> ${last.skeletalMuscleMassKg.toStringAsFixed(1)} kg',
        ),
        _smallLine(
          'Tuk',
          '${first.percentBodyFat.toStringAsFixed(1)} -> ${last.percentBodyFat.toStringAsFixed(1)} %',
        ),
        _smallLine(
          'BMI',
          '${first.bmi.toStringAsFixed(1)} -> ${last.bmi.toStringAsFixed(1)}',
        ),
      ]);
    }

    return _section('InBody', children);
  }

  static pw.Widget _compactCircSection(List<CoachCircumferenceEntry> circs) {
    if (circs.isEmpty) {
      return _section(
        'Obvody',
        [
          pw.Text(
            'Žádná data v daném období.',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      );
    }

    final first = circs.first;
    final last = circs.last;

    final children = <pw.Widget>[
      pw.Text(
        'Počet měření: ${circs.length}',
        style: const pw.TextStyle(fontSize: 10),
      ),
    ];

    if (circs.length == 1) {
      children.addAll([
        _smallLine('Pas', '${last.waistCm.toStringAsFixed(1)} cm'),
        _smallLine('Paže', '${last.armCm.toStringAsFixed(1)} cm'),
        _smallLine('Hrudník', '${last.chestCm.toStringAsFixed(1)} cm'),
        _smallLine('Boky', '${last.hipsCm.toStringAsFixed(1)} cm'),
        _smallLine('Stehno', '${last.thighCm.toStringAsFixed(1)} cm'),
        _smallLine('Lýtko', '${last.calfCm.toStringAsFixed(1)} cm'),
        _smallLine('Krk', '${last.neckCm.toStringAsFixed(1)} cm'),
      ]);
    } else {
      children.addAll([
        _smallLine(
          'Pas',
          '${first.waistCm.toStringAsFixed(1)} -> ${last.waistCm.toStringAsFixed(1)} cm',
        ),
        _smallLine(
          'Paže',
          '${first.armCm.toStringAsFixed(1)} -> ${last.armCm.toStringAsFixed(1)} cm',
        ),
        _smallLine(
          'Hrudník',
          '${first.chestCm.toStringAsFixed(1)} -> ${last.chestCm.toStringAsFixed(1)} cm',
        ),
        _smallLine(
          'Boky',
          '${first.hipsCm.toStringAsFixed(1)} -> ${last.hipsCm.toStringAsFixed(1)} cm',
        ),
        _smallLine(
          'Stehno',
          '${first.thighCm.toStringAsFixed(1)} -> ${last.thighCm.toStringAsFixed(1)} cm',
        ),
        _smallLine(
          'Lýtko',
          '${first.calfCm.toStringAsFixed(1)} -> ${last.calfCm.toStringAsFixed(1)} cm',
        ),
        _smallLine(
          'Krk',
          '${first.neckCm.toStringAsFixed(1)} -> ${last.neckCm.toStringAsFixed(1)} cm',
        ),
      ]);
    }

    return _section('Obvody', children);
  }

  static pw.Widget _compactPerformanceSection(
    List<ExercisePerformance> performances,
  ) {
    if (performances.isEmpty) {
      return _section(
        'Výkon',
        [
          pw.Text(
            'Žádná data v daném období.',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      );
    }

    final grouped = <String, List<ExercisePerformance>>{};
    for (final p in performances) {
      final key = p.exerciseName.trim().isEmpty
          ? 'Bez názvu cviku'
          : p.exerciseName.trim();
      grouped.putIfAbsent(key, () => []).add(p);
    }

    final names = grouped.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final visibleNames = names.take(4).toList();

    return _section(
      'Výkon',
      [
        for (final name in visibleNames)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: _performanceMiniBlock(name, grouped[name]!),
          ),
      ],
    );
  }

  static pw.Widget _performanceMiniBlock(
    String exerciseName,
    List<ExercisePerformance> list,
  ) {
    final sorted = [...list]..sort((a, b) => a.date.compareTo(b.date));
    final first = sorted.first;
    final last = sorted.last;
    final best = [...sorted]..sort((a, b) => b.weight.compareTo(a.weight));

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            exerciseName,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'První výkon: ${first.weight.toStringAsFixed(1)} kg × ${first.reps}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'Poslední výkon: ${last.weight.toStringAsFixed(1)} kg × ${last.reps}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'Nejlepší váha: ${best.first.weight.toStringAsFixed(1)} kg × ${best.first.reps}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'Změna váhy: ${_formatDelta(last.weight - first.weight, 'kg')}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'Počet záznamů: ${sorted.length}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  static pw.Widget _compactSummarySection(
    List<CoachInbodyEntry> inbody,
    List<CoachCircumferenceEntry> circs,
    List<ExercisePerformance> performances,
  ) {
    final lines = <String>[];

    if (inbody.isNotEmpty) {
      final first = inbody.first;
      final last = inbody.last;

      if (inbody.length == 1) {
        lines.add(
          'K dispozici je 1 InBody měření: váha ${last.weightKg.toStringAsFixed(1)} kg, tuk ${last.percentBodyFat.toStringAsFixed(1)} %.',
        );
      } else {
        lines.add(
          'Váha se změnila z ${first.weightKg.toStringAsFixed(1)} na ${last.weightKg.toStringAsFixed(1)} kg.',
        );
      }
    }

    if (circs.isNotEmpty) {
      final first = circs.first;
      final last = circs.last;

      if (circs.length == 1) {
        lines.add(
          'K dispozici je 1 měření obvodů: pas ${last.waistCm.toStringAsFixed(1)} cm.',
        );
      } else {
        lines.add(
          'Pas se změnil z ${first.waistCm.toStringAsFixed(1)} na ${last.waistCm.toStringAsFixed(1)} cm.',
        );
      }
    }

    if (performances.isNotEmpty) {
      final grouped = <String, List<ExercisePerformance>>{};
      for (final p in performances) {
        final key = p.exerciseName.trim().isEmpty
            ? 'Bez názvu cviku'
            : p.exerciseName.trim();
        grouped.putIfAbsent(key, () => []).add(p);
      }

      final firstExerciseName = grouped.keys.isEmpty ? null : grouped.keys.first;
      if (firstExerciseName != null) {
        final list = [...grouped[firstExerciseName]!]
          ..sort((a, b) => a.date.compareTo(b.date));
        final last = list.last;
        lines.add(
          'Výkon u cviku $firstExerciseName: ${last.weight.toStringAsFixed(1)} kg × ${last.reps}.',
        );
      }
    }

    if (lines.isEmpty) {
      lines.add('Ve zvoleném období nejsou dostupná data pro shrnutí.');
    }

    return _section(
      'Shrnutí pro trenéra',
      [
        for (final line in lines)
          pw.Text(line, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _section(String title, List<pw.Widget> children) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _smallLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 1),
      child: pw.Text(
        '$label: $value',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static String _clientName(CoachClient client) {
    final full = '${client.firstName} ${client.lastName}'.trim();
    if (full.isNotEmpty) return full;
    return client.displayName.trim().isNotEmpty ? client.displayName : 'Klient';
  }

  static String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${d.year}';
  }

  static String _formatDelta(double value, String unit) {
    final prefix = value >= 0 ? '+' : '';
    return '$prefix${value.toStringAsFixed(1)} $unit';
  }

  static String _genderLabel(String g) {
    switch (g.toLowerCase()) {
      case 'male':
        return 'Muž';
      case 'female':
        return 'Žena';
      default:
        return 'Jiné';
    }
  }
}