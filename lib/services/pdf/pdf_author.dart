import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

/// Podpis a právní upozornění na tištěných plánech (jídelníčky,
/// tréninkové plány, souhrny).
class PdfAuthor {
  PdfAuthor._();

  static const _key = 'pdf_author_line';

  /// Krátké upozornění do patičky každé stránky.
  static const footerNote =
      'Nejde o lékařské doporučení ani léčbu.';

  /// Plné upozornění na konec dokumentu.
  static const disclaimer =
      'Tento plán sestavil/a osobní trenér/ka a výživový poradce na základě '
      'údajů, které klient sám uvedl. Nejde o lékařskou ani nutričně '
      'terapeutickou péči a plán nenahrazuje vyšetření, diagnózu ani léčbu. '
      'Máte-li zdravotní potíže nebo onemocnění (např. cukrovku, onemocnění '
      'srdce, ledvin, jater či štítné žlázy), alergii, poruchu příjmu potravy, '
      'jste těhotná nebo kojíte či užíváte léky, poraďte se před změnou '
      'stravy nebo zahájením tréninku s lékařem. Při bolesti, závrati, '
      'dušnosti nebo jiných potížích cvičení ihned přerušte a vyhledejte '
      'lékaře. Plán dodržujete dobrovolně a na vlastní odpovědnost.';

  /// Uložený podpis („Martina Šmejkalová – osobní trenérka a výživová
  /// poradkyně“). Bez uloženého podpisu se použije jméno trenéra
  /// z nastavení trenérského režimu. `null` = podpis se netiskne.
  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key)?.trim() ?? '';
    if (saved.isNotEmpty) return saved;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    final name =
        prefs.getString('coach_setup_${uid}_coach_first_name')?.trim() ?? '';
    return name.isEmpty ? null : name;
  }

  /// Jen to, co trenér sám uložil (pro formulář v nastavení).
  static Future<String> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key)?.trim() ?? '';
  }

  static Future<void> save(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final v = value.trim();
    if (v.isEmpty) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, v);
    }
  }

  /// Písma s českou diakritikou přibalená v aplikaci.
  static Future<pw.ThemeData> theme() async {
    final regular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final bold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    return pw.ThemeData.withFont(base: regular, bold: bold);
  }

  static String _date(DateTime d) => '${d.day}. ${d.month}. ${d.year}';

  /// Text do patičky stránky.
  static String footerText(String? author) => author == null
      ? 'Vytvořeno aplikací Chytrý trenér · $footerNote'
      : 'Vypracoval/a: $author · $footerNote';

  /// Blok na konec dokumentu: kdo plán vypracoval + upozornění.
  static pw.Widget signatureBlock(String? author, {DateTime? date}) {
    const muted = PdfColor.fromInt(0xFF5B6470);
    const line = PdfColor.fromInt(0xFFD5D9DE);
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 18),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: line),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (author != null) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Vypracoval/a: $author',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _date(date ?? DateTime.now()),
                  style: const pw.TextStyle(fontSize: 9, color: muted),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
          ],
          pw.Text(
            'Důležité upozornění',
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: muted,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            disclaimer,
            style: const pw.TextStyle(fontSize: 8, color: muted),
          ),
        ],
      ),
    );
  }
}
