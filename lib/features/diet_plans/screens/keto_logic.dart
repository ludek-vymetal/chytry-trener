import '../logic/keto_calculator.dart' as core;
import '../../../models/user_profile.dart';

class KetoCalculator {
  static Map<String, dynamic> calculateKetoMakra(UserProfile profile) {
    return core.KetoCalculator.calculateMacros(profile);
  }

  static List<Map<String, String>> generateKetoMenu(
    double p,
    double f,
    double c,
  ) {
    return core.KetoCalculator.generateKetoMenu(p, f, c);
  }
}