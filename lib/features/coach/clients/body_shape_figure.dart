import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/coach/coach_inbody_entry.dart';

/// Typ postavy podle měření InBody / váhy SPAL – 15 typů s kresbou
/// (assets/postavy/<klic>.png): atletická, fit, normální, obdélník,
/// obrácený trojúhelník, trojúhelník, přesýpací hodiny, jablko, hruška,
/// sud, břišní, boky a zadek, horní část těla, dolní část těla, skinny fat.
///
/// Z měření se bere % tuku, podíl kosterní svaloviny, rozložení tuku
/// (trup × nohy × paže) a rozložení svalů (paže + trup × nohy).
/// Bez segmentální analýzy se typ určí jen z % tuku, svalů a BMI.
class BodyShape {
  const BodyShape._({
    required this.key,
    required this.shapeLabel,
    required this.description,
    required this.advice,
    required this.muscleLabel,
    required this.muscleLevel,
    required this.fatType,
    required this.fatPercent,
  });

  /// Klíč typu = název obrázku v assets/postavy.
  final String key;

  /// Název typu (Jablko, Hruška, …).
  final String shapeLabel;

  /// Popis typu.
  final String description;

  /// Krátké doporučení.
  final String advice;

  /// Rozložení svalů (Silný vršek, slabší nohy, …).
  final String muscleLabel;

  /// Svalová hmota slovně (nízká / průměrná / nadprůměrná / vysoká).
  final String muscleLevel;

  /// Kde se ukládá tuk (rovnoměrně, břicho, boky…).
  final String fatType;

  final double fatPercent;

  String get asset => 'assets/postavy/$key.png';

  static double _c(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  /// Všechny typy (klíč, název, popis) – pro přehled typů.
  static const types = <(String, String, String)>[
    ('atleticka', 'Atletická', 'Nízký tuk, výrazná svalová hmota'),
    ('fit', 'Fit', 'Sportovní, vyvážená postava'),
    ('normalni', 'Normální', 'Průměrná postava bez výrazných disproporcí'),
    ('obdelnik', 'Obdélník', 'Rovné linie, podobná šířka ramen, pasu a boků'),
    ('obraceny_trojuhelnik', 'Obrácený trojúhelník', 'Široká ramena, užší boky'),
    ('trojuhelnik', 'Trojúhelník', 'Užší ramena, širší boky'),
    ('presypaci_hodiny', 'Přesýpací hodiny', 'Vyvážená ramena a boky, užší pas'),
    ('jablko', 'Jablko', 'Více tuku v oblasti břicha (viscerální tuk), štíhlejší nohy'),
    ('hruska', 'Hruška', 'Více tuku v bocích, stehnech a zadku, užší vršek těla'),
    ('sud', 'Sud', 'Zvýšený tuk v celém trupu'),
    ('bricni', 'Břišní (centrální)', 'Výrazný tuk v břiše, často i v oblasti hrudníku'),
    ('boky_zadek', 'Boky a zadek', 'Tuk v bocích a zadku, relativně ploché břicho'),
    ('horni_cast', 'Horní část těla', 'Více tuku na hrudníku, zádech a ramenou, štíhlejší nohy'),
    ('dolni_cast', 'Dolní část těla', 'Více tuku na stehnech, bocích a lýtkách, štíhlejší vršek'),
    ('skinny_fat', 'Skinny fat', 'Štíhlá postava, ale vyšší podíl tuku (hlavně v břiše) a méně svalů'),
  ];

  static const _advice = <String, String>{
    'atleticka': 'Udržovat – síla, dostatek bílkovin a regenerace.',
    'fit': 'Dobrý základ. Pro víc svalů progresivní silový trénink a mírný přebytek.',
    'normalni': 'Pravidelný silový trénink 3× týdně a bílkoviny podle plánu.',
    'obdelnik': 'Zúžit pas a rozšířit ramena: ramena, záda (přítahy), méně tuku v pase.',
    'obraceny_trojuhelnik': 'Silný vršek – nezapomínat na nohy (dřepy, výpady, mrtvé tahy).',
    'trojuhelnik': 'Silné nohy – přidat tlaky, přítahy a ramena pro vyvážení.',
    'presypaci_hodiny': 'Vyvážená postava – udržovat sílu celého těla.',
    'jablko': 'Břišní tuk je nejrizikovější, ale odchází první: mírný deficit, pohyb, spánek, méně alkoholu.',
    'hruska': 'Tuk na stehnech odchází pomaleji – trpělivost, síla nohou a zadku, mírný deficit.',
    'sud': 'Postupná redukce (0,5–0,75 % váhy týdně), denní kroky a silový trénink.',
    'bricni': 'Vysoký viscerální tuk – redukce má přednost, kontrolovat tlak a cukr.',
    'boky_zadek': 'Silový trénink nohou a zadku, mírný deficit, hodně kroků.',
    'horni_cast': 'Redukce a silový trénink celého těla, posílit nohy.',
    'dolni_cast': 'Redukce, silový trénink nohou i vršku, více kroků.',
    'skinny_fat': 'Nehubnout dál – nabrat svaly: silový trénink 3–4× týdně, bílkoviny, jídlo na údržbě.',
  };

  factory BodyShape.fromEntry(CoachInbodyEntry e, {required bool male}) {
    final h = e.heightCm > 0 ? e.heightCm / 100.0 : (male ? 1.78 : 1.66);
    final w = e.weightKg > 0 ? e.weightKg : (male ? 80.0 : 62.0);
    final bmi = w / (h * h);
    final fat = e.bodyFatPercent > 0 ? e.bodyFatPercent : (male ? 18.0 : 27.0);

    // svaly celkově (podíl kosterní svaloviny na váze)
    var mm = 0.0;
    if (e.smmKg > 0) {
      mm = _c((e.smmKg / w - (male ? 0.44 : 0.37)) / 0.08, -1, 1.5);
    }

    // rozložení svalů: paže + trup × nohy
    final upper = e.muscleLeftArmKg + e.muscleRightArmKg + e.muscleTrunkKg;
    final lower = e.muscleLeftLegKg + e.muscleRightLegKg;
    final hasSegMuscle = upper > 0 && lower > 0;
    final mu = hasSegMuscle
        ? _c(upper / lower / (male ? 1.85 : 1.7) - 1, -0.3, 0.3)
        : 0.0;

    // rozložení tuku
    final arms = e.fatLeftArmKg + e.fatRightArmKg;
    final legs = e.fatLeftLegKg + e.fatRightLegKg;
    final segFat = arms + e.fatTrunkKg + legs;
    var dTr = 0.0, dLeg = 0.0, dUpper = 0.0;
    if (segFat > 0) {
      dTr = e.fatTrunkKg / segFat - (male ? 0.52 : 0.45);
      dLeg = legs / segFat - (male ? 0.32 : 0.40);
      dUpper = (arms + e.fatTrunkKg) / segFat - (male ? 0.68 : 0.60);
    }

    final lowFat = fat <= (male ? 12 : 22);
    final okFat = fat <= (male ? 17 : 27);
    final highFat = fat >= (male ? 20 : 30);
    final veryHigh = fat >= (male ? 28 : 38);

    String key;
    if (fat >= (male ? 18 : 28) && mm <= -0.3 && bmi < 25) {
      key = 'skinny_fat';
    } else if (highFat) {
      if (dTr >= 0.08) {
        key = 'bricni';
      } else if (veryHigh && dTr >= -0.02) {
        key = 'sud';
      } else if (dTr >= 0.04) {
        key = 'jablko';
      } else if (dLeg >= 0.06) {
        key = male ? 'dolni_cast' : 'hruska';
      } else if (dLeg >= 0.03) {
        key = male ? 'dolni_cast' : 'boky_zadek';
      } else if (dUpper >= 0.04) {
        key = 'horni_cast';
      } else {
        key = veryHigh ? 'sud' : 'normalni';
      }
    } else if (lowFat && mm >= 0.5) {
      key = mu > 0.1 ? 'obraceny_trojuhelnik' : 'atleticka';
    } else if (mu > 0.1) {
      key = 'obraceny_trojuhelnik';
    } else if (mu < -0.1) {
      key = 'trojuhelnik';
    } else if (okFat && mm >= 0) {
      key = 'fit';
    } else if (!male && dLeg > 0 && mu > -0.05) {
      key = 'presypaci_hodiny';
    } else if (male && mm < 0) {
      key = 'obdelnik';
    } else {
      key = 'normalni';
    }

    final t = types.firstWhere((x) => x.$1 == key);

    final muscleLabel = !hasSegMuscle
        ? 'Svaly po částech těla nejsou změřené'
        : mu > 0.1
            ? 'Silný vršek, slabší nohy'
            : mu < -0.1
                ? 'Silné nohy, slabší vršek'
                : 'Svaly rozložené vyváženě';

    final muscleLevel = e.smmKg <= 0
        ? '–'
        : mm >= 1.0
            ? 'vysoké'
            : mm >= 0.3
                ? 'nadprůměrné'
                : mm > -0.3
                    ? 'průměrné'
                    : 'nižší';

    final fatType = segFat <= 0
        ? '–'
        : dTr >= 0.04
            ? 'břišní (trup)'
            : dLeg >= 0.03
                ? 'boky a nohy'
                : dUpper >= 0.04
                    ? 'horní část těla'
                    : 'rovnoměrný';

    return BodyShape._(
      key: key,
      shapeLabel: t.$2,
      description: t.$3,
      advice: _advice[key] ?? '',
      muscleLabel: muscleLabel,
      muscleLevel: muscleLevel,
      fatType: fatType,
      fatPercent: fat,
    );
  }
}

/// Karta „Typ postavy“: kresba typu, popis, tuk / svaly / typ tuku
/// a přehled všech typů.
class BodyShapeCard extends StatelessWidget {
  const BodyShapeCard({super.key, required this.entry, required this.male});

  final CoachInbodyEntry entry;
  final bool male;

  @override
  Widget build(BuildContext context) {
    final shape = BodyShape.fromEntry(entry, male: male);
    final cs = Theme.of(context).colorScheme;

    Widget radek(String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            SizedBox(width: 90, child: Text(a, style: TextStyle(color: cs.onSurfaceVariant))),
            Expanded(child: Text(b, style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
        );

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Typ postavy',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _ukazatVse(context, shape.key),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: AspectRatio(
                  aspectRatio: 450 / 720,
                  child: Image.asset(
                    shape.asset,
                    fit: BoxFit.contain,
                    semanticLabel: 'Typ postavy: ${shape.shapeLabel}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              shape.shapeLabel,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(shape.description, style: const TextStyle(height: 1.35)),
            const SizedBox(height: 8),
            radek('Tuk', '${shape.fatPercent.toStringAsFixed(1).replaceAll('.', ',')} %'),
            radek('Svaly', shape.muscleLevel),
            radek('Typ tuku', shape.fatType),
            radek('Rozložení', shape.muscleLabel),
            const SizedBox(height: 8),
            Text(shape.advice, style: const TextStyle(height: 1.35)),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _ukazatVse(context, shape.key),
                icon: const Icon(Icons.grid_view),
                label: const Text('Všechny typy postav'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _ukazatVse(BuildContext context, String aktualni) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final sirka = MediaQuery.sizeOf(ctx).width;
        final sloupce = math.max(2, math.min(5, (sirka / 170).floor()));
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 760),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Row(children: [
                    const Expanded(
                      child: Text('Typy postav',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      tooltip: 'Zavřít',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ]),
                ),
                Flexible(
                  child: GridView.count(
                    padding: const EdgeInsets.all(12),
                    crossAxisCount: sloupce,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.5,
                    children: [
                      for (final t in BodyShape.types)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: t.$1 == aktualni ? Colors.red : Colors.black12,
                              width: t.$1 == aktualni ? 3 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Column(children: [
                            Text(
                              t.$2,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Expanded(child: Image.asset('assets/postavy/${t.$1}.png')),
                            Text(
                              t.$3,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black87, fontSize: 11),
                            ),
                          ]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
