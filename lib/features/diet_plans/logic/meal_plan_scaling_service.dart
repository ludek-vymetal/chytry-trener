import '../../../l10n/app_localizations.dart';
import '../../../models/user_profile.dart';
import '../models/carb_cycling_plan.dart';
import '../models/saved_meal_plan.dart';
import 'diet_target_service.dart';

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
    required AppLocalizations l10n,
    bool preferCalories = true,
  }) {
    // Kalorie šablony bereme přímo z jejích makroživin (spolehlivé),
    // uložené baseCalories jen jako zálohu.
    final planCalories = planAverageCalories(template.plan);
    final fromCalories =
        planCalories > 0 ? planCalories : template.baseCalories;

    if (preferCalories && fromCalories > 0 && profile.goal != null) {
      final targetCalories =
          DietTargetService.resolve(profile, l10n).targetCalories;

      return scaleByCalories(
        original: template.plan,
        fromCalories: fromCalories,
        toCalories: targetCalories,
      ).copyWith(
        note: _appendScaleNote(
          template.plan.note,
          l10n.scaledByCalories(
            profile.displayName,
            profile.weight.toStringAsFixed(1),
          ),
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
        l10n.scaledByWeight(
          profile.displayName,
          profile.weight.toStringAsFixed(1),
        ),
      ),
    );
  }

  static DietMealPlan _scalePlan(
    DietMealPlan original,
    double ratio,
  ) {
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
            final scaledIngredients =
                meal.ingredients.map((ingredient) {
              return ingredient.copyWith(
                amount: _scaleIngredientAmount(
                  ingredient.amount,
                  ingredient.unit,
                  safeRatio,
                ),
              );
            }).toList();

            return meal.copyWith(
              calories: meal.calories == null
                  ? null
                  : meal.calories! * safeRatio,
              protein: meal.protein == null
                  ? null
                  : meal.protein! * safeRatio,
              carbs: meal.carbs == null
                  ? null
                  : meal.carbs! * safeRatio,
              fats: meal.fats == null
                  ? null
                  : meal.fats! * safeRatio,
              grams: meal.grams == null
                  ? null
                  : _roundGrams(
                      meal.grams! * safeRatio,
                    ),
              ingredients: scaledIngredients,
              description:
                  _buildDescriptionFromIngredients(
                scaledIngredients,
              ),
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
        return scaled < 1
            ? 1
            : scaled.roundToDouble();

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

  static double _roundToStep(
    double value,
    int step,
  ) {
    if (value <= 0) {
      return 0;
    }

    return ((value / step).round() * step)
        .toDouble();
  }

  static String _buildDescriptionFromIngredients(
    List<MealIngredient> items,
  ) {
    if (items.isEmpty) {
      return '';
    }

    return items
        .map(
          (e) =>
              '${e.name} (${e.formattedAmount})',
        )
        .join(' + ');
  }

  /// Průměrné denní kalorie jídelníčku spočítané z jeho makroživin.
  /// Používá se jako "výchozí kalorie" šablony (nezávisle na profilu).
  static double planAverageCalories(DietMealPlan plan) {
    if (plan.days.isEmpty) {
      return plan.protein * 4 + plan.carbs * 4 + plan.fats * 9;
    }

    var sum = 0.0;
    for (final day in plan.days) {
      sum += day.protein * 4 + day.carbs * 4 + day.fats * 9;
    }
    return sum / plan.days.length;
  }

  static String _appendScaleNote(
    String? note,
    String appended,
  ) {
    final base = (note ?? '').trim();

    if (base.isEmpty) {
      return appended;
    }

    if (base.contains(appended)) {
      return base;
    }

    return '$base\n$appended';
  }
}