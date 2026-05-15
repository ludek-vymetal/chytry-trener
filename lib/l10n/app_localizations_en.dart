// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get dashboard => 'Dashboard';

  @override
  String get addClient => 'Add Client';

  @override
  String get todayFood => 'Today\'s Food';

  @override
  String get trainingMode => 'Training Mode';

  @override
  String get changeGoal => 'Change Goal';

  @override
  String get retry => 'Try Again';

  @override
  String get enterAllNumbers => 'Please enter all numbers (use a dot instead of a comma)';

  @override
  String get addNewCircumferences => 'Add New Circumferences';

  @override
  String get fitnessApp => 'Fitness App';

  @override
  String get userMode => 'User Mode';

  @override
  String get coachMode => 'Coach Mode';

  @override
  String get switchToThisProfile => 'SWITCH TO THIS PROFILE';

  @override
  String get profileActivatedUserMode => 'Profile activated. Mode: User.';

  @override
  String get appName => 'Smart Coach';

  @override
  String get exitApp => 'Exit App';

  @override
  String get subscriptionError => 'Subscription Error';

  @override
  String get subscriptionInactive => 'Subscription is not active.';

  @override
  String get activeCoachClient => 'Active: Coach + Client ✅';

  @override
  String get activeClientCoachLocked => 'Active: Client ✅ (Coach locked)';

  @override
  String get noAccess => 'No access';

  @override
  String get selectMode => 'Select Mode';

  @override
  String get modeDescription => 'Regular user = onboarding + AI plan.\nCoach mode = client management.';

  @override
  String get userModeLocked => 'User Mode (locked)';

  @override
  String get coachModeLocked => 'Coach Mode (locked)';

  @override
  String get unlockClient => 'Unlock Client (Paywall)';

  @override
  String get unlockCoach => 'Unlock Coach (upgrade)';

  @override
  String get exportFolderSaved => 'Export folder has been saved.';

  @override
  String get customExportFolderRemoved => 'Custom export folder has been removed. Default Documents/Clients folder will be used.';

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get changeGoalDescription => 'Are you sure you want to change your goal? Changing the goal may modify strategy, phases and recommendations.';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get automatic => 'Automatic';

  @override
  String get czech => 'Czech';

  @override
  String get english => 'English';

  @override
  String get switchToLightMode => 'Switch to light mode';

  @override
  String get switchToDarkMode => 'Switch to dark mode';

  @override
  String get changeMode => 'Change mode';

  @override
  String get addMeasurement => 'Add Measurement';

  @override
  String get bodyCircumference => 'Body Circumference';

  @override
  String get addCircumference => 'Add Circumference';

  @override
  String get performance => 'Performance / PR';

  @override
  String get dailyMacros => 'Daily Macros';

  @override
  String get dietPlanStyle => 'Diet Plan Style';

  @override
  String get phaseLogicTest => 'Phase Logic Test';

  @override
  String folderPickFailed(Object error) {
    return 'Failed to select folder: $error';
  }

  @override
  String get newMeasurement => 'New Measurement';

  @override
  String get date => 'Date';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get muscleMassOptional => 'Muscle Mass (kg) – optional';

  @override
  String get fatMassOptional => 'Fat Mass (kg) – optional';

  @override
  String get saveMeasurement => 'Save Measurement';

  @override
  String get enterValidWeight => 'Enter valid weight';

  @override
  String get noMeasurementsYet => 'No measurements yet';

  @override
  String get history => 'History';

  @override
  String get waistChart => 'Chart (Waist)';

  @override
  String get waistTrend => 'Waist circumference trend';

  @override
  String get waistChartDescription => 'The chart shows waist progress over time (left to right)';

  @override
  String get waist => 'Waist';

  @override
  String get chest => 'Chest';

  @override
  String get biceps => 'Biceps';

  @override
  String get thigh => 'Thigh';

  @override
  String get neck => 'Neck';
}
