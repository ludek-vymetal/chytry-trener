import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/diet_plans/logic/choice_meal_plan.dart';
import '../../features/diet_plans/models/carb_cycling_plan.dart';
import 'pdf_author.dart';

/// PDF výběrového stravovacího plánu: úvodní strana s pravidly
/// a pak každé jídlo dne na vlastní stránce s 10 možnostmi.
class ChoiceMealPlanPdfService {
  ChoiceMealPlanPdfService._();

  static const _brand = PdfColor.fromInt(0xFF0F766E);
  static const _brandSoft = PdfColor.fromInt(0xFFE3F1EF);
  static const _ink = PdfColor.fromInt(0xFF13171C);
  static const _muted = PdfColor.fromInt(0xFF5B6470);
  static const _line = PdfColor.fromInt(0xFFD5D9DE);
  static const _soft = PdfColor.fromInt(0xFFF5F3EE);
  static const _warn = PdfColor.fromInt(0xFFDC2626);

  static String _g(double v) => '${v.round()} g';
  static String _date(DateTime d) => '${d.day}. ${d.month}. ${d.year}';

  static String _amount(MealIngredient i) {
    final a = i.unit == 'ks'
        ? i.amount.round().toString()
        : (i.amount >= 10 ? (i.amount / 5).round() * 5 : i.amount.round())
            .toString();
    return '$a ${i.unit}';
  }

  static Future<Uint8List> build(
    ChoiceMealPlan plan, {
    bool trialWatermark = false,
  }) async {
    final author = await PdfAuthor.load();
    final theme = await PdfAuthor.theme();
    final pdf = pw.Document(
      title: 'Výběrový stravovací plán – ${plan.clientName}',
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
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
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
          _cover(plan, author),
          for (var i = 0; i < plan.groups.length; i++) ...[
            pw.NewPage(),
            _groupHeader(plan.groups[i], i + 1),
            pw.SizedBox(height: 10),
            ..._optionRows(plan.groups[i]),
          ],
          PdfAuthor.signatureBlock(author, date: plan.createdAt),
        ],
      ),
    );
    return pdf.save();
  }

  static pw.Widget _cover(ChoiceMealPlan plan, String? author) {
    pw.Widget macro(String label, String value) => pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            child: pw.Column(
              children: [
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.Text(label,
                    style: const pw.TextStyle(fontSize: 9, color: _muted)),
              ],
            ),
          ),
        );

    pw.Widget step(String n, String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 7),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 18,
                height: 18,
                alignment: pw.Alignment.center,
                decoration: const pw.BoxDecoration(
                  color: _brand,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Text(
                  n,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
        );

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
                'VÝBĚROVÝ STRAVOVACÍ PLÁN',
                style: pw.TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                plan.clientName,
                style: pw.TextStyle(
                  fontSize: 26,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                [
                  'Sestaveno ${_date(plan.createdAt)}',
                  if (author != null) 'vypracoval/a $author',
                  if (plan.keto) 'ketogenní strava',
                ].join(' · '),
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Text(
          'Denní cíl',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _line),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Row(
            children: [
              macro('kcal', '${plan.kcal.round()}'),
              macro('bílkoviny', _g(plan.protein)),
              macro('sacharidy', _g(plan.carbs)),
              macro('tuky', _g(plan.fats)),
            ],
          ),
        ),
        if (plan.excluded.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _warn),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(
              'Plán je sestaven BEZ těchto potravin (alergie, nesnášenlivost, '
              'neoblíbené): ${plan.excluded.join(', ')}. Při nákupu hotových '
              'výrobků vždy čti složení na obalu.',
              style: const pw.TextStyle(fontSize: 9.5),
            ),
          ),
        ],
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: const pw.BoxDecoration(
            color: _brandSoft,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Jak s plánem pracovat',
                style:
                    pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              step('1',
                  'Každé jídlo dne má svou stránku s několika možnostmi. Každý den si z každé stránky vyber jedno jídlo – podle toho, na co máš chuť a co máš doma.'),
              step('2',
                  'Všechny možnosti na jedné stránce mají téměř stejné kalorie, bílkoviny, sacharidy i tuky. Můžeš je libovolně střídat a denní cíl stále dodržíš.'),
              step('3',
                  'Stejné jídlo můžeš jíst i víckrát za týden. Důležité je dodržet gramáž – potraviny važ, alespoň první týdny.'),
              step('4',
                  'Jídla nepřeskakuj a nepřesouvej mezi sebou. Když jedno vynecháš, nedoháněj ho větší porcí u dalšího.'),
              step('5',
                  'Pij průběžně vodu (orientačně 30–35 ml na kg tělesné hmotnosti denně). Zeleninu můžeš přidat navíc.'),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Jídla dne',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder(
            horizontalInside: const pw.BorderSide(color: _line, width: 0.6),
            bottom: const pw.BorderSide(color: _line, width: 0.6),
            top: const pw.BorderSide(color: _line, width: 0.6),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(1.4),
            2: pw.FlexColumnWidth(1.4),
            3: pw.FlexColumnWidth(1.4),
            4: pw.FlexColumnWidth(1.4),
            5: pw.FlexColumnWidth(1.6),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _soft),
              children: [
                for (final h in [
                  'Jídlo',
                  'kcal',
                  'Bílkoviny',
                  'Sacharidy',
                  'Tuky',
                  'Možností',
                ])
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            for (final g in plan.groups)
              pw.TableRow(
                children: [
                  for (final v in [
                    g.slot.label,
                    '${g.kcal.round()}',
                    _g(g.protein),
                    _g(g.carbs),
                    _g(g.fats),
                    '${g.options.length}',
                  ])
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(v, style: const pw.TextStyle(fontSize: 9.5)),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _groupHeader(ChoiceMealGroup g, int index) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const pw.BoxDecoration(
        color: _brand,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '$index. JÍDLO DNE',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    letterSpacing: 1.1,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  g.slot.label,
                  style: pw.TextStyle(
                    fontSize: 20,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Vyber si 1 z ${g.options.length} možností',
                  style:
                      const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                '~${g.kcal.round()} kcal',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'B ${_g(g.protein)} · S ${_g(g.carbs)} · T ${_g(g.fats)}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _optionRows(ChoiceMealGroup g) {
    final rows = <pw.Widget>[];
    for (var i = 0; i < g.options.length; i += 2) {
      rows.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _option(g.options[i], i + 1)),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: i + 1 < g.options.length
                  ? _option(g.options[i + 1], i + 2)
                  : pw.SizedBox(),
            ),
          ],
        ),
      ));
    }
    return rows;
  }

  static pw.Widget _option(PlannedMeal m, int n) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 16,
                height: 16,
                alignment: pw.Alignment.center,
                decoration: const pw.BoxDecoration(
                  color: _brandSoft,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Text(
                  '$n',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: _brand,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Text(
                  _cap(m.name),
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          for (final i in m.ingredients)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 1.5),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 44,
                    child: pw.Text(
                      _amount(i),
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(i.name,
                        style: const pw.TextStyle(fontSize: 8.5)),
                  ),
                ],
              ),
            ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${(m.calories ?? 0).round()} kcal · B ${(m.protein ?? 0).round()} g · '
            'S ${(m.carbs ?? 0).round()} g · T ${(m.fats ?? 0).round()} g',
            style: const pw.TextStyle(fontSize: 7.5, color: _muted),
          ),
        ],
      ),
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static String _fileName(ChoiceMealPlan plan) {
    final name = plan.clientName
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-áčďéěíňóřšťúůýž]'), '');
    return 'vyberovy-plan-$name';
  }

  static Future<void> printPlan(ChoiceMealPlan plan,
      {bool trialWatermark = false}) {
    return Printing.layoutPdf(
      name: _fileName(plan),
      onLayout: (_) => build(plan, trialWatermark: trialWatermark),
    );
  }

  static Future<void> sharePlan(ChoiceMealPlan plan,
      {bool trialWatermark = false}) async {
    final bytes = await build(plan, trialWatermark: trialWatermark);
    await Printing.sharePdf(bytes: bytes, filename: '${_fileName(plan)}.pdf');
  }
}
