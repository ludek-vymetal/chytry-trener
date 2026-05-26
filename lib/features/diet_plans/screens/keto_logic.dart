import '../logic/keto_calculator.dart' as core;
import '../../../models/user_profile.dart';
import '../../../l10n/app_localizations.dart';

class KetoCalculator {
  static Map<String, dynamic> calculateKetoMakra(
    UserProfile profile,
    AppLocalizations l10n,
  ) {
    return core.KetoCalculator.calculateMacros(
      profile,
      l10n,
    );
  }

  static List<Map<String, String>> generateKetoMenu(
    double p,
    double f,
    double c,
    AppLocalizations l10n,
  ) {
    return core.KetoCalculator.generateKetoMenu(
      p,
      f,
      c,
      l10n: l10n,
    );
  }
}