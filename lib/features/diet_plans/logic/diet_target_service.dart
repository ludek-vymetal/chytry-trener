import '../../../l10n/app_localizations.dart';
import '../../../models/goal.dart';
import '../../../models/user_profile.dart';
import 'diet_macro_service.dart';

class DietTargetResult {
  final double targetCalories;

  final String sourceLabel;

  final bool accelerated;

  const DietTargetResult({
    required this.targetCalories,
    required this.sourceLabel,
    required this.accelerated,
  });
}

/// Kalorický cíl pro jídelníčky.
///
/// Dřív měl vlastní pevná čísla (cut −400 kcal apod.) a počítal z pole
/// `profile.tdee`, které se nikde nenastavovalo (vždy 2000 kcal). Teď bere
/// stejný cíl jako hlavní obrazovka – přes [DietMacroService.base].
class DietTargetService {
  static DietTargetResult resolve(
    UserProfile profile,
    AppLocalizations l10n,
  ) {
    final goal = profile.goal;
    final macros = DietMacroService.base(profile);

    return DietTargetResult(
      targetCalories: macros.targetCalories.toDouble(),
      sourceLabel:
          goal == null ? l10n.noGoalMaintenanceMode : macros.phaseLabel,
      accelerated: goal?.planMode == GoalPlanMode.accelerated,
    );
  }
}
