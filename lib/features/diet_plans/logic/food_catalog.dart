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
    maxGrams: 330, minGrams: 110, pieceGrams: 55, // vejce M bez skořápky
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

  // ----------------------------------------------------------------
  // Další potraviny pro pestrost jídelníčku
  // ----------------------------------------------------------------
  static const porkTenderloin = NutritionFood(
    id: 'pork_tenderloin',
    name: 'Vepřová panenka',
    kcal: 120, protein: 21.0, carbs: 0, fat: 3.5,
    maxGrams: 300, minGrams: 50, weightNote: 'syrová váha',
  );
  static const groundBeef5 = NutritionFood(
    id: 'beef_ground_5',
    name: 'Hovězí mleté 5 %',
    kcal: 137, protein: 21.0, carbs: 0, fat: 5.0,
    maxGrams: 300, minGrams: 50, weightNote: 'syrová váha',
  );
  static const tuna = NutritionFood(
    id: 'tuna',
    name: 'Tuňák ve vlastní šťávě (okapaný)',
    kcal: 116, protein: 26.0, carbs: 0, fat: 1.0,
    maxGrams: 250, minGrams: 50,
  );
  static const shrimp = NutritionFood(
    id: 'shrimp',
    name: 'Krevety',
    kcal: 85, protein: 20.1, carbs: 0.2, fat: 0.5,
    maxGrams: 300, minGrams: 50, weightNote: 'syrová váha',
  );
  static const greekYogurt = NutritionFood(
    id: 'greek_yogurt',
    name: 'Řecký jogurt 0 %',
    kcal: 59, protein: 10.2, carbs: 3.6, fat: 0.4,
    maxGrams: 400, minGrams: 50, step: 10,
  );
  static const cottage = NutritionFood(
    id: 'cottage',
    name: 'Cottage sýr',
    kcal: 98, protein: 11.0, carbs: 3.4, fat: 4.3,
    maxGrams: 300, minGrams: 50, step: 10,
  );
  static const mozzarellaLight = NutritionFood(
    id: 'mozzarella_light',
    name: 'Mozzarella light',
    kcal: 165, protein: 19.0, carbs: 1.5, fat: 9.0,
    maxGrams: 150, minGrams: 30,
  );
  static const seitan = NutritionFood(
    id: 'seitan',
    name: 'Seitan',
    kcal: 140, protein: 25.0, carbs: 4.0, fat: 2.0,
    maxGrams: 250, minGrams: 50,
  );
  static const redBeans = NutritionFood(
    id: 'red_beans',
    name: 'Fazole červené (sterilované, okapané)',
    kcal: 110, protein: 7.5, carbs: 14.0, fat: 0.5,
    maxGrams: 300, minGrams: 50, step: 10,
  );
  static const ryeBread = NutritionFood(
    id: 'rye_bread',
    name: 'Žitný chléb',
    kcal: 240, protein: 7.0, carbs: 46.0, fat: 1.5,
    maxGrams: 200, minGrams: 30,
  );
  static const tortilla = NutritionFood(
    id: 'tortilla',
    name: 'Tortilla pšeničná',
    kcal: 300, protein: 8.0, carbs: 50.0, fat: 7.5,
    maxGrams: 180, minGrams: 30,
  );
  static const couscous = NutritionFood(
    id: 'couscous',
    name: 'Kuskus',
    kcal: 360, protein: 12.8, carbs: 72.0, fat: 0.6,
    maxGrams: 160, minGrams: 30, weightNote: 'suchá váha',
  );
  static const bulgur = NutritionFood(
    id: 'bulgur',
    name: 'Bulgur',
    kcal: 342, protein: 12.3, carbs: 63.0, fat: 1.3,
    maxGrams: 160, minGrams: 30, weightNote: 'suchá váha',
  );
  static const quinoa = NutritionFood(
    id: 'quinoa',
    name: 'Quinoa',
    kcal: 368, protein: 14.1, carbs: 57.0, fat: 6.1,
    maxGrams: 160, minGrams: 30, weightNote: 'suchá váha',
  );
  static const buckwheat = NutritionFood(
    id: 'buckwheat',
    name: 'Pohanka',
    kcal: 343, protein: 13.3, carbs: 61.5, fat: 3.4,
    maxGrams: 160, minGrams: 30, weightNote: 'suchá váha',
  );
  static const apple = NutritionFood(
    id: 'apple',
    name: 'Jablko',
    kcal: 52, protein: 0.3, carbs: 12.0, fat: 0.2,
    maxGrams: 300, minGrams: 50, step: 10,
  );
  static const strawberries = NutritionFood(
    id: 'strawberries',
    name: 'Jahody',
    kcal: 32, protein: 0.7, carbs: 5.7, fat: 0.3,
    maxGrams: 300, minGrams: 50, step: 10,
  );
  static const walnuts = NutritionFood(
    id: 'walnuts',
    name: 'Vlašské ořechy',
    kcal: 654, protein: 15.0, carbs: 7.0, fat: 65.0,
    maxGrams: 40, minGrams: 10,
  );
  static const cashews = NutritionFood(
    id: 'cashews',
    name: 'Kešu',
    kcal: 553, protein: 18.0, carbs: 27.0, fat: 44.0,
    maxGrams: 40, minGrams: 10,
  );

  // ----------------------------------------------------------------
  // Levné potraviny (úsporná varianta jídelníčku)
  // ----------------------------------------------------------------
  static const chickenThigh = NutritionFood(
    id: 'chicken_thigh',
    name: 'Kuřecí stehenní maso (bez kůže)',
    kcal: 117, protein: 19.7, carbs: 0, fat: 4.2,
    maxGrams: 300, minGrams: 50, weightNote: 'syrová váha',
  );
  static const porkLeg = NutritionFood(
    id: 'pork_leg',
    name: 'Vepřová kýta',
    kcal: 129, protein: 21.0, carbs: 0, fat: 5.0,
    maxGrams: 300, minGrams: 50, weightNote: 'syrová váha',
  );
  static const milk = NutritionFood(
    id: 'milk',
    name: 'Mléko polotučné 1,5 %',
    kcal: 47, protein: 3.4, carbs: 4.9, fat: 1.5,
    maxGrams: 400, minGrams: 100, step: 50,
  );
  static const whiteYogurt = NutritionFood(
    id: 'white_yogurt',
    name: 'Bílý jogurt 3 %',
    kcal: 65, protein: 4.5, carbs: 5.0, fat: 3.0,
    maxGrams: 300, minGrams: 100, step: 10,
  );
  static const rapeseedOil = NutritionFood(
    id: 'rapeseed_oil',
    name: 'Řepkový olej',
    kcal: 884, protein: 0, carbs: 0, fat: 100.0,
    maxGrams: 30, minGrams: 5,
  );
  static const vegetablesBudget = NutritionFood(
    id: 'vegetables_budget',
    name: 'Zelenina (mrkev, zelí, mražená směs…)',
    kcal: 30, protein: 1.5, carbs: 5.0, fat: 0.2,
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
    porkTenderloin,
    groundBeef5,
    tuna,
    shrimp,
    greekYogurt,
    cottage,
    mozzarellaLight,
    seitan,
    redBeans,
    ryeBread,
    tortilla,
    couscous,
    bulgur,
    quinoa,
    buckwheat,
    apple,
    strawberries,
    walnuts,
    cashews,
    chickenThigh,
    porkLeg,
    milk,
    whiteYogurt,
    rapeseedOil,
    vegetablesBudget,
  ];

  /// Klíčová slova vyloučení (z výběru "nechci jíst") → potraviny.
  /// Hodnoty výběru v aplikaci: 'Losos', 'Vejce', 'Hovězí maso'.
  /// Alergie, nesnášenlivosti a neoblíbená jídla právě vybraného klienta.
  /// Nastavuje je `activeFoodExclusionsProvider`; platí pro VŠECHNY
  /// jídelníčky (týdenní, keto, půst, vlny, výběrový plán).
  static List<String> activeExclusions = const [];

  /// Alergeny a skupiny potravin → potraviny z katalogu. Klíč je začátek
  /// slova, takže sedí „mléko“, „mléčné výrobky“, „ořechy“, „ořech“…
  static const Map<String, List<String>> _groups = {
    // mléko a mléčné výrobky (alergie na bílkovinu i laktóza)
    'mlé': _dairy,
    'mlék': _dairy,
    'mléč': _dairy,
    'lakt': _dairy,
    'sýr': ['gouda', 'cottage', 'mozzarella_light'],
    'jogurt': ['greek_yogurt', 'white_yogurt', 'skyr'],
    'tvaroh': ['quark_low_fat'],
    'syrovátk': ['whey'],
    // lepek
    'lepe': _gluten,
    'glut': _gluten,
    'pšen': _gluten,
    'celiak': _gluten,
    'oves': ['oats'],
    'vločk': ['oats'],
    // vejce
    'vejc': ['eggs'],
    'vaj': ['eggs'],
    // skořápkové plody a arašídy
    // „ořechy“ z opatrnosti včetně arašídů (u alergie častá zkřížená reakce)
    'ořech': ['almonds', 'walnuts', 'cashews', 'peanut_butter'],
    'mandl': ['almonds'],
    'kešu': ['cashews'],
    'arašíd': ['peanut_butter'],
    'buráks': ['peanut_butter'],
    'burák': ['peanut_butter'],
    // ryby a mořské plody
    'ryb': ['salmon', 'cod', 'tuna'],
    'losos': ['salmon'],
    'tuňák': ['tuna'],
    'tresk': ['cod'],
    'kreve': ['shrimp'],
    'korýš': ['shrimp'],
    'mořsk': ['shrimp'],
    // sója
    'sój': _soy,
    'soj': _soy,
    'tofu': ['tofu'],
    // luštěniny
    'lušt': ['lentils', 'chickpeas', 'red_beans'],
    'čočk': ['lentils'],
    'cizr': ['chickpeas'],
    'fazol': ['red_beans'],
    // maso
    'vepř': ['pork_tenderloin', 'pork_leg', 'ham'],
    'šunk': ['ham'],
    'hověz': ['beef_lean', 'beef_ribeye', 'beef_ground_5'],
    'kuř': ['chicken_breast', 'chicken_thigh'],
    'krůt': ['turkey_breast'],
    'drůbe': ['chicken_breast', 'chicken_thigh', 'turkey_breast'],
    // ovoce
    'banán': ['banana'],
    'jahod': ['strawberries'],
    'borův': ['blueberries'],
    'jablk': ['apple'],
    'avok': ['avocado'],
  };

  static const List<String> _dairy = [
    'milk', 'quark_low_fat', 'skyr', 'greek_yogurt', 'white_yogurt',
    'cottage', 'gouda', 'mozzarella_light', 'butter', 'whey',
  ];
  static const List<String> _gluten = [
    'oats', 'wholegrain_bread', 'rye_bread', 'pasta', 'tortilla',
    'couscous', 'bulgur', 'seitan',
  ];
  static const List<String> _soy = [
    'tofu', 'tempeh', 'soy_protein', 'soy_yogurt',
  ];

  /// Rozdělí volný text („laktóza, ořechy; ryby“) na jednotlivé položky.
  static List<String> parseExclusions(String text) => text
      .toLowerCase()
      .split(RegExp(r'[,;/\n]|\s+a\s+|\s+nebo\s+'))
      .map((s) => s.trim())
      .where((s) => s.length >= 3 && s != '—' && s != 'nic' && s != 'žádné')
      .toSet()
      .toList();

  static bool isExcluded(NutritionFood food, List<String> excluded) {
    for (final raw in [...excluded, ...activeExclusions]) {
      final e = raw.trim().toLowerCase();
      if (e.isEmpty) continue;

      final name = food.name.toLowerCase();
      if (name.contains(e)) return true;

      for (final g in _groups.entries) {
        if (e.contains(g.key) && g.value.contains(food.id)) return true;
      }

      if (e.contains('hovězí') && food.id.startsWith('beef')) return true;
      if (e.contains('vejce') && food.id == 'eggs') return true;
      if (e.contains('losos') && food.id == 'salmon') return true;
    }
    return false;
  }
}
