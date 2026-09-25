/// Katalog potravin pro generování jídelníčků.
///
/// Hodnoty jsou na 100 g potraviny VE STAVU, VE KTERÉM SE VÁŽÍ:
///   - maso a ryby: syrová váha,
///   - rýže, těstoviny, vločky: suchá váha,
///   - brambory a batáty: syrová oloupaná váha.
///
/// Sacharidy = využitelné sacharidy (bez vlákniny), jak je uvádějí etikety
/// v EU. Kalorie odpovídají součtu 4·B + 4·S + 9·T (+ vláknina) s odchylkou
/// do ~8 %. Zdroj: běžné nutriční tabulky (USDA FoodData Central,
/// české etikety) – orientační průměrné hodnoty.
class NutritionFood {
  final String id;

  /// Název pro jídelníček a nákupní seznam.
  final String name;

  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  /// Hmotnost 1 kusu (např. vejce). Když je nastavena, porce se zaokrouhluje
  /// na celé kusy a v jídelníčku se zobrazuje v kusech.
  final double? pieceGrams;

  /// Rozumné maximum na jednu porci (g).
  final double maxGrams;

  /// Nejmenší smysluplná porce (g). Menší množství se do jídla nedává
  /// (např. 5 g šunky) a výpočet se přepočítá bez této potraviny.
  final double minGrams;

  /// Krok zaokrouhlení porce (g).
  final double step;

  /// Poznámka ke stavu potraviny (syrová / suchá váha).
  final String? weightNote;

  const NutritionFood({
    required this.id,
    required this.name,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.maxGrams,
    this.minGrams = 0,
    this.pieceGrams,
    this.step = 5,
    this.weightNote,
  });

  double get proteinPerG => protein / 100;
  double get carbsPerG => carbs / 100;
  double get fatPerG => fat / 100;
  double get kcalPerG => kcal / 100;

  /// Název s poznámkou o stavu (např. "Rýže bílá (suchá váha)").
  String get displayName => weightNote == null ? name : '$name ($weightNote)';
}

class FoodCatalog {
  // ----------------------------------------------------------------
  // Bílkovinné zdroje
  // ----------------------------------------------------------------
  static const chickenBreast = NutritionFood(
    id: 'chicken_breast',
    name: 'Kuřecí prsa',
    kcal: 120, protein: 22.5, carbs: 0, fat: 2.6,
    maxGrams: 300, minGrams: 50, weightNote: 'syrová váha',
  );
  static const turkeyBreast = NutritionFood(
    id: 'turkey_breast',
    name: 'Krůtí prsa',
    kcal: 114, protein: 23.7, carbs: 0, fat: 1.5,
    maxGrams: 300, minGrams: 50, weightNote: 'syrová váha',
  );
  static const beefLean = NutritionFood(
    id: 'beef_lean',
    name: 'Hovězí maso libové (zadní)',
    kcal: 125, protein: 22.0, carbs: 0, fat: 4.0,
    maxGrams: 300, minGrams: 50, weightNote: 'syrová váha',
  );
  static const salmon = NutritionFood(
    id: 'salmon',
    name: 'Losos',
    kcal: 208, protein: 20.0, carbs: 0, fat: 13.0,
    maxGrams: 250, minGrams: 50, weightNote: 'syrová váha',
  );
  static const cod = NutritionFood(
    id: 'cod',
    name: 'Treska',
    kcal: 82, protein: 17.8, carbs: 0, fat: 0.7,
    maxGrams: 350, minGrams: 50, weightNote: 'syrová váha',
  );
  static const beefRibeye = NutritionFood(
    id: 'beef_ribeye',
    name: 'Hovězí steak (rib eye)',
    kcal: 247, protein: 19.0, carbs: 0, fat: 19.0,
    maxGrams: 300, minGrams: 50, weightNote: 'syrová váha',
  );
  static const eggs = NutritionFood(
    id: 'eggs',
    name: 'Vejce',
    kcal: 143, protein: 12.6, carbs: 0.7, fat: 9.5,
    maxGrams: 330, pieceGrams: 55, // vejce M bez skořápky
  );
  static const skyr = NutritionFood(
    id: 'skyr',
    name: 'Skyr natur',
    kcal: 63, protein: 11.0, carbs: 4.0, fat: 0.2,
    maxGrams: 400, minGrams: 50,
  );
  static const quarkLowFat = NutritionFood(
    id: 'quark_low_fat',
    name: 'Tvaroh nízkotučný',
    kcal: 72, protein: 12.5, carbs: 4.0, fat: 0.5,
    maxGrams: 400, minGrams: 50,
  );
  static const whey = NutritionFood(
    id: 'whey',
    name: 'Syrovátkový protein (whey)',
    kcal: 385, protein: 78.0, carbs: 7.0, fat: 5.0,
    maxGrams: 50, minGrams: 10,
  );
  static const ham = NutritionFood(
    id: 'ham',
    name: 'Šunka nejvyšší jakosti',
    kcal: 110, protein: 19.0, carbs: 1.0, fat: 3.5,
    maxGrams: 150, minGrams: 20,
  );
  static const gouda = NutritionFood(
    id: 'gouda',
    name: 'Sýr gouda 45 %',
    kcal: 356, protein: 25.0, carbs: 2.2, fat: 27.4,
    maxGrams: 80, minGrams: 15,
  );

  // ----------------------------------------------------------------
  // Rostlinné bílkovinné zdroje (vegan)
  // ----------------------------------------------------------------
  static const tofu = NutritionFood(
    id: 'tofu',
    name: 'Tofu natural',
    kcal: 144, protein: 15.8, carbs: 1.9, fat: 8.7,
    maxGrams: 300, minGrams: 50,
  );
  static const tempeh = NutritionFood(
    id: 'tempeh',
    name: 'Tempeh',
    kcal: 195, protein: 20.3, carbs: 7.6, fat: 10.8,
    maxGrams: 250, minGrams: 50,
  );
  static const lentils = NutritionFood(
    id: 'lentils',
    name: 'Čočka červená',
    kcal: 330, protein: 24.6, carbs: 50.0, fat: 1.1,
    maxGrams: 130, minGrams: 30, weightNote: 'suchá váha',
  );
  static const chickpeas = NutritionFood(
    id: 'chickpeas',
    name: 'Cizrna (sterilovaná, okapaná)',
    kcal: 125, protein: 7.0, carbs: 15.5, fat: 2.3,
    maxGrams: 300, minGrams: 50, step: 10,
  );
  static const soyProtein = NutritionFood(
    id: 'soy_protein',
    name: 'Sójový protein (izolát)',
    kcal: 370, protein: 85.0, carbs: 2.0, fat: 1.5,
    maxGrams: 50, minGrams: 10,
  );
  static const soyYogurt = NutritionFood(
    id: 'soy_yogurt',
    name: 'Sójový jogurt natur',
    kcal: 50, protein: 4.0, carbs: 2.1, fat: 2.3,
    maxGrams: 300, minGrams: 50, step: 10,
  );

  // ----------------------------------------------------------------
  // Sacharidové zdroje
  // ----------------------------------------------------------------
  static const oats = NutritionFood(
    id: 'oats',
    name: 'Ovesné vločky',
    kcal: 372, protein: 13.2, carbs: 60.0, fat: 6.5,
    maxGrams: 130, minGrams: 20, weightNote: 'suchá váha',
  );
  static const rice = NutritionFood(
    id: 'rice',
    name: 'Rýže bílá',
    kcal: 355, protein: 7.0, carbs: 78.0, fat: 0.6,
    maxGrams: 160, minGrams: 30, weightNote: 'suchá váha',
  );
  static const pasta = NutritionFood(
    id: 'pasta',
    name: 'Těstoviny',
    kcal: 355, protein: 12.5, carbs: 71.0, fat: 1.5,
    maxGrams: 160, minGrams: 30, weightNote: 'suchá váha',
  );
  static const potatoes = NutritionFood(
    id: 'potatoes',
    name: 'Brambory',
    kcal: 77, protein: 2.0, carbs: 17.0, fat: 0.1,
    maxGrams: 700, minGrams: 80, step: 10, weightNote: 'syrová oloupaná váha',
  );
  static const sweetPotato = NutritionFood(
    id: 'sweet_potato',
    name: 'Batáty',
    kcal: 86, protein: 1.6, carbs: 20.0, fat: 0.1,
    maxGrams: 600, minGrams: 80, step: 10, weightNote: 'syrová oloupaná váha',
  );
  static const wholegrainBread = NutritionFood(
    id: 'wholegrain_bread',
    name: 'Celozrnný chléb',
    kcal: 247, protein: 13.0, carbs: 41.0, fat: 3.4,
    maxGrams: 200, minGrams: 30,
  );
  static const riceCakes = NutritionFood(
    id: 'rice_cakes',
    name: 'Rýžové chlebíčky',
    kcal: 387, protein: 8.0, carbs: 81.0, fat: 2.8,
    maxGrams: 60, minGrams: 10,
  );
  static const banana = NutritionFood(
    id: 'banana',
    name: 'Banán',
    kcal: 89, protein: 1.1, carbs: 20.0, fat: 0.3,
    maxGrams: 250, minGrams: 50, step: 10,
  );
  static const blueberries = NutritionFood(
    id: 'blueberries',
    name: 'Borůvky',
    kcal: 57, protein: 0.7, carbs: 12.0, fat: 0.3,
    maxGrams: 200, minGrams: 30, step: 10,
  );

  // ----------------------------------------------------------------
  // Tuky
  // ----------------------------------------------------------------
  static const oliveOil = NutritionFood(
    id: 'olive_oil',
    name: 'Olivový olej',
    kcal: 884, protein: 0, carbs: 0, fat: 100.0,
    maxGrams: 30, minGrams: 5,
  );
  static const butter = NutritionFood(
    id: 'butter',
    name: 'Máslo',
    kcal: 717, protein: 0.9, carbs: 0.1, fat: 81.0,
    maxGrams: 30, minGrams: 5,
  );
  static const almonds = NutritionFood(
    id: 'almonds',
    name: 'Mandle',
    kcal: 579, protein: 21.0, carbs: 9.9, fat: 50.0,
    maxGrams: 50, minGrams: 10,
  );
  static const peanutButter = NutritionFood(
    id: 'peanut_butter',
    name: 'Arašídové máslo',
    kcal: 588, protein: 25.0, carbs: 14.0, fat: 50.0,
    maxGrams: 40, minGrams: 10,
  );
  static const avocado = NutritionFood(
    id: 'avocado',
    name: 'Avokádo',
    kcal: 160, protein: 2.0, carbs: 1.8, fat: 14.7,
    maxGrams: 200, minGrams: 30, step: 10,
  );

  // ----------------------------------------------------------------
  // Zelenina (pevná porce)
  // ----------------------------------------------------------------
  static const vegetables = NutritionFood(
    id: 'vegetables',
    name: 'Zelenina (brokolice, paprika, rajče…)',
    kcal: 30, protein: 1.8, carbs: 4.5, fat: 0.3,
    maxGrams: 400, step: 10,
  );

  static const List<NutritionFood> all = [
    chickenBreast,
    turkeyBreast,
    beefLean,
    salmon,
    cod,
    beefRibeye,
    eggs,
    skyr,
    quarkLowFat,
    whey,
    ham,
    gouda,
    tofu,
    tempeh,
    lentils,
    chickpeas,
    soyProtein,
    soyYogurt,
    oats,
    rice,
    pasta,
    potatoes,
    sweetPotato,
    wholegrainBread,
    riceCakes,
    banana,
    blueberries,
    oliveOil,
    butter,
    almonds,
    peanutButter,
    avocado,
    vegetables,
  ];

  /// Klíčová slova vyloučení (z výběru "nechci jíst") → potraviny.
  /// Hodnoty výběru v aplikaci: 'Losos', 'Vejce', 'Hovězí maso'.
  static bool isExcluded(NutritionFood food, List<String> excluded) {
    for (final raw in excluded) {
      final e = raw.trim().toLowerCase();
      if (e.isEmpty) continue;

      final name = food.name.toLowerCase();
      if (name.contains(e)) return true;

      if (e.contains('hovězí') && food.id.startsWith('beef')) return true;
      if (e.contains('vejce') && food.id == 'eggs') return true;
      if (e.contains('losos') && food.id == 'salmon') return true;
    }
    return false;
  }
}
