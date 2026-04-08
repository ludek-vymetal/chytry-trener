import '../models/food_combo.dart';

class FoodComboSeed {
  // final = můžeš přidávat za běhu aplikace
  static final List<FoodCombo> items = [
    // ==========================================================
    // SNÍDANĚ – SLANÉ
    // ==========================================================
    FoodCombo(
      title: 'Vejce + celozrnný chléb + rajče',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Vejce', grams: 120),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 100),
        FoodComboItem(mealName: 'Rajče', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Míchaná vejce + rohlík + okurka',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Vejce', grams: 150),
        FoodComboItem(mealName: 'Rohlík', grams: 50),
        FoodComboItem(mealName: 'Okurka', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Vejce natvrdo + cottage + okurka',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Vejce', grams: 120),
        FoodComboItem(mealName: 'Cottage', grams: 200),
        FoodComboItem(mealName: 'Okurka', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Tortilla se šunkou a sýrem + rajče',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tortilla (pšeničná)', grams: 80),
        FoodComboItem(mealName: 'Šunka (libová)', grams: 70),
        FoodComboItem(mealName: 'Sýr eidam 30%', grams: 40),
        FoodComboItem(mealName: 'Rajče', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Tuňák + celozrnný chléb + okurka',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tuňák ve vlastní šťávě', grams: 120),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 100),
        FoodComboItem(mealName: 'Okurka', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Cottage + chléb + šunka',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Cottage', grams: 200),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 90),
        FoodComboItem(mealName: 'Šunka (libová)', grams: 60),
      ],
    ),
    FoodCombo(
      title: 'Avokádo toast + vejce',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 100),
        FoodComboItem(mealName: 'Avokádo', grams: 80),
        FoodComboItem(mealName: 'Vejce', grams: 100),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh slaný + chléb + rajče',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tvaroh (polotučný)', grams: 250),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 80),
        FoodComboItem(mealName: 'Rajče', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Bílky + špenát + kapka oleje',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Bílky', grams: 250),
        FoodComboItem(mealName: 'Špenát', grams: 150),
        FoodComboItem(mealName: 'Olivový olej', grams: 5),
      ],
    ),
    FoodCombo(
      title: 'Skyr (slané) + chléb + okurka',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 80),
        FoodComboItem(mealName: 'Okurka', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Sýr + chléb + rajče (klasika)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Sýr eidam 30%', grams: 50),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 100),
        FoodComboItem(mealName: 'Rajče', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Šunka + rohlík + mléko (rychlovka)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Šunka (libová)', grams: 70),
        FoodComboItem(mealName: 'Rohlík', grams: 50),
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 300),
      ],
    ),
    FoodCombo(
      title: 'Tuňák + tortilla (bez vaření)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tuňák ve vlastní šťávě', grams: 120),
        FoodComboItem(mealName: 'Tortilla (pšeničná)', grams: 80),
      ],
    ),
    FoodCombo(
      title: 'Vejce + brambory (zbyly od včera)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Vejce', grams: 120),
        FoodComboItem(mealName: 'Brambory vařené', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Cottage + rajče + olivový olej',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Cottage', grams: 200),
        FoodComboItem(mealName: 'Rajče', grams: 250),
        FoodComboItem(mealName: 'Olivový olej', grams: 5),
      ],
    ),
    FoodCombo(
      title: 'Šunka + vejce + chléb',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Šunka (libová)', grams: 70),
        FoodComboItem(mealName: 'Vejce', grams: 120),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 80),
      ],
    ),
    FoodCombo(
      title: 'Bílky + rýže (divný, ale zasytí)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Bílky', grams: 250),
        FoodComboItem(mealName: 'Rýže vařená', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + šunka (proteinová nouzovka)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tvaroh (nízkotučný)', grams: 250),
        FoodComboItem(mealName: 'Šunka (libová)', grams: 80),
      ],
    ),
    FoodCombo(
      title: 'Vejce + špenát + chléb',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Vejce', grams: 120),
        FoodComboItem(mealName: 'Špenát', grams: 150),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 80),
      ],
    ),
    FoodCombo(
      title: 'Rohlík + sýr + rajče',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Rohlík', grams: 50),
        FoodComboItem(mealName: 'Sýr eidam 30%', grams: 40),
        FoodComboItem(mealName: 'Rajče', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Chléb + arašídové máslo (slano-sladký typ)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 90),
        FoodComboItem(mealName: 'Arašídové máslo', grams: 20),
      ],
    ),
    FoodCombo(
      title: 'Tuňák + okurka + kapka oleje',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tuňák ve vlastní šťávě', grams: 120),
        FoodComboItem(mealName: 'Okurka', grams: 250),
        FoodComboItem(mealName: 'Olivový olej', grams: 5),
      ],
    ),
    FoodCombo(
      title: 'Cottage + chléb + jablko (mix)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Cottage', grams: 200),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 70),
        FoodComboItem(mealName: 'Jablko', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Skyr + šunka + okurka',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Šunka (libová)', grams: 70),
        FoodComboItem(mealName: 'Okurka', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Tuňák + rýže + brokolice (rychlé “fit”)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tuňák ve vlastní šťávě', grams: 120),
        FoodComboItem(mealName: 'Rýže vařená', grams: 200),
        FoodComboItem(mealName: 'Brokolice', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Vejce + šunka + rohlík',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Vejce', grams: 120),
        FoodComboItem(mealName: 'Šunka (libová)', grams: 60),
        FoodComboItem(mealName: 'Rohlík', grams: 50),
      ],
    ),
    FoodCombo(
      title: 'Sýr + šunka + chléb (těžší snídaně)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Sýr eidam 30%', grams: 50),
        FoodComboItem(mealName: 'Šunka (libová)', grams: 70),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 80),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + chléb + okurka',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tvaroh (polotučný)', grams: 250),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 80),
        FoodComboItem(mealName: 'Okurka', grams: 200),
      ],
    ),

    // ==========================================================
    // SNÍDANĚ – SLADKÉ
    // ==========================================================
    FoodCombo(
      title: 'Ovesné vločky + whey + banán + mléko',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Ovesné vločky', grams: 80),
        FoodComboItem(mealName: 'Syrovátkový protein (whey) prášek', grams: 30),
        FoodComboItem(mealName: 'Banán', grams: 120),
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Skyr + lesní ovoce + vločky',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Lesní ovoce (mix)', grams: 150),
        FoodComboItem(mealName: 'Ovesné vločky', grams: 50),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + jablko (klasika)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Tvaroh (polotučný)', grams: 250),
        FoodComboItem(mealName: 'Jablko', grams: 180),
      ],
    ),
    FoodCombo(
      title: 'Whey shake + banán',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Syrovátkový protein (whey) prášek', grams: 30),
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 300),
        FoodComboItem(mealName: 'Banán', grams: 120),
      ],
    ),
    FoodCombo(
      title: 'Ovesné vločky + arašídové máslo + banán',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Ovesné vločky', grams: 80),
        FoodComboItem(mealName: 'Arašídové máslo', grams: 20),
        FoodComboItem(mealName: 'Banán', grams: 120),
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Řecký jogurt 0% + jablko + vločky',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Řecký jogurt 0%', grams: 200),
        FoodComboItem(mealName: 'Jablko', grams: 180),
        FoodComboItem(mealName: 'Ovesné vločky', grams: 50),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + banán + trocha arašídového másla',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Tvaroh (nízkotučný)', grams: 250),
        FoodComboItem(mealName: 'Banán', grams: 120),
        FoodComboItem(mealName: 'Arašídové máslo', grams: 15),
      ],
    ),
    FoodCombo(
      title: 'Skyr + banán',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Banán', grams: 120),
      ],
    ),
    FoodCombo(
      title: 'Mléko + vločky (studentská)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 350),
        FoodComboItem(mealName: 'Ovesné vločky', grams: 80),
      ],
    ),
    FoodCombo(
      title: 'Proteinová tyčinka + skyr',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Proteinová tyčinka', grams: 60),
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + lesní ovoce',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Tvaroh (polotučný)', grams: 250),
        FoodComboItem(mealName: 'Lesní ovoce (mix)', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Řecký jogurt 0% + lesní ovoce',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Řecký jogurt 0%', grams: 200),
        FoodComboItem(mealName: 'Lesní ovoce (mix)', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Skyr + vločky + arašídy',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Ovesné vločky', grams: 60),
        FoodComboItem(mealName: 'Arašídy', grams: 20),
      ],
    ),
    FoodCombo(
      title: 'Banán + mléko + whey (shake)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Banán', grams: 120),
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 300),
        FoodComboItem(mealName: 'Syrovátkový protein (whey) prášek', grams: 25),
      ],
    ),
    FoodCombo(
      title: 'Jablko + skyr + vločky',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Jablko', grams: 180),
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Ovesné vločky', grams: 40),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + vločky + mléko',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Tvaroh (polotučný)', grams: 250),
        FoodComboItem(mealName: 'Ovesné vločky', grams: 50),
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Skyr + jablko',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Jablko', grams: 180),
      ],
    ),
    FoodCombo(
      title: 'Ovesné vločky + jablko + arašídy',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Ovesné vločky', grams: 80),
        FoodComboItem(mealName: 'Jablko', grams: 180),
        FoodComboItem(mealName: 'Arašídy', grams: 15),
      ],
    ),
    FoodCombo(
      title: 'Proteinová tyčinka + banán',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Proteinová tyčinka', grams: 60),
        FoodComboItem(mealName: 'Banán', grams: 120),
      ],
    ),
    FoodCombo(
      title: 'Skyr + arašídové máslo (malá porce)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Arašídové máslo', grams: 15),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + banán',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Tvaroh (nízkotučný)', grams: 250),
        FoodComboItem(mealName: 'Banán', grams: 120),
      ],
    ),
    FoodCombo(
      title: 'Řecký jogurt 0% + banán + vločky',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Řecký jogurt 0%', grams: 200),
        FoodComboItem(mealName: 'Banán', grams: 120),
        FoodComboItem(mealName: 'Ovesné vločky', grams: 50),
      ],
    ),
    FoodCombo(
      title: 'Mléko + whey (bez ovoce)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 350),
        FoodComboItem(mealName: 'Syrovátkový protein (whey) prášek', grams: 30),
      ],
    ),
    FoodCombo(
      title: 'Skyr + lesní ovoce (větší porce)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 300),
        FoodComboItem(mealName: 'Lesní ovoce (mix)', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Ovesné vločky + mléko + arašídové máslo',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Ovesné vločky', grams: 80),
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 300),
        FoodComboItem(mealName: 'Arašídové máslo', grams: 15),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + jablko + arašídy',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Tvaroh (polotučný)', grams: 250),
        FoodComboItem(mealName: 'Jablko', grams: 180),
        FoodComboItem(mealName: 'Arašídy', grams: 15),
      ],
    ),
    FoodCombo(
      title: 'Skyr + vločky (minimalistická)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Ovesné vločky', grams: 60),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + whey (extra protein)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Tvaroh (nízkotučný)', grams: 250),
        FoodComboItem(mealName: 'Syrovátkový protein (whey) prášek', grams: 20),
      ],
    ),
    FoodCombo(
      title: 'Banán + vločky (bez mléka)',
      time: ComboMealTime.breakfast,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Banán', grams: 150),
        FoodComboItem(mealName: 'Ovesné vločky', grams: 70),
      ],
    ),

    // ==========================================================
    // SVAČINY – SLANÉ
    // ==========================================================
    FoodCombo(
      title: 'Cottage + okurka',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Cottage', grams: 200),
        FoodComboItem(mealName: 'Okurka', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Šunka + rohlík + rajče',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Šunka (libová)', grams: 70),
        FoodComboItem(mealName: 'Rohlík', grams: 50),
        FoodComboItem(mealName: 'Rajče', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Sýr + celozrnný chléb',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Sýr eidam 30%', grams: 50),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 80),
      ],
    ),
    FoodCombo(
      title: 'Vejce natvrdo + okurka',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Vejce', grams: 120),
        FoodComboItem(mealName: 'Okurka', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Tuňák + rajče (rychlovka)',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tuňák ve vlastní šťávě', grams: 120),
        FoodComboItem(mealName: 'Rajče', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Skyr (slané) + okurka + olivový olej',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Okurka', grams: 200),
        FoodComboItem(mealName: 'Olivový olej', grams: 5),
      ],
    ),
    FoodCombo(
      title: 'Tortilla se šunkou',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tortilla (pšeničná)', grams: 80),
        FoodComboItem(mealName: 'Šunka (libová)', grams: 70),
      ],
    ),
    FoodCombo(
      title: 'Tortilla se sýrem + rajče',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tortilla (pšeničná)', grams: 80),
        FoodComboItem(mealName: 'Sýr eidam 30%', grams: 40),
        FoodComboItem(mealName: 'Rajče', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Cottage + šunka',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Cottage', grams: 200),
        FoodComboItem(mealName: 'Šunka (libová)', grams: 80),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh slaný + rajče',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tvaroh (nízkotučný)', grams: 250),
        FoodComboItem(mealName: 'Rajče', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Tuňák + celozrnný chléb',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tuňák ve vlastní šťávě', grams: 120),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 80),
      ],
    ),
    FoodCombo(
      title: 'Vejce + rohlík (klasika)',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Vejce', grams: 120),
        FoodComboItem(mealName: 'Rohlík', grams: 50),
      ],
    ),
    FoodCombo(
      title: 'Bílky + špenát',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Bílky', grams: 200),
        FoodComboItem(mealName: 'Špenát', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Šunka + chléb + okurka',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Šunka (libová)', grams: 70),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 80),
        FoodComboItem(mealName: 'Okurka', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Sýr + rohlík',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Sýr eidam 30%', grams: 40),
        FoodComboItem(mealName: 'Rohlík', grams: 50),
      ],
    ),
    FoodCombo(
      title: 'Avokádo + chléb',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Avokádo', grams: 80),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 80),
      ],
    ),
    FoodCombo(
      title: 'Vejce + rajče + olivový olej',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Vejce', grams: 120),
        FoodComboItem(mealName: 'Rajče', grams: 250),
        FoodComboItem(mealName: 'Olivový olej', grams: 5),
      ],
    ),
    FoodCombo(
      title: 'Cottage + chléb',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Cottage', grams: 200),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 70),
      ],
    ),
    FoodCombo(
      title: 'Tuňák + okurka + olivový olej',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tuňák ve vlastní šťávě', grams: 120),
        FoodComboItem(mealName: 'Okurka', grams: 250),
        FoodComboItem(mealName: 'Olivový olej', grams: 5),
      ],
    ),
    FoodCombo(
      title: 'Tortilla + šunka + okurka',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tortilla (pšeničná)', grams: 80),
        FoodComboItem(mealName: 'Šunka (libová)', grams: 70),
        FoodComboItem(mealName: 'Okurka', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Skyr + šunka (divný, ale top protein)',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Šunka (libová)', grams: 70),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + šunka',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tvaroh (polotučný)', grams: 250),
        FoodComboItem(mealName: 'Šunka (libová)', grams: 80),
      ],
    ),
    FoodCombo(
      title: 'Sýr + šunka (bez pečiva)',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Sýr eidam 30%', grams: 50),
        FoodComboItem(mealName: 'Šunka (libová)', grams: 80),
      ],
    ),
    FoodCombo(
      title: 'Brokolice + tuňák (rychle fit)',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Brokolice', grams: 250),
        FoodComboItem(mealName: 'Tuňák ve vlastní šťávě', grams: 120),
      ],
    ),
    FoodCombo(
      title: 'Okurka + rajče + cottage',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Okurka', grams: 200),
        FoodComboItem(mealName: 'Rajče', grams: 200),
        FoodComboItem(mealName: 'Cottage', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Rýže + tuňák (studentská)',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Rýže vařená', grams: 200),
        FoodComboItem(mealName: 'Tuňák ve vlastní šťávě', grams: 120),
      ],
    ),
    FoodCombo(
      title: 'Brambory + vejce (zbytky = ideál)',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Brambory vařené', grams: 250),
        FoodComboItem(mealName: 'Vejce', grams: 120),
      ],
    ),
    FoodCombo(
      title: 'Chléb + arašídové máslo (slano-sladký typ)',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 80),
        FoodComboItem(mealName: 'Arašídové máslo', grams: 20),
      ],
    ),
    FoodCombo(
      title: 'Šunka + tortilla + sýr (těžší svačina)',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Tortilla (pšeničná)', grams: 80),
        FoodComboItem(mealName: 'Šunka (libová)', grams: 70),
        FoodComboItem(mealName: 'Sýr eidam 30%', grams: 30),
      ],
    ),
    FoodCombo(
      title: 'Proteinová tyčinka (když nestíháš) + okurka',
      time: ComboMealTime.snack,
      taste: ComboTaste.savory,
      items: [
        FoodComboItem(mealName: 'Proteinová tyčinka', grams: 60),
        FoodComboItem(mealName: 'Okurka', grams: 200),
      ],
    ),

    // ==========================================================
    // SVAČINY – SLADKÉ
    // ==========================================================
    FoodCombo(
      title: 'Skyr + banán',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Banán', grams: 120),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + jablko',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Tvaroh (polotučný)', grams: 250),
        FoodComboItem(mealName: 'Jablko', grams: 180),
      ],
    ),
    FoodCombo(
      title: 'Řecký jogurt 0% + lesní ovoce',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Řecký jogurt 0%', grams: 200),
        FoodComboItem(mealName: 'Lesní ovoce (mix)', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Skyr + vločky (rychle)',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Ovesné vločky', grams: 50),
      ],
    ),
    FoodCombo(
      title: 'Skyr + lesní ovoce + vločky',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Lesní ovoce (mix)', grams: 150),
        FoodComboItem(mealName: 'Ovesné vločky', grams: 40),
      ],
    ),
    FoodCombo(
      title: 'Proteinová tyčinka + skyr',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Proteinová tyčinka', grams: 60),
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Banán + arašídové máslo',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Banán', grams: 120),
        FoodComboItem(mealName: 'Arašídové máslo', grams: 20),
      ],
    ),
    FoodCombo(
      title: 'Jablko + arašídy',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Jablko', grams: 180),
        FoodComboItem(mealName: 'Arašídy', grams: 20),
      ],
    ),
    FoodCombo(
      title: 'Skyr + arašídové máslo (malá porce)',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Arašídové máslo', grams: 15),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + banán + trocha arašídového másla',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Tvaroh (nízkotučný)', grams: 250),
        FoodComboItem(mealName: 'Banán', grams: 120),
        FoodComboItem(mealName: 'Arašídové máslo', grams: 15),
      ],
    ),
    FoodCombo(
      title: 'Mléko + whey (shake)',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 300),
        FoodComboItem(mealName: 'Syrovátkový protein (whey) prášek', grams: 30),
      ],
    ),
    FoodCombo(
      title: 'Mléko + whey + banán',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 300),
        FoodComboItem(mealName: 'Syrovátkový protein (whey) prášek', grams: 25),
        FoodComboItem(mealName: 'Banán', grams: 120),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + lesní ovoce',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Tvaroh (polotučný)', grams: 250),
        FoodComboItem(mealName: 'Lesní ovoce (mix)', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Řecký jogurt 0% + banán',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Řecký jogurt 0%', grams: 200),
        FoodComboItem(mealName: 'Banán', grams: 120),
      ],
    ),
    FoodCombo(
      title: 'Skyr + jablko',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Jablko', grams: 180),
      ],
    ),
    FoodCombo(
      title: 'Ovesné vločky + mléko (rychlé)',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Ovesné vločky', grams: 70),
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Ovesné vločky + mléko + banán',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Ovesné vločky', grams: 70),
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 250),
        FoodComboItem(mealName: 'Banán', grams: 120),
      ],
    ),
    FoodCombo(
      title: 'Skyr + arašídy',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Arašídy', grams: 20),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + arašídy',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Tvaroh (polotučný)', grams: 250),
        FoodComboItem(mealName: 'Arašídy', grams: 20),
      ],
    ),
    FoodCombo(
      title: 'Proteinová tyčinka + jablko',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Proteinová tyčinka', grams: 60),
        FoodComboItem(mealName: 'Jablko', grams: 180),
      ],
    ),
    FoodCombo(
      title: 'Banán + mandle',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Banán', grams: 120),
        FoodComboItem(mealName: 'Mandle', grams: 20),
      ],
    ),
    FoodCombo(
      title: 'Jablko + mandle',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Jablko', grams: 180),
        FoodComboItem(mealName: 'Mandle', grams: 20),
      ],
    ),
    FoodCombo(
      title: 'Lesní ovoce + skyr (větší porce)',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Lesní ovoce (mix)', grams: 200),
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Řecký jogurt 0% + vločky',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Řecký jogurt 0%', grams: 200),
        FoodComboItem(mealName: 'Ovesné vločky', grams: 50),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + vločky',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Tvaroh (nízkotučný)', grams: 250),
        FoodComboItem(mealName: 'Ovesné vločky', grams: 40),
      ],
    ),
    FoodCombo(
      title: 'Skyr + banán + arašídy',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Banán', grams: 120),
        FoodComboItem(mealName: 'Arašídy', grams: 15),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + jablko + arašídy',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Tvaroh (polotučný)', grams: 250),
        FoodComboItem(mealName: 'Jablko', grams: 180),
        FoodComboItem(mealName: 'Arašídy', grams: 15),
      ],
    ),
    FoodCombo(
      title: 'Mléko + proteinová tyčinka',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 300),
        FoodComboItem(mealName: 'Proteinová tyčinka', grams: 60),
      ],
    ),
    FoodCombo(
      title: 'Skyr + whey (extra protein)',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Syrovátkový protein (whey) prášek', grams: 15),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + whey (extra protein)',
      time: ComboMealTime.snack,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Tvaroh (nízkotučný)', grams: 250),
        FoodComboItem(mealName: 'Syrovátkový protein (whey) prášek', grams: 15),
      ],
    ),

    // ==========================================================
    // OBĚDY – české, levné, i "nezdravé"
    // ==========================================================
    FoodCombo(
      title: 'Kuřecí prsa + rýže + brokolice',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Kuřecí prsa', grams: 180),
        FoodComboItem(mealName: 'Rýže vařená', grams: 250),
        FoodComboItem(mealName: 'Brokolice', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Kuřecí prsa + brambory + okurka',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Kuřecí prsa', grams: 180),
        FoodComboItem(mealName: 'Brambory vařené', grams: 300),
        FoodComboItem(mealName: 'Okurka', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Krůtí prsa + basmati + špenát',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Krůtí prsa', grams: 180),
        FoodComboItem(mealName: 'Basmati rýže vařená', grams: 250),
        FoodComboItem(mealName: 'Špenát', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Hovězí (libové) + brambory + rajče',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Hovězí (libové)', grams: 170),
        FoodComboItem(mealName: 'Brambory vařené', grams: 300),
        FoodComboItem(mealName: 'Rajče', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Vepřová kýta + rýže + zelenina',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Vepřová kýta (libová)', grams: 170),
        FoodComboItem(mealName: 'Rýže vařená', grams: 250),
        FoodComboItem(mealName: 'Brokolice', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Vepřový řízek + brambory (klasika)',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Vepřový řízek (smažený)', grams: 180),
        FoodComboItem(mealName: 'Brambory vařené', grams: 300),
      ],
    ),
    FoodCombo(
      title: 'Vepřový řízek + rýže (rychlá menza)',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Vepřový řízek (smažený)', grams: 180),
        FoodComboItem(mealName: 'Rýže vařená', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Těstoviny + sýr (studentská klasika)',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Těstoviny vařené', grams: 300),
        FoodComboItem(mealName: 'Sýr eidam 30%', grams: 50),
      ],
    ),
    FoodCombo(
      title: 'Těstoviny + šunka + sýr',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Těstoviny vařené', grams: 300),
        FoodComboItem(mealName: 'Šunka (libová)', grams: 80),
        FoodComboItem(mealName: 'Sýr eidam 30%', grams: 40),
      ],
    ),
    FoodCombo(
      title: 'Treska + brambory + rajče',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Treska', grams: 200),
        FoodComboItem(mealName: 'Brambory vařené', grams: 300),
        FoodComboItem(mealName: 'Rajče', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Losos + brambory + špenát',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Losos', grams: 170),
        FoodComboItem(mealName: 'Brambory vařené', grams: 300),
        FoodComboItem(mealName: 'Špenát', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Tuňák + rýže + okurka',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Tuňák ve vlastní šťávě', grams: 120),
        FoodComboItem(mealName: 'Rýže vařená', grams: 250),
        FoodComboItem(mealName: 'Okurka', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Vejce + brambory (rychlá pánev)',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Vejce', grams: 180),
        FoodComboItem(mealName: 'Brambory vařené', grams: 300),
      ],
    ),
    FoodCombo(
      title: 'Bílky + rýže + špenát (fit levně)',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Bílky', grams: 250),
        FoodComboItem(mealName: 'Rýže vařená', grams: 250),
        FoodComboItem(mealName: 'Špenát', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Čočka + rýže + okurka',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Čočka vařená', grams: 300),
        FoodComboItem(mealName: 'Rýže vařená', grams: 200),
        FoodComboItem(mealName: 'Okurka', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Cizrna + rýže + rajče',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Cizrna vařená', grams: 300),
        FoodComboItem(mealName: 'Rýže vařená', grams: 200),
        FoodComboItem(mealName: 'Rajče', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Fazole + brambory (český styl)',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Fazole vařené', grams: 300),
        FoodComboItem(mealName: 'Brambory vařené', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Tofu + rýže + brokolice',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Tofu', grams: 200),
        FoodComboItem(mealName: 'Rýže vařená', grams: 250),
        FoodComboItem(mealName: 'Brokolice', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Tempeh + brambory + okurka',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Tempeh', grams: 180),
        FoodComboItem(mealName: 'Brambory vařené', grams: 300),
        FoodComboItem(mealName: 'Okurka', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Celozrnný chléb + šunka + sýr',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 120),
        FoodComboItem(mealName: 'Šunka (libová)', grams: 80),
        FoodComboItem(mealName: 'Sýr eidam 30%', grams: 40),
      ],
    ),
    FoodCombo(
      title: 'Tortilla + kuře + zelenina',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Tortilla (pšeničná)', grams: 80),
        FoodComboItem(mealName: 'Kuřecí prsa', grams: 150),
        FoodComboItem(mealName: 'Rajče', grams: 150),
        FoodComboItem(mealName: 'Okurka', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Slané vločky + vejce + špenát (fakt to jde)',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Ovesné vločky', grams: 60),
        FoodComboItem(mealName: 'Vejce', grams: 120),
        FoodComboItem(mealName: 'Špenát', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Kuře + těstoviny + olivový olej',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Kuřecí prsa', grams: 180),
        FoodComboItem(mealName: 'Těstoviny vařené', grams: 300),
        FoodComboItem(mealName: 'Olivový olej', grams: 10),
      ],
    ),
    FoodCombo(
      title: 'Vepřová kýta + těstoviny',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Vepřová kýta (libová)', grams: 170),
        FoodComboItem(mealName: 'Těstoviny vařené', grams: 300),
      ],
    ),
    FoodCombo(
      title: 'Hovězí + rýže + olivový olej',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Hovězí (libové)', grams: 170),
        FoodComboItem(mealName: 'Rýže vařená', grams: 250),
        FoodComboItem(mealName: 'Olivový olej', grams: 10),
      ],
    ),
    FoodCombo(
      title: 'Tvaroh + chléb (když není čas vařit)',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Tvaroh (polotučný)', grams: 250),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 100),
      ],
    ),
    FoodCombo(
      title: 'Cottage + rohlík + rajče (rychlý oběd)',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Cottage', grams: 200),
        FoodComboItem(mealName: 'Rohlík', grams: 50),
        FoodComboItem(mealName: 'Rajče', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Proteinová tyčinka + mléko (nouzovka)',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Proteinová tyčinka', grams: 60),
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 300),
      ],
    ),
    FoodCombo(
      title: 'Whey + banán (nouzový oběd po tréninku)',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Syrovátkový protein (whey) prášek', grams: 30),
        FoodComboItem(mealName: 'Banán', grams: 120),
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Losos + rýže (luxus, ale pořád ČR)',
      time: ComboMealTime.lunch,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Losos', grams: 170),
        FoodComboItem(mealName: 'Rýže vařená', grams: 250),
      ],
    ),

    // ==========================================================
    // VEČEŘE – lehké i klasické české
    // ==========================================================
    FoodCombo(
      title: 'Tvaroh + banán + ovesné vločky',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Tvaroh (nízkotučný)', grams: 250),
        FoodComboItem(mealName: 'Banán', grams: 120),
        FoodComboItem(mealName: 'Ovesné vločky', grams: 50),
      ],
    ),
    FoodCombo(
      title: 'Cottage + celozrnný chléb + rajče',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Cottage', grams: 200),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 100),
        FoodComboItem(mealName: 'Rajče', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Vejce + žitný chléb + okurka',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Vejce', grams: 150),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 100),
        FoodComboItem(mealName: 'Okurka', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Kuřecí prsa + salát',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Kuřecí prsa', grams: 180),
        FoodComboItem(mealName: 'Špenát', grams: 150),
        FoodComboItem(mealName: 'Rajče', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Tuňák + chléb + zelenina',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Tuňák ve vlastní šťávě', grams: 120),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 100),
        FoodComboItem(mealName: 'Okurka', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Těstoviny + cottage (rychlá večeře)',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Těstoviny vařené', grams: 250),
        FoodComboItem(mealName: 'Cottage', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Brambory + tvaroh (klasika)',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Brambory vařené', grams: 300),
        FoodComboItem(mealName: 'Tvaroh (polotučný)', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Šunka + sýr + chléb',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Šunka (libová)', grams: 100),
        FoodComboItem(mealName: 'Sýr eidam 30%', grams: 50),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 100),
      ],
    ),
    FoodCombo(
      title: 'Protein + mléko + banán',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Syrovátkový protein (whey) prášek', grams: 30),
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 300),
        FoodComboItem(mealName: 'Banán', grams: 120),
      ],
    ),
    FoodCombo(
      title: 'Losos + salát (lehčí verze)',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Losos', grams: 150),
        FoodComboItem(mealName: 'Špenát', grams: 150),
        FoodComboItem(mealName: 'Rajče', grams: 200),
      ],
    ),

    // ==========================================================
    // TROCHU TĚŽŠÍ VEČEŘE
    // ==========================================================
    FoodCombo(
      title: 'Vepřový řízek + chléb',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Vepřový řízek (smažený)', grams: 150),
        FoodComboItem(mealName: 'Celozrnný chléb', grams: 100),
      ],
    ),
    FoodCombo(
      title: 'Rýže + vejce + šunka',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Rýže vařená', grams: 250),
        FoodComboItem(mealName: 'Vejce', grams: 150),
        FoodComboItem(mealName: 'Šunka (libová)', grams: 80),
      ],
    ),
    FoodCombo(
      title: 'Ovesná kaše + protein',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Ovesné vločky', grams: 80),
        FoodComboItem(mealName: 'Syrovátkový protein (whey) prášek', grams: 30),
        FoodComboItem(mealName: 'Mléko 1.5%', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Cottage + mandle + jablko',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Cottage', grams: 200),
        FoodComboItem(mealName: 'Mandle', grams: 20),
        FoodComboItem(mealName: 'Jablko', grams: 180),
      ],
    ),
    FoodCombo(
      title: 'Krůtí prsa + zelenina',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Krůtí prsa', grams: 180),
        FoodComboItem(mealName: 'Brokolice', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Tofu + brambory',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Tofu', grams: 200),
        FoodComboItem(mealName: 'Brambory vařené', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Tempeh + rýže',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Tempeh', grams: 180),
        FoodComboItem(mealName: 'Rýže vařená', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Skyr + lesní ovoce',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Skyr (bílý)', grams: 250),
        FoodComboItem(mealName: 'Lesní ovoce (mix)', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Řecký jogurt + ořechy',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Řecký jogurt 0%', grams: 250),
        FoodComboItem(mealName: 'Vlašské ořechy', grams: 20),
      ],
    ),
    FoodCombo(
      title: 'Brambory + vejce + špenát',
      time: ComboMealTime.dinner,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Brambory vařené', grams: 300),
        FoodComboItem(mealName: 'Vejce', grams: 150),
        FoodComboItem(mealName: 'Špenát', grams: 150),
      ],
    ),

    // ==========================================================
    // VEGAN (rychlé, levné, realistické)
    // ==========================================================
    FoodCombo(
      title: 'Tofu + rýže + brokolice (vegan)',
      time: ComboMealTime.vegan,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Tofu', grams: 200),
        FoodComboItem(mealName: 'Rýže vařená', grams: 250),
        FoodComboItem(mealName: 'Brokolice', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Cizrna + rýže + rajče (vegan)',
      time: ComboMealTime.vegan,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Cizrna vařená', grams: 300),
        FoodComboItem(mealName: 'Rýže vařená', grams: 200),
        FoodComboItem(mealName: 'Rajče', grams: 200),
      ],
    ),
    FoodCombo(
      title: 'Čočka + brambory (vegan)',
      time: ComboMealTime.vegan,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Čočka vařená', grams: 300),
        FoodComboItem(mealName: 'Brambory vařené', grams: 250),
      ],
    ),
    FoodCombo(
      title: 'Tempeh + rýže + špenát (vegan)',
      time: ComboMealTime.vegan,
      taste: ComboTaste.any,
      items: [
        FoodComboItem(mealName: 'Tempeh', grams: 180),
        FoodComboItem(mealName: 'Rýže vařená', grams: 250),
        FoodComboItem(mealName: 'Špenát', grams: 150),
      ],
    ),
    FoodCombo(
      title: 'Ovesné vločky + arašídové máslo + banán (vegan)',
      time: ComboMealTime.vegan,
      taste: ComboTaste.sweet,
      items: [
        FoodComboItem(mealName: 'Ovesné vločky', grams: 80),
        FoodComboItem(mealName: 'Arašídové máslo', grams: 20),
        FoodComboItem(mealName: 'Banán', grams: 120),
      ],
    ),
  ];
}