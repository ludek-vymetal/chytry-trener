import '../../models/diet_preference.dart';
import '../../models/food_combo.dart';

/// Úroveň potraviny z pohledu stravovacích omezení.
enum FoodDietLevel {
  /// Rostlinná – vhodná pro vegany.
  vegan,

  /// Obsahuje mléko / vejce / med – vhodná pro vegetariány.
  vegetarian,

  /// Obsahuje maso nebo ryby.
  meat,

  /// Nelze spolehlivě určit – z bezpečnostních důvodů se veganům
  /// a vegetariánům nenabízí.
  unknown,
}

/// Rozpoznání masa / živočišných produktů podle názvu potraviny.
///
/// Pravidla (v tomto pořadí):
///  1. rostlinné výjimky ("arašídové máslo", "sójové mléko", "vegan"…)
///     se z názvu odstraní – nejsou to živočišné produkty,
///  2. obsahuje-li název maso/rybu → [FoodDietLevel.meat],
///  3. obsahuje-li mléčný výrobek, vejce, med… → [FoodDietLevel.vegetarian],
///  4. obsahuje-li známou rostlinnou potravinu → [FoodDietLevel.vegan],
///  5. jinak [FoodDietLevel.unknown] (radši nenabídnout, než se splést).
///
/// Konzervativní volby: kaše, nákypy, müsli, granola, gnocchi, proteinové
/// tyčinky a pudinky se berou jako vegetariánské (často obsahují mléko,
/// vejce nebo med).
class DietClassifier {
  static const List<String> _plantOverrides = [
    'arašídové máslo', 'mandlové máslo', 'kešu máslo', 'ořechové máslo',
    'kakaové máslo', 'sójové mléko', 'ovesné mléko', 'mandlové mléko',
    'rýžové mléko', 'kokosové mléko', 'rostlinné mléko', 'rostlinný nápoj',
    'rostlinný jogurt', 'sójový jogurt', 'kokosový jogurt', 'sójový protein',
    'hrachový protein', 'rostlinný protein', 'veganský protein', 'vegan',
  ];

  static const List<String> _meat = [
    'maso', 'masa', 'kuře', 'kuřec', 'krůt', 'hovězí', 'hovězi', 'vepř',
    'šunk', 'slanin', 'salám', 'klobás', 'párek', 'párky', 'uzen', 'kachn',
    'husa', 'husí', 'jehněč', 'telecí', 'zvěřin', 'králík', 'játr', 'steak',
    'svíčkov', 'guláš', 'řízek', 'sekaná', 'kotlet', 'špek', 'sádlo',
    'jerky', 'prosciutto', 'pršut', 'bacon', 'losos', 'tuňák', 'treska',
    'tresky', 'krevet', 'makrel', 'pstruh', 'ryba', 'ryby', 'rybí', 'sardin',
    'sleď', 'kapr', 'tilápi', 'pangas', 'chobotnic', 'kalamár', 'mušl',
    'anchov', 'želatin', 'vývar', 'chicken', 'beef', 'pork', 'tuna',
    'salmon', 'fish', 'shrimp', 'ham',
  ];

  static const List<String> _animal = [
    'vejce', 'vajíč', 'vaječ', 'bílk', 'mléko', 'mléč', 'jogurt', 'skyr',
    'tvaroh', 'sýr', 'cottage', 'mozzarell', 'eidam', 'gouda', 'čedar',
    'cheddar', 'parmez', 'ricott', 'mascarpone', 'žervé', 'cream cheese',
    'smetan', 'máslo', 'kefír', 'podmáslí', 'whey', 'syrovátk', 'kasein',
    'protein tyčink', 'proteinová tyčink', 'wafle', 'palačink', 'lívan',
    'granola', 'müsli', 'kaše', 'nákyp', 'pudink', 'gnocchi', 'egg', 'milk',
    'cheese', 'yogurt', 'butter', 'honey',
    // Majonéza a tatarka obsahují vejce, knedlíky a buchtičky vejce/mléko.
    'majonéz', 'tatarsk', 'knedl', 'buchtič', 'parmaz',
  ];

  /// Krátká slova, která se hledají jen jako celé slovo (jinak by "med"
  /// našel i jiná slova).
  static final List<RegExp> _animalWords = [
    RegExp(r'(?<![a-záčďéěíňóřšťúůýž])med(?![a-záčďéěíňóřšťúůýž])'),
  ];

  static const List<String> _vegan = [
    'tofu', 'tempeh', 'seitan', 'čočk', 'cizrn', 'fazol', 'hrách', 'hrach',
    'sója', 'sójov', 'edamame', 'rýž', 'rýže', 'těstovin', 'quinoa',
    'kuskus', 'bulgur', 'pohank', 'jáhl', 'kroup', 'brambor', 'batát',
    'vločk', 'ovesn', 'oves', 'chléb', 'chleba', 'chlebíč', 'rohlík',
    'bageta', 'tortill', 'kukuř', 'cornflakes', 'krupic', 'ovoce', 'banán',
    'jablk', 'jablko', 'hrušk', 'pomeranč', 'mandarin', 'mango', 'borůvk',
    'jahod', 'malin', 'ostružin', 'datl', 'hrozn', 'kiwi', 'ananas',
    'meloun', 'švestk', 'meruňk', 'broskv', 'třešn', 'višn', 'citron',
    'avokád', 'brokolic', 'špenát', 'okurk', 'rajč', 'paprik', 'mrkev',
    'zelenin', 'salát', 'cibul', 'česnek', 'cuket', 'lilek', 'kapust',
    'zelí', 'květák', 'hub', 'žampion', 'dýn', 'kedlub', 'ředkvič', 'řepa',
    'celer', 'pórek', 'hrášek', 'mandl', 'arašíd', 'kešu', 'ořech', 'semínk',
    'chia', 'lněn', 'slunečnic', 'sezam', 'tahini', 'olej', 'kokos',
    'javorový sirup', 'cukr', 'agáv', 'nudle',
  ];

  static FoodDietLevel levelOfName(String name) {
    var n = ' ${name.toLowerCase()} ';
    var plant = false;

    for (final p in _plantOverrides) {
      if (n.contains(p)) {
        n = n.replaceAll(p, ' ');
        plant = true;
      }
    }

    if (_meat.any(n.contains)) return FoodDietLevel.meat;

    if (_animal.any(n.contains) || _animalWords.any((r) => r.hasMatch(n))) {
      return FoodDietLevel.vegetarian;
    }

    if (plant || _vegan.any(n.contains)) return FoodDietLevel.vegan;

    return FoodDietLevel.unknown;
  }

  /// Úroveň celého jídla = nejpřísnější z jeho surovin (i názvu).
  static FoodDietLevel levelOfCombo(FoodCombo combo) {
    var worst = FoodDietLevel.vegan;
    for (final item in combo.items) {
      worst = _max(worst, levelOfName(item.mealName));
    }
    return worst;
  }

  static bool allows(DietPreference preference, FoodDietLevel level) {
    switch (preference) {
      case DietPreference.none:
        return true;
      case DietPreference.vegetarian:
        return level == FoodDietLevel.vegan ||
            level == FoodDietLevel.vegetarian;
      case DietPreference.vegan:
        return level == FoodDietLevel.vegan;
    }
  }

  static bool allowsName(DietPreference preference, String name) =>
      allows(preference, levelOfName(name));

  static bool allowsCombo(DietPreference preference, FoodCombo combo) =>
      allows(preference, levelOfCombo(combo));

  static FoodDietLevel _max(FoodDietLevel a, FoodDietLevel b) =>
      a.index >= b.index ? a : b;
}
