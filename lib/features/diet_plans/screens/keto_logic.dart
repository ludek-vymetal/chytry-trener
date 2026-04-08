import '../../../data/keto_bank.dart';

import '../../../models/user_profile.dart';

class KetoCalculator {
  static Map<String, dynamic> calculateKetoMakra(UserProfile profile) {
    final double targetCalories = profile.tdee * 0.85; // Mírný deficit
    
    // Keto standard: 70% Tuky, 25% Bílkoviny, 5% Sacharidy
    final double protein = (targetCalories * 0.25) / 4;
    final double carbs = 30.0; // Fixní limit pro keto
    final double fats = (targetCalories - (protein * 4) - (carbs * 4)) / 9;

    return {
      'protein': protein,
      'fats': fats,
      'carbs': carbs,
    };
  }

  static List<Map<String, String>> generateKetoMenu(double p, double f, double c) {
    // Rozdělíme na 4 jídla
    return [
      _buildKetoMeal("Snídaně", p / 4, f / 4),
      _buildKetoMeal("Oběd", p / 4, f / 4),
      _buildKetoMeal("Svačina", p / 4, f / 4),
      _buildKetoMeal("Večeře", p / 4, f / 4),
    ];
  }

  static Map<String, String> _buildKetoMeal(String type, double targetP, double targetF) {
    final bank = KetoBank.items;
    
    // Najdeme něco s bílkovinou
    final proteinSources = bank.where((m) => m.proteinPer100g > 15).toList()..shuffle();
    final fatSources = bank.where((m) => m.fatsPer100g > 30).toList()..shuffle();

    final main = proteinSources.first;
    final fatAddon = fatSources.first;

    double mainGrams = (targetP / (main.proteinPer100g / 100));
    
    return {
      "label": type,
      "name": "${main.name} na tuku",
      "description": "${mainGrams.round()}g ${main.name} + ${fatAddon.name} + listová zelenina",
    };
  }
}