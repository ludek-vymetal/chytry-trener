// Odborný rozbor měření InBody pro trenéra.
//
// Použité referenční hodnoty:
// - % tuku podle pohlaví a věku: Gallagher et al., Am J Clin Nutr 2000.
// - FFMI / FMI (index beztukové a tukové hmoty): Kelly et al. 2009,
//   Kouri et al. 1995 (horní hranice přirozené svalové hmoty).
// - Index kosterní svaloviny končetin (ASMI): EWGSOP2 2019 a AWGS 2019.
// - Poměr pas/boky: WHO 2008.
// - Viscerální tuk: stupnice InBody (úroveň 10 ≈ 100 cm²).
// - Hydratace beztukové hmoty: ~73 % (Wang et al. 1999).
//
// Nejde o lékařskou diagnózu – rozbor slouží k plánování tréninku a stravy.

import 'dart:math' as math;

import '../../models/coach/coach_inbody_entry.dart';

enum InbodyStatus { good, ok, warn, bad, info }

class InbodyFinding {
  final String title;
  final String value;
  final String reference;
  final String explanation;
  final InbodyStatus status;

  const InbodyFinding({
    required this.title,
    required this.value,
    required this.reference,
    required this.explanation,
    required this.status,
  });
}

class InbodySection {
  final String title;
  final List<InbodyFinding> findings;

  const InbodySection(this.title, this.findings);
}

class InbodyTarget {
  final String label;
  final double bodyFatPercent;
  final double weightKg;
  final double fatToLoseKg;

  const InbodyTarget({
    required this.label,
    required this.bodyFatPercent,
    required this.weightKg,
    required this.fatToLoseKg,
  });
}

/// Strojově čitelné závěry rozboru – pro navazující doporučení
/// (strava, trénink) v aplikaci a v PDF souhrnu.
class InbodyFlags {
  final double bodyFatPercent;
  final double leanMassKg;
  final double fatKg;
  final bool fatLow;
  final bool fatHigh;
  final bool fatVeryHigh;
  final bool lowMuscle;
  final bool highMuscle;
  final bool lowLimbMuscle;
  final bool abdominalRisk;
  final bool poorHydration;

  /// 'levá' / 'pravá', když je rozdíl stran 5 % a víc.
  final String? weakerArm;
  final String? weakerLeg;
  final bool legsLag;
  final bool upperLags;

  /// recomp, cut, cutMuscleLoss, leanGain, gain, dirtyGain, fatGain,
  /// muscleLoss, stable – `null`, když není předchozí měření.
  final String? trend;
  final bool changeTooFast;

  const InbodyFlags({
    required this.bodyFatPercent,
    required this.leanMassKg,
    required this.fatKg,
    required this.fatLow,
    required this.fatHigh,
    required this.fatVeryHigh,
    required this.lowMuscle,
    required this.highMuscle,
    required this.lowLimbMuscle,
    required this.abdominalRisk,
    required this.poorHydration,
    required this.weakerArm,
    required this.weakerLeg,
    required this.legsLag,
    required this.upperLags,
    required this.trend,
    required this.changeTooFast,
  });
}

class InbodyReport {
  final InbodyFlags flags;

  /// Typ postavy jednou větou, např. „Normální váha se zvýšeným tukem“.
  final String bodyType;

  /// Krátké shrnutí pro klienta (2–3 věty).
  final String summary;

  final List<InbodySection> sections;

  /// Doporučení pro trénink a stravu, seřazená podle priority.
  final List<String> recommendations;

  /// Cílové váhy při zachování současné beztukové hmoty.
  final List<InbodyTarget> targets;

  /// Upozornění na přesnost měření (hydratace, chybějící údaje…).
  final List<String> measurementNotes;

  const InbodyReport({
    required this.flags,
    required this.bodyType,
    required this.summary,
    required this.sections,
    required this.recommendations,
    required this.targets,
    required this.measurementNotes,
  });

  int get warnCount => sections
      .expand((s) => s.findings)
      .where((f) => f.status == InbodyStatus.warn || f.status == InbodyStatus.bad)
      .length;
}

/// Rozsahy % tuku (Gallagher 2000): [nízké, zdravé do, nadváha do].
class _FatBands {
  final double low;
  final double healthyMax;
  final double overMax;
  const _FatBands(this.low, this.healthyMax, this.overMax);
}

class InbodyAnalysis {
  InbodyAnalysis._();

  static String _f(double v, [int d = 1]) =>
      v.toStringAsFixed(d).replaceAll('.', ',');

  static String _signed(double v, [int d = 1]) =>
      '${v >= 0 ? '+' : '−'}${_f(v.abs(), d)}';

  static _FatBands _fatBands(bool male, int age) {
    if (male) {
      if (age < 40) return const _FatBands(8, 20, 25);
      if (age < 60) return const _FatBands(11, 22, 28);
      return const _FatBands(13, 25, 30);
    }
    if (age < 40) return const _FatBands(21, 33, 39);
    if (age < 60) return const _FatBands(23, 34, 40);
    return const _FatBands(24, 36, 42);
  }

  static InbodyReport analyze({
    required CoachInbodyEntry latest,
    CoachInbodyEntry? previous,
    required String gender,
    required int age,
  }) {
    final male = gender == 'male';
    final e = latest;
    final hM = (e.heightCm > 0 ? e.heightCm : 170) / 100.0;
    final h2 = hM * hM;

    final weight = e.weightKg;
    final fatKg = e.fatKg > 0 ? e.fatKg : weight * e.bodyFatPercent / 100;
    // Beztuková hmota: když zadaná hodnota nesedí s váhou a tukem
    // (překlep při přepisu z výpisu), počítá se jako váha − tuk.
    final leanCalc = weight - fatKg;
    final leanMismatch =
        e.leanMassKg > 0 && (e.leanMassKg + fatKg - weight).abs() > 1.5;
    final lean =
        e.leanMassKg > 0 && !leanMismatch ? e.leanMassKg : leanCalc;
    final bf = e.bodyFatPercent > 0
        ? e.bodyFatPercent
        : (weight > 0 ? fatKg / weight * 100 : 0.0);
    final bmi = e.bmi > 0 ? e.bmi : (h2 > 0 ? weight / h2 : 0.0);

    final bands = _fatBands(male, age);
    final notes = <String>[];
    final recs = <String>[];
    if (leanMismatch) {
      notes.add('Zadaná beztuková hmota (${_f(e.leanMassKg)} kg) nesedí '
          's váhou a tukem – pro výpočty je použita ${_f(leanCalc)} kg '
          '(váha − tuk). Zkontroluj přepis z výpisu InBody.');
    }
    var legsLag = false;
    var upperLags = false;
    var lowLimb = false;
    String? trendKey;
    var tooFastFlag = false;

    // ------------------------------------------------------------
    // 1) Složení těla
    // ------------------------------------------------------------
    final comp = <InbodyFinding>[];

    InbodyStatus bfStatus;
    String bfText;
    if (bf < bands.low) {
      bfStatus = bf >= (male ? 5 : 14) ? InbodyStatus.ok : InbodyStatus.warn;
      bfText = bfStatus == InbodyStatus.ok
          ? 'Tuku máš méně, než je běžné zdravé rozmezí – typické pro sportovce '
              'nebo závodní formu. Dlouhodobě hlídej energii, regeneraci'
              '${male ? '' : ' a menstruační cyklus'}.'
          : 'Tuk je pod bezpečnou hranicí. Tento stav nedrž dlouhodobě – '
              'hrozí hormonální a imunitní potíže.';
    } else if (bf <= bands.healthyMax) {
      bfStatus = InbodyStatus.good;
      bfText = 'Podíl tuku máš ve zdravém rozmezí pro svůj věk a pohlaví.';
    } else if (bf <= bands.overMax) {
      bfStatus = InbodyStatus.warn;
      bfText = 'Tuku je trochu víc, než je ideál. Půjdeme na něj postupně '
          'a svaly přitom udržíme.';
    } else {
      bfStatus = InbodyStatus.bad;
      bfText = 'Tuku je tolik, že už zvyšuje zdravotní rizika (cukrovka, '
          'krevní tlak). Prioritou je ho snížit – a to se dá.';
    }
    comp.add(InbodyFinding(
      title: 'Tělesný tuk',
      value: '${_f(bf)} %  (${_f(fatKg)} kg)',
      reference: 'zdravé rozmezí ${_f(bands.low, 0)}–${_f(bands.healthyMax, 0)} % '
          '(${male ? 'muž' : 'žena'}, $age let)',
      explanation: bfText,
      status: bfStatus,
    ));

    // FMI – index tukové hmoty (nezávisí na výšce tolik jako kg)
    final fmi = h2 > 0 ? fatKg / h2 : 0.0;
    final fmiNormMax = male ? 6.0 : 9.0;
    final fmiExcessMax = male ? 9.0 : 13.0;
    comp.add(InbodyFinding(
      title: 'Tuk vzhledem k výšce (FMI)',
      value: '${_f(fmi)} kg/m²',
      reference: 'běžné ${male ? '3–6' : '5–9'} kg/m²',
      explanation: fmi <= fmiNormMax
          ? 'Na svou výšku máš tuku přiměřeně.'
          : fmi <= fmiExcessMax
              ? 'Na svou výšku máš tuku víc, než je norma.'
              : 'Množství tuku na tvou výšku odpovídá obezitě.',
      status: fmi <= fmiNormMax
          ? InbodyStatus.good
          : (fmi <= fmiExcessMax ? InbodyStatus.warn : InbodyStatus.bad),
    ));

    // FFMI – index beztukové hmoty, normalizovaný na 1,80 m
    final ffmi = h2 > 0 ? lean / h2 : 0.0;
    final ffmiN = ffmi + 6.1 * (1.8 - hM);
    final ffmiAvgLow = male ? 18.0 : 14.5;
    final ffmiGood = male ? 20.0 : 16.5;
    final ffmiHigh = male ? 23.0 : 18.5;
    InbodyStatus ffmiStatus;
    String ffmiText;
    if (ffmiN < ffmiAvgLow) {
      ffmiStatus = InbodyStatus.warn;
      ffmiText = 'Svalů máš na svou výšku méně než průměr – silový trénink '
          'je teď to nejdůležitější.';
    } else if (ffmiN < ffmiGood) {
      ffmiStatus = InbodyStatus.ok;
      ffmiText = 'Průměrná svalová hmota – máme z čeho stavět.';
    } else if (ffmiN < ffmiHigh) {
      ffmiStatus = InbodyStatus.good;
      ffmiText = 'Nadprůměrná svalová hmota – skvělý základ.';
    } else {
      ffmiStatus = InbodyStatus.good;
      ffmiText = 'Svalová hmota na úrovni pokročilého sportovce.';
    }
    comp.add(InbodyFinding(
      title: 'Svaly vzhledem k výšce (FFMI)',
      value: '${_f(ffmiN)} kg/m²',
      reference: male
          ? 'průměr 18–20, trénovaný 20–23, špička 23–25'
          : 'průměr 14,5–16,5, trénovaná 16,5–18,5, špička 18,5–21',
      explanation: ffmiText,
      status: ffmiStatus,
    ));

    final smmPct = weight > 0 ? e.smmKg / weight * 100 : 0.0;
    if (e.smmKg > 0) {
      comp.add(InbodyFinding(
        title: 'Kosterní svalovina (SMM)',
        value: '${_f(e.smmKg)} kg  (${_f(smmPct)} % váhy)',
        reference: male ? 'běžně 40–50 % váhy' : 'běžně 30–40 % váhy',
        explanation: 'Svaly, které tréninkem přímo budujeme. '
            'Nejdůležitější je, jak rostou mezi měřeními.',
        status: smmPct >= (male ? 40 : 30) ? InbodyStatus.good : InbodyStatus.warn,
      ));
    }

    // BMI vs. tuk – odhalí „skinny fat“ i svalnaté „nadváhy“
    String bodyType;
    final bfHigh = bf > bands.healthyMax;
    if (bmi >= 25 && !bfHigh) {
      bodyType = 'Svalnatá postava – vysoké BMI díky svalům, ne tuku';
    } else if (bmi < 25 && bmi >= 18.5 && bfHigh) {
      bodyType = 'Normální váha se zvýšeným tukem (skinny fat)';
    } else if (bmi >= 25 && bfHigh) {
      bodyType = bf > bands.overMax
          ? 'Nadváha s vysokým podílem tuku'
          : 'Mírná nadváha s vyšším podílem tuku';
    } else if (bmi < 18.5) {
      bodyType = 'Nízká tělesná hmotnost';
    } else if (ffmiStatus == InbodyStatus.good && bf <= bands.healthyMax) {
      bodyType = 'Atletická postava';
    } else {
      bodyType = 'Vyvážená postava ve zdravém rozmezí';
    }
    comp.add(InbodyFinding(
      title: 'BMI',
      value: _f(bmi),
      reference: '18,5–25 (neodlišuje svaly od tuku)',
      explanation: bmi >= 25 && !bfHigh
          ? 'BMI vychází vysoko, ale tuk je v normě – váhu tvoří svaly. '
              'U tebe BMI nic neříká, rozhoduje % tuku.'
          : bmi < 25 && bfHigh
              ? 'BMI vypadá v pořádku, ale na málo svalů připadá hodně tuku. '
                  'Cílem není hubnout, ale nabrat svaly a snížit tuk.'
              : 'BMI odpovídá složení těla.',
      status: bmi >= 18.5 && bmi < 25
          ? (bfHigh ? InbodyStatus.warn : InbodyStatus.good)
          : (bmi >= 25 && !bfHigh ? InbodyStatus.info : InbodyStatus.warn),
    ));

    // ------------------------------------------------------------
    // 2) Zdravotní rizika (tuk v oblasti břicha)
    // ------------------------------------------------------------
    final risk = <InbodyFinding>[];
    final whrLimit = male ? 0.90 : 0.85;
    if (e.whr > 0) {
      risk.add(InbodyFinding(
        title: 'Poměr pas/boky (WHR)',
        value: _f(e.whr, 2),
        reference: 'pod ${_f(whrLimit, 2)} (WHO)',
        explanation: e.whr < whrLimit
            ? 'Tuk je rozložený bez zvýšeného rizika.'
            : 'Tuk se ukládá hlavně na břiše, což souvisí s vyšším rizikem '
                'srdečních a metabolických onemocnění.',
        status: e.whr < whrLimit
            ? InbodyStatus.good
            : (e.whr < whrLimit + 0.05 ? InbodyStatus.warn : InbodyStatus.bad),
      ));
    }
    final vfl = e.visceralFatLevel;
    if (vfl != null && vfl > 0) {
      risk.add(InbodyFinding(
        title: 'Viscerální (útrobní) tuk',
        value: 'úroveň ${_f(vfl, 0)}',
        reference: 'do 9 v pořádku, 10–14 zvýšený, 15+ vysoký',
        explanation: vfl < 10
            ? 'Tuk kolem vnitřních orgánů je v bezpečné míře.'
            : 'Tuku kolem orgánů je víc. Dobrá zpráva: na pravidelný pohyb, '
                'spánek a méně alkoholu a sladkého reaguje nejrychleji.',
        status: vfl < 10
            ? InbodyStatus.good
            : (vfl < 15 ? InbodyStatus.warn : InbodyStatus.bad),
      ));
    }
    final segFatTotal = e.fatLeftArmKg +
        e.fatRightArmKg +
        e.fatTrunkKg +
        e.fatLeftLegKg +
        e.fatRightLegKg;
    if (segFatTotal > 0) {
      final trunkShare = e.fatTrunkKg / segFatTotal * 100;
      final limit = male ? 55.0 : 50.0;
      risk.add(InbodyFinding(
        title: 'Tuk na trupu',
        value: '${_f(e.fatTrunkKg)} kg  (${_f(trunkShare, 0)} % tuku)',
        reference: male ? 'do ~55 % celkového tuku' : 'do ~50 % celkového tuku',
        explanation: trunkShare <= limit
            ? 'Tuk je rozložený rovnoměrně.'
            : 'Tuk se ti ukládá hlavně na trupu (typ „jablko“).',
        status: trunkShare <= limit ? InbodyStatus.good : InbodyStatus.warn,
      ));
    }

    // ------------------------------------------------------------
    // 3) Svaly po segmentech
    // ------------------------------------------------------------
    final seg = <InbodyFinding>[];
    final armsKg = e.muscleLeftArmKg + e.muscleRightArmKg;
    final legsKg = e.muscleLeftLegKg + e.muscleRightLegKg;

    InbodyFinding? sideCheck(String name, double l, double r) {
      if (l <= 0 || r <= 0) return null;
      final diff = (l - r).abs() / math.max(l, r) * 100;
      final weaker = l < r ? 'levá' : 'pravá';
      return InbodyFinding(
        title: 'Symetrie – $name',
        value: 'L ${_f(l, 2)} kg / P ${_f(r, 2)} kg',
        reference: 'rozdíl do 5 %',
        explanation: diff < 5
            ? 'Strany jsou vyrovnané (rozdíl ${_f(diff)} %).'
            : 'Slabší je $weaker strana o ${_f(diff)} %. Pomůžou jednostranné '
                'cviky – sérii vždy začni slabší stranou.',
        status: diff < 5
            ? InbodyStatus.good
            : (diff < 10 ? InbodyStatus.warn : InbodyStatus.bad),
      );
    }

    final arms = sideCheck('paže', e.muscleLeftArmKg, e.muscleRightArmKg);
    final legs = sideCheck('nohy', e.muscleLeftLegKg, e.muscleRightLegKg);
    if (arms != null) seg.add(arms);
    if (legs != null) seg.add(legs);

    if (armsKg > 0 && legsKg > 0) {
      // Svaly končetin / výška² – ukazatel úbytku svalů (sarkopenie)
      final asmi = (armsKg + legsKg) / h2;
      final asmiLimit = male ? 7.0 : 5.7;
      seg.add(InbodyFinding(
        title: 'Svaly rukou a nohou (ASMI)',
        value: '${_f(asmi, 2)} kg/m²',
        reference: 'nad ${_f(asmiLimit)} kg/m² (EWGSOP2/AWGS)',
        explanation: asmi >= asmiLimit
            ? 'Svalů na rukou a nohou máš dostatek.'
            : 'Na rukou a nohou je svalů málo – hrozí úbytek síly. Pomůže '
                'silový trénink celého těla a dostatek bílkovin.',
        status: asmi >= asmiLimit ? InbodyStatus.good : InbodyStatus.bad,
      ));

      // Poměr nohy / paže – vyváženost horní a dolní poloviny
      final ratio = legsKg / armsKg;
      final low = male ? 2.6 : 2.9;
      final high = male ? 3.4 : 3.9;
      legsLag = ratio < low;
      upperLags = ratio > high;
      lowLimb = asmi < asmiLimit;
      seg.add(InbodyFinding(
        title: 'Horní vs. dolní polovina těla',
        value: 'nohy ${_f(legsKg)} kg / paže ${_f(armsKg)} kg',
        reference: 'poměr ${_f(low)}–${_f(high)}',
        explanation: ratio < low
            ? 'Nohy zaostávají za horní polovinou těla – přidej objem na '
                'dřepy, výpady, mrtvé tahy a hýždě.'
            : ratio > high
                ? 'Horní polovina těla zaostává – přidej tlaky, přítahy '
                    'a cviky na ramena.'
                : 'Horní a dolní polovina těla jsou vyvážené.',
        status: ratio < low || ratio > high ? InbodyStatus.warn : InbodyStatus.good,
      ));
    }

    // ------------------------------------------------------------
    // 4) Energie a hydratace
    // ------------------------------------------------------------
    final energy = <InbodyFinding>[];
    if (e.bmr > 0) {
      final low = (e.bmr * 1.4 / 10).round() * 10;
      final high = (e.bmr * 1.7 / 10).round() * 10;
      energy.add(InbodyFinding(
        title: 'Bazální metabolismus',
        value: '${e.bmr.round()} kcal',
        reference: 'odhad celkového výdeje $low–$high kcal/den',
        explanation: 'Energie, kterou tělo spálí jen na základní funkce. '
            'Celkový výdej záleží na pohybu během dne – přesný cíl '
            'počítá aplikace v jídelníčku.',
        status: InbodyStatus.info,
      ));
    }
    if (e.waterKg > 0 && lean > 0) {
      final hyd = e.waterKg / lean * 100;
      final ok = hyd >= 71 && hyd <= 76;
      energy.add(InbodyFinding(
        title: 'Hydratace těla',
        value: '${_f(hyd)} %  (${_f(e.waterKg)} l vody)',
        reference: '71–76 %',
        explanation: ok
            ? 'Hydratace v pořádku – měření je spolehlivé.'
            : hyd < 71
                ? 'Nižší hydratace – svaly mohly vyjít o něco méně a tuk více.'
                : 'Tělo zadržuje víc vody (otok, menstruace, slané jídlo) – '
                    'výsledky můžou být trochu zkreslené.',
        status: ok ? InbodyStatus.good : InbodyStatus.warn,
      ));
      if (!ok) {
        notes.add('Hydratace byla mimo normu – příští měření proto ráno, '
            'nalačno, po toaletě a bez tréninku předem.');
      }
    }

    // ------------------------------------------------------------
    // 5) Vývoj od minulého měření
    // ------------------------------------------------------------
    final trend = <InbodyFinding>[];
    if (previous != null) {
      final days = e.date.difference(previous.date).inDays.abs();
      final weeks = math.max(days / 7.0, 1.0);
      final dW = e.weightKg - previous.weightKg;
      final dM = e.smmKg - previous.smmKg;
      final pFat = previous.fatKg > 0
          ? previous.fatKg
          : previous.weightKg * previous.bodyFatPercent / 100;
      final dF = fatKg - pFat;
      final dBf = bf - previous.bodyFatPercent;

      String verdict;
      InbodyStatus st;
      if (dF < -0.3 && dM >= -0.2) {
        verdict = dM > 0.2
            ? 'Rekompozice – tuk dolů, svaly nahoru. Tohle je nejlepší možný výsledek!'
            : 'Čisté hubnutí – ubývá tuk a svaly zůstávají. Přesně tak to má být.';
        trendKey = dM > 0.2 ? 'recomp' : 'cut';
        st = InbodyStatus.good;
      } else if (dF < -0.3 && dM < -0.2) {
        final share = dW < 0 ? (-dM / -dW * 100) : 0.0;
        verdict = share > 30
            ? 'Hubneš, ale i o svaly (${_f(share, 0)} % úbytku váhy tvoří '
                'svaly). Zvýšíme bílkoviny, zmírníme deficit a udržíme těžký '
                'silový trénink.'
            : 'Hubnutí jen s malou ztrátou svalů – v deficitu normální.';
        st = share > 30 ? InbodyStatus.warn : InbodyStatus.ok;
        trendKey = share > 30 ? 'cutMuscleLoss' : 'cut';
      } else if (dM > 0.2 && dF <= 0.5) {
        verdict = 'Kvalitní nabírání – přibývají hlavně svaly. Výborně!';
        st = InbodyStatus.good;
        trendKey = 'leanGain';
      } else if (dM > 0.2 && dF > 0.5) {
        verdict = dF > dM * 1.5
            ? 'Nabírání s větším přírůstkem tuku – zmenši přebytek kalorií.'
            : 'Nabírání svalů i tuku v přijatelném poměru.';
        st = dF > dM * 1.5 ? InbodyStatus.warn : InbodyStatus.ok;
        trendKey = dF > dM * 1.5 ? 'dirtyGain' : 'gain';
      } else if (dF > 0.5) {
        verdict = 'Přibývá tuk bez růstu svalů – zkontroluj příjem a '
            'pravidelnost tréninku.';
        st = InbodyStatus.bad;
        trendKey = 'fatGain';
      } else if (dM < -0.3) {
        verdict = 'Ubývají svaly – zkontroluj bílkoviny, spánek a trénink.';
        st = InbodyStatus.warn;
        trendKey = 'muscleLoss';
      } else {
        verdict = 'Beze změny – složení těla je stabilní.';
        st = InbodyStatus.info;
        trendKey = 'stable';
      }

      trend.add(InbodyFinding(
        title: 'Hodnocení vývoje',
        value: '$days dní od minulého měření',
        reference: 'váha ${_signed(dW)} kg · svaly ${_signed(dM)} kg · '
            'tuk ${_signed(dF)} kg (${_signed(dBf)} %)',
        explanation: verdict,
        status: st,
      ));

      final rate = dW / weeks / (previous.weightKg > 0 ? previous.weightKg : 1) * 100;
      if (days >= 7 && dW.abs() > 0.2) {
        final losing = dW < 0;
        final tooFast = losing ? rate < -1.0 : rate > 0.5;
        tooFastFlag = tooFast;
        trend.add(InbodyFinding(
          title: 'Tempo změny váhy',
          value: '${_signed(dW / weeks, 2)} kg/týden (${_signed(rate, 2)} %)',
          reference: losing
              ? 'hubnutí ideálně 0,5–1 % váhy týdně'
              : 'nabírání ideálně 0,25–0,5 % váhy týdně',
          explanation: tooFast
              ? (losing
                  ? 'Hubnutí je příliš rychlé – roste riziko ztráty svalů.'
                  : 'Nabírání je příliš rychlé – přibývá zbytečně tuku.')
              : 'Tempo je v doporučeném rozmezí.',
          status: tooFast ? InbodyStatus.warn : InbodyStatus.good,
        ));
      }
    }

    // ------------------------------------------------------------
    // Cílové váhy (se zachováním současné beztukové hmoty)
    // ------------------------------------------------------------
    final targets = <InbodyTarget>[];
    void addTarget(String label, double pct) {
      if (bf <= pct + 0.5 || lean <= 0) return;
      final w = lean / (1 - pct / 100);
      if (w >= weight - 0.3) return;
      targets.add(InbodyTarget(
        label: label,
        bodyFatPercent: pct,
        weightKg: w,
        fatToLoseKg: weight - w,
      ));
    }

    addTarget('Zdravé rozmezí', bands.healthyMax);
    addTarget('Fit postava', male ? 15 : 24);
    addTarget('Vyrýsovaná postava', male ? 11 : 20);

    // ------------------------------------------------------------
    // Doporučení
    // ------------------------------------------------------------
    final protein = (lean * (bfHigh ? 2.2 : 2.0)).round();
    if (bf > bands.overMax) {
      recs.add('Priorita: snížit tuk. Mírný deficit 15–20 % pod výdejem, '
          'hubnutí 0,5–1 % váhy týdně.');
    } else if (bfHigh && ffmiN < ffmiGood) {
      recs.add('Priorita: rekompozice. Jez kolem údržby (max. −10 %) '
          'a zaměř se na progresivní silový trénink – tuk půjde dolů a svaly nahoru.');
    } else if (bfHigh) {
      recs.add('Priorita: postupná redukce tuku při udržení síly.');
    } else if (ffmiN < ffmiGood) {
      recs.add('Priorita: nabrat svaly. Mírný přebytek 5–10 % nad výdejem '
          'a silový trénink 3–4× týdně.');
    } else {
      recs.add('Složení těla máš dobré – drž současný režim a sledujeme vývoj.');
    }
    recs.add('Bílkoviny kolem $protein g denně '
        '(${_f(bfHigh ? 2.2 : 2.0)} g na kg beztukové hmoty).');
    if (ffmiStatus == InbodyStatus.warn ||
        seg.any((f) => f.title.startsWith('Svaly končetin') &&
            f.status == InbodyStatus.bad)) {
      recs.add('Silový trénink celého těla 3× týdně, základní vícekloubové '
          'cviky, postupně zvyšovat zátěž.');
    }
    if (arms?.status == InbodyStatus.warn ||
        arms?.status == InbodyStatus.bad ||
        legs?.status == InbodyStatus.warn ||
        legs?.status == InbodyStatus.bad) {
      recs.add('Vyrovnej strany: jednoručky a jednonož cviky, slabší '
          'stranou začínat a opakování nepřidávat silnější straně.');
    }
    if (risk.any((f) =>
        f.status == InbodyStatus.warn || f.status == InbodyStatus.bad)) {
      recs.add('Kvůli tuku na břiše přidej denní chůzi (8–10 tisíc kroků), '
          'kvalitní spánek 7–9 h a omez alkohol a slazené nápoje.');
    }
    if (bf < bands.low) {
      recs.add('Tuk je pod běžným rozmezím – nedrž deficit dlouhodobě, '
          'plánuj období údržby.');
    }

    if (previous == null) {
      notes.add('Pro hodnocení vývoje přidej další měření za 4–6 týdnů.');
    }
    notes.add('Rozbor slouží k plánování tréninku a stravy, nenahrazuje '
        'lékařské vyšetření.');

    // ------------------------------------------------------------
    // Shrnutí
    // ------------------------------------------------------------
    final summary = StringBuffer()
      ..write('Tuk ${_f(bf)} % – ')
      ..write(switch (bfStatus) {
        InbodyStatus.good => 've zdravém rozmezí',
        InbodyStatus.ok => 'pod běžným rozmezím',
        InbodyStatus.warn when bf < bands.low => 'příliš nízko',
        InbodyStatus.warn => 'mírně zvýšený',
        _ => 'vysoký',
      })
      ..write(', svalová hmota ')
      ..write(switch (ffmiStatus) {
        InbodyStatus.warn => 'pod průměrem',
        InbodyStatus.ok => 'průměrná',
        _ => 'nadprůměrná',
      })
      ..write('. ');
    if (targets.isNotEmpty) {
      final t = targets.first;
      summary.write('K cíli „${t.label.toLowerCase()}“ '
          '(${_f(t.bodyFatPercent, 0)} % tuku) zbývá shodit asi '
          '${_f(t.fatToLoseKg)} kg tuku.');
    } else {
      summary.write(recs.first);
    }

    final anyRisk = risk.any(
        (f) => f.status == InbodyStatus.warn || f.status == InbodyStatus.bad);
    String? weak(InbodyFinding? f) {
      if (f == null || f.status == InbodyStatus.good) return null;
      return f.explanation.contains('levá') ? 'levá' : 'pravá';
    }

    return InbodyReport(
      flags: InbodyFlags(
        bodyFatPercent: bf,
        leanMassKg: lean,
        fatKg: fatKg,
        fatLow: bf < bands.low,
        fatHigh: bf > bands.healthyMax,
        fatVeryHigh: bf > bands.overMax,
        lowMuscle: ffmiStatus == InbodyStatus.warn,
        highMuscle: ffmiN >= ffmiGood,
        lowLimbMuscle: lowLimb,
        abdominalRisk: anyRisk,
        poorHydration: energy.any((f) =>
            f.title.startsWith('Hydratace') && f.status != InbodyStatus.good),
        weakerArm: weak(arms),
        weakerLeg: weak(legs),
        legsLag: legsLag,
        upperLags: upperLags,
        trend: trendKey,
        changeTooFast: tooFastFlag,
      ),
      bodyType: bodyType,
      summary: summary.toString(),
      sections: [
        InbodySection('Složení těla', comp),
        if (risk.isNotEmpty) InbodySection('Zdravotní rizika', risk),
        if (seg.isNotEmpty) InbodySection('Svaly po segmentech', seg),
        if (energy.isNotEmpty) InbodySection('Energie a hydratace', energy),
        if (trend.isNotEmpty) InbodySection('Vývoj od minulého měření', trend),
      ],
      recommendations: recs,
      targets: targets,
      measurementNotes: notes,
    );
  }
}
