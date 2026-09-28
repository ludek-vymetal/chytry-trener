// Akční plán pro klienta: konkrétní doporučení ke stravě, tréninku
// a regeneraci podle složení těla, cíle, skutečného příjmu a docházky.
//
// Čistá logika bez UI – používá ji PDF souhrn klienta.

import 'dart:math' as math;

import '../../models/custom_training_plan.dart';
import '../../models/goal.dart';
import 'inbody_analysis.dart';

class CoachAction {
  final String headline;
  final String detail;

  const CoachAction(this.headline, this.detail);
}

class CoachActionGroup {
  final String title;
  final List<CoachAction> actions;

  const CoachActionGroup(this.title, this.actions);
}

class CoachPlanInput {
  final String gender;
  final int age;
  final double weightKg;

  final GoalType? goalType;
  final DateTime? goalDate;

  /// Závěry z InBody (`null` = bez měření nebo citlivý režim).
  final InbodyFlags? body;

  /// Denní cíl z aplikace (`null` = cíl není nastaven).
  final int? targetKcal;
  final int? targetProtein;
  final int? targetCarbs;
  final int? targetFat;

  /// Průměr zapsaných dnů (`null` = klient nic nezapsal).
  final double? avgKcal;
  final double? avgProtein;
  final double? avgCarbs;
  final double? avgFat;
  final int loggedDays;
  final int periodDays;

  final double trainingsPerWeek;
  final bool hasTrainingData;

  final CustomTrainingPlanType? planType;
  final DateTime? eventDate;

  /// Cviky, u kterých se výkon za období nezlepšil.
  final List<String> stagnatingLifts;

  /// Klient v režimu podpory při poruše příjmu potravy – bez čísel
  /// o jídle a bez redukčních rad.
  final bool sensitive;

  const CoachPlanInput({
    required this.gender,
    required this.age,
    required this.weightKg,
    required this.goalType,
    required this.goalDate,
    required this.body,
    required this.targetKcal,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.avgKcal,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
    required this.loggedDays,
    required this.periodDays,
    required this.trainingsPerWeek,
    required this.hasTrainingData,
    required this.planType,
    required this.eventDate,
    required this.stagnatingLifts,
    required this.sensitive,
  });
}

class CoachRecommendations {
  CoachRecommendations._();

  static int _r50(double v) => (v / 50).round() * 50;
  static int _r5(double v) => (v / 5).round() * 5;
  static String _f(double v, [int d = 1]) =>
      v.toStringAsFixed(d).replaceAll('.', ',');

  static List<CoachActionGroup> build(CoachPlanInput i) {
    final food = i.sensitive ? _supportFood() : _food(i);
    final training = _training(i);
    final recovery = _recovery(i);

    return [
      if (food.isNotEmpty) CoachActionGroup('Strava', food.take(5).toList()),
      if (training.isNotEmpty)
        CoachActionGroup('Trénink', training.take(5).toList()),
      if (recovery.isNotEmpty)
        CoachActionGroup('Regenerace a měření', recovery.take(3).toList()),
    ];
  }

  // ---------------------------------------------------------------
  // Strava
  // ---------------------------------------------------------------

  static List<CoachAction> _supportFood() => const [
        CoachAction(
          'Pravidelnost jídla',
          'Jez pravidelně 3 hlavní jídla a 1–2 svačiny a nevynechávej snídani. '
              'Další kroky plánujeme společně s odborníkem, který tě vede.',
        ),
      ];

  static List<CoachAction> _food(CoachPlanInput i) {
    final out = <CoachAction>[];
    final b = i.body;
    final strengthGoal = i.goalType == GoalType.strength ||
        i.planType == CustomTrainingPlanType.benchMeetPrep ||
        i.planType == CustomTrainingPlanType.powerliftingMeetPrep;
    final cutGoal = i.goalType == GoalType.weightLoss ||
        i.planType == CustomTrainingPlanType.hollywoodPrep ||
        i.planType == CustomTrainingPlanType.bikiniMeetPrep ||
        (b?.fatHigh ?? false);
    final hasIntake = i.avgKcal != null && i.loggedDays > 0;
    final hasTarget = i.targetKcal != null && i.targetKcal! > 0;

    // Kalorie
    if (hasIntake && hasTarget) {
      final diff = i.avgKcal! - i.targetKcal!;
      final pct = i.avgKcal! / i.targetKcal! * 100;
      if (pct > 110) {
        final carbCut = _r5(math.min(diff * 0.6 / 4, 150));
        out.add(CoachAction(
          'Sniž příjem o ~${_r50(diff)} kcal denně',
          'Jíš v průměru ${i.avgKcal!.round()} kcal, cíl je ${i.targetKcal} kcal. '
              'Nejjednodušší je ubrat asi $carbCut g sacharidů '
              '(~${_r5(carbCut / 0.28)} g vařené rýže nebo těstovin) '
              'a pohlídat tuky v omáčkách a pečivu.',
        ));
      } else if (pct < 90) {
        out.add(CoachAction(
          'Přidej ~${_r50(-diff)} kcal denně',
          strengthGoal
              ? 'Jíš ${i.avgKcal!.round()} kcal, to je pod cílem a na výkonu '
                  'se to projeví. Přidej hlavně sacharidy kolem tréninku '
                  '(ovesné vločky, rýže, banán, pečivo).'
              : cutGoal
                  ? 'Deficit je zbytečně velký (${pct.round()} % cíle) – hrozí '
                      'ztráta svalů, únava a přejídání o víkendu. Doplň '
                      'nejdřív bílkoviny a zeleninu, pak sacharidy.'
                  : 'Jíš méně, než je v plánu (${pct.round()} % cíle). Přidej '
                      'jednu svačinu s bílkovinou a sacharidem.',
        ));
      }
    }

    // Bílkoviny
    if (hasIntake && i.targetProtein != null && i.avgProtein != null) {
      final missing = i.targetProtein! - i.avgProtein!;
      if (missing > i.targetProtein! * 0.1) {
        out.add(CoachAction(
          'Přidej ~${_r5(missing)} g bílkovin denně',
          'Teď máš ${i.avgProtein!.round()} g, cíl je ${i.targetProtein} g. '
              'Např. 250 g tvarohu (~30 g), 150 g kuřecích prsou (~35 g), '
              'řecký jogurt (~15 g) nebo odměrka proteinu (~25 g). '
              'Rozděl je do 3–5 jídel po 25–40 g.',
        ));
      }
    } else if (b != null) {
      final protein = _r5(b.leanMassKg * (b.fatHigh ? 2.2 : 2.0));
      out.add(CoachAction(
        'Bílkoviny ~$protein g denně',
        '${_f(b.fatHigh ? 2.2 : 2.0)} g na kg beztukové hmoty, '
            'rozděl je do 3–5 jídel po 25–40 g.',
      ));
    }

    // Sacharidy
    if (hasIntake && i.targetCarbs != null && i.avgCarbs != null) {
      final pct = i.avgCarbs! / i.targetCarbs! * 100;
      if (pct < 80 && (strengthGoal || i.goalType == GoalType.endurance)) {
        final add = _r5(i.targetCarbs! - i.avgCarbs!);
        out.add(CoachAction(
          'Zvyš sacharidy o ~$add g denně',
          'Sacharidy jsou na ${pct.round()} % cíle – to brzdí sílu i '
              'regeneraci. Dej je hlavně 1–3 h před tréninkem a do jídla po '
              'něm (rýže, brambory, ovesné vločky, ovoce).',
        ));
      } else if (pct > 115 && cutGoal) {
        final cut = _r5(i.avgCarbs! - i.targetCarbs!);
        out.add(CoachAction(
          'Sniž sacharidy o ~$cut g denně',
          'Uber z večeře a svačin (pečivo, sladké, přílohy navíc). '
              'Sacharidy si nech hlavně kolem tréninku, večer dej přednost '
              'bílkovinám a zelenině.',
        ));
      }
    } else if (cutGoal && b != null && b.fatHigh) {
      out.add(const CoachAction(
        'Sacharidy hlavně kolem tréninku',
        'V tréninkové dny si dej přílohy k jídlu před a po tréninku, ve volné dny '
            'a večer menší porce příloh a víc zeleniny a bílkovin.',
      ));
    }

    // Tuky
    if (hasIntake && i.avgFat != null) {
      final minFat = i.weightKg * 0.7;
      if (i.avgFat! < minFat) {
        out.add(CoachAction(
          'Zvyš tuky aspoň na ${_r5(minFat)} g denně',
          'Teď máš ${i.avgFat!.round()} g, to je málo – tuky tělo potřebuje pro '
              'hormony. Ořechy, olivový olej, avokádo, vejce, tučné ryby.',
        ));
      }
    }

    // Vývoj složení těla
    switch (b?.trend) {
      case 'cutMuscleLoss':
        out.add(const CoachAction(
          'Zmírni deficit',
          'S tukem ti ubývají i svaly. Sniž deficit na 10–15 % pod výdej '
              'a zvedni bílkoviny na 2,2–2,5 g/kg beztukové hmoty.',
        ));
      case 'dirtyGain':
      case 'fatGain':
        out.add(const CoachAction(
          'Sniž kalorický přebytek o 200–300 kcal',
          'Přibývá víc tuku než svalů. Uber hlavně tekuté kalorie, '
              'sladkosti a večerní příjem.',
        ));
      default:
        break;
    }

    if (b != null && b.abdominalRisk) {
      out.add(const CoachAction(
        'Zelenina a vláknina každý den',
        'Kvůli tuku v oblasti břicha: aspoň 400 g zeleniny denně, celozrnné '
            'přílohy a luštěniny, méně alkoholu a slazených nápojů.',
      ));
    }

    // Závod / akce blízko
    final daysToEvent = i.eventDate?.difference(DateTime.now()).inDays;
    if (daysToEvent != null && daysToEvent >= 0 && daysToEvent <= 14) {
      out.insert(
        0,
        const CoachAction(
          'Před akcí stravu neměň',
          'Poslední 2 týdny žádné nové potraviny ani doplňky. Den před '
              'a v den akce lehce stravitelné sacharidy a dostatek tekutin.',
        ),
      );
    }

    // Zapisování
    if (i.loggedDays == 0) {
      out.add(const CoachAction(
        'Začni zapisovat jídlo',
        'Bez záznamů nejde strava vyhodnotit. Stačí 4–5 dní v týdnu '
            'včetně jednoho víkendového dne.',
      ));
    } else if (i.periodDays > 0 && i.loggedDays / i.periodDays < 0.4) {
      out.add(CoachAction(
        'Zapisuj jídlo pravidelněji',
        'Zapsáno máš ${i.loggedDays} z ${i.periodDays} dní – závěry o stravě '
            'jsou jen orientační. Cíl: aspoň 4 dny v týdnu.',
      ));
    }

    return out;
  }

  // ---------------------------------------------------------------
  // Trénink
  // ---------------------------------------------------------------

  static List<CoachAction> _training(CoachPlanInput i) {
    final out = <CoachAction>[];
    final b = i.body;

    // Fáze přípravy na závod / akci
    final days = i.eventDate?.difference(DateTime.now()).inDays;
    final isStrengthMeet = i.planType == CustomTrainingPlanType.benchMeetPrep ||
        i.planType == CustomTrainingPlanType.powerliftingMeetPrep;
    final isStageEvent = i.planType == CustomTrainingPlanType.bikiniMeetPrep ||
        i.planType == CustomTrainingPlanType.hollywoodPrep;
    if (days != null && days >= 0 && (isStrengthMeet || isStageEvent)) {
      final weeks = (days / 7).ceil();
      if (isStrengthMeet) {
        if (weeks > 8) {
          out.add(CoachAction(
            'Fáze objemu ($weeks týdnů do závodu)',
            'Drž plán a nevynechávej doplňkové cviky – triceps, ramena '
                'a záda 3–4 série. Teď se buduje základ pro závěrečnou sílu.',
          ));
        } else if (weeks > 3) {
          out.add(CoachAction(
            'Fáze intenzity ($weeks týdnů do závodu)',
            'Prioritou jsou těžké série 85–95 %. Doplňkové cviky zkrať na '
                '2–3 série, ať ti zbude energie na hlavní cvik. Nacvičuj '
                'závodní povely a pauzu na hrudníku.',
          ));
        } else {
          out.add(CoachAction(
            'Ladění před závodem ($days dní)',
            'Objem sniž o 40–60 %, váhy drž. Poslední těžký single '
                '7–10 dní před závodem, pak jen rychlé lehké série. '
                'Úvodní pokus naplánuj kolem 90–92 % maxima.',
          ));
        }
      } else {
        out.add(CoachAction(
          weeks > 3
              ? 'Příprava na akci – $weeks týdnů'
              : 'Závěr přípravy – $days dní',
          weeks > 3
              ? 'Drž objem a pravidelnost, vývoj tuku kontrolujeme každé '
                  '2–3 týdny a podle něj ladit příjem.'
              : 'Sniž objem, intenzitu drž a přidej nácvik '
                  '(pózování, prokrvení), žádné nové cviky.',
        ));
      }
    }

    // Frekvence
    if (i.hasTrainingData && i.trainingsPerWeek < 2) {
      out.add(CoachAction(
        'Trénuj 3× týdně',
        'Teď je to ${_f(i.trainingsPerWeek)}× týdně – na změnu postavy i sílu je '
            'to málo. Naplánuj si pevné dny a časy na celé období.',
      ));
    } else if (!i.hasTrainingData) {
      out.add(const CoachAction(
        'Zapisuj tréninky',
        'V období nejsou zapsané tréninky – bez nich nejde vyhodnotit '
            'docházku ani progres.',
      ));
    }

    if (b != null) {
      if (b.lowMuscle || b.lowLimbMuscle) {
        out.add(const CoachAction(
          'Silový trénink celého těla 3× týdně',
          'Základní vícekloubové cviky (dřep, tlaky, přítahy, mrtvý tah), '
              '2–3 série na partii, každý týden přidej opakování nebo váhu.',
        ));
      }
      if (b.weakerArm != null || b.weakerLeg != null) {
        final parts = [
          if (b.weakerArm != null) '${b.weakerArm} paže',
          if (b.weakerLeg != null) '${b.weakerLeg} noha',
        ].join(' a ');
        out.add(CoachAction(
          'Vyrovnej strany – slabší je $parts',
          'U 1–2 cviků vyměň osu za jednoručky nebo jednostrannou '
              'variantou. Slabší strana začíná, silnější dělá stejný počet '
              'opakování. Slabší straně 1 série navíc.',
        ));
      }
      if (b.legsLag) {
        out.add(const CoachAction(
          'Posil nohy',
          'Nohy zaostávají za horní polovinou těla. 2× týdně trénink nohou: '
              'dřep nebo leg press 3–4 × 8–12, rumunský mrtvý tah, výpady.',
        ));
      } else if (b.upperLags) {
        out.add(const CoachAction(
          'Posil horní polovinu těla',
          'Přidej tlaky a přítahy – 2× týdně horní polovina těla, '
              '10–15 sérií na hrudník i záda týdně.',
        ));
      }
      if (b.fatHigh && !i.sensitive) {
        out.add(const CoachAction(
          'Přidej kardio v zóně 2',
          '2–3× týdně 30–40 min svižné chůze, kola nebo stepperu (dá se '
              'mluvit v celých větách) a 8–10 tisíc kroků denně. '
              'Neubere ti sílu a zrychlí úbytek tuku.',
        ));
      }
      if (b.trend == 'cutMuscleLoss') {
        out.add(const CoachAction(
          'Při hubnutí drž těžké série',
          'Váhy neubírej (RIR 1–2) a kardio neprodlužuj – signál pro '
              'udržení svalů je těžká zátěž.',
        ));
      }
    }

    if (i.stagnatingLifts.isNotEmpty) {
      out.add(CoachAction(
        'Stagnace: ${i.stagnatingLifts.take(3).join(', ')}',
        'Na 3–4 týdny změň podnět – jiný rozsah opakování '
            '(např. z 5 × 5 na 4 × 8) nebo variantu cviku, pak se vrátit.',
      ));
    }

    if (i.age >= 50) {
      out.add(CoachAction(
        'Péče o klouby (věk ${i.age})',
        'Rozcvičuj se 10–15 min, zařaď mobilitu ramen a kyčlí a odlehčovací týden '
            'každých 4–6 týdnů. Těžké série cvič v kontrolovaném tempu.',
      ));
    } else if (i.age >= 40) {
      out.add(const CoachAction(
        'Odlehčovací týden každých 6 týdnů',
        'Objem sniž o třetinu – klouby a šlachy regenerují pomaleji než svaly.',
      ));
    }

    if (out.isEmpty && b != null && b.highMuscle && !b.fatHigh) {
      out.add(const CoachAction(
        'Prostor pro specializaci',
        'Složení těla máš výborné – další blok zaměříme na slabou partii '
            'nebo na silový cíl.',
      ));
    }

    return out;
  }

  // ---------------------------------------------------------------
  // Regenerace
  // ---------------------------------------------------------------

  static List<CoachAction> _recovery(CoachPlanInput i) {
    final out = <CoachAction>[];
    final b = i.body;
    final water = i.weightKg * 0.035;

    out.add(CoachAction(
      'Spánek 7–9 hodin a pitný režim',
      'Choď spát v pravidelnou dobu. Pij ~${_f(water)} l vody denně '
          '(35 ml/kg), v tréninkové dny o 0,5 l víc.',
    ));

    if (b != null && b.changeTooFast) {
      out.add(const CoachAction(
        'Zpomal tempo změny váhy',
        'Hubnutí max. 1 % váhy týdně, nabírání max. 0,5 % – jinak se ztrácí '
            'svaly, nebo zbytečně přibývá tuk.',
      ));
    }

    if (!i.sensitive) {
      out.add(CoachAction(
        'Další měření za 4–6 týdnů',
        b != null && b.poorHydration
            ? 'Hydratace při měření byla mimo normu – příště přijď ráno, nalačno, '
                'po toaletě, bez tréninku a alkoholu den předem.'
            : 'Vždy za stejných podmínek: ráno, nalačno, po toaletě, '
                'bez tréninku předem.',
      ));
    }

    return out;
  }
}
