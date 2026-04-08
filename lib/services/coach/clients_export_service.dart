import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/coach/coach_client.dart';

class ClientsExportService {
  const ClientsExportService._();

  static List<CoachClient> _sorted(List<CoachClient> clients) {
    final copy = [...clients];
    copy.sort((a, b) {
      final aName = '${a.firstName} ${a.lastName}'.toLowerCase().trim();
      final bName = '${b.firstName} ${b.lastName}'.toLowerCase().trim();
      return aName.compareTo(bName);
    });
    return copy;
  }

  static String buildEmailsString(List<CoachClient> clients) {
    final emails = _sorted(clients)
        .map((c) => c.email.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    return emails.join('; ');
  }

  static Future<void> copyEmails(List<CoachClient> clients) async {
    final text = buildEmailsString(clients);
    await Clipboard.setData(ClipboardData(text: text));
  }

  static String _csvEscape(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static Future<String?> exportClientsCsv(List<CoachClient> clients) async {
    final sorted = _sorted(clients);

    final buffer = StringBuffer();
    buffer.writeln(
      '${_csvEscape('Jméno')};${_csvEscape('Příjmení')};${_csvEscape('Email')}',
    );

    for (final client in sorted) {
      buffer.writeln([
        _csvEscape(client.firstName),
        _csvEscape(client.lastName),
        _csvEscape(client.email),
      ].join(';'));
    }

    final location = await getSaveLocation(
      suggestedName: 'seznam_klientu.csv',
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'CSV',
          extensions: ['csv'],
        ),
      ],
    );

    if (location == null) return null;

    final file = File(location.path);

    final bom = [0xEF, 0xBB, 0xBF];
    final encoded = utf8.encode(buffer.toString());

    await file.writeAsBytes(
      [...bom, ...encoded],
      flush: true,
    );

    return file.path;
  }

  static Future<void> exportClientsPdf(List<CoachClient> clients) async {
    final sorted = _sorted(clients);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Seznam klientů',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const ['Jméno', 'Příjmení', 'Email'],
            data: sorted
                .map(
                  (c) => [
                    c.firstName,
                    c.lastName,
                    c.email,
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            border: pw.TableBorder.all(
              color: PdfColors.grey500,
              width: 0.5,
            ),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'seznam_klientu.pdf',
      onLayout: (format) async => pdf.save(),
    );
  }
}