import 'package:flutter/material.dart';

/// Vzhled sekce SPAL jako aplikace Clubspire, na kterou jsou členové zvyklí:
/// tmavá lišta, žluté prvky, bílý obsah.
const spalZluta = Color(0xFFF2B705);
const spalTmava = Color(0xFF262626);
const spalCerna = Color(0xFF000000);

ThemeData spalTema(BuildContext context) {
  final zaklad = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: spalZluta, primary: spalZluta, brightness: Brightness.light),
  );
  return zaklad.copyWith(
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: spalTmava,
      foregroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white,
      indicatorColor: spalZluta,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 16),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      floatingLabelStyle: TextStyle(color: spalZluta),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: spalZluta, width: 2)),
    ),
  );
}

/// Žluté velké tlačítko dole (Koupit permanentku, Rezervovat…)
class SpalSpodniTlacitko extends StatelessWidget {
  const SpalSpodniTlacitko({super.key, required this.text, required this.ikona, this.onTap});
  final String text;
  final IconData ikona;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: onTap == null ? Colors.grey.shade400 : spalZluta,
        child: InkWell(
          onTap: onTap,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 54,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(ikona, color: Colors.white, size: 24),
                const SizedBox(width: 14),
                Text(text,
                    style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ),
      );
}

/// Šedý nadpis sekce (Aktuální, Historie, Nepoužité…)
class SpalNadpis extends StatelessWidget {
  const SpalNadpis(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 0, 6),
        child: Text(text,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.grey.shade600)),
      );
}

String spalDatum(Object? v) {
  if (v == null) return '';
  final d = v is DateTime ? v : DateTime.parse(v as String).toLocal();
  return '${d.day}.${d.month}.${d.year}';
}

String spalCas(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String spalKc(Object? v) {
  final n = (v as num?) ?? 0;
  final s = n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2).replaceAll('.', ',');
  return '$s Kč';
}

const spalDny = ['pondělí', 'úterý', 'středa', 'čtvrtek', 'pátek', 'sobota', 'neděle'];
