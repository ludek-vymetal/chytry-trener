import '../../../models/goal.dart';
import '../../../models/user_profile.dart';
import '../models/carb_cycling_plan.dart';
import '../models/saved_meal_plan.dart';

class MealPlanScalingService {
  static DietMealPlan scaleByWeight({
    required DietMealPlan original,
    required double fromWeight,
    required double toWeight,
  }) {
    if (fromWeight <= 0 || toWeight <= 0) {
      return original;
    }

    final ratio = toWeight / fromWeight;
    return _scalePlan(original, ratio);
  }

  static DietMealPlan scaleByCalories({
    required DietMealPlan original,
    required double fromCalories,
    required double toCalories,
  }) {
    if (fromCalories <= 0 || toCalories <= 0) {
      return original;
    }

    final ratio = toCalories / fromCalories;
    return _scalePlan(original, ratio);
  }

  static DietMealPlan scaleTemplateToProfile({
    required SavedMealPlan template,
    required UserProfile profile,
    bool preferCalories = true,
  }) {
    if (preferCalories &&
        template.baseCalories > 0 &&
        profile.tdee > 0 &&
        profile.goal != null) {
      final targetCalories = _resolveTargetCalories(profile);
      return scaleByCalories(
        original: template.plan,
        fromCalories: template.baseCalories,
        toCalories: targetCalories,
      ).copyWith(
        note: _appendScaleNote(
          template.plan.note,
          'Přepočteno podle kalorií pro ${profile.displayName} (${profile.weight.toStringAsFixed(1)} kg).',
        ),
      );
    }

    return scaleByWeight(
      original: template.plan,
      fromWeight: template.baseWeight,
      toWeight: profile.weight,
    ).copyWith(
      note: _appendScaleNote(
        template.plan.note,
        'Přepočteno podle váhy pro ${profile.displayName} (${profile.weight.toStringAsFixed(1)} kg).',
      ),
    );
  }

  static DietMealPlan _scalePlan(DietMealPlan original, double ratio) {
    final safeRatio = ratio <= 0 ? 1.0 : ratio;

    return DietMealPlan(
      planType: original.planType,
      protein: original.protein * safeRatio,
      carbs: original.carbs * safeRatio,
      fats: original.fats * safeRatio,
      note: original.note,
      days: original.days.map((day) {
        return PlannedDay(
          dayName: day.dayName,
          protein: day.protein * safeRatio,
          carbs: day.carbs * safeRatio,
          fats: day.fats * safeRatio,
          meals: day.meals.map((meal) {
            final scaledIngredients = meal.ingredients.map((ingredient) {
              return ingredient.copyWith(
                amount: _scaleIngredientAmount(
                  ingredient.amount,
                  ingredient.unit,
                  safeRatio,
                ),
              );
            }).toList();

            return meal.copyWith(
              calories:
                  meal.calories == null ? null : meal.calories! * safeRatio,
              protein: meal.protein == null ? null : meal.protein! * safeRatio,
              carbs: meal.carbs == null ? null : meal.carbs! * safeRatio,
              fats: meal.fats == null ? null : meal.fats! * safeRatio,
              grams: meal.grams == null
                  ? null
                  : _roundGrams(meal.grams! * safeRatio),
              ingredients: scaledIngredients,
              description: _buildDescriptionFromIngredients(scaledIngredients),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  static double _scaleIngredientAmount(
    double amount,
    String unit,
    double ratio,
  ) {
    final scaled = amount * ratio;

    switch (unit.trim().toLowerCase()) {
      case 'ks':
        return scaled < 1 ? 1 : scaled.roundToDouble();
      case 'ml':
        return _roundToStep(scaled, 10);
      case 'g':
      default:
        return _roundToStep(scaled, 5);
    }
  }

  static int _roundGrams(double value) {
    return _roundToStep(value, 5).round();
  }

  static double _roundToStep(double value, int step) {
    if (value <= 0) return 0;
    return ((value / step).round() * step).toDouble();
  }

  static String _buildDescriptionFromIngredients(List<MealIngredient> items) {
    if (items.isEmpty) return '';
    return items.map((e) => '${e.name} (${e.formattedAmount})').join(' + ');
  }

  static double _resolveTargetCalories(UserProfile profile) {
    final goal = profile.goal;

    if (goal == null) {
      return profile.tdee;
    }

    switch (goal.phase) {
      case GoalPhase.cut:
        return profile.tdee - 400;
      case GoalPhase.build:
        return profile.tdee + 200;
      case GoalPhase.maintain:
        return profile.tdee;
      case GoalPhase.strength:
        return profile.tdee + 100;
      case null:
        return profile.tdee;
    }
  }

  static String _appendScaleNote(String? note, String appended) {
    final base = (note ?? '').trim();
    if (base.isEmpty) return appended;
    return '$base\n$appended';
  }
}