import 'package:dart_application_1/features/diet_plans/models/carb_cycling_plan.dart';
import 'package:dart_application_1/models/user_profile.dart';
import '../../../data/sacharidove_vlny_bank.dart'; 
import '../../../models/meal.dart';

class CarbCyclingCalculator {
  
  static CarbCyclingPlan calculate({required UserProfile profile}) {
    final double targetCalories = profile.tdee * 0.9;
    final double protein = profile.weight * 2.0; 
    
    const double avgTarget = 239.0;
    const double weeklyBank = avgTarget * 7; 
    const double lowDay = 50.0;
    
    final double fatCalories = targetCalories - (protein * 4) - (lowDay * 4);
    final double fats = fatCalories / 9;
    
    double remainingBank = weeklyBank - (2 * lowDay);
    double baseShare = remainingBank / 5;
    List<double> multipliers = [0.65, 0.85, 1.0, 1.15, 1.35]; 

    List<double> rawCarbs = [
      lowDay, 
      baseShare * multipliers[0], 
      lowDay, 
      baseShare * multipliers[1], 
      baseShare * multipliers[2], 
      baseShare * multipliers[3], 
      baseShare * multipliers[4], 
    ];

    List<double> dailyCarbs = rawCarbs.map((g) => (g / 5).round() * 5.0).toList();

    return CarbCyclingPlan(
      dailyCarbs: dailyCarbs,
      protein: protein,
      fats: fats,
      weeklyBank: weeklyBank,
    );
  }

  static List<Map<String, String>> generateDailyMenu({
    required double carbs,    
    required double protein,
    required double fats,
    bool isKeto = false,
  }) {
    return [
      _buildMealForMealTime("Snídaně", protein * 0.25, fats * 0.25, carbs * 0.25, isKeto),
      _buildMealForMealTime("Svačina", protein * 0.15, fats * 0.20, carbs * 0.15, isKeto),
      _buildMealForMealTime("Oběd", protein * 0.35, fats * 0.30, carbs * 0.35, isKeto),
      _buildMealForMealTime("Večeře", protein * 0.25, fats * 0.25, carbs * 0.25, isKeto),
    ];
  }

  static Map<String, String> _buildMealForMealTime(String type, double p, double f, double c, bool isKeto) {
    final allMeals = SacharidoveVlnyBank.items;
    if (allMeals.isEmpty) return {"label": type, "name": "Chyba", "description": "Banka jídel je prázdná"};
    
    Meal chosenMain;
    Meal? chosenCarb;

    // 1. SNÍDANĚ
    if (type == "Snídaně") {
      if (!isKeto && c > 20) {
        chosenMain = allMeals.firstWhere((m) => m.name.toLowerCase().contains("vločky"), orElse: () => allMeals.first);
        double grams = (c / (chosenMain.carbsPer100g / 100)).clamp(40, 120);
        return {
          "label": type,
          "name": "Ovesná kaše s proteinem",
          "description": "${grams.round()}g Ovesné vločky, zalít vodou/mlékem + protein.",
          "ingredients": "${grams.round()}g Ovesné vločky, 30g Protein", // ✅ PRO NÁKUP
        };
      } else {
        chosenMain = allMeals.firstWhere((m) => m.name == "Vejce", orElse: () => allMeals.first);
        int count = (p / 6.5).round().clamp(2, 5);
        return {
          "label": type,
          "name": "Míchaná vejce",
          "description": "$count ks Vejce připravená na pánvi + zelenina.",
          "ingredients": "$count ks Vejce, 100g Zelenina", // ✅ PRO NÁKUP
        };
      }
    }

    // 2. SVAČINA
    if (type == "Svačina") {
      final lightPool = allMeals.where((m) => 
        m.name.contains("Šunka") || m.name.contains("Sýr") || m.name.contains("Jogurt") || m.name.contains("Mandle")
      ).toList()..shuffle();
      
      chosenMain = lightPool.isNotEmpty ? lightPool.first : allMeals.first;
      double grams = (p / (chosenMain.proteinPer100g / 100)).clamp(50, 150);
      
      return {
        "label": type,
        "name": "Lehká svačina: ${chosenMain.name}",
        "description": "${grams.round()}g ${chosenMain.name} + zelenina nebo kousek ovoce.",
        "ingredients": "${grams.round()}g ${chosenMain.name}", // ✅ PRO NÁKUP
      };
    }

    // 3. OBĚD & VEČEŘE
    final proteinPool = allMeals.where((m) => m.proteinPer100g > 15 && !m.name.contains("Vejce")).toList()..shuffle();
    final carbPool = allMeals.where((m) => m.carbsPer100g > 30).toList()..shuffle();

    chosenMain = proteinPool.first;
    if (!isKeto && c > 15) {
      chosenCarb = carbPool.first;
    }

    double grams = (p / (chosenMain.proteinPer100g / 100)).clamp(100, 250);
    double carbGrams = 0;
    if (chosenCarb != null) {
      carbGrams = (c / (chosenCarb.carbsPer100g / 100)).clamp(50, 250);
    }

    String content = "${grams.round()}g ${chosenMain.name}";
    String ingredients = "${grams.round()}g ${chosenMain.name}";

    if (chosenCarb != null && carbGrams > 10) {
      content += " + ${carbGrams.round()}g ${chosenCarb.name}";
      ingredients += ", ${carbGrams.round()}g ${chosenCarb.name}";
    }
    content += " + zelenina";
    ingredients += ", 150g Zelenina";

    return {
      "label": type,
      "name": "${chosenMain.name}${chosenCarb != null ? " + ${chosenCarb.name}" : ""}",
      "description": content,
      "ingredients": ingredients, // ✅ PRO NÁKUP
    };
  }
}