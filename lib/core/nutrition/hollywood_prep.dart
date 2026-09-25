// Jídelníčky k tréninkovým programům:
//  - Hollywood training (příprava postavy na natáčení / focení),
//  - Bikini fitness (příprava na závody),
//  - Kulatý zadek (růst hýždí).
//
// Přípravy k datu (Hollywood, Bikini) počítají týdny ZPĚTNĚ od data
// natáčení / závodu – stejně jako tréninkové plány, takže jídelníček
// i trénink vždy ukazují stejný týden a stejnou fázi.

/// Fáze jídelníčku.
class PrepPhase {
  /// Týden programu (1 = první týden).
  final int week;

  /// Název fáze (např. Stavba, Rýsování, Peak).
  final String label;

  /// Cílový úbytek hmotnosti v % týdně. `null` = bez deficitu.
  final double? weeklyLossPct;

  /// Násobek TDEE, když není deficit (1,0 = údržba, 1,075 = přebytek 7,5 %).
  final double calorieMultiplier;

  final double proteinGPerKg;
  final double fatGPerKg;

  const PrepPhase({
    required this.week,
    required this.label,
    required this.weeklyLossPct,
    required this.proteinGPerKg,
    required this.fatGPerKg,
    this.calorieMultiplier = 1.0,
  });

  /// Týden bez deficitu s vyššími sacharidy (peak / natáčení / závod).
  bool get isPeak => weeklyLossPct == null && calorieMultiplier == 1.0;
}

/// Kalendář přípravy k datu.
class PrepCalendar {
  /// Týden přípravy 1–[totalWeeks] pro dnešek, nebo `null`, když příprava
  /// ještě nezačala (datum je dál než [totalWeeks] týdnů) nebo už skončila.
  ///
  /// Poslední týden = posledních 7 dní včetně dne akce, předposlední = 7 dní
  /// před tím atd.
  static int? weekFor(DateTime eventDate, int totalWeeks, [DateTime? now]) {
    final d = now ?? DateTime.now();
    final today = DateTime(d.year, d.month, d.day);
    final event = DateTime(eventDate.year, eventDate.month, eventDate.day);

    final daysToEvent = event.difference(today).inDays;
    if (daysToEvent < 0) return null;

    final week = totalWeeks - daysToEvent ~/ 7;
    if (week < 1) return null;
    return week;
  }

  /// První den přípravy (začátek týdne 1).
  static DateTime startDate(DateTime eventDate, int totalWeeks) {
    final event = DateTime(eventDate.year, eventDate.month, eventDate.day);
    return event.subtract(Duration(days: totalWeeks * 7 - 1));
  }
}

/// Hollywood training – 12týdenní příprava postavy na natáčení / focení
/// (styl přípravy herců na role: nízký podkožní tuk, důraz na partie
/// viditelné na kameře, síla se jen udržuje).
class HollywoodPrep {
  /// Hodnota `UserProfile.selectedPlan` pro jídelníček Hollywood training.
  static const String planKey = 'Hollywood';

  static const String name = 'Hollywood training';

  static const int totalWeeks = 12;

  static int? weekFor(DateTime shootDate, [DateTime? now]) =>
      PrepCalendar.weekFor(shootDate, totalWeeks, now);

  static DateTime startDate(DateTime shootDate) =>
      PrepCalendar.startDate(shootDate, totalWeeks);

  /// Fáze přípravy pro daný týden.
  ///
  /// Tempo úbytku se stupňuje (0,5 → 0,75 → 1 % hmotnosti týdně). Bílkoviny
  /// jsou vysoko (2,2–2,4 g/kg), aby se v dlouhém deficitu udržely svaly.
  /// Týden natáčení je na údržbě s vyššími sacharidy – svaly se doplní
  /// glykogenem a nejsou „prázdné“. Pojistky aplikace (max. deficit 25 %
  /// TDEE, spodní hranice kalorií, minimum tuků) platí i tady – u vyššího
  /// tempa proto deficit často narazí na 25 % TDEE a přísnost poslední
  /// fáze pak dělá hlavně trénink a kardio.
  static PrepPhase phaseFor(int week) {
    if (week <= 4) {
      return PrepPhase(
        week: week,
        label: 'Stavba',
        weeklyLossPct: 0.5,
        proteinGPerKg: 2.2,
        fatGPerKg: 0.8,
      );
    }
    if (week <= 8) {
      return PrepPhase(
        week: week,
        label: 'Rýsování',
        weeklyLossPct: 0.75,
        proteinGPerKg: 2.4,
        fatGPerKg: 0.7,
      );
    }
    if (week <= 11) {
      return PrepPhase(
        week: week,
        label: 'Finální rýsování',
        weeklyLossPct: 1.0,
        proteinGPerKg: 2.4,
        fatGPerKg: 0.7,
      );
    }
    return PrepPhase(
      week: week,
      label: 'Peak / natáčení',
      weeklyLossPct: null,
      proteinGPerKg: 2.2,
      fatGPerKg: 0.7,
    );
  }
}

/// Bikini fitness – 16týdenní příprava na závody.
class BikiniPrep {
  /// Hodnota `UserProfile.selectedPlan` pro jídelníček Bikini fitness.
  static const String planKey = 'Bikini';

  static const String name = 'Bikini fitness';

  static const int totalWeeks = 16;

  static int? weekFor(DateTime meetDate, [DateTime? now]) =>
      PrepCalendar.weekFor(meetDate, totalWeeks, now);

  static DateTime startDate(DateTime meetDate) =>
      PrepCalendar.startDate(meetDate, totalWeeks);

  /// Fáze přípravy – stejné rozdělení jako tréninkový plán:
  /// 1–6 stavba tvaru (0,5 %/týden), 7–12 rýsování (0,75 %), 13–15 finální
  /// rýsování (1 %), 16 peak week na údržbě s vyššími sacharidy (plné,
  /// kulaté svaly na pódiu). Tuky nejdou pod 0,7 g/kg – u žen důležité
  /// pro hormonální zdraví během dlouhé přípravy.
  static PrepPhase phaseFor(int week) {
    if (week <= 6) {
      return PrepPhase(
        week: week,
        label: 'Stavba tvaru',
        weeklyLossPct: 0.5,
        proteinGPerKg: 2.2,
        fatGPerKg: 0.8,
      );
    }
    if (week <= 12) {
      return PrepPhase(
        week: week,
        label: 'Rýsování',
        weeklyLossPct: 0.75,
        proteinGPerKg: 2.4,
        fatGPerKg: 0.7,
      );
    }
    if (week <= 15) {
      return PrepPhase(
        week: week,
        label: 'Finální rýsování',
        weeklyLossPct: 1.0,
        proteinGPerKg: 2.4,
        fatGPerKg: 0.7,
      );
    }
    return PrepPhase(
      week: week,
      label: 'Peak week / závod',
      weeklyLossPct: null,
      proteinGPerKg: 2.2,
      fatGPerKg: 0.7,
    );
  }
}

/// Kulatý zadek – jídelníček pro růst hýždí.
///
/// Svaly nerostou v deficitu: mírný přebytek 7,5 % nad TDEE (střed
/// doporučených 5–10 %), bílkoviny 2,0 g/kg, tuky 0,9 g/kg, zbytek
/// sacharidy (palivo na těžký trénink nohou).
class GlutePlan {
  /// Hodnota `UserProfile.selectedPlan` pro jídelníček Kulatý zadek.
  static const String planKey = 'Glutes';

  static const String name = 'Kulatý zadek';

  static const double surplus = 0.075;

  static const PrepPhase phase = PrepPhase(
    week: 1,
    label: 'Mírný přebytek',
    weeklyLossPct: null,
    calorieMultiplier: 1 + surplus,
    proteinGPerKg: 2.0,
    fatGPerKg: 0.9,
  );
}

/// Název programu podle typu jídelníčku, `null` = nejde o program.
class ProgramDiets {
  static String? nameFor(String? planType) {
    switch (planType) {
      case HollywoodPrep.planKey:
        return HollywoodPrep.name;
      case BikiniPrep.planKey:
        return BikiniPrep.name;
      case GlutePlan.planKey:
        return GlutePlan.name;
    }
    return null;
  }
}
