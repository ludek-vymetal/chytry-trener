import 'dart:typed_data';


import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/diet_plans/models/carb_cycling_plan.dart';
import '../../l10n/app_localizations.dart';

class DietPlanPdfService {
  static Future<Uint8List> buildPdf(
    DietMealPlan plan,
    AppLocalizations l10n, {
    String? trainerNote,
    String? documentTitle,
    String? subtitle,
  }) async {
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final pdf = pw.Document();

    final nextCheck = DateTime.now().add(
      const Duration(days: 30),
    );

    final baseStyle = pw.TextStyle(
      font: regularFont,
      fontSize: 10,
    );

    final boldStyle = pw.TextStyle(
      font: boldFont,
    );

    final normalizedSubtitle = subtitle?.trim();
    final normalizedNote = plan.note?.trim();

    final hasSubtitle =
        normalizedSubtitle != null &&
        normalizedSubtitle.isNotEmpty;

    final hasPlanNote =
        normalizedNote != null &&
        normalizedNote.isNotEmpty;

    final shouldShowPlanNote =
        hasPlanNote &&
        normalizedNote != normalizedSubtitle;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),

        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),

        build: (context) {
          final shopping = plan.buildShoppingList();

          return [
            pw.Text(
              documentTitle ?? _title(plan, l10n),
              style: baseStyle.copyWith(
                font: boldFont,
                fontSize: 22,
              ),
            ),

            if (hasSubtitle) ...[
              pw.SizedBox(height: 6),

              pw.Text(
                normalizedSubtitle,
                style: baseStyle,
              ),
            ],

            if (shouldShowPlanNote) ...[
              pw.SizedBox(height: 8),

              pw.Text(
                normalizedNote,
                style: baseStyle,
              ),
            ],

            pw.SizedBox(height: 12),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),

              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.grey400,
                ),

                borderRadius: const pw.BorderRadius.all(
                  pw.Radius.circular(8),
                ),
              ),

              child: pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceAround,

                children: [
                  _macroBox(
                    l10n.protein,
                    '${plan.protein.round()} g',
                    baseStyle,
                    boldStyle,
                  ),

                  _macroBox(
                    l10n.carbs,
                    '${plan.carbs.round()} g',
                    baseStyle,
                    boldStyle,
                  ),

                  _macroBox(
                    l10n.fat,
                    '${plan.fats.round()} g',
                    baseStyle,
                    boldStyle,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            for (final day in plan.days) ...[
              pw.Container(
                width: double.infinity,

                padding: const pw.EdgeInsets.all(10),

                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,

                  borderRadius:
                      const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                ),

                child: pw.Text(
                  '${day.dayName} • '
                  '${l10n.proteinShort} ${day.protein.round()} g • '
                  '${l10n.carbsShort} ${day.carbs.round()} g • '
                  '${l10n.fatShort} ${day.fats.round()} g',

                  style: baseStyle.copyWith(
                    font: boldFont,
                    fontSize: 12,
                  ),
                ),
              ),

              pw.SizedBox(height: 8),

              for (final meal in day.meals)
                pw.Container(
                  margin: const pw.EdgeInsets.only(
                    bottom: 8,
                  ),

                  padding: const pw.EdgeInsets.all(10),

                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColors.grey300,
                    ),

                    borderRadius:
                        const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                  ),

                  child: pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,

                    children: [
                      pw.Text(
                        meal.time != null
                            ? '${meal.time} • '
                                '${meal.label}: '
                                '${meal.name}'
                            : '${meal.label}: '
                                '${meal.name}',

                        style: baseStyle.copyWith(
                          font: boldFont,
                          fontSize: 11,
                        ),
                      ),

                      pw.SizedBox(height: 4),

                      pw.Text(
                        meal.description,
                        style: baseStyle,
                      ),

                      if (meal.ingredients.isNotEmpty) ...[
                        pw.SizedBox(height: 4),

                        pw.Text(
                          '${l10n.ingredients}: '
                          '${meal.ingredients.map(
                            (e) =>
                                '${e.name} '
                                '(${e.formattedAmount})',
                          ).join(', ')}',

                          style: baseStyle.copyWith(
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              pw.SizedBox(height: 6),
            ],

            pw.SizedBox(height: 16),

            pw.Text(
              l10n.shoppingList,
              style: baseStyle.copyWith(
                font: boldFont,
                fontSize: 16,
              ),
            ),

            pw.SizedBox(height: 8),

            if (shopping.isEmpty)
              pw.Text(
                l10n.shoppingListEmpty,
                style: baseStyle,
              )
            else
              pw.Wrap(
                spacing: 10,
                runSpacing: 10,

                children: shopping
                    .map(
                      (item) => pw.Container(
                        width: 240,

                        padding:
                            const pw.EdgeInsets.all(8),

                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey300,
                          ),

                          borderRadius:
                              const pw.BorderRadius.all(
                            pw.Radius.circular(6),
                          ),
                        ),

                        child: pw.Text(
                          '${item.name}: '
                          '${item.formattedAmount}',

                          style: baseStyle,
                        ),
                      ),
                    )
                    .toList(),
              ),

            pw.SizedBox(height: 18),

            pw.Text(
              l10n.trainerRecommendation,
              style: baseStyle.copyWith(
                font: boldFont,
                fontSize: 16,
              ),
            ),

            pw.SizedBox(height: 8),

            pw.Text(
              (trainerNote == null ||
                      trainerNote.trim().isEmpty)
                  ? '${l10n.followPlanFor4Weeks} '
                      '${l10n.nextCheckAndWeight} '
                      '${_fmtDate(nextCheck)}.'
                  : trainerNote.trim(),

              style: baseStyle,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printPlan(
    DietMealPlan plan,
    AppLocalizations l10n, {
    String? trainerNote,
    String? documentTitle,
    String? subtitle,
  }) async {
    await Printing.layoutPdf(
      onLayout: (_) => buildPdf(
        plan,
        l10n,
        trainerNote: trainerNote,
        documentTitle: documentTitle,
        subtitle: subtitle,
      ),

      name: _safeFileName(plan),
    );
  }

  static Future<void> sharePlan(
    DietMealPlan plan,
    AppLocalizations l10n, {
    String? trainerNote,
    String? documentTitle,
    String? subtitle,
  }) async {
    final bytes = await buildPdf(
      plan,
      l10n,
      trainerNote: trainerNote,
      documentTitle: documentTitle,
      subtitle: subtitle,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename:
          '${_safeFileName(plan)}.pdf',
    );
  }

  static pw.Widget _macroBox(
    String label,
    String value,
    pw.TextStyle baseStyle,
    pw.TextStyle boldStyle,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: baseStyle,
        ),

        pw.Text(
          value,
          style: baseStyle.copyWith(
            font: boldStyle.font,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  static String _title(
    DietMealPlan plan,
    AppLocalizations l10n,
  ) {
    switch (plan.planType.toLowerCase()) {
      case 'keto':
        return l10n.ketoMealPlan;

      case 'fasting':
        return l10n.fastingMealPlan;

      case 'linear':
        return l10n.linearMealPlan;

      default:
        return l10n.mealPlan;
    }
  }

  static String _safeFileName(
    DietMealPlan plan,
  ) {
    final type = plan.planType
        .toLowerCase()
        .replaceAll(' ', '-');

    return 'meal-plan-$type';
  }

  static String _fmtDate(
    DateTime d,
  ) {
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${d.year}';
  }
}