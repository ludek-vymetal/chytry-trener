import '../models/meal.dart';

/// Velká startovní databáze (orientační hodnoty na 100 g).
/// Uživatel si je může časem zpřesnit (a banka se ukládá do storage).
///
/// Poznámka:
/// - Většina položek je "na 100 g suroviny / hotové potraviny".
/// - Sekce "HOTOVÁ JÍDLA (porce)" jsou celé porce jako jedna položka:
///   hodnoty jsou přepočítané na 100 g hotového jídla a defaultGrams = typická porce.
class FoodBankSeed {
  static const List<Meal> items = [
    // =========================
    // MASO / RYBY
    // =========================
    Meal(
      name: 'Kuřecí prsa',
      caloriesPer100g: 165,
      proteinPer100g: 31.0,
      carbsPer100g: 0.0,
      fatsPer100g: 3.6,
      defaultGrams: 200,
    ),
    Meal(
      name: 'Kuřecí stehno (bez kůže)',
      caloriesPer100g: 177,
      proteinPer100g: 24.0,
      carbsPer100g: 0.0,
      fatsPer100g: 8.0,
      defaultGrams: 220,
    ),
    Meal(
      name: 'Krůtí prsa',
      caloriesPer100g: 135,
      proteinPer100g: 29.0,
      carbsPer100g: 0.0,
      fatsPer100g: 1.0,
      defaultGrams: 200,
    ),
    Meal(
      name: 'Hovězí (libové)',
      caloriesPer100g: 170,
      proteinPer100g: 26.0,
      carbsPer100g: 0.0,
      fatsPer100g: 7.0,
      defaultGrams: 180,
    ),
    Meal(
      name: 'Hovězí mleté 5%',
      caloriesPer100g: 137,
      proteinPer100g: 21.0,
      carbsPer100g: 0.0,
      fatsPer100g: 5.0,
      defaultGrams: 180,
    ),
    Meal(
      name: 'Vepřová kýta (libová)',
      caloriesPer100g: 160,
      proteinPer100g: 26.0,
      carbsPer100g: 0.0,
      fatsPer100g: 6.0,
      defaultGrams: 180,
    ),
    Meal(
      name: 'Šunka (libová)',
      caloriesPer100g: 120,
      proteinPer100g: 20.0,
      carbsPer100g: 2.0,
      fatsPer100g: 3.0,
      defaultGrams: 60,
    ),
    Meal(
      name: 'Tuňák ve vlastní šťávě',
      caloriesPer100g: 116,
      proteinPer100g: 26.0,
      carbsPer100g: 0.0,
      fatsPer100g: 1.0,
      defaultGrams: 120,
    ),
    Meal(
      name: 'Losos',
      caloriesPer100g: 208,
      proteinPer100g: 20.0,
      carbsPer100g: 0.0,
      fatsPer100g: 13.0,
      defaultGrams: 180,
    ),
    Meal(
      name: 'Treska',
      caloriesPer100g: 82,
      proteinPer100g: 18.0,
      carbsPer100g: 0.0,
      fatsPer100g: 0.7,
      defaultGrams: 200,
    ),
    Meal(
      name: 'Krevety',
      caloriesPer100g: 99,
      proteinPer100g: 24.0,
      carbsPer100g: 0.2,
      fatsPer100g: 0.3,
      defaultGrams: 180,
    ),

    // =========================
    // VEJCE
    // =========================
    Meal(
      name: 'Vejce',
      caloriesPer100g: 143,
      proteinPer100g: 13.0,
      carbsPer100g: 1.1,
      fatsPer100g: 9.5,
      defaultGrams: 120,
    ),
    Meal(
      name: 'Bílky',
      caloriesPer100g: 52,
      proteinPer100g: 11.0,
      carbsPer100g: 0.7,
      fatsPer100g: 0.2,
      defaultGrams: 200,
    ),

    // =========================
    // MLÉČNÉ / HIGH PROTEIN
    // =========================
    Meal(
      name: 'Tvaroh (polotučný)',
      caloriesPer100g: 120,
      proteinPer100g: 17.0,
      carbsPer100g: 4.0,
      fatsPer100g: 4.0,
      defaultGrams: 250,
    ),
    Meal(
      name: 'Tvaroh (nízkotučný)',
      caloriesPer100g: 92,
      proteinPer100g: 18.0,
      carbsPer100g: 4.0,
      fatsPer100g: 0.5,
      defaultGrams: 250,
    ),
    Meal(
      name: 'Skyr (bílý)',
      caloriesPer100g: 60,
      proteinPer100g: 11.0,
      carbsPer100g: 4.0,
      fatsPer100g: 0.2,
      defaultGrams: 250,
    ),
    Meal(
      name: 'Řecký jogurt 0%',
      caloriesPer100g: 59,
      proteinPer100g: 10.0,
      carbsPer100g: 3.6,
      fatsPer100g: 0.4,
      defaultGrams: 200,
    ),
    Meal(
      name: 'Cottage',
      caloriesPer100g: 98,
      proteinPer100g: 12.0,
      carbsPer100g: 3.0,
      fatsPer100g: 4.0,
      defaultGrams: 200,
    ),
    Meal(
      name: 'Mozzarella light',
      caloriesPer100g: 170,
      proteinPer100g: 22.0,
      carbsPer100g: 2.0,
      fatsPer100g: 8.0,
      defaultGrams: 125,
    ),
    Meal(
      name: 'Sýr eidam 30%',
      caloriesPer100g: 250,
      proteinPer100g: 30.0,
      carbsPer100g: 1.0,
      fatsPer100g: 14.0,
      defaultGrams: 60,
    ),
    Meal(
      name: 'Mléko 1.5%',
      caloriesPer100g: 46,
      proteinPer100g: 3.4,
      carbsPer100g: 4.8,
      fatsPer100g: 1.5,
      defaultGrams: 300,
    ),
    Meal(
      name: 'Kefír',
      caloriesPer100g: 50,
      proteinPer100g: 3.5,
      carbsPer100g: 4.0,
      fatsPer100g: 1.8,
      defaultGrams: 300,
    ),

    // =========================
    // PROTEIN / SUPLEMENTY
    // =========================
    Meal(
      name: 'Syrovátkový protein (whey) prášek',
      caloriesPer100g: 400,
      proteinPer100g: 80.0,
      carbsPer100g: 8.0,
      fatsPer100g: 6.0,
      defaultGrams: 30,
    ),
    Meal(
      name: 'Proteinový pudink (obecně)',
      caloriesPer100g: 80,
      proteinPer100g: 10.0,
      carbsPer100g: 6.0,
      fatsPer100g: 1.5,
      defaultGrams: 200,
    ),

    // =========================
    // LUŠTĚNINY / VEG
    // =========================
    Meal(
      name: 'Tofu',
      caloriesPer100g: 144,
      proteinPer100g: 15.0,
      carbsPer100g: 3.0,
      fatsPer100g: 9.0,
      defaultGrams: 200,
    ),
    Meal(
      name: 'Tempeh',
      caloriesPer100g: 193,
      proteinPer100g: 20.0,
      carbsPer100g: 9.0,
      fatsPer100g: 11.0,
      defaultGrams: 180,
    ),
    Meal(
      name: 'Seitan',
      caloriesPer100g: 140,
      proteinPer100g: 25.0,
      carbsPer100g: 4.0,
      fatsPer100g: 2.0,
      defaultGrams: 150,
    ),
    Meal(
      name: 'Sójový protein (izolát)',
      caloriesPer100g: 370,
      proteinPer100g: 85.0,
      carbsPer100g: 2.0,
      fatsPer100g: 1.5,
      defaultGrams: 30,
    ),
    Meal(
      name: 'Sójový jogurt natur',
      caloriesPer100g: 50,
      proteinPer100g: 4.0,
      carbsPer100g: 2.1,
      fatsPer100g: 2.3,
      defaultGrams: 150,
    ),
    Meal(
      name: 'Sójové mléko (bez cukru)',
      caloriesPer100g: 33,
      proteinPer100g: 3.3,
      carbsPer100g: 0.3,
      fatsPer100g: 1.8,
      defaultGrams: 250,
    ),
    Meal(
      name: 'Čočka vařená',
      caloriesPer100g: 116,
      proteinPer100g: 9.0,
      carbsPer100g: 20.0,
      fatsPer100g: 0.4,
      defaultGrams: 250,
    ),
    Meal(
      name: 'Cizrna vařená',
      caloriesPer100g: 164,
      proteinPer100g: 9.0,
      carbsPer100g: 27.0,
      fatsPer100g: 2.6,
      defaultGrams: 250,
    ),
    Meal(
      name: 'Fazole vařené',
      caloriesPer100g: 127,
      proteinPer100g: 9.0,
      carbsPer100g: 23.0,
      fatsPer100g: 0.5,
      defaultGrams: 250,
    ),

    // =========================
    // PŘÍLOHY (COOKED)
    // =========================
    Meal(
      name: 'Rýže vařená',
      caloriesPer100g: 130,
      proteinPer100g: 2.7,
      carbsPer100g: 28.0,
      fatsPer100g: 0.3,
      defaultGrams: 250,
    ),
    Meal(
      name: 'Basmati rýže vařená',
      caloriesPer100g: 121,
      proteinPer100g: 2.5,
      carbsPer100g: 27.0,
      fatsPer100g: 0.3,
      defaultGrams: 250,
    ),
    Meal(
      name: 'Těstoviny vařené',
      caloriesPer100g: 131,
      proteinPer100g: 5.0,
      carbsPer100g: 25.0,
      fatsPer100g: 1.1,
      defaultGrams: 250,
    ),
    Meal(
      name: 'Celozrnné těstoviny vařené',
      caloriesPer100g: 124,
      proteinPer100g: 5.5,
      carbsPer100g: 24.0,
      fatsPer100g: 1.2,
      defaultGrams: 250,
    ),
    Meal(
      name: 'Quinoa vařená',
      caloriesPer100g: 120,
      proteinPer100g: 4.4,
      carbsPer100g: 21.3,
      fatsPer100g: 1.9,
      defaultGrams: 220,
    ),
    Meal(
      name: 'Kuskus vařený',
      caloriesPer100g: 112,
      proteinPer100g: 3.8,
      carbsPer100g: 23.0,
      fatsPer100g: 0.2,
      defaultGrams: 250,
    ),
    Meal(
      name: 'Bulgur vařený',
      caloriesPer100g: 83,
      proteinPer100g: 3.1,
      carbsPer100g: 18.6,
      fatsPer100g: 0.2,
      defaultGrams: 260,
    ),
    Meal(
      name: 'Brambory vařené',
      caloriesPer100g: 77,
      proteinPer100g: 2.0,
      carbsPer100g: 17.0,
      fatsPer100g: 0.1,
      defaultGrams: 300,
    ),
    Meal(
      name: 'Batáty pečené',
      caloriesPer100g: 90,
      proteinPer100g: 2.0,
      carbsPer100g: 21.0,
      fatsPer100g: 0.2,
      defaultGrams: 300,
    ),
    Meal(
      name: 'Ovesné vločky',
      caloriesPer100g: 389,
      proteinPer100g: 17.0,
      carbsPer100g: 66.0,
      fatsPer100g: 7.0,
      defaultGrams: 80,
    ),

    // =========================
    // PEČIVO / SNÍDANĚ
    // =========================
    Meal(
      name: 'Celozrnný chléb',
      caloriesPer100g: 250,
      proteinPer100g: 9.0,
      carbsPer100g: 43.0,
      fatsPer100g: 4.0,
      defaultGrams: 120,
    ),
    Meal(
      name: 'Tortilla (pšeničná)',
      caloriesPer100g: 300,
      proteinPer100g: 8.0,
      carbsPer100g: 50.0,
      fatsPer100g: 8.0,
      defaultGrams: 80,
    ),
    Meal(
      name: 'Tortilla (celozrnná)',
      caloriesPer100g: 290,
      proteinPer100g: 9.0,
      carbsPer100g: 47.0,
      fatsPer100g: 7.0,
      defaultGrams: 80,
    ),
    Meal(
      name: 'Rohlík',
      caloriesPer100g: 270,
      proteinPer100g: 9.0,
      carbsPer100g: 52.0,
      fatsPer100g: 2.5,
      defaultGrams: 50,
    ),
    Meal(
      name: 'Rýžové chlebíčky',
      caloriesPer100g: 380,
      proteinPer100g: 7.0,
      carbsPer100g: 81.0,
      fatsPer100g: 3.0,
      defaultGrams: 30,
    ),

    // =========================
    // OVOCE
    // =========================
    Meal(
      name: 'Banán',
      caloriesPer100g: 89,
      proteinPer100g: 1.1,
      carbsPer100g: 23.0,
      fatsPer100g: 0.3,
      defaultGrams: 120,
    ),
    Meal(
      name: 'Jablko',
      caloriesPer100g: 52,
      proteinPer100g: 0.3,
      carbsPer100g: 14.0,
      fatsPer100g: 0.2,
      defaultGrams: 180,
    ),
    Meal(
      name: 'Lesní ovoce (mix)',
      caloriesPer100g: 50,
      proteinPer100g: 1.0,
      carbsPer100g: 12.0,
      fatsPer100g: 0.3,
      defaultGrams: 150,
    ),
    Meal(
      name: 'Pomeranč',
      caloriesPer100g: 47,
      proteinPer100g: 0.9,
      carbsPer100g: 12.0,
      fatsPer100g: 0.1,
      defaultGrams: 200,
    ),

    // =========================
    // ZELENINA (low kcal)
    // =========================
    Meal(
      name: 'Brokolice',
      caloriesPer100g: 34,
      proteinPer100g: 2.8,
      carbsPer100g: 7.0,
      fatsPer100g: 0.4,
      defaultGrams: 250,
    ),
    Meal(
      name: 'Špenát',
      caloriesPer100g: 23,
      proteinPer100g: 2.9,
      carbsPer100g: 3.6,
      fatsPer100g: 0.4,
      defaultGrams: 150,
    ),
    Meal(
      name: 'Okurka',
      caloriesPer100g: 15,
      proteinPer100g: 0.7,
      carbsPer100g: 3.6,
      fatsPer100g: 0.1,
      defaultGrams: 200,
    ),
    Meal(
      name: 'Rajče',
      caloriesPer100g: 18,
      proteinPer100g: 0.9,
      carbsPer100g: 3.9,
      fatsPer100g: 0.2,
      defaultGrams: 200,
    ),
    Meal(
      name: 'Paprika',
      caloriesPer100g: 31,
      proteinPer100g: 1.0,
      carbsPer100g: 6.0,
      fatsPer100g: 0.3,
      defaultGrams: 200,
    ),
    Meal(
      name: 'Mrkev',
      caloriesPer100g: 41,
      proteinPer100g: 0.9,
      carbsPer100g: 10.0,
      fatsPer100g: 0.2,
      defaultGrams: 150,
    ),

    // =========================
    // TUKY / OŘECHY
    // =========================
    Meal(
      name: 'Olivový olej',
      caloriesPer100g: 884,
      proteinPer100g: 0.0,
      carbsPer100g: 0.0,
      fatsPer100g: 100.0,
      defaultGrams: 10,
    ),
    Meal(
      name: 'Avokádo',
      caloriesPer100g: 160,
      proteinPer100g: 2.0,
      carbsPer100g: 9.0,
      fatsPer100g: 15.0,
      defaultGrams: 120,
    ),
    Meal(
      name: 'Mandle',
      caloriesPer100g: 579,
      proteinPer100g: 21.0,
      carbsPer100g: 22.0,
      fatsPer100g: 50.0,
      defaultGrams: 30,
    ),
    Meal(
      name: 'Arašídy',
      caloriesPer100g: 567,
      proteinPer100g: 26.0,
      carbsPer100g: 16.0,
      fatsPer100g: 49.0,
      defaultGrams: 30,
    ),
    Meal(
      name: 'Arašídové máslo',
      caloriesPer100g: 588,
      proteinPer100g: 25.0,
      carbsPer100g: 20.0,
      fatsPer100g: 50.0,
      defaultGrams: 25,
    ),
    Meal(
      name: 'Kešu',
      caloriesPer100g: 553,
      proteinPer100g: 18.0,
      carbsPer100g: 30.0,
      fatsPer100g: 44.0,
      defaultGrams: 30,
    ),

    // ✅ DOPLNĚNO: Vlašské ořechy (bylo v hotovkách, chybělo v bance)
    Meal(
      name: 'Vlašské ořechy',
      caloriesPer100g: 654,
      proteinPer100g: 15.0,
      carbsPer100g: 14.0,
      fatsPer100g: 65.0,
      defaultGrams: 20,
    ),

    // =========================
    // SNACKY / „FIT“ HOTOVKY
    // =========================

    // ✅ DOPLNĚNO: alias přesného názvu používaného v hotovkách
    Meal(
      name: 'Proteinová tyčinka',
      caloriesPer100g: 360,
      proteinPer100g: 30.0,
      carbsPer100g: 35.0,
      fatsPer100g: 12.0,
      defaultGrams: 60,
    ),

    Meal(
      name: 'Proteinová tyčinka (obecná)',
      caloriesPer100g: 360,
      proteinPer100g: 30.0,
      carbsPer100g: 35.0,
      fatsPer100g: 12.0,
      defaultGrams: 60,
    ),
    Meal(
      name: 'Rýžový nákyp (obecný)',
      caloriesPer100g: 140,
      proteinPer100g: 4.0,
      carbsPer100g: 25.0,
      fatsPer100g: 2.5,
      defaultGrams: 300,
    ),
    Meal(
      name: 'Tuňáková pomazánka (obecná)',
      caloriesPer100g: 180,
      proteinPer100g: 16.0,
      carbsPer100g: 3.0,
      fatsPer100g: 11.0,
      defaultGrams: 120,
    ),
    Meal(
      name: 'Vepřový řízek (smažený)',
      caloriesPer100g: 290,
      proteinPer100g: 20.0,
      carbsPer100g: 10.0,
      fatsPer100g: 18.0,
      defaultGrams: 180,
    ),

    // =========================
    // HOTOVÁ JÍDLA (porce) – “kombo”, co chceš ty
    // hodnoty jsou na 100 g hotového jídla, defaultGrams = porce
    // =========================

    // 1) Kuře + rýže + brokolice + olej (porce ~340 g; cca 560 kcal)
    Meal(
      name: 'HOTOVKA: Kuře + rýže + brokolice',
      caloriesPer100g: 165,
      proteinPer100g: 12.4,
      carbsPer100g: 18.8,
      fatsPer100g: 3.5,
      defaultGrams: 340,
    ),

    // 2) Losos + brambory + zelenina (porce ~520 g; cca 520 kcal)
    Meal(
      name: 'HOTOVKA: Losos + brambory + zelenina',
      caloriesPer100g: 100,
      proteinPer100g: 5.8,
      carbsPer100g: 8.7,
      fatsPer100g: 4.6,
      defaultGrams: 520,
    ),

    // 3) Hovězí mleté + celozrnné těstoviny + passata (porce ~380 g; cca 610 kcal)
    Meal(
      name: 'HOTOVKA: Hovězí mleté + těstoviny',
      caloriesPer100g: 161,
      proteinPer100g: 10.0,
      carbsPer100g: 15.8,
      fatsPer100g: 4.7,
      defaultGrams: 380,
    ),

    // 4) Krůta + bulgur + avokádo + špenát (porce ~330 g; cca 585 kcal)
    Meal(
      name: 'HOTOVKA: Krůta + bulgur + avokádo',
      caloriesPer100g: 177,
      proteinPer100g: 13.3,
      carbsPer100g: 18.8,
      fatsPer100g: 4.2,
      defaultGrams: 330,
    ),

    // 5) Tofu stir-fry + nudle + arašídové máslo (porce ~350 g; cca 590 kcal)
    Meal(
      name: 'HOTOVKA: Tofu + nudle + zelenina',
      caloriesPer100g: 169,
      proteinPer100g: 9.1,
      carbsPer100g: 19.4,
      fatsPer100g: 5.7,
      defaultGrams: 350,
    ),

    // DALŠÍ hotovky (rychlé “fit klasiky”)
    Meal(
      name: 'HOTOVKA: Kuře + batáty + zelenina',
      caloriesPer100g: 140,
      proteinPer100g: 12.0,
      carbsPer100g: 14.0,
      fatsPer100g: 3.0,
      defaultGrams: 450,
    ),
    Meal(
      name: 'HOTOVKA: Krůta + rýže + zelenina',
      caloriesPer100g: 150,
      proteinPer100g: 13.0,
      carbsPer100g: 17.0,
      fatsPer100g: 2.5,
      defaultGrams: 430,
    ),
    Meal(
      name: 'HOTOVKA: Tuňákový salát + olivový olej',
      caloriesPer100g: 120,
      proteinPer100g: 10.5,
      carbsPer100g: 4.0,
      fatsPer100g: 6.0,
      defaultGrams: 350,
    ),
    Meal(
      name: 'HOTOVKA: Vaječná omeleta (3 vejce) + šunka',
      caloriesPer100g: 175,
      proteinPer100g: 13.0,
      carbsPer100g: 2.0,
      fatsPer100g: 12.0,
      defaultGrams: 250,
    ),
    Meal(
      name: 'HOTOVKA: Ovesná kaše + whey + banán',
      caloriesPer100g: 140,
      proteinPer100g: 8.0,
      carbsPer100g: 19.0,
      fatsPer100g: 3.0,
      defaultGrams: 450,
    ),
    Meal(
      name: 'HOTOVKA: Skyr bowl + ovoce + ořechy',
      caloriesPer100g: 120,
      proteinPer100g: 9.0,
      carbsPer100g: 11.0,
      fatsPer100g: 4.0,
      defaultGrams: 350,
    ),
    Meal(
      name: 'HOTOVKA: Tvaroh + whey (míchané)',
      caloriesPer100g: 120,
      proteinPer100g: 17.0,
      carbsPer100g: 6.0,
      fatsPer100g: 2.0,
      defaultGrams: 300,
    ),
    Meal(
      name: 'HOTOVKA: Tortilla wrap (kuře + zelenina + jogurt)',
      caloriesPer100g: 170,
      proteinPer100g: 12.0,
      carbsPer100g: 18.0,
      fatsPer100g: 5.0,
      defaultGrams: 350,
    ),
    Meal(
      name: 'HOTOVKA: Rýže + tuňák + cottage',
      caloriesPer100g: 140,
      proteinPer100g: 11.0,
      carbsPer100g: 16.0,
      fatsPer100g: 3.0,
      defaultGrams: 400,
    ),
    Meal(
      name: 'HOTOVKA: Bowl (quinoa + kuře + zelenina + olej)',
      caloriesPer100g: 160,
      proteinPer100g: 11.0,
      carbsPer100g: 16.0,
      fatsPer100g: 5.0,
      defaultGrams: 450,
    ),

    // =========================
    // ČESKÁ HOTOVÁ JÍDLA (celá porce včetně přílohy)
    // Hodnoty na 100 g hotového jídla podle KalorickéTabulky.cz
    // (ověřeno: 4×B + 4×S + 9×T odpovídá kcal); defaultGrams = běžná porce.
    // =========================
    // kaloricketabulky.cz/potraviny/svickova-na-smetane-knedlik
    Meal(
      name: 'HOTOVKA: Svíčková na smetaně s knedlíkem',
      caloriesPer100g: 133,
      proteinPer100g: 7.2,
      carbsPer100g: 11.3,
      fatsPer100g: 6.5,
      defaultGrams: 450,
    ),
    // kaloricketabulky.cz/potraviny/hovezi-gulas-s-houskovymi-knedliky
    Meal(
      name: 'HOTOVKA: Hovězí guláš s knedlíkem',
      caloriesPer100g: 154,
      proteinPer100g: 6.0,
      carbsPer100g: 18.0,
      fatsPer100g: 7.0,
      defaultGrams: 400,
    ),
    // kaloricketabulky.cz/potraviny/vepro-knedlo-zelo
    Meal(
      name: 'HOTOVKA: Vepřo knedlo zelo',
      caloriesPer100g: 198,
      proteinPer100g: 16.8,
      carbsPer100g: 19.2,
      fatsPer100g: 5.2,
      defaultGrams: 400,
    ),
    // kaloricketabulky.cz/potraviny/segedinsky-gulas-knedlik
    Meal(
      name: 'HOTOVKA: Segedínský guláš s knedlíkem',
      caloriesPer100g: 179,
      proteinPer100g: 7.8,
      carbsPer100g: 22.1,
      fatsPer100g: 6.5,
      defaultGrams: 400,
    ),
    // kaloricketabulky.cz/potraviny/hovezi-maso-rajska-omacka-houskovy-knedlik-apetit
    Meal(
      name: 'HOTOVKA: Hovězí v rajské omáčce s knedlíkem',
      caloriesPer100g: 135,
      proteinPer100g: 6.9,
      carbsPer100g: 21.8,
      fatsPer100g: 1.9,
      defaultGrams: 450,
    ),
    // kaloricketabulky.cz/potraviny/kure-na-paprice-s-testovinami-albert
    Meal(
      name: 'HOTOVKA: Kuře na paprice s těstovinami',
      caloriesPer100g: 156,
      proteinPer100g: 8.8,
      carbsPer100g: 17.0,
      fatsPer100g: 5.7,
      defaultGrams: 400,
    ),
    // kaloricketabulky.cz/potraviny/albert-quality-kure-na-paprice-s-knedlikem
    Meal(
      name: 'HOTOVKA: Kuře na paprice s knedlíkem',
      caloriesPer100g: 113,
      proteinPer100g: 6.0,
      carbsPer100g: 13.0,
      fatsPer100g: 4.0,
      defaultGrams: 450,
    ),
    // kaloricketabulky.cz/potraviny/smazeny-kureci-rizek-s-bramborovou-kasi
    Meal(
      name: 'HOTOVKA: Kuřecí řízek s bramborovou kaší',
      caloriesPer100g: 117,
      proteinPer100g: 7.2,
      carbsPer100g: 14.0,
      fatsPer100g: 3.3,
      defaultGrams: 400,
    ),
    // kaloricketabulky.cz/potraviny/kure-pecene-se-zeleninovou-nadivkou-a-brambory
    Meal(
      name: 'HOTOVKA: Pečené kuře s brambory',
      caloriesPer100g: 190,
      proteinPer100g: 17.0,
      carbsPer100g: 24.0,
      fatsPer100g: 4.0,
      defaultGrams: 400,
    ),
    // kaloricketabulky.cz/potraviny/pecena-kureci-prsa-v-masove-stave-s-pecenymi-bramborami-mrkvi-a-hraskem
    Meal(
      name: 'HOTOVKA: Pečená kuřecí prsa s brambory a zeleninou',
      caloriesPer100g: 88,
      proteinPer100g: 9.6,
      carbsPer100g: 8.2,
      fatsPer100g: 1.4,
      defaultGrams: 450,
    ),
    // kaloricketabulky.cz/potraviny/rizoto-s-kurecim-masem
    Meal(
      name: 'HOTOVKA: Kuřecí rizoto',
      caloriesPer100g: 138,
      proteinPer100g: 8.0,
      carbsPer100g: 18.0,
      fatsPer100g: 3.7,
      defaultGrams: 400,
    ),
    // kaloricketabulky.cz/potraviny/kung-pao-kureci-s-ryzi
    Meal(
      name: 'HOTOVKA: Kuřecí kung pao s rýží',
      caloriesPer100g: 124,
      proteinPer100g: 6.2,
      carbsPer100g: 20.0,
      fatsPer100g: 1.9,
      defaultGrams: 450,
    ),
    // kaloricketabulky.cz/potraviny/bolonske-spagety
    Meal(
      name: 'HOTOVKA: Špagety boloňské (mleté maso)',
      caloriesPer100g: 157,
      proteinPer100g: 8.1,
      carbsPer100g: 20.0,
      fatsPer100g: 5.0,
      defaultGrams: 400,
    ),
    // kaloricketabulky.cz/potraviny/bolonske-lasagne
    Meal(
      name: 'HOTOVKA: Lasagne boloňské (mleté maso)',
      caloriesPer100g: 155,
      proteinPer100g: 8.0,
      carbsPer100g: 9.0,
      fatsPer100g: 9.0,
      defaultGrams: 350,
    ),
    // kaloricketabulky.cz/potraviny/chilli-con-carne-s-ryzi-hame-menu-1
    Meal(
      name: 'HOTOVKA: Chilli con carne (hovězí) s rýží',
      caloriesPer100g: 134,
      proteinPer100g: 4.8,
      carbsPer100g: 22.2,
      fatsPer100g: 2.3,
      defaultGrams: 450,
    ),
    // kaloricketabulky.cz/potraviny/papriky-plnene-v-rajske-omacce
    Meal(
      name: 'HOTOVKA: Plněné papriky (mleté maso) v rajské omáčce, bez přílohy',
      caloriesPer100g: 112,
      proteinPer100g: 4.5,
      carbsPer100g: 10.5,
      fatsPer100g: 5.5,
      defaultGrams: 350,
    ),
    // kaloricketabulky.cz/potraviny/zapecene-testoviny-se-sunkou
    Meal(
      name: 'HOTOVKA: Zapečené těstoviny se šunkou',
      caloriesPer100g: 148,
      proteinPer100g: 9.3,
      carbsPer100g: 16.9,
      fatsPer100g: 4.5,
      defaultGrams: 400,
    ),
    // kaloricketabulky.cz/potraviny/bramborovy-gulas-burtgulas
    Meal(
      name: 'HOTOVKA: Bramborový guláš (buřtguláš)',
      caloriesPer100g: 173,
      proteinPer100g: 2.7,
      carbsPer100g: 13.7,
      fatsPer100g: 11.7,
      defaultGrams: 400,
    ),
    // kaloricketabulky.cz/potraviny/kureci-vyvar-se-zeleninou-a-nudlemi
    Meal(
      name: 'HOTOVKA: Kuřecí vývar s nudlemi',
      caloriesPer100g: 50,
      proteinPer100g: 3.5,
      carbsPer100g: 3.9,
      fatsPer100g: 2.3,
      defaultGrams: 350,
    ),
    // kaloricketabulky.cz/potraviny/cocka-na-kyselo-varene-vejce
    Meal(
      name: 'HOTOVKA: Čočka na kyselo s vejcem',
      caloriesPer100g: 90,
      proteinPer100g: 4.7,
      carbsPer100g: 12.5,
      fatsPer100g: 2.2,
      defaultGrams: 450,
    ),
    // kaloricketabulky.cz/potraviny/smazeny-syr-hranolky-tatarska-omacka
    Meal(
      name: 'HOTOVKA: Smažený sýr s hranolky a tatarkou',
      caloriesPer100g: 319,
      proteinPer100g: 12.0,
      carbsPer100g: 32.8,
      fatsPer100g: 15.6,
      defaultGrams: 350,
    ),
    // kaloricketabulky.cz/potraviny/rizoto-zeleninove
    Meal(
      name: 'HOTOVKA: Zeleninové rizoto (s parmazánem)',
      caloriesPer100g: 111,
      proteinPer100g: 2.4,
      carbsPer100g: 22.7,
      fatsPer100g: 0.8,
      defaultGrams: 400,
    ),
    // kaloricketabulky.cz/potraviny/knedlik-ovocny
    Meal(
      name: 'HOTOVKA: Ovocné knedlíky (tvarohové)',
      caloriesPer100g: 168,
      proteinPer100g: 5.7,
      carbsPer100g: 26.3,
      fatsPer100g: 4.7,
      defaultGrams: 300,
    ),
    // kaloricketabulky.cz/potraviny/buchticky-se-sodo-cukrarna-mysak
    Meal(
      name: 'HOTOVKA: Buchtičky se šodó',
      caloriesPer100g: 199,
      proteinPer100g: 5.1,
      carbsPer100g: 24.0,
      fatsPer100g: 8.6,
      defaultGrams: 250,
    ),
    // kaloricketabulky.cz/potraviny/bramborovy-salat-s-majonezou
    Meal(
      name: 'HOTOVKA: Bramborový salát s majonézou',
      caloriesPer100g: 216,
      proteinPer100g: 2.0,
      carbsPer100g: 12.0,
      fatsPer100g: 17.5,
      defaultGrams: 200,
    ),
    // kaloricketabulky.cz/potraviny/testovinovy-salat-se-zeleninou-a-majonezou
    Meal(
      name: 'HOTOVKA: Těstovinový salát se zeleninou a majonézou',
      caloriesPer100g: 140,
      proteinPer100g: 3.9,
      carbsPer100g: 17.4,
      fatsPer100g: 6.0,
      defaultGrams: 250,
    ),
    // kaloricketabulky.cz/potraviny/dhal
    Meal(
      name: 'HOTOVKA: Čočkový dhal',
      caloriesPer100g: 101,
      proteinPer100g: 4.5,
      carbsPer100g: 11.5,
      fatsPer100g: 4.0,
      defaultGrams: 400,
    ),
    // kaloricketabulky.cz/potraviny/falafel
    Meal(
      name: 'HOTOVKA: Falafel (cizrnový)',
      caloriesPer100g: 192,
      proteinPer100g: 6.2,
      carbsPer100g: 19.0,
      fatsPer100g: 9.9,
      defaultGrams: 150,
    ),
    // kaloricketabulky.cz/potraviny/cockova-polevka-domaci
    Meal(
      name: 'HOTOVKA: Čočková polévka (postní)',
      caloriesPer100g: 110,
      proteinPer100g: 5.0,
      carbsPer100g: 17.0,
      fatsPer100g: 2.0,
      defaultGrams: 350,
    ),
  ];

  /// Rychlé hledání podle přesného názvu (name).
  static final Map<String, Meal> byName = {
    for (final m in items) m.name: m,
  };
}