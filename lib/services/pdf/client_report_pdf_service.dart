import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/body/inbody_analysis.dart';
import '../../core/nutrition/hollywood_prep.dart';
import '../../models/coach/coach_circumference_entry.dart';
import '../../models/coach/coach_client.dart';
import '../../models/coach/coach_inbody_entry.dart';
import '../../models/exercise_performance.dart';
import '../../models/goal.dart';
import 'client_report_data.dart';
import 'pdf_author.dart';
import '../../core/body/coach_recommendations.dart';
import '../../core/training/exercises/exercise_db.dart';

/// Profesionální souhrn klienta do tisku / PDF:
/// postava (InBody + rozbor), obvody, trénink, strava, cíl a doporučení.
class ClientReportPdfService {
  // ---------------------------------------------------------------
  // Barvy
  // ---------------------------------------------------------------
  /// Černobílý tisk – šetří barevný toner, vše v odstínech šedi.
  static bool _bw = false;

  static PdfColor get _ink =>
      _bw ? const PdfColor.fromInt(0xFF111111) : PdfColor.fromInt(0xFF1F2933);
  static PdfColor get _muted =>
      _bw ? const PdfColor.fromInt(0xFF555555) : PdfColor.fromInt(0xFF616E7C);
  static PdfColor get _line =>
      _bw ? const PdfColor.fromInt(0xFFBBBBBB) : PdfColor.fromInt(0xFFD9DEE3);
  static PdfColor get _soft =>
      _bw ? const PdfColor.fromInt(0xFFF2F2F2) : PdfColor.fromInt(0xFFF3F5F7);
  static PdfColor get _brand =>
      _bw ? const PdfColor.fromInt(0xFF222222) : PdfColor.fromInt(0xFF0F766E);
  static PdfColor get _brandSoft =>
      _bw ? const PdfColor.fromInt(0xFFEEEEEE) : PdfColor.fromInt(0xFFE6F4F2);
  static PdfColor get _brandDark =>
      _bw ? const PdfColor.fromInt(0xFF000000) : PdfColor.fromInt(0xFF0B3B3C);
  static PdfColor get _brandLight =>
      _bw ? const PdfColor.fromInt(0xFF555555) : PdfColor.fromInt(0xFF14A38B);
  static PdfColor get _fatColor =>
      _bw ? const PdfColor.fromInt(0xFF8A8A8A) : PdfColor.fromInt(0xFFF4A259);
  static PdfColor get _otherColor =>
      _bw ? const PdfColor.fromInt(0xFFD6D6D6) : PdfColor.fromInt(0xFFCBD2D9);
  static PdfColor get _good =>
      _bw ? const PdfColor.fromInt(0xFF222222) : PdfColor.fromInt(0xFF2E7D32);
  static PdfColor get _ok =>
      _bw ? const PdfColor.fromInt(0xFF444444) : PdfColor.fromInt(0xFF1565C0);
  static PdfColor get _warn =>
      _bw ? const PdfColor.fromInt(0xFF666666) : PdfColor.fromInt(0xFFE65100);
  static PdfColor get _bad =>
      _bw ? const PdfColor.fromInt(0xFF000000) : PdfColor.fromInt(0xFFC62828);

  static Future<pw.Document> generate({
    required CoachClient client,
    required DateTime from,
    required DateTime to,
    required List<CoachInbodyEntry> inbody,
    required List<CoachCircumferenceEntry> circs,
    required List<ExercisePerformance> performances,
    bool blackAndWhite = false,
    bool trialWatermark = false,
  }) async {
    _bw = blackAndWhite;
    final pdf = pw.Document(
      title: 'Souhrn klienta – ${_clientName(client)}',
      author: 'Chytrý trenér',
    );

    final regular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final bold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    final theme = pw.ThemeData.withFont(base: regular, bold: bold);
    final author = await PdfAuthor.load();

    final extras = await ClientReportExtras.load(
      client: client,
      from: from,
      to: to,
    );

    final ib = [...inbody]..sort((a, b) => a.date.compareTo(b.date));
    final cs = [...circs]..sort((a, b) => a.date.compareTo(b.date));
    final perf = [...performances]..sort((a, b) => a.date.compareTo(b.date));

    // Klient v režimu podpory při poruše příjmu potravy – bez čísel
    // o postavě a jídle.
    final sensitive = client.isEatingDisorderSupport;

    final report = !sensitive && ib.isNotEmpty
        ? InbodyAnalysis.analyze(
            latest: ib.last,
            // Vývoj od MINULÉHO měření (měří se zhruba jednou měsíčně);
            // změny za celé období ukazují tabulky a grafy.
            previous: ib.length > 1 ? ib[ib.length - 2] : null,
            gender: client.gender,
            age: client.age,
          )
        : null;

    final generated = DateTime.now();
    final actions =
        _actionPlan(client, extras, ib, perf, report, from, to, sensitive);
    final wins = _wins(client, ib, cs, extras, perf, from, to, sensitive);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
        theme: theme,
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                margin: pw.EdgeInsets.only(bottom: 10),
                padding: pw.EdgeInsets.only(bottom: 4),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _line, width: 0.6),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Souhrn klienta · ${_clientName(client)}',
                      style: pw.TextStyle(fontSize: 8, color: _muted),
                    ),
                    pw.Text(
                      '${_fmtDate(from)} – ${_fmtDate(to)}',
                      style: pw.TextStyle(fontSize: 8, color: _muted),
                    ),
                  ],
                ),
              ),
        footer: (ctx) => pw.Container(
          margin: pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                trialWatermark
                    ? 'ZKUŠEBNÍ VERZE aplikace Chytrý trenér · '
                        'plná verze tiskne souhrn bez tohoto nápisu'
                    : author == null
                        ? 'Vytvořeno aplikací Chytrý trenér ${_fmtDate(generated)} · '
                            'Nenahrazuje lékařské vyšetření.'
                        : 'Vypracoval/a: $author · ${_fmtDate(generated)} · '
                            'Nenahrazuje lékařské vyšetření.',
                style: pw.TextStyle(fontSize: 7, color: _muted),
              ),
              pw.Text(
                'Strana ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 7, color: _muted),
              ),
            ],
          ),
        ),
        build: (ctx) => [
          _cover(client, from, to, extras,
              _formScore(client, extras, perf, report, from, to, sensitive)),
          pw.SizedBox(height: 12),
          _keyStats(client, ib, cs, extras, perf, from, to, sensitive),
          _overview(client, extras, perf, report, from, to, sensitive),
          pw.SizedBox(height: 12),
          _intro(to.difference(from).inDays + 1, wins),
          pw.SizedBox(height: 16),

          // 1) Postava
          _h1('1', 'Postava a složení těla'),
          if (sensitive)
            _note('Údaje o hmotnosti a složení těla v tomto souhrnu '
                'záměrně neuvádíme – soustředíme se na pohodu a pravidelnost.')
          else ...[
            ..._inbodyBlock(ib),
            if (report != null) ..._analysisBlock(report),
          ],
          pw.SizedBox(height: 10),

          // 2) Obvody
          _h1('2', 'Obvody těla'),
          if (sensitive)
            _note('Obvody v tomto souhrnu záměrně neuvádíme.')
          else
            ..._circBlock(cs),
          pw.SizedBox(height: 10),

          // 3) Trénink
          _h1('3', 'Trénink'),
          ..._trainingBlock(client, extras, perf, from, to),
          pw.SizedBox(height: 10),

          // 4) Strava
          _h1('4', 'Strava'),
          ..._foodBlock(extras, from, to, sensitive),
          pw.SizedBox(height: 10),

          // 5) Cíl a doporučení
          _h1('5', 'Cíl a plán na další období'),
          ..._goalBlock(extras, ib, sensitive),
          ..._actionPlanBlock(actions),
          pw.SizedBox(height: 10),
          _summaryBlock(wins, actions),
          pw.SizedBox(height: 10),
          _coachNotesBox(),
          PdfAuthor.signatureBlock(author, date: generated),
        ],
      ),
    );

    return pdf;
  }

  // =================================================================
  // Úvod
  // =================================================================

  static pw.Widget _cover(
    CoachClient client,
    DateTime from,
    DateTime to,
    ClientReportExtras extras,
    (int, String)? score,
  ) {
    final days = to.difference(from).inDays + 1;
    // Černobíle: bílá hlavička s černým rámečkem (neplýtvá tonerem).
    final white = _bw ? _ink : PdfColors.white;
    final faded = _bw ? _muted : PdfColor.fromInt(0xFFCFE7E3);

    return pw.Container(
      padding: pw.EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: _bw
          ? pw.BoxDecoration(
              border: pw.Border.all(color: _ink, width: 1.5),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(14)),
            )
          : pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [_brandDark, _brand, _brandLight],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(14)),
            ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SOUHRN KLIENTA',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: faded,
                    letterSpacing: 2,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  _clientName(client),
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${_genderLabel(client.gender)} · ${client.age} let · '
                  '${client.heightCm} cm',
                  style: pw.TextStyle(fontSize: 10, color: faded),
                ),
                pw.SizedBox(height: 14),
                pw.Row(
                  children: [
                    _coverChip('Období', '${_fmtDate(from)} – ${_fmtDate(to)}'),
                    pw.SizedBox(width: 8),
                    _coverChip('Délka', '$days dní'),
                  ],
                ),
                if (extras.activePlan != null) ...[
                  pw.SizedBox(height: 6),
                  _coverChip('Plán', _clean(extras.activePlan!.name)),
                ],
              ],
            ),
          ),
          if (score != null) ...[
            pw.SizedBox(width: 16),
            pw.Column(
              children: [
                pw.SizedBox(
                  width: 86,
                  height: 86,
                  child: pw.Stack(
                    alignment: pw.Alignment.center,
                    children: [
                      pw.SizedBox(
                        width: 86,
                        height: 86,
                        child: pw.CircularProgressIndicator(
                          value: score.$1 / 100,
                          color: white,
                          backgroundColor: _bw
                              ? PdfColor.fromInt(0xFFDDDDDD)
                              : PdfColor.fromInt(0xFF2E7F76),
                          strokeWidth: 7,
                        ),
                      ),
                      pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text(
                            '${score.$1}',
                            style: pw.TextStyle(
                              fontSize: 26,
                              fontWeight: pw.FontWeight.bold,
                              color: white,
                            ),
                          ),
                          pw.Text(
                            'ze 100',
                            style: pw.TextStyle(fontSize: 7, color: faded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'SKÓRE FORMY',
                  style: pw.TextStyle(
                    fontSize: 7,
                    color: faded,
                    letterSpacing: 1.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  score.$2,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _coverChip(String label, String value) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _bw ? PdfColor.fromInt(0xFFEEEEEE) : PdfColor.fromInt(0xFF1C6B64),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label  ',
              style: pw.TextStyle(
                fontSize: 7.5,
                color: _bw ? _muted : PdfColor.fromInt(0xFFCFE7E3),
              ),
            ),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(
                fontSize: 8.5,
                color: _bw ? _ink : PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Skóre formy 0–100 ze tří složek: vývoj postavy, pravidelnost
  /// tréninku a strava. Počítá se jen z toho, co je k dispozici.
  static (int, String)? _formScore(
    CoachClient client,
    ClientReportExtras extras,
    List<ExercisePerformance> perf,
    InbodyReport? report,
    DateTime from,
    DateTime to,
    bool sensitive,
  ) {
    final parts = <double>[];

    if (!sensitive && report != null) {
      final f = report.flags;
      parts.add(switch (f.trend) {
        'recomp' || 'cut' || 'leanGain' => 100.0,
        'gain' || 'stable' => 75.0,
        'cutMuscleLoss' || 'dirtyGain' || 'muscleLoss' => 50.0,
        'fatGain' => 25.0,
        _ => f.fatVeryHigh ? 45.0 : (f.fatHigh ? 60.0 : 80.0),
      });
    }

    final weeks = math.max(1.0, (to.difference(from).inDays + 1) / 7.0);
    final perWeek = _trainingDays(client, extras, perf, from, to) / weeks;
    if (perWeek > 0) parts.add(math.min(perWeek / 3, 1) * 100);

    if (!sensitive && extras.foodDays.isNotEmpty) {
      final ratio = extras.foodDays.length / (to.difference(from).inDays + 1);
      final m = extras.macros;
      if (ratio < 0.3 || m == null) {
        parts.add(30 + ratio * 100);
      } else {
        final avg = extras.foodDays
                .map((d) => d.intake.calories)
                .reduce((a, b) => a + b) /
            extras.foodDays.length;
        final dev = (avg / m.targetCalories * 100 - 100).abs();
        parts.add(100 - math.min(dev * 2, 60));
      }
    }

    if (parts.isEmpty) return null;
    final s = (parts.reduce((a, b) => a + b) / parts.length)
        .round()
        .clamp(0, 100);
    final label = s >= 80
        ? 'Výborná forma'
        : s >= 60
            ? 'Dobrý směr'
            : s >= 40
                ? 'Je co zlepšovat'
                : 'Začínáme';
    return (s, label);
  }

  static pw.Widget _keyStats(
    CoachClient client,
    List<CoachInbodyEntry> ib,
    List<CoachCircumferenceEntry> cs,
    ClientReportExtras extras,
    List<ExercisePerformance> perf,
    DateTime from,
    DateTime to,
    bool sensitive,
  ) {
    final tiles = <pw.Widget>[];

    if (!sensitive && ib.isNotEmpty) {
      final a = ib.first;
      final b = ib.last;
      final more = ib.length > 1;
      tiles.add(_tile(
        'Váha',
        '${_n(b.weightKg)} kg',
        more ? '${_d(b.weightKg - a.weightKg)} kg' : null,
        change: more ? b.weightKg - a.weightKg : null,
      ));
      tiles.add(_tile(
        'Tělesný tuk',
        '${_n(b.bodyFatPercent)} %',
        more ? '${_d(b.bodyFatPercent - a.bodyFatPercent)} %' : null,
        change: more ? b.bodyFatPercent - a.bodyFatPercent : null,
        higherIsBetter: false,
      ));
      tiles.add(_tile(
        'Svaly (SMM)',
        '${_n(b.smmKg)} kg',
        more ? '${_d(b.smmKg - a.smmKg)} kg' : null,
        change: more ? b.smmKg - a.smmKg : null,
        higherIsBetter: true,
      ));
    }
    if (!sensitive && cs.isNotEmpty) {
      tiles.add(_tile(
        'Pas',
        '${_n(cs.last.waistCm)} cm',
        cs.length > 1 ? '${_d(cs.last.waistCm - cs.first.waistCm)} cm' : null,
      ));
    }

    final weeks = math.max(1.0, (to.difference(from).inDays + 1) / 7.0);
    final done = _trainingDays(client, extras, perf, from, to);
    tiles.add(_tile(
      'Tréninky',
      '$done',
      '${_n(done / weeks)}× týdně',
    ));

    if (!sensitive && extras.foodDays.isNotEmpty) {
      final avg = extras.foodDays
              .map((f) => f.intake.calories)
              .reduce((a, b) => a + b) /
          extras.foodDays.length;
      tiles.add(_tile(
        'Příjem (průměr)',
        '${avg.round()} kcal',
        extras.macros != null ? 'cíl ${extras.macros!.targetCalories}' : null,
      ));
    }

    final rows = <pw.Widget>[];
    for (var i = 0; i < tiles.length; i += 3) {
      final chunk = tiles.sublist(i, math.min(i + 3, tiles.length));
      rows.add(pw.Row(
        children: [
          for (var j = 0; j < 3; j++) ...[
            pw.Expanded(child: j < chunk.length ? chunk[j] : pw.SizedBox()),
            if (j < 2) pw.SizedBox(width: 8),
          ],
        ],
      ));
      rows.add(pw.SizedBox(height: 8));
    }
    return pw.Column(children: rows);
  }

  /// Rychlé hodnocení období: postava, trénink, strava (semafor).
  static pw.Widget _overview(
    CoachClient client,
    ClientReportExtras extras,
    List<ExercisePerformance> perf,
    InbodyReport? report,
    DateTime from,
    DateTime to,
    bool sensitive,
  ) {
    final items = <(String, String, PdfColor)>[];

    if (!sensitive && report != null) {
      final (text, color) = switch (report.flags.trend) {
        'recomp' => ('rekompozice', _good),
        'cut' => ('ubývá tuk', _good),
        'leanGain' => ('přibývají svaly', _good),
        'gain' => ('nabírání', _ok),
        'cutMuscleLoss' => ('hubne i o svaly', _warn),
        'dirtyGain' => ('přibývá i tuk', _warn),
        'muscleLoss' => ('ubývají svaly', _warn),
        'fatGain' => ('přibývá tuk', _bad),
        'stable' => ('beze změny', _ok),
        _ => ('vstupní měření', _muted),
      };
      items.add(('Postava', text, color));
    }

    final weeks = math.max(1.0, (to.difference(from).inDays + 1) / 7.0);
    final perWeek = _trainingDays(client, extras, perf, from, to) / weeks;
    items.add((
      'Trénink',
      perWeek == 0 ? 'bez záznamů' : '${_n(perWeek)}× týdně',
      perWeek >= 3
          ? _good
          : perWeek >= 2
              ? _ok
              : perWeek > 0
                  ? _warn
                  : _bad,
    ));

    if (!sensitive) {
      final periodDays = to.difference(from).inDays + 1;
      final logged = extras.foodDays.length;
      final ratio = logged / periodDays;
      final m = extras.macros;
      String text;
      PdfColor color;
      if (logged == 0) {
        text = 'nezapisuje';
        color = _bad;
      } else if (ratio < 0.3) {
        text = 'zapsáno ${(ratio * 100).round()} % dní';
        color = _warn;
      } else if (m != null) {
        final avg = extras.foodDays
                .map((d) => d.intake.calories)
                .reduce((a, b) => a + b) /
            logged;
        final pct = avg / m.targetCalories * 100;
        text = '${pct.round()} % cíle';
        color = (pct - 100).abs() <= 10 ? _good : _warn;
      } else {
        text = 'zapsáno ${(ratio * 100).round()} % dní';
        color = _ok;
      }
      items.add(('Strava', text, color));
    }

    final plan = extras.activePlan;
    final event = plan?.meetDate ?? extras.profile?.goal?.targetDate;
    if (event != null) {
      final d = event.difference(DateTime.now()).inDays;
      if (d >= 0) {
        items.add((
          plan?.meetDate != null ? 'Do závodu' : 'Do cíle',
          '$d dní',
          d <= 14 ? _warn : _brand,
        ));
      }
    }

    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              pw.Container(
                width: 0.6,
                height: 22,
                margin: pw.EdgeInsets.symmetric(horizontal: 8),
                color: _line,
              ),
            pw.Expanded(
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 8,
                    height: 8,
                    decoration: pw.BoxDecoration(
                      color: items[i].$3,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          items[i].$1,
                          style: pw.TextStyle(fontSize: 7, color: _muted),
                        ),
                        pw.Text(
                          items[i].$2,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: items[i].$3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _tile(
    String label,
    String value,
    String? delta, {
    double? change,
    bool? higherIsBetter,
  }) {
    var deltaColor = _brand;
    var arrow = '';
    if (change != null && change.abs() >= 0.05) {
      arrow = '';
      if (higherIsBetter != null) {
        final better = higherIsBetter ? change > 0 : change < 0;
        deltaColor = better ? _good : _bad;
      } else {
        deltaColor = _muted;
      }
    }
    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _line, width: 0.8),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _muted)),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            delta == null ? ' ' : '$arrow$delta',
            style: pw.TextStyle(
              fontSize: 8.5,
              color: deltaColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =================================================================
  // 1) Postava
  // =================================================================

  static List<pw.Widget> _inbodyBlock(List<CoachInbodyEntry> ib) {
    if (ib.isEmpty) {
      return [_note('V tomto období není žádné měření InBody.')];
    }

    final widgets = <pw.Widget>[];

    if (ib.length > 1) {
      final a = ib.first;
      final b = ib.last;
      // Při pravidelném (měsíčním) měření: začátek – minule – nyní.
      final p = ib.length >= 3 ? ib[ib.length - 2] : null;
      final vfOk = (a.visceralFatLevel ?? 0) > 0 &&
          (b.visceralFatLevel ?? 0) > 0 &&
          (p == null || (p.visceralFatLevel ?? 0) > 0);
      final whrOk = a.whr > 0 && b.whr > 0 && (p == null || p.whr > 0);
      widgets.add(_withTitle(
        p == null
            ? 'Porovnání: první a poslední měření'
            : 'Porovnání: začátek, minulé a poslední měření',
        _table(
          header: [
            'Ukazatel',
            _fmtDate(a.date),
            if (p != null) _fmtDate(p.date),
            _fmtDate(b.date),
            if (p != null) 'Od minula',
            p != null ? 'Celkem' : 'Změna',
          ],
          widths: p == null
              ? [2.4, 1.3, 1.3, 1.2]
              : [2.1, 1.1, 1.1, 1.1, 1.05, 1.05],
          rows: [
            _cmpRow('Váha', a.weightKg, b.weightKg, 'kg', prev: p?.weightKg),
            _cmpRow('Kosterní svalovina', a.smmKg, b.smmKg, 'kg',
                higherIsBetter: true, prev: p?.smmKg),
            _cmpRow('Tuk (kg)', a.fatKg, b.fatKg, 'kg',
                higherIsBetter: false, prev: p?.fatKg),
            _cmpRow('Tuk (%)', a.bodyFatPercent, b.bodyFatPercent, '%',
                higherIsBetter: false, prev: p?.bodyFatPercent),
            _cmpRow('Beztuková hmota', a.weightKg - a.fatKg,
                b.weightKg - b.fatKg, 'kg',
                higherIsBetter: true,
                prev: p == null ? null : p.weightKg - p.fatKg),
            _cmpRow('Voda v těle', a.waterKg, b.waterKg, 'l',
                prev: p?.waterKg),
            _cmpRow('BMI', a.bmi, b.bmi, '', prev: p?.bmi),
            if (whrOk)
              _cmpRow('Poměr pas/boky', a.whr, b.whr, '',
                  higherIsBetter: false, digits: 2, prev: p?.whr),
            if (vfOk)
              _cmpRow('Viscerální tuk', a.visceralFatLevel!,
                  b.visceralFatLevel!, '',
                  higherIsBetter: false, digits: 0,
                  prev: p?.visceralFatLevel),
            _cmpRow('Bazální metabolismus', a.bmr, b.bmr, 'kcal',
                digits: 0, prev: p?.bmr),
          ],
        ),
      ));
      widgets.add(pw.SizedBox(height: 10));
    }

    widgets.add(_withTitle(
        'Z čeho se skládá váha (poslední měření)', _compositionBar(ib.last)));
    widgets.add(pw.SizedBox(height: 10));
    if (ib.length > 1) {
      widgets.add(_withTitle('Vývoj po měřeních', _trendCharts(ib)));
      widgets.add(pw.SizedBox(height: 10));
    }

    // Tabulka všech měření: nejnovější nahoře, změna proti předchozímu.
    final shown = ib.length > 24 ? ib.sublist(ib.length - 24) : ib;
    String dl(double v, [int d = 1]) => _d(v, d);
    widgets.add(_h2(ib.length > 24
        ? 'Posledních 24 měření (celkem ${ib.length})'
        : 'Všechna měření v období (${ib.length})'));
    widgets.add(_table(
      header: ['Datum', 'Váha', '±', 'Svaly', '±', 'Tuk %', '±', 'BMI'],
      widths: [1.25, 0.95, 0.75, 0.95, 0.75, 0.95, 0.75, 0.7],
      rows: [
        for (var i = shown.length - 1; i >= 0; i--)
          () {
            final e = shown[i];
            final prevIndex = ib.indexOf(e) - 1;
            final pr = prevIndex >= 0 ? ib[prevIndex] : null;
            pw.Widget delta(double? v, bool? better) => v == null
                ? _cell('–', color: _muted)
                : _cell(dl(v),
                    color: _deltaColor(v, better, 1), bold: true);
            return [
              _cell(_fmtDate(e.date)),
              _cell('${_n(e.weightKg)} kg'),
              delta(pr == null ? null : e.weightKg - pr.weightKg, null),
              _cell('${_n(e.smmKg)} kg'),
              delta(pr == null ? null : e.smmKg - pr.smmKg, true),
              _cell('${_n(e.bodyFatPercent)} %'),
              delta(pr == null ? null : e.bodyFatPercent - pr.bodyFatPercent,
                  false),
              _cell(_n(e.bmi)),
            ];
          }(),
      ],
    ));
    widgets.add(pw.SizedBox(height: 10));

    final last = ib.last;
    final hasSegments = last.muscleLeftArmKg > 0 && last.muscleLeftLegKg > 0;
    if (hasSegments) {
      widgets.add(_withTitle(
          'Segmentální analýza (poslední měření)', _bodyMap(last)));
      widgets.add(pw.SizedBox(height: 10));
    }

    return widgets;
  }

  static pw.Widget _compositionBar(CoachInbodyEntry e) {
    final w = e.weightKg;
    if (w <= 0) return pw.SizedBox();
    final muscle = e.smmKg.clamp(0, w).toDouble();
    final fat = e.fatKg.clamp(0, w - muscle).toDouble();
    final other = math.max(w - muscle - fat, 0.0);
    int flex(double v) => math.max((v / w * 1000).round(), 1);

    pw.Widget legend(PdfColor c, String label, double kg) => pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Container(
              width: 8,
              height: 8,
              decoration: pw.BoxDecoration(
                color: c,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
              ),
            ),
            pw.SizedBox(width: 4),
            pw.Text(
              '$label ${_n(kg)} kg (${_n(kg / w * 100, 0)} %)',
              style: pw.TextStyle(fontSize: 8, color: _ink),
            ),
          ],
        );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.ClipRRect(
          horizontalRadius: 6,
          verticalRadius: 6,
          child: pw.SizedBox(
            height: 18,
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: flex(muscle),
                  child: pw.Container(color: _brand),
                ),
                pw.Expanded(
                  flex: flex(fat),
                  child: pw.Container(color: _fatColor),
                ),
                pw.Expanded(
                  flex: flex(other),
                  child: pw.Container(color: _otherColor),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Wrap(
          spacing: 14,
          runSpacing: 3,
          children: [
            legend(_brand, 'Kosterní svaly', muscle),
            legend(_fatColor, 'Tuk', fat),
            legend(_otherColor, 'Kosti, orgány, voda', other),
          ],
        ),
      ],
    );
  }

  /// Segmenty jako jednoduchá „mapa těla“: paže – trup – paže, nohy.
  static pw.Widget _bodyMap(CoachInbodyEntry e) {
    bool weaker(double me, double other) =>
        me > 0 && other > 0 && (other - me) / other >= 0.05;

    pw.Widget box(String name, double muscle, double fat, {bool weak = false,
        double width = 110}) {
      return pw.Container(
        width: width,
        padding: pw.EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: pw.BoxDecoration(
          color: weak
              ? (_bw ? PdfColor.fromInt(0xFFE6E6E6) : PdfColor.fromInt(0xFFFFF3E0))
              : _soft,
          border: pw.Border(
            left: pw.BorderSide(color: weak ? _warn : _brand, width: 3),
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              weak ? '$name · slabší' : name,
              style: pw.TextStyle(
                fontSize: 7.5,
                color: weak ? _warn : _muted,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'svaly ${_n(muscle, 2)} kg',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            pw.Text(
              'tuk ${_n(fat, 2)} kg',
              style: pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              box('Pravá paže', e.muscleRightArmKg, e.fatRightArmKg,
                  weak: weaker(e.muscleRightArmKg, e.muscleLeftArmKg)),
              pw.SizedBox(width: 8),
              box('Trup', e.muscleTrunkKg, e.fatTrunkKg, width: 130),
              pw.SizedBox(width: 8),
              box('Levá paže', e.muscleLeftArmKg, e.fatLeftArmKg,
                  weak: weaker(e.muscleLeftArmKg, e.muscleRightArmKg)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              box('Pravá noha', e.muscleRightLegKg, e.fatRightLegKg,
                  weak: weaker(e.muscleRightLegKg, e.muscleLeftLegKg)),
              pw.SizedBox(width: 8),
              box('Levá noha', e.muscleLeftLegKg, e.fatLeftLegKg,
                  weak: weaker(e.muscleLeftLegKg, e.muscleRightLegKg)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Pohled zepředu, jako na výpisu InBody (pravá strana vlevo).',
            style: pw.TextStyle(fontSize: 6.5, color: _muted),
          ),
        ],
      ),
    );
  }

  static PdfColor _deltaColor(double diff, bool? higherIsBetter, int digits) {
    if (higherIsBetter == null || diff.abs() < math.pow(10, -digits)) {
      return _ink;
    }
    final better = higherIsBetter ? diff > 0 : diff < 0;
    return better ? _good : _bad;
  }

  /// Řádek porovnání. S [prev] (předchozí měření) přibude sloupec
  /// „Minule“ a změna za poslední měsíc vedle změny za celé období.
  static List<pw.Widget> _cmpRow(
    String label,
    double a,
    double b,
    String unit, {
    bool? higherIsBetter,
    int digits = 1,
    double? prev,
  }) {
    final u = unit.isEmpty ? '' : ' $unit';
    final total = b - a;
    return [
      _cell(label),
      _cell('${_n(a, digits)}$u'),
      if (prev != null) _cell('${_n(prev, digits)}$u'),
      _cell('${_n(b, digits)}$u', bold: true),
      if (prev != null)
        _cell(
          '${_d(b - prev, digits)}$u',
          color: _deltaColor(b - prev, higherIsBetter, digits),
          bold: true,
        ),
      _cell(
        '${_d(total, digits)}$u',
        color: _deltaColor(total, higherIsBetter, digits),
        bold: true,
      ),
    ];
  }

  /// Vývoj po měřeních – tři malé grafy vedle sebe (váha, tuk, svaly).
  /// Vejde se až 24 měření (2 roky při měření jednou za měsíc).
  static pw.Widget _trendCharts(List<CoachInbodyEntry> ib) {
    final data = ib.length > 24 ? ib.sublist(ib.length - 24) : ib;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _miniBars('Váha', data.map((e) => e.weightKg).toList(),
              data, 'kg', _brand, null),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _miniBars('Tuk', data.map((e) => e.bodyFatPercent).toList(),
              data, '%', _fatColor, false),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _miniBars('Svaly', data.map((e) => e.smmKg).toList(), data,
              'kg', _brandLight, true),
        ),
      ],
    );
  }

  static pw.Widget _miniBars(
    String title,
    List<double> values,
    List<CoachInbodyEntry> data,
    String unit,
    PdfColor color,
    bool? higherIsBetter,
  ) {
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final floor = minV - math.max((maxV - minV) * 0.8, maxV * 0.02);
    final span = math.max(maxV - floor, 0.1);
    final change = values.last - values.first;
    final first = data.first.date;
    final last = data.last.date;

    return pw.Container(
      padding: pw.EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(fontSize: 8, color: _muted)),
              if (values.length > 1)
                pw.Text(
                  '${_d(change)} $unit',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _deltaColor(change, higherIsBetter, 1),
                  ),
                ),
            ],
          ),
          pw.Text(
            '${_n(values.last)} $unit',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.SizedBox(
            height: 46,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++)
                  pw.Expanded(
                    child: pw.Padding(
                      padding: pw.EdgeInsets.symmetric(
                        horizontal: values.length > 12
                            ? 0.6
                            : values.length <= 3
                                ? 16
                                : 2,
                      ),
                      child: pw.Container(
                        height: 4 + (values[i] - floor) / span * 42,
                        decoration: pw.BoxDecoration(
                          color: i == values.length - 1 ? color : _otherColor,
                          borderRadius: pw.BorderRadius.all(
                            pw.Radius.circular(1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${first.day}.${first.month}.${first.year % 100}',
                  style: pw.TextStyle(fontSize: 6, color: _muted)),
              pw.Text('${last.day}.${last.month}.${last.year % 100}',
                  style: pw.TextStyle(fontSize: 6, color: _muted)),
            ],
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _analysisBlock(InbodyReport r) {
    final widgets = <pw.Widget>[
      _h2('Odborný rozbor posledního měření'),
      pw.Container(
        padding: pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _brandSoft,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              r.bodyType,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _brand,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(r.summary, style: pw.TextStyle(fontSize: 9)),
          ],
        ),
      ),
      pw.SizedBox(height: 8),
    ];

    for (final s in r.sections) {
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.only(top: 4, bottom: 3),
        child: pw.Text(
          s.title,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _muted,
          ),
        ),
      ));
      widgets.add(_table(
        header: null,
        widths: [0.35, 2.1, 1.6, 3.6],
        rows: [
          for (final f in s.findings)
            [
              pw.Container(
                alignment: pw.Alignment.topLeft,
                padding: pw.EdgeInsets.only(top: 6, left: 4),
                child: pw.Container(
                  width: 7,
                  height: 7,
                  decoration: pw.BoxDecoration(
                    color: _statusColor(f.status),
                    shape: pw.BoxShape.circle,
                  ),
                ),
              ),
              _cell(f.title, bold: true),
              _cell(f.value, color: _statusColor(f.status), bold: true),
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(f.explanation, style: pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      f.reference,
                      style: pw.TextStyle(fontSize: 7, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ));
    }

    if (r.targets.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 8));
      widgets.add(_withTitle('Cílová váha při zachování svalů', _table(
        header: ['Cíl', '% tuku', 'Cílová váha', 'Zbývá shodit tuku'],
        widths: [2, 1, 1.2, 1.4],
        rows: [
          for (final t in r.targets)
            [
              _cell(t.label),
              _cell('${_n(t.bodyFatPercent, 0)} %'),
              _cell('${_n(t.weightKg)} kg', bold: true),
              _cell('${_n(t.fatToLoseKg)} kg'),
            ],
        ],
      )));
    }

    widgets.add(pw.SizedBox(height: 10));
    return widgets;
  }

  // =================================================================
  // 2) Obvody
  // =================================================================

  static List<pw.Widget> _circBlock(List<CoachCircumferenceEntry> cs) {
    if (cs.isEmpty) {
      return [_note('V tomto období nejsou změřené obvody.')];
    }
    final a = cs.first;
    final b = cs.last;
    final p = cs.length >= 3 ? cs[cs.length - 2] : null;
    final single = cs.length == 1;

    double v(CoachCircumferenceEntry e, int i) => switch (i) {
          0 => e.neckCm,
          1 => e.chestCm,
          2 => e.armCm,
          3 => e.waistCm,
          4 => e.hipsCm,
          5 => e.thighCm,
          _ => e.calfCm,
        };
    const names = ['Krk', 'Hrudník', 'Paže', 'Pas', 'Boky', 'Stehno', 'Lýtko'];
    final idx = [
      for (var i = 0; i < names.length; i++)
        if (v(a, i) > 0 || v(b, i) > 0) i,
    ];

    return [
      _table(
        header: single
            ? ['Obvod', _fmtDate(b.date)]
            : [
                'Obvod',
                _fmtDate(a.date),
                if (p != null) _fmtDate(p.date),
                _fmtDate(b.date),
                if (p != null) 'Od minula',
                p != null ? 'Celkem' : 'Změna',
              ],
        widths: single
            ? [2, 1]
            : p == null
                ? [2, 1.2, 1.2, 1]
                : [1.6, 1.1, 1.1, 1.1, 1.05, 1.05],
        rows: [
          for (final i in idx)
            single
                ? [_cell(names[i]), _cell('${_n(v(b, i))} cm', bold: true)]
                : _cmpRow(names[i], v(a, i), v(b, i), 'cm',
                    prev: p == null ? null : v(p, i)),
        ],
      ),
      if (!single && a.waistCm > 0 && b.waistCm > 0)
        pw.Padding(
          padding: pw.EdgeInsets.only(top: 4),
          child: pw.Text(
            b.waistCm < a.waistCm
                ? 'Pas se zmenšil o ${_n(a.waistCm - b.waistCm)} cm – '
                    'ubývá tuk v oblasti břicha.'
                : b.waistCm > a.waistCm
                    ? 'Pas se zvětšil o ${_n(b.waistCm - a.waistCm)} cm.'
                    : 'Obvod pasu je beze změny.',
            style: pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ),
      pw.SizedBox(height: 6),
    ];
  }

  // =================================================================
  // 3) Trénink
  // =================================================================

  static List<pw.Widget> _trainingBlock(
    CoachClient client,
    ClientReportExtras extras,
    List<ExercisePerformance> perf,
    DateTime from,
    DateTime to,
  ) {
    final widgets = <pw.Widget>[];
    final plan = extras.activePlan;

    if (plan != null) {
      widgets.add(_kv([
        ('Plán', plan.name),
        if (plan.meetDate != null) ('Datum akce / závodu', _fmtDate(plan.meetDate!)),
        ('Tréninkových dnů v plánu', '${plan.days.length}'),
        if (plan.maxes?.bench1rm != null)
          ('Bench press 1RM', '${_n(plan.maxes!.bench1rm!)} kg'),
        if (plan.maxes?.squat1rm != null)
          ('Dřep 1RM', '${_n(plan.maxes!.squat1rm!)} kg'),
        if (plan.maxes?.deadlift1rm != null)
          ('Mrtvý tah 1RM', '${_n(plan.maxes!.deadlift1rm!)} kg'),
      ]));
      widgets.add(pw.SizedBox(height: 8));
    }

    final sessions = extras.sessions
        .where((s) => s.sets > 0 || s.completed)
        .toList();
    final weeks = math.max(1.0, (to.difference(from).inDays + 1) / 7.0);
    final coachDays = client.completedDays
        .where((d) =>
            !d.isBefore(DateTime(from.year, from.month, from.day)) &&
            !d.isAfter(to))
        .length;

    if (sessions.isEmpty && coachDays == 0) {
      widgets.add(_note('V tomto období nejsou zapsané žádné tréninky.'));
    } else {
      final volume = sessions.fold<double>(0, (a, s) => a + s.volumeKg);
      final sets = sessions.fold<int>(0, (a, s) => a + s.sets);
      final allDays = _trainingDays(client, extras, perf, from, to);
      widgets.add(_kv([
        ('Tréninkové dny celkem', '$allDays'),
        ('Průměrně týdně', '${_n(allDays / weeks)}×'),
        if (coachDays > 0) ('Z toho s trenérem', '$coachDays dní'),
        if (sessions.isNotEmpty) ...[
          ('Tréninky zapsané v aplikaci', '${sessions.length}'),
          ('Odpracované série', '$sets'),
          ('Celkem zvednuto (váha × opakování)',
              '${_thousands(volume.round())} kg'),
        ],
      ]));
      widgets.add(pw.SizedBox(height: 8));

      if (sessions.isNotEmpty) {
        final shown = sessions.length > 12
            ? sessions.sublist(sessions.length - 12)
            : sessions;
        widgets.add(_h2(sessions.length > 12
            ? 'Posledních 12 tréninků'
            : 'Přehled tréninků'));
        widgets.add(_table(
          header: ['Datum', 'Trénink', 'Cviky', 'Série', 'Objem'],
          widths: [1.1, 3, 0.7, 0.7, 1.1],
          rows: [
            for (final s in shown.reversed)
              [
                _cell(_fmtDate(s.date)),
                _cell(s.dayLabel.isEmpty ? '–' : s.dayLabel),
                _cell('${s.exercisesLogged}'),
                _cell('${s.sets}'),
                _cell('${_thousands(s.volumeKg.round())} kg'),
              ],
          ],
        ));
        widgets.add(pw.SizedBox(height: 8));
      }
    }

    // Výkony
    final grouped = <String, List<ExercisePerformance>>{};
    for (final p in perf) {
      final name = p.exerciseName.trim();
      if (name.isEmpty) continue;
      grouped.putIfAbsent(name, () => []).add(p);
    }
    if (grouped.isNotEmpty) {
      final names = grouped.keys.toList()
        ..sort((a, b) => grouped[b]!.length.compareTo(grouped[a]!.length));
      widgets.add(_withTitle('Silový progres', _table(
        header: ['Cvik', 'Začátek', 'Nejlepší', 'Nyní', 'Odhad maxima'],
        widths: [2.4, 1.1, 1.1, 1.1, 1.3],
        rows: [
          for (final name in names.take(10))
            () {
              final list = grouped[name]!
                ..sort((a, b) => a.date.compareTo(b.date));
              final first = list.first;
              final last = list.last;
              final best = list.reduce((a, b) => _e1rm(b) > _e1rm(a) ? b : a);
              final valid = _e1rmValid(last);
              final gain = valid && _e1rmValid(first)
                  ? _e1rm(last) - _e1rm(first)
                  : 0.0;
              return [
                _cell(_exName(name), bold: true),
                _cell(_set(first)),
                _cell(_set(best)),
                _cell(_set(last)),
                _cell(
                  !valid
                      ? '–'
                      : list.length > 1 && _e1rmValid(first)
                          ? '${_n(_e1rm(last), 0)} kg (${_d(gain, 0)})'
                          : '${_n(_e1rm(last), 0)} kg',
                  color: list.length > 1 && gain > 0 ? _good : _ink,
                  bold: true,
                ),
              ];
            }(),
        ],
      )));
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.only(top: 3),
        child: pw.Text(
          'Odhad maxima na 1 opakování (1RM) podle Epleyho vzorce – '
          'ukazuje růst síly, i když zvedáš víc opakování.',
          style: pw.TextStyle(fontSize: 7, color: _muted),
        ),
      ));
    }

    widgets.add(pw.SizedBox(height: 6));
    return widgets;
  }

  static double _e1rm(ExercisePerformance p) =>
      p.reps <= 1 ? p.weight : p.weight * (1 + p.reps / 30);

  static String _set(ExercisePerformance p) => p.weight <= 1
      ? '${p.reps} opak.'
      : '${_n(p.weight)} × ${p.reps}';

  /// Odhad maxima má smysl jen s činkou a do ~12 opakování.
  static bool _e1rmValid(ExercisePerformance p) =>
      p.weight > 1 && p.reps > 0 && p.reps <= 12;

  // =================================================================
  // 4) Strava
  // =================================================================

  static String _planLabel(String plan) {
    switch (plan) {
      case 'Linear':
        return 'Lineární jídelníček';
      case 'Vlny':
        return 'Sacharidové vlny';
      case 'Keto':
        return 'Keto';
      case 'Fasting':
        return 'Přerušovaný půst';
    }
    return ProgramDiets.nameFor(plan) ?? plan;
  }

  static List<pw.Widget> _foodBlock(
    ClientReportExtras extras,
    DateTime from,
    DateTime to,
    bool sensitive,
  ) {
    final widgets = <pw.Widget>[];
    final profile = extras.profile;
    final m = extras.macros;

    if (profile != null) {
      final diet = switch (profile.diet.name) {
        'vegetarian' => 'vegetariánská',
        'vegan' => 'veganská',
        _ => 'bez omezení',
      };
      widgets.add(_kv([
        ('Jídelníček', _planLabel(profile.selectedPlan)),
        ('Strava', diet),
        if (profile.budget) ('Varianta', 'levnější'),
      ]));
      widgets.add(pw.SizedBox(height: 8));
    }

    if (sensitive) {
      widgets.add(_note('Kalorie a makroživiny v tomto souhrnu záměrně '
          'neuvádíme.'));
      return widgets;
    }

    final days = extras.foodDays;
    final periodDays = to.difference(from).inDays + 1;

    if (m != null && days.isEmpty) {
      widgets.add(_kv([
        ('Denní cíl',
            '${m.targetCalories} kcal · B ${m.protein} g · S ${m.carbs} g · '
            'T ${m.fat} g'),
      ]));
      widgets.add(pw.SizedBox(height: 8));
    }

    if (days.isEmpty) {
      widgets.add(_note('V tomto období není zapsané žádné jídlo.'));
      return widgets;
    }

    double avg(int Function(ReportFoodDay d) f) =>
        days.map(f).reduce((a, b) => a + b) / days.length;
    final kcal = avg((d) => d.intake.calories);
    final prot = avg((d) => d.intake.protein);
    final carb = avg((d) => d.intake.carbs);
    final fat = avg((d) => d.intake.fat);

    if (m != null) {
      widgets.add(_withTitle(
        'Skutečný příjem vs. cíl (průměr za zapsané dny)',
        pw.Column(
          children: [
            _macroBar('Energie', kcal, m.targetCalories.toDouble(), 'kcal'),
            _macroBar('Bílkoviny', prot, m.protein.toDouble(), 'g',
                minOnly: true),
            _macroBar('Sacharidy', carb, m.carbs.toDouble(), 'g'),
            _macroBar('Tuky', fat, m.fat.toDouble(), 'g'),
          ],
        ),
      ));
    } else {
      widgets.add(_withTitle('Skutečný příjem (průměr za zapsané dny)', _table(
        header: ['Energie', 'Bílkoviny', 'Sacharidy', 'Tuky'],
        widths: [1, 1, 1, 1],
        rows: [
          [
            _cell('${kcal.round()} kcal', bold: true),
            _cell('${prot.round()} g', bold: true),
            _cell('${carb.round()} g', bold: true),
            _cell('${fat.round()} g', bold: true),
          ],
        ],
      )));
    }
    widgets.add(pw.SizedBox(height: 8));

    final onTarget = m == null
        ? null
        : days
            .where((d) =>
                (d.intake.calories - m.targetCalories).abs() <=
                m.targetCalories * 0.1)
            .length;
    final proteinOk = m == null
        ? null
        : days.where((d) => d.intake.protein >= m.protein * 0.9).length;

    widgets.add(_kv([
      ('Zapsané dny', '${days.length} z $periodDays '
          '(${(days.length / periodDays * 100).round()} %)'),
      if (onTarget != null)
        ('Dny v rozmezí ±10 % kalorií', '$onTarget z ${days.length}'),
      if (proteinOk != null)
        ('Dny s dostatkem bílkovin', '$proteinOk z ${days.length}'),
    ]));

    // Nejčastější jídla
    final counts = <String, int>{};
    for (final d in days) {
      for (final item in d.intake.items) {
        final name = item.name.trim();
        if (name.isEmpty) continue;
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    if (counts.isNotEmpty) {
      final top = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      widgets.add(pw.SizedBox(height: 8));
      widgets.add(_withTitle('Nejčastější potraviny', pw.Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final e in top.take(12))
            pw.Container(
              padding:
                  pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: pw.BoxDecoration(
                color: _soft,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Text(
                '${_clean(e.key)} (${e.value}×)',
                style: pw.TextStyle(fontSize: 8),
              ),
            ),
        ],
      )));
    }

    widgets.add(pw.SizedBox(height: 6));
    return widgets;
  }

  static pw.Widget _macroBar(
    String label,
    double actual,
    double target,
    String unit, {
    bool minOnly = false,
  }) {
    if (target <= 0) return pw.SizedBox();
    final pct = actual / target * 100;
    final ok = minOnly ? pct >= 90 : (pct >= 90 && pct <= 110);
    final close = minOnly ? pct >= 75 : (pct >= 80 && pct <= 120);
    final color = ok ? _good : (close ? _warn : _bad);
    const scale = 130.0; // osa do 130 % cíle
    final filled = (math.min(pct, scale) / scale * 1000).round();
    final targetPos = (100 / scale * 1000).round();

    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 62,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Stack(
              alignment: pw.Alignment.centerLeft,
              children: [
                pw.Container(
                  height: 10,
                  decoration: pw.BoxDecoration(
                    color: _soft,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                ),
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: math.max(filled, 1),
                      child: pw.Container(
                        height: 10,
                        decoration: pw.BoxDecoration(
                          color: color,
                          borderRadius:
                              pw.BorderRadius.all(pw.Radius.circular(5)),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: math.max(1000 - filled, 1),
                      child: pw.SizedBox(height: 10),
                    ),
                  ],
                ),
                // značka cíle (100 %)
                pw.Row(
                  children: [
                    pw.Expanded(flex: targetPos, child: pw.SizedBox(height: 14)),
                    pw.Container(width: 1.2, height: 14, color: _ink),
                    pw.Expanded(
                      flex: 1000 - targetPos,
                      child: pw.SizedBox(height: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.SizedBox(
            width: 120,
            child: pw.RichText(
              textAlign: pw.TextAlign.right,
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: '${actual.round()} / ${target.round()} $unit  ',
                    style: pw.TextStyle(fontSize: 8, color: _muted),
                  ),
                  pw.TextSpan(
                    text: '${pct.round()} %',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =================================================================
  // 5) Cíl
  // =================================================================

  static String _goalTypeLabel(GoalType t) => switch (t) {
        GoalType.strength => 'Síla',
        GoalType.physique => 'Postava',
        GoalType.weightLoss => 'Hubnutí',
        GoalType.endurance => 'Vytrvalost',
        GoalType.weightGainSupport => 'Podpora nabírání',
      };

  static List<pw.Widget> _goalBlock(
    ClientReportExtras extras,
    List<CoachInbodyEntry> ib,
    bool sensitive,
  ) {
    final goal = extras.profile?.goal;
    final cg = extras.coachGoal;
    final items = <(String, String)>[];

    if (goal != null) {
      items.add(('Cíl', _goalTypeLabel(goal.type)));
      final daysLeft = goal.targetDate.difference(DateTime.now()).inDays;
      items.add((
        'Termín',
        '${_fmtDate(goal.targetDate)}'
            '${daysLeft > 0 ? ' (zbývá $daysLeft dní)' : ''}',
      ));
      if (!sensitive && goal.targetWeightKg != null) {
        final tw = goal.targetWeightKg!;
        final now = ib.isNotEmpty ? ib.last.weightKg : null;
        items.add((
          'Cílová váha',
          now == null
              ? '${_n(tw)} kg'
              : '${_n(tw)} kg (zbývá ${_d(tw - now)} kg)',
        ));
      }
    }
    if (cg != null) {
      if (cg.goalDetail.trim().isNotEmpty) {
        items.add(('Zadání od trenéra', cg.goalDetail.trim()));
      }
      if (!sensitive && cg.targetBodyFatPercent != null) {
        items.add(('Cílové % tuku', '${_n(cg.targetBodyFatPercent!)} %'));
      }
      if (cg.note.trim().isNotEmpty) {
        items.add(('Poznámka', cg.note.trim()));
      }
    }

    if (items.isEmpty) {
      return [_note('Cíl zatím není nastavený.'), pw.SizedBox(height: 6)];
    }
    return [_kv(items), pw.SizedBox(height: 8)];
  }

  static List<pw.Widget> _actionPlanBlock(List<CoachActionGroup> groups) {
    if (groups.isEmpty) return [];
    var n = 0;
    final widgets = <pw.Widget>[_h2('Akční plán na další období')];
    for (final g in groups) {
      widgets.add(pw.Container(
        margin: pw.EdgeInsets.only(top: 4, bottom: 4),
        padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: pw.BoxDecoration(
          color: _brandSoft,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(
          g.title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _brand,
            letterSpacing: 1,
          ),
        ),
      ));
      for (final a in g.actions) {
        n++;
        widgets.add(pw.Padding(
          padding: pw.EdgeInsets.only(bottom: 6, left: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 15,
                height: 15,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: _brand,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Text(
                  '$n',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(width: 7),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _clean(a.headline),
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      _clean(a.detail),
                      style: pw.TextStyle(fontSize: 8.5, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
      }
    }
    widgets.add(pw.SizedBox(height: 6));
    return widgets;
  }

  /// Akční plán pro obrazovku klienta – stejná logika jako v PDF.
  static List<CoachActionGroup> actionPlan({
    required CoachClient client,
    required ClientReportExtras extras,
    required List<CoachInbodyEntry> inbody,
    required List<ExercisePerformance> performances,
    required DateTime from,
    required DateTime to,
  }) {
    final ib = [...inbody]..sort((a, b) => a.date.compareTo(b.date));
    final perf = [...performances]..sort((a, b) => a.date.compareTo(b.date));
    final sensitive = client.isEatingDisorderSupport;
    final report = !sensitive && ib.isNotEmpty
        ? InbodyAnalysis.analyze(
            latest: ib.last,
            previous: ib.length > 1 ? ib[ib.length - 2] : null,
            gender: client.gender,
            age: client.age,
          )
        : null;
    return _actionPlan(client, extras, ib, perf, report, from, to, sensitive);
  }

  static List<CoachActionGroup> _actionPlan(
    CoachClient client,
    ClientReportExtras extras,
    List<CoachInbodyEntry> ib,
    List<ExercisePerformance> perf,
    InbodyReport? report,
    DateTime from,
    DateTime to,
    bool sensitive,
  ) {
    final m = extras.macros;
    final days = extras.foodDays;
    double? avg(int Function(ReportFoodDay d) f) => days.isEmpty
        ? null
        : days.map(f).reduce((a, b) => a + b) / days.length;

    final weeks = math.max(1.0, (to.difference(from).inDays + 1) / 7.0);
    final trainingDays = _trainingDays(client, extras, perf, from, to);

    // Cviky bez zlepšení (aspoň 3 záznamy, odhad 1RM nevzrostl o 1 %)
    final grouped = <String, List<ExercisePerformance>>{};
    for (final p in perf) {
      if (p.exerciseName.trim().isEmpty) continue;
      grouped.putIfAbsent(p.exerciseName.trim(), () => []).add(p);
    }
    final stagnating = <String>[
      for (final e in grouped.entries)
        if (e.value.length >= 3)
          if (() {
            final l = [...e.value]..sort((a, b) => a.date.compareTo(b.date));
            return _e1rmValid(l.first) &&
                _e1rmValid(l.last) &&
                _e1rm(l.last) <= _e1rm(l.first) * 1.01;
          }())
            _exName(e.key),
    ];

    final plan = extras.activePlan;
    final goal = extras.profile?.goal;

    return CoachRecommendations.build(CoachPlanInput(
      gender: client.gender,
      age: client.age,
      weightKg: ib.isNotEmpty ? ib.last.weightKg : client.weightKg,
      goalType: goal?.type,
      goalDate: goal?.targetDate,
      body: report?.flags,
      targetKcal: m?.targetCalories,
      targetProtein: m?.protein,
      targetCarbs: m?.carbs,
      targetFat: m?.fat,
      avgKcal: avg((d) => d.intake.calories),
      avgProtein: avg((d) => d.intake.protein),
      avgCarbs: avg((d) => d.intake.carbs),
      avgFat: avg((d) => d.intake.fat),
      loggedDays: days.length,
      periodDays: to.difference(from).inDays + 1,
      trainingsPerWeek: trainingDays / weeks,
      hasTrainingData: trainingDays > 0,
      planType: plan?.type,
      eventDate: plan?.meetDate ?? goal?.targetDate,
      stagnatingLifts: stagnating,
      sensitive: sensitive,
    ));
  }

  /// Počet různých tréninkových dnů v období: zapsané tréninky, zapsané
  /// výkony a dny odškrtnuté trenérem.
  static int _trainingDays(
    CoachClient client,
    ClientReportExtras extras,
    List<ExercisePerformance> perf,
    DateTime from,
    DateTime to,
  ) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
    bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);
    String key(DateTime d) => '${d.year}-${d.month}-${d.day}';
    return {
      for (final s in extras.sessions)
        if (s.sets > 0 || s.completed) key(s.date),
      for (final p in perf)
        if (inRange(p.date)) key(p.date),
      for (final d in client.completedDays)
        if (inRange(d)) key(d),
    }.length;
  }

  /// Čitelný název cviku (id z databáze cviků → český název).
  static String _exName(String raw) {
    for (final e in ExerciseDB.all) {
      if (e.id == raw) return e.displayName;
    }
    if (!raw.contains('_')) return raw;
    final s = raw.replaceAll('_', ' ');
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Odstraní emoji a znaky, které písmo v PDF neumí vykreslit.
  static String _clean(String s) {
    final out = StringBuffer();
    for (final r in s.runes) {
      final emoji = r > 0xFFFF ||
          (r >= 0x2600 && r <= 0x27BF) ||
          (r >= 0x2B00 && r <= 0x2BFF) ||
          r == 0xFE0F ||
          r == 0x200D;
      if (!emoji) out.writeCharCode(r);
    }
    return out.toString().trim();
  }

  // =================================================================
  // Shrnutí a poznámky
  // =================================================================

  /// Co se za období povedlo – krátké, konkrétní věty s čísly.
  static List<String> _wins(
    CoachClient client,
    List<CoachInbodyEntry> ib,
    List<CoachCircumferenceEntry> cs,
    ClientReportExtras extras,
    List<ExercisePerformance> perf,
    DateTime from,
    DateTime to,
    bool sensitive,
  ) {
    final wins = <String>[];

    if (!sensitive && ib.length > 1) {
      final a = ib.first;
      final b = ib.last;
      final dF = b.fatKg - a.fatKg;
      final dM = b.smmKg - a.smmKg;
      if (dF <= -0.3) wins.add('Ubylo ${_n(-dF)} kg čistého tuku');
      if (dM >= 0.2) wins.add('Přibylo ${_n(dM)} kg svalů');
      final dBf = b.bodyFatPercent - a.bodyFatPercent;
      if (dBf <= -0.5) wins.add('Podíl tuku klesl o ${_n(-dBf)} %');
    }
    if (!sensitive && cs.length > 1) {
      final dw = cs.first.waistCm - cs.last.waistCm;
      if (dw >= 0.5) wins.add('Pas se zmenšil o ${_n(dw)} cm');
    }

    // Síla: největší nárůst odhadu maxima
    final grouped = <String, List<ExercisePerformance>>{};
    for (final p in perf) {
      if (p.exerciseName.trim().isEmpty) continue;
      grouped.putIfAbsent(p.exerciseName.trim(), () => []).add(p);
    }
    String? bestLift;
    var bestGain = 0.0;
    for (final e in grouped.entries) {
      if (e.value.length < 2) continue;
      final l = [...e.value]..sort((a, b) => a.date.compareTo(b.date));
      if (!_e1rmValid(l.first) || !_e1rmValid(l.last)) continue;
      final gain = _e1rm(l.last) - _e1rm(l.first);
      if (gain > bestGain) {
        bestGain = gain;
        bestLift = e.key;
      }
    }
    if (bestLift != null && bestGain >= 2.5) {
      wins.add('Síla roste – ${_exName(bestLift)} +${_n(bestGain, 0)} kg '
          'na odhadu maxima');
    }

    final weeks = math.max(1.0, (to.difference(from).inDays + 1) / 7.0);
    final perWeek = _trainingDays(client, extras, perf, from, to) / weeks;
    if (perWeek >= 2) {
      wins.add('Pravidelný trénink – v průměru ${_n(perWeek)}× týdně');
    }

    final m = extras.macros;
    final days = extras.foodDays;
    if (!sensitive && m != null && days.isNotEmpty) {
      double avg(int Function(ReportFoodDay d) f) =>
          days.map(f).reduce((a, b) => a + b) / days.length;
      final kcalPct = avg((d) => d.intake.calories) / m.targetCalories * 100;
      final protPct = avg((d) => d.intake.protein) / m.protein * 100;
      if ((kcalPct - 100).abs() <= 10) {
        wins.add('Kalorie odpovídají plánu (${kcalPct.round()} % cíle)');
      }
      if (protPct >= 90) {
        wins.add('Bílkoviny máš pod kontrolou (${protPct.round()} % cíle)');
      }
    }

    return wins;
  }

  /// Úvodní slovo – lidsky, bez tabulek.
  static pw.Widget _intro(int days, List<String> wins) {
    final text = wins.isEmpty
        ? 'Tohle je tvůj výchozí bod. Na dalších stránkách najdeš podrobný '
            'rozbor postavy, tréninku a stravy – a na konci konkrétní plán '
            'prvních kroků. Od příštího měření už uvidíme, jak se posouváš.'
        : 'Za posledních $days dní máš za sebou kus poctivé práce a je to '
            'vidět: ${wins.first.toLowerCase()}. Na dalších stránkách najdeš '
            'podrobný rozbor postavy, tréninku a stravy – a na konci '
            'konkrétní plán, jak pokračovat dál.';
    return pw.Container(
      padding: pw.EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: pw.BoxDecoration(
        color: _brandSoft,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9.5, color: _ink, lineSpacing: 2),
      ),
    );
  }

  static pw.Widget _summaryBlock(
    List<String> wins,
    List<CoachActionGroup> actions,
  ) {
    final focus = actions
        .expand((g) => g.actions)
        .map((a) => a.headline)
        .take(3)
        .toList();

    pw.Widget column(
      String title,
      PdfColor color,
      String mark,
      List<String> lines,
      String empty,
    ) {
      return pw.Expanded(
        child: pw.Container(
          padding: pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: color, width: 1),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
              pw.SizedBox(height: 6),
              if (lines.isEmpty)
                pw.Text(empty,
                    style: pw.TextStyle(fontSize: 9, color: _muted)),
              for (var k = 0; k < lines.length; k++)
                pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 12,
                        height: 12,
                        alignment: pw.Alignment.center,
                        margin: pw.EdgeInsets.only(right: 6),
                        decoration: pw.BoxDecoration(
                          color: color,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Text(
                          mark == '#' ? '${k + 1}' : mark,
                          style: pw.TextStyle(
                            fontSize: 7,
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          _clean(lines[k]),
                          style: pw.TextStyle(fontSize: 9),
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

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        column('Co se povedlo', _good, '+', wins.take(5).toList(),
            'Tohle je vstupní období – úspěchy začneme sbírat od teď.'),
        pw.SizedBox(width: 10),
        column('Na čem zapracujeme', _brand, '#', focus,
            'Drž současný režim – jde to dobře.'),
      ],
    );
  }

  static pw.Widget _coachNotesBox() {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Poznámky trenéra',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          for (var i = 0; i < 4; i++)
            pw.Container(
              height: 20,
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: _line, width: 0.6),
                ),
              ),
            ),
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Podpis trenéra: ....................................',
                style: pw.TextStyle(fontSize: 8, color: _muted),
              ),
              pw.Text(
                'Další měření: ....................',
                style: pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =================================================================
  // Stavební prvky
  // =================================================================

  static pw.Widget _h1(String number, String title) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 8),
      padding: pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _brand, width: 1.2)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 20,
            height: 20,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: _brand,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Text(
              number,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  /// Nadpis a obsah na stejné stránce (nadpis nezůstane osiřelý dole).
  static pw.Widget _withTitle(String title, pw.Widget child) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [_h2(title), child],
      ),
    );
  }

  static pw.Widget _h2(String title) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
    );
  }

  static pw.Widget _note(String text) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, color: _muted)),
    );
  }

  static pw.Widget _cell(String text, {PdfColor? color, bool bold = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(
        _clean(text),
        style: pw.TextStyle(
          fontSize: 8.5,
          color: color ?? _ink,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _table({
    required List<String>? header,
    required List<double> widths,
    required List<List<pw.Widget>> rows,
  }) {
    return pw.Table(
      columnWidths: {
        for (var i = 0; i < widths.length; i++) i: pw.FlexColumnWidth(widths[i]),
      },
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _line, width: 0.5),
        bottom: pw.BorderSide(color: _line, width: 0.5),
      ),
      children: [
        if (header != null)
          pw.TableRow(
            decoration: pw.BoxDecoration(color: _soft),
            children: [
              for (final h in header)
                pw.Padding(
                  padding:
                      pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _muted,
                    ),
                  ),
                ),
            ],
          ),
        for (final r in rows) pw.TableRow(children: r),
      ],
    );
  }

  static pw.Widget _kv(List<(String, String)> items) {
    return _table(
      header: null,
      widths: [1.6, 3],
      rows: [
        for (final i in items)
          [
            _cell(i.$1, color: _muted),
            _cell(i.$2, bold: true),
          ],
      ],
    );
  }

  static PdfColor _statusColor(InbodyStatus s) => switch (s) {
        InbodyStatus.good => _good,
        InbodyStatus.ok => _ok,
        InbodyStatus.warn => _warn,
        InbodyStatus.bad => _bad,
        InbodyStatus.info => _muted,
      };

  static String _n(double v, [int digits = 1]) =>
      v.toStringAsFixed(digits).replaceAll('.', ',');

  static String _d(double v, [int digits = 1]) {
    final r = double.parse(v.toStringAsFixed(digits));
    if (r == 0) return _n(0, digits);
    return '${r > 0 ? '+' : '−'}${_n(r.abs(), digits)}';
  }

  static String _thousands(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
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

  static String _genderLabel(String g) {
    switch (g.toLowerCase()) {
      case 'male':
        return 'Muž';
      case 'female':
        return 'Žena';
      default:
        return 'Neuvedeno';
    }
  }
}
