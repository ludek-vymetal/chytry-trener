import 'food_catalog.dart';

/// Porce jedné potraviny v jídle.
class FoodPortion {
  final NutritionFood food;
  final double grams;

  const FoodPortion(this.food, this.grams);

  double get protein => food.proteinPerG * grams;
  double get carbs => food.carbsPerG * grams;
  double get fat => food.fatPerG * grams;
  double get kcal => food.kcalPerG * grams;

  /// Počet kusů (jen u potravin s [NutritionFood.pieceGrams]).
  int? get pieces {
    final pg = food.pieceGrams;
    if (pg == null || pg <= 0) return null;
    return (grams / pg).round();
  }
}

/// Výpočet gramáží tak, aby jídlo co nejpřesněji trefilo cílové
/// bílkoviny, sacharidy a tuky.
///
/// Počítá se se VŠEMI makroživinami každé potraviny (např. vločky obsahují
/// i bílkoviny a tuky), ne jen s "hlavní" makroživinou. Chyba se měří
/// v kcal (B a S × 4, T × 9), takže gram tuku váží víc než gram sacharidů.
///
/// Postup:
///  1. nejmenší čtverce s omezením 0 ≤ gramy ≤ maximum porce
///     (souřadnicový sestup – úloha je konvexní, konverguje k optimu),
///  2. potraviny, které by vyšly pod nejmenší smysluplnou porci
///     (např. 5 g šunky), se vyřadí a výpočet se zopakuje,
///  3. zaokrouhlení na kuchyňské kroky (5 g, 10 g, celé kusy) a doladění
///     po jednotlivých krocích.
class PortionSolver {
  static const double _wProtein = 16; // (4 kcal)^2
  static const double _wCarbs = 16; // (4 kcal)^2
  static const double _wFat = 81; // (9 kcal)^2

  static List<FoodPortion> solve({
    required List<NutritionFood> variable,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
    List<FoodPortion> fixed = const [],

    /// Násobek maximálních porcí (u vysokého denního příjmu jsou porce
    /// přirozeně větší).
    double maxScale = 1.0,
  }) {
    // Cíl po odečtení pevných porcí (např. zelenina).
    var tP = targetProtein;
    var tC = targetCarbs;
    var tF = targetFat;
    for (final f in fixed) {
      tP -= f.protein;
      tC -= f.carbs;
      tF -= f.fat;
    }

    final n = variable.length;
    final grams = List<double>.filled(n, 0);
    final upper = [for (final f in variable) f.maxGrams * maxScale];
    final lower = List<double>.filled(n, 0);

    if (n > 0) {
      // Optimalizace + řešení příliš malých porcí: pod polovinou minimální
      // porce potravinu vyřadíme, jinak ji zvedneme na minimální porci
      // a ostatní potraviny se dopočítají.
      for (var round = 0; round <= 2 * n; round++) {
        _optimize(variable, grams, lower, upper, tP, tC, tF);

        var changed = false;
        for (var i = 0; i < n; i++) {
          final minG = variable[i].minGrams;
          if (grams[i] > 0 && grams[i] < minG && lower[i] < minG) {
            if (grams[i] < minG / 2) {
              upper[i] = 0;
              grams[i] = 0;
            } else {
              lower[i] = minG > upper[i] ? upper[i] : minG;
              grams[i] = lower[i];
            }
            changed = true;
          }
        }
        if (!changed) break;
      }

      _roundAndRefine(variable, grams, upper, tP, tC, tF);
    }

    return [
      for (var i = 0; i < n; i++)
        if (grams[i] > 0) FoodPortion(variable[i], grams[i]),
      ...fixed,
    ];
  }

  // ---------------------------------------------------------------
  // Spojitá optimalizace
  // ---------------------------------------------------------------

  static void _optimize(
    List<NutritionFood> foods,
    List<double> g,
    List<double> lower,
    List<double> upper,
    double tP,
    double tC,
    double tF,
  ) {
    // residuum r = A·g − t
    var rP = -tP, rC = -tC, rF = -tF;
    for (var i = 0; i < foods.length; i++) {
      rP += foods[i].proteinPerG * g[i];
      rC += foods[i].carbsPerG * g[i];
      rF += foods[i].fatPerG * g[i];
    }

    for (var sweep = 0; sweep < 400; sweep++) {
      var maxChange = 0.0;

      for (var i = 0; i < foods.length; i++) {
        final f = foods[i];
        final p = f.proteinPerG, c = f.carbsPerG, fa = f.fatPerG;

        final h = _wProtein * p * p + _wCarbs * c * c + _wFat * fa * fa;
        if (h <= 0) continue;

        final grad = _wProtein * p * rP + _wCarbs * c * rC + _wFat * fa * rF;

        var next = g[i] - grad / h;
        if (next < lower[i]) next = lower[i];
        if (next > upper[i]) next = upper[i];

        final d = next - g[i];
        if (d != 0) {
          g[i] = next;
          rP += p * d;
          rC += c * d;
          rF += fa * d;
          if (d.abs() > maxChange) maxChange = d.abs();
        }
      }

      if (maxChange < 0.01) break;
    }
  }

  // ---------------------------------------------------------------
  // Zaokrouhlení na kuchyňské kroky + doladění
  // ---------------------------------------------------------------

  static double _stepOf(NutritionFood f) => f.pieceGrams ?? f.step;

  /// Nejmenší povolená nenulová porce zaokrouhlená nahoru na krok.
  static double _minPortion(NutritionFood f) {
    final s = _stepOf(f);
    final m = f.minGrams > s ? f.minGrams : s;
    return (m / s).ceil() * s;
  }

  static void _roundAndRefine(
    List<NutritionFood> foods,
    List<double> g,
    List<double> upper,
    double tP,
    double tC,
    double tF,
  ) {
    for (var i = 0; i < foods.length; i++) {
      final s = _stepOf(foods[i]);
      var r = (g[i] / s).round() * s;
      if (r > upper[i]) r = (upper[i] / s).floor() * s;
      if (r > 0 && r < _minPortion(foods[i])) {
        // blíž nule, nebo k minimální porci?
        r = g[i] < _minPortion(foods[i]) / 2 ? 0.0 : _minPortion(foods[i]);
      }
      if (r < 0) r = 0;
      g[i] = r;
    }

    double error() {
      var p = -tP, c = -tC, fa = -tF;
      for (var i = 0; i < foods.length; i++) {
        p += foods[i].proteinPerG * g[i];
        c += foods[i].carbsPerG * g[i];
        fa += foods[i].fatPerG * g[i];
      }
      return _wProtein * p * p + _wCarbs * c * c + _wFat * fa * fa;
    }

    // Doladění: zkoušíme ± jeden krok u každé potraviny, dokud to pomáhá.
    // Porce je vždy buď 0, nebo aspoň minimální porce.
    var best = error();
    for (var pass = 0; pass < 30; pass++) {
      var improved = false;
      for (var i = 0; i < foods.length; i++) {
        final s = _stepOf(foods[i]);
        final minP = _minPortion(foods[i]);

        for (final up in const [true, false]) {
          double candidate;
          if (up) {
            candidate = g[i] == 0 ? minP : g[i] + s;
            if (candidate > upper[i]) continue;
          } else {
            if (g[i] == 0) continue;
            candidate = g[i] - s;
            if (candidate < minP) candidate = 0;
          }

          final old = g[i];
          g[i] = candidate;
          final e = error();
          if (e + 1e-9 < best) {
            best = e;
            improved = true;
          } else {
            g[i] = old;
          }
        }
      }
      if (!improved) break;
    }
  }
}
