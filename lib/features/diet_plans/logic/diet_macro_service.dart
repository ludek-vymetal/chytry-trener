import '../../../models/user_profile.dart';
import '../../../services/macro_service.dart';
import '../../../services/metabolism_service.dart';

/// Denní cíl makroživin pro jídelníček.
class DietDayTargets {
  final double protein;
  final double carbs;
  final double fats;

  const DietDayTargets({
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  double get kcal => protein * 4 + carbs * 4 + fats * 9;
}

/// JEDINÝ zdroj cílů pro všechny jídelníčky (lineární, keto, vlny, půst).
///
/// Vychází z hlavního výpočtu aplikace (MacroService): TDEE podle aktivity,
/// periodizace (fáze, tempo úbytku), pojistky (max. deficit, spodní hranice
/// kalorií, minimum bílkovin a tuků). Jednotlivé diety pak jen jinak
/// rozdělují stejný kalorický cíl.
class DietMacroService {
  /// Minimum tuků (g / kg tělesné hmotnosti) – hormonální zdraví.
  static const double minFatPerKg = 0.6;

  /// Keto: max. využitelných sacharidů za den.
  static const double ketoCarbs = 30;

  /// Keto: bílkoviny max. 30 % energie (jinak už nejde o keto).
  static const double ketoMaxProteinShare = 0.30;

  /// Keto: bílkoviny ale nikdy pod 1,6 g/kg (ochrana svalové hmoty).
  static const double minProteinPerKg = 1.6;

  static MacroTarget base(UserProfile profile) {
    final tdee = MetabolismService.calculateTDEE(
      profile,
      MetabolismService.activityFor(profile),
    );
    return MacroService.calculate(profile, tdee);
  }

  /// Lineární plán a půst: stejné makro každý den.
  static DietDayTargets linear(UserProfile profile) {
    final m = base(profile);
    return DietDayTargets(
      protein: m.protein.toDouble(),
      carbs: m.carbs.toDouble(),
      fats: m.fat.toDouble(),
    );
  }

  static DietDayTargets fasting(UserProfile profile) => linear(profile);

  /// Keto: sacharidy ≤ 30 g, bílkoviny max. 30 % kcal (min. 1,6 g/kg),
  /// zbytek energie z tuků. Celkové kalorie = stejný cíl jako jinde.
  static DietDayTargets keto(UserProfile profile) {
    final m = base(profile);
    final kcal = m.targetCalories.toDouble();

    final minProtein = m.weightForProteinKg * minProteinPerKg;
    final maxProteinByShare = kcal * ketoMaxProteinShare / 4;

    var protein = m.protein.toDouble();
    if (protein > maxProteinByShare) protein = maxProteinByShare;
    if (protein < minProtein) protein = minProtein;

    final minFat = profile.weight * minFatPerKg;
    var fats = (kcal - protein * 4 - ketoCarbs * 4) / 9;
    if (fats < minFat) fats = minFat;

    return DietDayTargets(
      protein: protein.roundToDouble(),
      carbs: ketoCarbs,
      fats: fats.roundToDouble(),
    );
  }

  /// Sacharidové vlny: bílkoviny a tuky každý den stejné, týdenní součet
  /// sacharidů = 7 × průměr lineárního plánu (týdenní kalorie se nemění).
  /// 2 nízké dny (50 % průměru), zbytek rozdělen do 5 dnů s rostoucí
  /// porcí (0,65 / 0,85 / 1,0 / 1,15 / 1,35 – součet 5,0).
  ///
  /// Pořadí dnů: Po nízký, Út, St nízký, Čt, Pá, So, Ne.
  static List<double> carbCyclingDailyCarbs(double avgCarbs) {
    if (avgCarbs <= 0) return List<double>.filled(7, 0);

    final weeklyBank = avgCarbs * 7;
    final lowDay = avgCarbs * 0.5;
    final baseShare = (weeklyBank - 2 * lowDay) / 5;

    const multipliers = [0.65, 0.85, 1.0, 1.15, 1.35];

    final raw = [
      lowDay,
      baseShare * multipliers[0],
      lowDay,
      baseShare * multipliers[1],
      baseShare * multipliers[2],
      baseShare * multipliers[3],
      baseShare * multipliers[4],
    ];

    // Zaokrouhlení na 5 g a dorovnání, aby týdenní banka přesně seděla.
    final rounded = raw.map((g) => (g / 5).round() * 5.0).toList();
    final diff = weeklyBank - rounded.fold<double>(0, (a, b) => a + b);
    rounded[6] = (rounded[6] + diff).roundToDouble();

    return rounded;
  }
}
