import '../../models/food_combo.dart';

/// Levné potraviny pro úspornou variantu (dopočítání jídla, výběr jídel).
///
/// Rozhoduje se podle názvu potraviny. Dražší suroviny mají přednost
/// (např. "Sójový jogurt" není levný, i když obsahuje "jogurt"). Potraviny,
/// které nejde zařadit (vlastní potraviny uživatele), se za levné
/// nepovažují – nabídnou se jen tehdy, když levná náhrada chybí.
class BudgetClassifier {
  static const List<String> _expensive = [
    'losos', 'krevet', 'treska', 'tresky', 'tuňák', 'hovězí', 'krůt', 'šunk',
    'panenk', 'steak', 'ribeye', 'skyr', 'řecký', 'cottage', 'mozzarell',
    'parmez', 'parmaz', 'whey', 'syrovátk', 'protein', 'tempeh', 'seitan',
    'sójov', 'quinoa', 'bulgur', 'kuskus', 'batát', 'avokád', 'mandl',
    'kešu', 'vlašsk', 'ořech', 'lesní ovoce', 'borůvk', 'jahod', 'malin',
    'basmati', 'tortill', 'chlebíč', 'olivov', 'hotovka', 'chia', 'lněn',
  ];

  static const List<String> _cheap = [
    'kuřecí', 'kuře', 'vepřov', 'vejce', 'vajíč', 'vaječ', 'bílk', 'tvaroh',
    'jogurt', 'mléko', 'kefír', 'podmáslí', 'eidam', 'tofu', 'čočk', 'cizrn',
    'fazol', 'hrách', 'hrach', 'rýže', 'těstovin', 'brambor', 'vločk',
    'chléb', 'chleba', 'rohlík', 'banán', 'jablk', 'pomeranč', 'mrkev',
    'zelí', 'zelenin', 'brokolic', 'špenát', 'okurk', 'rajč', 'paprik',
    'cibul', 'arašíd', 'slunečnic', 'řepkov', 'máslo', 'pohank', 'kroup',
    'jáhl', 'mražen', 'dýn', 'cuket',
  ];

  static bool isCheapName(String name) {
    final n = name.toLowerCase();
    if (_expensive.any(n.contains)) return false;
    return _cheap.any(n.contains);
  }

  /// Jídlo je levné, jen když jsou levné všechny jeho suroviny.
  static bool isCheapCombo(FoodCombo combo) =>
      combo.items.isNotEmpty &&
      combo.items.every((i) => isCheapName(i.mealName));
}
