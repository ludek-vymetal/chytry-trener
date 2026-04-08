import 'carb_cycling_plan.dart';

class Food {
  final String name;
  final double p; // bílkoviny na 100g
  final double s; // sacharidy na 100g
  final double t; // tuky na 100g
  final String unit;

  Food(this.name, this.p, this.s, this.t, {this.unit = "g"});
}

class MealGenerator {
  static List<Map<String, dynamic>> generateMenu(
    double targetS,
    double targetB,
    double targetT, {
    List<String> excluded = const [],
  }) {
    final double bPerMeal = targetB / 5;

    final double eggsCount = (bPerMeal / 7).roundToDouble();
    final double hiddenS = eggsCount * 0.5;

    double remainingS = targetS - hiddenS;
    if (remainingS < 0) {
      remainingS = 0;
    }

    final List<Map<String, dynamic>> meals = [];
    final List<String> mealNames = [
      "Snídaně",
      "Svačina",
      "Oběd",
      "Svačina 2",
      "Večeře",
    ];

    final String drinkNote = targetS < 50
        ? "☕ Káva/Čaj OK (bez cukru). Pij hodně minerálek (Zero nápoje střídmě)."
        : "💧 Nezapomínej na čistou vodu během celého dne.";

    for (int i = 0; i < 5; i++) {
      String proteinText = "";
      String carbText = "";
      String fatAddition = "";

      if (i == 0) {
        if (excluded.contains("Vejce")) {
          final int curdAmount = (bPerMeal / 12 * 100).round();
          proteinText = "${curdAmount}g Nízkotučný tvaroh";
        } else {
          proteinText = "${eggsCount.toInt()}ks Vejce";
        }

        if (targetS < 50) {
          fatAddition = " + 20g Slanina";
        }
      } else {
        final double meat = bPerMeal / 23 * 100;
        final int roundedMeat = (meat / 5).round() * 5;

        if (excluded.contains("Hovězí maso") && i == 2) {
          proteinText = "${roundedMeat}g Krůtí prsa";
        } else {
          proteinText = "${roundedMeat}g Kuřecí prsa";
        }

        if (targetS < 50 && (i == 2 || i == 4)) {
          fatAddition = " + 15g Olivový olej (nebo Avokádo)";
        }
      }

      if (remainingS > 0 && i < 4) {
        final double sPortion = remainingS / 4;
        final double rice = sPortion / 78 * 100;
        final int roundedRice = (rice / 5).round() * 5;

        if (roundedRice > 0) {
          carbText = " + ${roundedRice}g Rýže";
        }
      }

      meals.add({
        "name": mealNames[i],
        "content": "$proteinText$carbText$fatAddition + zelenina",
        "drinkNote": i == 4 ? drinkNote : null,
      });
    }

    return meals;
  }

  static Map<String, double> generateShoppingList(
    CarbCyclingPlan plan, {
    bool isKeto = false,
    List<String> excluded = const [],
  }) {
    final Map<String, double> consolidatedList = {};

    for (int i = 0; i < 7; i++) {
      double currentS;
      final double currentB = plan.protein;
      double currentT = plan.fats;

      if (isKeto) {
        currentS = 30.0;
        currentT = plan.fats + 40;
      } else {
        if (plan.dailyCarbs.isNotEmpty) {
          currentS =
              plan.dailyCarbs.length > i ? plan.dailyCarbs[i] : plan.dailyCarbs[0];
        } else {
          currentS = 0.0;
        }
      }

      final meals = generateMenu(
        currentS,
        currentB,
        currentT,
        excluded: excluded,
      );

      for (final meal in meals) {
        final String content = meal["content"] as String;

        final RegExp regExp = RegExp(r'(\d+)(g|ks|ml)\s+([^+]+)');
        final matches = regExp.allMatches(content);

        for (final match in matches) {
          final double amount = double.tryParse(match.group(1)!) ?? 0;
          final String unit = match.group(2)!;
          final String itemName = match.group(3)!.replaceAll('+', '').trim();

          final String key = "$itemName ($unit)";

          if (consolidatedList.containsKey(key)) {
            consolidatedList[key] = consolidatedList[key]! + amount;
          } else {
            consolidatedList[key] = amount;
          }
        }
      }
    }

    return consolidatedList;
  }
}