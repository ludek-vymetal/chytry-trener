import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/custom_training_plan.dart';
import '../coach/coach_storage_service.dart';
import 'pdf_author.dart';

/// PDF tréninkového plánu: hlavička, pravidla, dny s cviky,
/// podpis trenéra a upozornění.
class TrainingPlanPdfService {
  TrainingPlanPdfService._();

  static const _brand = PdfColor.fromInt(0xFF0F766E);
  static const _brandSoft = PdfColor.fromInt(0xFFE3F1EF);
  static const _muted = PdfColor.fromInt(0xFF5B6470);
  static const _line = PdfColor.fromInt(0xFFD5D9DE);
  static const _soft = PdfColor.fromInt(0xFFF5F3EE);

  static String _date(DateTime d) => '${d.day}. ${d.month}. ${d.year}';

  static String _kg(double v) {
    final s = v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(1).replaceAll('.', ',');
    return '$s kg';
  }

  static Future<String?> _clientName(String clientId) async {
    try {
      final clients = await CoachStorageService.loadClients();
      for (final c in clients) {
        if (c.clientId == clientId) {
          final n = '${c.firstName} ${c.lastName}'.trim();
          return n.isEmpty ? null : n;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Uint8List> build(
    CustomTrainingPlan plan, {
    required String categoryLabel,
    String? clientName,
    bool trialWatermark = false,
  }) async {
    final author = await PdfAuthor.load();
    final theme = await PdfAuthor.theme();
    final client = clientName ?? await _clientName(plan.clientId);
    final now = DateTime.now();

    final pdf = pw.Document(
      title: 'Tréninkový plán – ${plan.name}',
      author: author,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 30, 32, 30),
        theme: theme,
        header: (ctx) => PdfAuthor.brandHeader(),
        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  trialWatermark
                      ? 'ZKUŠEBNÍ VERZE aplikace Chytrý trenér'
                      : PdfAuthor.footerText(author),
                  style: const pw.TextStyle(fontSize: 7, color: _muted),
                ),
              ),
              pw.Text(
                'Strana ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 7, color: _muted),
              ),
            ],
          ),
        ),
        build: (ctx) => [
          _header(plan, client, author, categoryLabel, now),
          pw.SizedBox(height: 14),
          _rules(),
          for (var i = 0; i < plan.days.length; i++) ...[
            pw.SizedBox(height: 16),
            _dayTitle(plan.days[i], i + 1),
            pw.SizedBox(height: 6),
            _dayTable(plan.days[i]),
          ],
          PdfAuthor.signatureBlock(author, date: now),
        ],
      ),
    );
    return pdf.save();
  }

  static pw.Widget _header(
    CustomTrainingPlan plan,
    String? client,
    String? author,
    String categoryLabel,
    DateTime now,
  ) {
    final chips = <String>[
      categoryLabel,
      '${plan.days.length} ${plan.days.length == 1 ? 'tréninkový den' : plan.days.length < 5 ? 'tréninkové dny' : 'tréninkových dnů'} v týdnu',
      if (plan.meetDate != null) 'závody / cíl: ${_date(plan.meetDate!)}',
    ];
    final maxes = plan.maxes;
    final desc = plan.description?.trim() ?? '';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          decoration: const pw.BoxDecoration(
            color: _brand,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(14)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TRÉNINKOVÝ PLÁN',
                style: pw.TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                plan.name,
                style: pw.TextStyle(
                  fontSize: 24,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                [
                  if (client != null) 'pro: $client',
                  'sestaveno ${_date(now)}',
                  if (author != null) 'vypracoval/a $author',
                ].join(' · '),
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final c in chips)
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const pw.BoxDecoration(
                  color: _brandSoft,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Text(c, style: const pw.TextStyle(fontSize: 9)),
              ),
          ],
        ),
        if (desc.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text(desc, style: const pw.TextStyle(fontSize: 10)),
        ],
        if (maxes != null && maxes.hasAnyValue) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            'Výchozí maxima (1RM): ${[
              if (maxes.squat1rm != null) 'dřep ${_kg(maxes.squat1rm!)}',
              if (maxes.bench1rm != null) 'bench ${_kg(maxes.bench1rm!)}',
              if (maxes.deadlift1rm != null) 'mrtvý tah ${_kg(maxes.deadlift1rm!)}',
            ].join(' · ')}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ],
    );
  }

  static pw.Widget _rules() {
    pw.Widget line(String title, String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '$title  ',
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.TextSpan(
                  text: text,
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
              ],
            ),
          ),
        );

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: const pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Jak s plánem pracovat',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          line('Rozcvička:',
              '5–10 minut lehkého kardia a 1–2 rozcvičovací série s lehkou váhou před prvním cvikem.'),
          line('RIR:',
              'kolik opakování by ti ještě zbylo do vyčerpání. RIR 2 = sérii ukonči, když bys zvládl/a ještě 2 opakování.'),
          line('Pauzy:',
              'u těžkých vícekloubových cviků 2–3 minuty, u doplňkových 60–90 sekund.'),
          line('Postup:',
              'když zvládneš všechny série v horní hranici opakování, příště přidej 2,5–5 % váhy.'),
          line('Technika:',
              'vždy má přednost před vahou. Při bolesti (ne únavě) cvik ukonči.'),
        ],
      ),
    );
  }

  static pw.Widget _dayTitle(CustomTrainingDay day, int index) {
    return pw.Row(
      children: [
        pw.Container(
          width: 22,
          height: 22,
          alignment: pw.Alignment.center,
          decoration: const pw.BoxDecoration(
            color: _brand,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Text(
            '$index',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            day.name,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Text(
          '${day.exercises.length} cviků',
          style: const pw.TextStyle(fontSize: 9, color: _muted),
        ),
      ],
    );
  }

  static pw.Widget _dayTable(CustomTrainingDay day) {
    if (day.exercises.isEmpty) {
      return pw.Text(
        'Den volna / regenerace.',
        style: const pw.TextStyle(fontSize: 10, color: _muted),
      );
    }

    pw.Widget cell(String t, {bool bold = false, bool head = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: pw.Text(
            t,
            style: pw.TextStyle(
              fontSize: head ? 8.5 : 9.5,
              fontWeight:
                  bold || head ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: head ? _muted : null,
            ),
          ),
        );

    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(color: _line, width: 0.6),
        top: const pw.BorderSide(color: _line, width: 0.6),
        bottom: const pw.BorderSide(color: _line, width: 0.6),
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(18),
        1: pw.FlexColumnWidth(4),
        2: pw.FlexColumnWidth(1.1),
        3: pw.FlexColumnWidth(1.5),
        4: pw.FlexColumnWidth(0.9),
        5: pw.FlexColumnWidth(1.3),
        6: pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _soft),
          repeat: true,
          children: [
            cell('#', head: true),
            cell('Cvik', head: true),
            cell('Série', head: true),
            cell('Opakování', head: true),
            cell('RIR', head: true),
            cell('Váha', head: true),
            cell('Poznámka', head: true),
          ],
        ),
        for (var i = 0; i < day.exercises.length; i++)
          pw.TableRow(
            children: [
              cell('${i + 1}', head: true),
              cell(day.exercises[i].customName, bold: true),
              cell(day.exercises[i].sets),
              cell(day.exercises[i].reps),
              cell(day.exercises[i].rir),
              cell(day.exercises[i].weightKg == null
                  ? '–'
                  : _kg(day.exercises[i].weightKg!)),
              cell(day.exercises[i].note?.trim().isNotEmpty == true
                  ? day.exercises[i].note!.trim()
                  : ''),
            ],
          ),
      ],
    );
  }

  static String _fileName(CustomTrainingPlan plan) {
    final n = plan.name
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-áčďéěíňóřšťúůýž]'), '');
    return 'treninkovy-plan-$n';
  }

  static Future<void> printPlan(
    CustomTrainingPlan plan, {
    required String categoryLabel,
    bool trialWatermark = false,
  }) {
    return Printing.layoutPdf(
      name: _fileName(plan),
      onLayout: (_) => build(
        plan,
        categoryLabel: categoryLabel,
        trialWatermark: trialWatermark,
      ),
    );
  }

  static Future<void> sharePlan(
    CustomTrainingPlan plan, {
    required String categoryLabel,
    bool trialWatermark = false,
  }) async {
    final bytes = await build(
      plan,
      categoryLabel: categoryLabel,
      trialWatermark: trialWatermark,
    );
    await Printing.sharePdf(bytes: bytes, filename: '${_fileName(plan)}.pdf');
  }
}
