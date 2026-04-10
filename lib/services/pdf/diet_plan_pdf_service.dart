import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/diet_plans/models/carb_cycling_plan.dart';

class DietPlanPdfService {
  static Future<Uint8List> buildPdf(DietMealPlan plan) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          final shopping = plan.buildShoppingList();

          return [
            pw.Text(
              _title(plan),
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if ((plan.note ?? '').isNotEmpty)
              pw.Text(
                plan.note!,
                style: const pw.TextStyle(fontSize: 10),
              ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _macroBox('Bílkoviny', '${plan.protein.round()} g'),
                  _macroBox('Sacharidy', '${plan.carbs.round()} g'),
                  _macroBox('Tuky', '${plan.fats.round()} g'),
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
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Text(
                  '${day.dayName} • B ${day.protein.round()} g • S ${day.carbs.round()} g • T ${day.fats.round()} g',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              for (final meal in day.meals)
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        meal.time != null
                            ? '${meal.time} • ${meal.label}: ${meal.name}'
                            : '${meal.label}: ${meal.name}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        meal.description,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      if (meal.ingredients.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Ingredience: ${meal.ingredients.map((e) => '${e.name} (${e.formattedAmount})').join(', ')}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ],
                  ),
                ),
              pw.SizedBox(height: 6),
            ],
            pw.SizedBox(height: 16),
            pw.Text(
              'Nákupní seznam',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: shopping
                  .map(
                    (item) => pw.Container(
                      width: 240,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Text(
                        '${item.name}: ${item.formattedAmount}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printPlan(DietMealPlan plan) async {
    await Printing.layoutPdf(
      onLayout: (_) => buildPdf(plan),
      name: _safeFileName(plan),
    );
  }

  static Future<void> sharePlan(DietMealPlan plan) async {
    final bytes = await buildPdf(plan);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${_safeFileName(plan)}.pdf',
    );
  }

  static pw.Widget _macroBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static String _title(DietMealPlan plan) {
    switch (plan.planType.toLowerCase()) {
      case 'keto':
        return 'Keto jídelníček';
      case 'fasting':
        return 'Fasting jídelníček';
      case 'linear':
        return 'Linear jídelníček';
      default:
        return 'Týdenní meal plan';
    }
  }

  static String _safeFileName(DietMealPlan plan) {
    final type = plan.planType.toLowerCase().replaceAll(' ', '-');
    return 'meal-plan-$type';
    }
}