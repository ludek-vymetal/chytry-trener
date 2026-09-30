import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

/// Kontakty a logo trenéra na dokumentech.
class PdfBrand {
  final String phone;
  final String email;
  final String instagram;
  final String web;
  final Uint8List? logo;

  const PdfBrand({
    this.phone = '',
    this.email = '',
    this.instagram = '',
    this.web = '',
    this.logo,
  });

  bool get hasContacts =>
      phone.isNotEmpty || email.isNotEmpty || instagram.isNotEmpty ||
      web.isNotEmpty;

  bool get isEmpty => !hasContacts && logo == null;

  /// „tel. 777 123 456 · martina@… · IG @… · web“
  String get contactLine => [
        if (phone.isNotEmpty) 'tel. $phone',
        if (email.isNotEmpty) email,
        if (instagram.isNotEmpty)
          'IG ${instagram.startsWith('@') ? instagram : '@$instagram'}',
        if (web.isNotEmpty) web,
      ].join(' · ');
}

/// Podpis a právní upozornění na tištěných plánech (jídelníčky,
/// tréninkové plány, souhrny).
class PdfAuthor {
  PdfAuthor._();

  static const _key = 'pdf_author_line';

  /// Klíče kontaktů a loga (zálohují se s ostatními daty trenéra).
  static const phoneKey = 'pdf_contact_phone';
  static const emailKey = 'pdf_contact_email';
  static const instagramKey = 'pdf_contact_instagram';
  static const webKey = 'pdf_contact_web';
  static const logoKey = 'pdf_logo_b64';

  /// Maximální velikost loga (aby PDF i záloha zůstaly malé).
  static const maxLogoBytes = 1500 * 1024;

  /// Značka načtená při posledním [load] – používají ji hlavičky
  /// a podpis ve všech PDF.
  static PdfBrand brand = const PdfBrand();

  static Future<PdfBrand> loadBrand() async {
    final prefs = await SharedPreferences.getInstance();
    String s(String k) => prefs.getString(k)?.trim() ?? '';
    Uint8List? logo;
    final b64 = prefs.getString(logoKey);
    if (b64 != null && b64.isNotEmpty) {
      try {
        logo = base64Decode(b64);
      } catch (_) {}
    }
    brand = PdfBrand(
      phone: s(phoneKey),
      email: s(emailKey),
      instagram: s(instagramKey),
      web: s(webKey),
      logo: logo,
    );
    return brand;
  }

  static Future<void> saveBrand({
    required String phone,
    required String email,
    required String instagram,
    required String web,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    Future<void> put(String k, String v) async {
      final t = v.trim();
      if (t.isEmpty) {
        await prefs.remove(k);
      } else {
        await prefs.setString(k, t);
      }
    }

    await put(phoneKey, phone);
    await put(emailKey, email);
    await put(instagramKey, instagram);
    await put(webKey, web);
    await loadBrand();
  }

  static Future<void> saveLogo(Uint8List? bytes) async {
    final prefs = await SharedPreferences.getInstance();
    if (bytes == null || bytes.isEmpty) {
      await prefs.remove(logoKey);
    } else {
      await prefs.setString(logoKey, base64Encode(bytes));
    }
    await loadBrand();
  }

  /// Hlavička stránky: logo vlevo, kontakty vpravo. Bez loga a kontaktů
  /// nic nezabere.
  static pw.Widget brandHeader() {
    final b = brand;
    if (b.isEmpty) return pw.SizedBox();
    const muted = PdfColor.fromInt(0xFF5B6470);
    const line = PdfColor.fromInt(0xFFD5D9DE);
    final logo = b.logo;
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: line, width: 0.6)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Container(
              height: 30,
              constraints: const pw.BoxConstraints(maxWidth: 120),
              child: pw.Image(pw.MemoryImage(logo), fit: pw.BoxFit.contain),
            ),
          pw.Spacer(),
          if (b.hasContacts)
            pw.Text(
              b.contactLine,
              style: const pw.TextStyle(fontSize: 8, color: muted),
            ),
        ],
      ),
    );
  }

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
    await loadBrand();
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
          if (brand.hasContacts) ...[
            pw.Text(
              'Kontakt: ${brand.contactLine}',
              style: const pw.TextStyle(fontSize: 9),
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
