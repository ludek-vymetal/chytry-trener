import '../../../l10n/app_localizations.dart';
import '../../../models/user_profile.dart';
import '../models/carb_cycling_plan.dart';
import '../models/saved_meal_plan.dart';
import 'diet_target_service.dart';
import 'meal_plan_math.dart';

/// Přepočet uloženého jídelníčku (šablony) na jiného klienta.
///
/// Porce se vynásobí poměrem kalorií, zaokrouhlí na reálně odvažitelná
/// množství (celé kusy, 5 g…) a makroživiny se pak znovu spočítají
/// z potravin – vždy v celých gramech.
class MealPlanScalingService {
  static DietMealPlan scaleByWeight({
    required DietMealPlan original,
    required double fromWeight,
    required double toWeight,
  }) {
    if (fromWeight <= 0 || toWeight <= 0) {
      return MealPlanMath.normalizePlan(original);
    }
    return MealPlanMath.scale(original, toWeight / fromWeight);
  }

  static DietMealPlan scaleByCalories({
    required DietMealPlan original,
    required double fromCalories,
    required double toCalories,
  }) {
    if (fromCalories <= 0 || toCalories <= 0) {
      return MealPlanMath.normalizePlan(original);
    }
    return MealPlanMath.scaleToKcal(original, toCalories);
  }

  /// Kalorický cíl profilu pro přepočet šablony. Bez cíle se použije
  /// poměr tělesné hmotnosti vůči šabloně.
  static double suggestedCalories({
    required SavedMealPlan template,
    required UserProfile profile,
    required AppLocalizations l10n,
  }) {
    final from = templateCalories(template);
    if (profile.goal != null) {
      final t = DietTargetService.resolve(profile, l10n).targetCalories;
      if (t > 0) return t;
    }
    if (template.baseWeight > 0 && profile.weight > 0 && from > 0) {
      return from * profile.weight / template.baseWeight;
    }
    return from;
  }

  /// Průměrné denní kalorie šablony.
  static double templateCalories(SavedMealPlan template) {
    final k = planAverageCalories(template.plan);
    return k > 0 ? k : template.baseCalories;
  }

  static DietMealPlan scaleTemplateToProfile({
    required SavedMealPlan template,
    required UserProfile profile,
    required AppLocalizations l10n,
    double? targetCalories,
  }) {
    final to = targetCalories ??
        suggestedCalories(template: template, profile: profile, l10n: l10n);
    final scaled = scaleByCalories(
      original: template.plan,
      fromCalories: templateCalories(template),
      toCalories: to,
    );
    return scaled.copyWith(
      note: _appendScaleNote(
        template.plan.note,
        l10n.scaledByCalories(
          profile.displayName,
          profile.weight.toStringAsFixed(1),
        ),
      ),
    );
  }

  /// Průměrné denní kalorie jídelníčku.
  static double planAverageCalories(DietMealPlan plan) =>
      MealPlanMath.planKcal(plan);

  static String _appendScaleNote(String? note, String appended) {
    final base = (note ?? '').trim();
    if (base.isEmpty) return appended;
    if (base.contains(appended)) return base;
    return '$base\n$appended';
  }
}
