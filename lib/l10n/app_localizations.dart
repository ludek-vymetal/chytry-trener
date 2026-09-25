import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('cs'),
    Locale('en')
  ];

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @addClient.
  ///
  /// In en, this message translates to:
  /// **'Add Client'**
  String get addClient;

  /// No description provided for @todayFood.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Food'**
  String get todayFood;

  /// No description provided for @trainingMode.
  ///
  /// In en, this message translates to:
  /// **'Training Mode'**
  String get trainingMode;

  /// No description provided for @changeGoal.
  ///
  /// In en, this message translates to:
  /// **'Change Goal'**
  String get changeGoal;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get retry;

  /// No description provided for @enterAllNumbers.
  ///
  /// In en, this message translates to:
  /// **'Please enter all numbers (use a dot instead of a comma)'**
  String get enterAllNumbers;

  /// No description provided for @addNewCircumferences.
  ///
  /// In en, this message translates to:
  /// **'Add New Circumferences'**
  String get addNewCircumferences;

  /// No description provided for @fitnessApp.
  ///
  /// In en, this message translates to:
  /// **'Fitness App'**
  String get fitnessApp;

  /// No description provided for @userMode.
  ///
  /// In en, this message translates to:
  /// **'User Mode'**
  String get userMode;

  /// No description provided for @coachMode.
  ///
  /// In en, this message translates to:
  /// **'Coach Mode'**
  String get coachMode;

  /// No description provided for @switchToThisProfile.
  ///
  /// In en, this message translates to:
  /// **'SWITCH TO THIS PROFILE'**
  String get switchToThisProfile;

  /// No description provided for @profileActivatedUserMode.
  ///
  /// In en, this message translates to:
  /// **'Profile activated. Mode: User.'**
  String get profileActivatedUserMode;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Smart Coach'**
  String get appName;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitApp;

  /// No description provided for @subscriptionError.
  ///
  /// In en, this message translates to:
  /// **'Subscription Error'**
  String get subscriptionError;

  /// No description provided for @subscriptionInactive.
  ///
  /// In en, this message translates to:
  /// **'Subscription is not active.'**
  String get subscriptionInactive;

  /// No description provided for @activeCoachClient.
  ///
  /// In en, this message translates to:
  /// **'Active: Coach + Client ✅'**
  String get activeCoachClient;

  /// No description provided for @activeClientCoachLocked.
  ///
  /// In en, this message translates to:
  /// **'Active: Client ✅ (Coach locked)'**
  String get activeClientCoachLocked;

  /// No description provided for @noAccess.
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get noAccess;

  /// No description provided for @selectMode.
  ///
  /// In en, this message translates to:
  /// **'Select Mode'**
  String get selectMode;

  /// No description provided for @modeDescription.
  ///
  /// In en, this message translates to:
  /// **'Regular user = onboarding + personal plan.\nCoach mode = client management.'**
  String get modeDescription;

  /// No description provided for @userModeLocked.
  ///
  /// In en, this message translates to:
  /// **'User Mode (locked)'**
  String get userModeLocked;

  /// No description provided for @coachModeLocked.
  ///
  /// In en, this message translates to:
  /// **'Coach Mode (locked)'**
  String get coachModeLocked;

  /// No description provided for @unlockClient.
  ///
  /// In en, this message translates to:
  /// **'Unlock Client (Paywall)'**
  String get unlockClient;

  /// No description provided for @unlockCoach.
  ///
  /// In en, this message translates to:
  /// **'Unlock Coach (upgrade)'**
  String get unlockCoach;

  /// No description provided for @exportFolderSaved.
  ///
  /// In en, this message translates to:
  /// **'Export folder has been saved.'**
  String get exportFolderSaved;

  /// No description provided for @customExportFolderRemoved.
  ///
  /// In en, this message translates to:
  /// **'Custom export folder has been removed. Default Documents/Clients folder will be used.'**
  String get customExportFolderRemoved;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// No description provided for @changeGoalDescription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change your goal? Changing the goal may modify strategy, phases and recommendations.'**
  String get changeGoalDescription;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @czech.
  ///
  /// In en, this message translates to:
  /// **'Czech'**
  String get czech;

  /// English label
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @ketoMealPlanPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Keto Meal Plan'**
  String get ketoMealPlanPdfTitle;

  /// No description provided for @carbCyclingPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Carb Cycling'**
  String get carbCyclingPdfTitle;

  /// No description provided for @ketoMealPlanPdfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Low-carb nutrition focused on fats and stable protein intake.'**
  String get ketoMealPlanPdfSubtitle;

  /// No description provided for @carbCyclingPdfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates are cycled depending on the training day.'**
  String get carbCyclingPdfSubtitle;

  /// No description provided for @yourKetoMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Your Keto Meal Plan'**
  String get yourKetoMealPlan;

  /// No description provided for @yourPlan.
  ///
  /// In en, this message translates to:
  /// **'Your Plan'**
  String get yourPlan;

  /// No description provided for @printPdf.
  ///
  /// In en, this message translates to:
  /// **'Print / PDF'**
  String get printPdf;

  /// No description provided for @sharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get sharePdf;

  /// No description provided for @dailyCarbIntake.
  ///
  /// In en, this message translates to:
  /// **'DAILY CARBOHYDRATE INTAKE'**
  String get dailyCarbIntake;

  /// No description provided for @weeklyCarbBank.
  ///
  /// In en, this message translates to:
  /// **'YOUR WEEKLY CARB BANK'**
  String get weeklyCarbBank;

  /// No description provided for @proteinLabel.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get proteinLabel;

  /// No description provided for @fatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Fats'**
  String get fatsLabel;

  /// No description provided for @generateShoppingList.
  ///
  /// In en, this message translates to:
  /// **'GENERATE SHOPPING LIST'**
  String get generateShoppingList;

  /// No description provided for @showFullWeeklyMealPlan.
  ///
  /// In en, this message translates to:
  /// **'SHOW FULL WEEKLY MEAL PLAN'**
  String get showFullWeeklyMealPlan;

  /// No description provided for @dayMealBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Daily breakdown and meal plan:'**
  String get dayMealBreakdown;

  /// No description provided for @refeedDay.
  ///
  /// In en, this message translates to:
  /// **'REFEED DAY 🚀'**
  String get refeedDay;

  /// No description provided for @closeAndActivate.
  ///
  /// In en, this message translates to:
  /// **'CLOSE AND ACTIVATE'**
  String get closeAndActivate;

  /// No description provided for @setupProfileAndGoalFirst.
  ///
  /// In en, this message translates to:
  /// **'Please set up profile and goal first.'**
  String get setupProfileAndGoalFirst;

  /// No description provided for @eatingSupportOnlyMode.
  ///
  /// In en, this message translates to:
  /// **'This questionnaire is only for Weight Gain / Eating Disorder Support mode.'**
  String get eatingSupportOnlyMode;

  /// No description provided for @safeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight gain support / safe mode'**
  String get safeModeTitle;

  /// No description provided for @safeModeDescription.
  ///
  /// In en, this message translates to:
  /// **'This mode is designed to avoid restriction and calorie tracking.\nThe goal is a safe return of energy, routine and strength.'**
  String get safeModeDescription;

  /// No description provided for @safetyAndPreferences.
  ///
  /// In en, this message translates to:
  /// **'Safety and preferences'**
  String get safetyAndPreferences;

  /// No description provided for @hideNutritionNumbers.
  ///
  /// In en, this message translates to:
  /// **'Hide nutrition numbers (calories/macros)'**
  String get hideNutritionNumbers;

  /// No description provided for @hideNutritionNumbersDescription.
  ///
  /// In en, this message translates to:
  /// **'Recommended – the app will avoid pressure around numbers.'**
  String get hideNutritionNumbersDescription;

  /// No description provided for @medicalSupport.
  ///
  /// In en, this message translates to:
  /// **'I have professional support (therapist / doctor / nutritionist)'**
  String get medicalSupport;

  /// No description provided for @medicalSupportDescription.
  ///
  /// In en, this message translates to:
  /// **'Helps provide more sensitive recommendations.'**
  String get medicalSupportDescription;

  /// No description provided for @focusQuestion.
  ///
  /// In en, this message translates to:
  /// **'What do you want to focus on the most right now?'**
  String get focusQuestion;

  /// No description provided for @focusEnergyRoutine.
  ///
  /// In en, this message translates to:
  /// **'Energy & routine'**
  String get focusEnergyRoutine;

  /// No description provided for @focusStrengthPerformance.
  ///
  /// In en, this message translates to:
  /// **'Strength & performance'**
  String get focusStrengthPerformance;

  /// No description provided for @focusGentleMode.
  ///
  /// In en, this message translates to:
  /// **'Gentle pressure-free mode'**
  String get focusGentleMode;

  /// No description provided for @optionalNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get optionalNote;

  /// No description provided for @trainingSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Training Setup'**
  String get trainingSetupTitle;

  /// No description provided for @trainingFrequencyQuestion.
  ///
  /// In en, this message translates to:
  /// **'How many times per week do you want to train?'**
  String get trainingFrequencyQuestion;

  /// No description provided for @trainingFrequencyHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a realistic number based on your time and recovery.'**
  String get trainingFrequencyHint;

  /// No description provided for @timesPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{count}× per week'**
  String timesPerWeek(Object count);

  /// No description provided for @performancePr.
  ///
  /// In en, this message translates to:
  /// **'Performance / PR'**
  String get performancePr;

  /// No description provided for @addPerformance.
  ///
  /// In en, this message translates to:
  /// **'Add Performance'**
  String get addPerformance;

  /// No description provided for @noPerformanceRecords.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any performance records yet.\n\nClick + to add your first exercise.'**
  String get noPerformanceRecords;

  /// No description provided for @equipmentQuestion.
  ///
  /// In en, this message translates to:
  /// **'What equipment do you have?'**
  String get equipmentQuestion;

  /// No description provided for @insert90DayCutPlan.
  ///
  /// In en, this message translates to:
  /// **'Insert 90-Day Cutting Plan'**
  String get insert90DayCutPlan;

  /// No description provided for @insertPowerliftingPrep.
  ///
  /// In en, this message translates to:
  /// **'Insert Powerlifting Meet Prep'**
  String get insertPowerliftingPrep;

  /// No description provided for @planCreationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create the plan.'**
  String get planCreationFailed;

  /// No description provided for @planInserted.
  ///
  /// In en, this message translates to:
  /// **'The plan has been added to custom training plans.'**
  String get planInserted;

  /// No description provided for @enterMaxes.
  ///
  /// In en, this message translates to:
  /// **'Enter Maxes'**
  String get enterMaxes;

  /// No description provided for @squat1rm.
  ///
  /// In en, this message translates to:
  /// **'Squat 1RM (kg)'**
  String get squat1rm;

  /// No description provided for @bench1rm.
  ///
  /// In en, this message translates to:
  /// **'Bench press 1RM (kg)'**
  String get bench1rm;

  /// No description provided for @deadlift1rm.
  ///
  /// In en, this message translates to:
  /// **'Deadlift 1RM (kg)'**
  String get deadlift1rm;

  /// No description provided for @meetDate.
  ///
  /// In en, this message translates to:
  /// **'Meet Date'**
  String get meetDate;

  /// No description provided for @createPlan.
  ///
  /// In en, this message translates to:
  /// **'Create Plan'**
  String get createPlan;

  /// No description provided for @strengthTrainings.
  ///
  /// In en, this message translates to:
  /// **'Strength Trainings'**
  String get strengthTrainings;

  /// No description provided for @bulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk'**
  String get bulk;

  /// No description provided for @cut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// No description provided for @recomp.
  ///
  /// In en, this message translates to:
  /// **'Recomp'**
  String get recomp;

  /// No description provided for @fillWeeklyMealPlanName.
  ///
  /// In en, this message translates to:
  /// **'Fill weekly meal plan name'**
  String get fillWeeklyMealPlanName;

  /// No description provided for @selectTemplateForEachDay.
  ///
  /// In en, this message translates to:
  /// **'Select a template for each day'**
  String get selectTemplateForEachDay;

  /// No description provided for @failedToLoadDailyTemplate.
  ///
  /// In en, this message translates to:
  /// **'Failed to load daily template'**
  String get failedToLoadDailyTemplate;

  /// No description provided for @weeklyMealPlanSaved.
  ///
  /// In en, this message translates to:
  /// **'Weekly meal plan saved'**
  String get weeklyMealPlanSaved;

  /// No description provided for @buildWeeklyMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Build Weekly Meal Plan'**
  String get buildWeeklyMealPlan;

  /// No description provided for @saveWeek.
  ///
  /// In en, this message translates to:
  /// **'Save Week'**
  String get saveWeek;

  /// No description provided for @createDailyTemplateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create daily template first'**
  String get createDailyTemplateFirst;

  /// No description provided for @weeklyMealPlanName.
  ///
  /// In en, this message translates to:
  /// **'Weekly meal plan name'**
  String get weeklyMealPlanName;

  /// No description provided for @selectDailyTemplate.
  ///
  /// In en, this message translates to:
  /// **'Select daily template'**
  String get selectDailyTemplate;

  /// No description provided for @saveWeeklyMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Save weekly meal plan'**
  String get saveWeeklyMealPlan;

  /// No description provided for @mealCount.
  ///
  /// In en, this message translates to:
  /// **'Meal count'**
  String get mealCount;

  /// No description provided for @fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fat;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @tdeeDescription.
  ///
  /// In en, this message translates to:
  /// **'Note: TDEE is energy expenditure. Target calories and macros are determined by goal, phase, and target date.'**
  String get tdeeDescription;

  /// No description provided for @profileOrGoalNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile or goal not found'**
  String get profileOrGoalNotFound;

  /// No description provided for @powerlifting.
  ///
  /// In en, this message translates to:
  /// **'Powerlifting'**
  String get powerlifting;

  /// No description provided for @bodybuilding.
  ///
  /// In en, this message translates to:
  /// **'Bodybuilding'**
  String get bodybuilding;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'Days Count'**
  String get daysCount;

  /// No description provided for @deleteTemplate.
  ///
  /// In en, this message translates to:
  /// **'Delete Template'**
  String get deleteTemplate;

  /// No description provided for @insert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get insert;

  /// No description provided for @templateInserted.
  ///
  /// In en, this message translates to:
  /// **'Template \"{name}\" has been inserted for the client.'**
  String templateInserted(Object name);

  /// No description provided for @planSavedAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Plan \"{name}\" has been saved as a shared template.'**
  String planSavedAsTemplate(Object name);

  /// No description provided for @confirmDeletePlan.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete the plan \"{name}\"?'**
  String confirmDeletePlan(Object name);

  /// No description provided for @confirmDeleteDay.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete the day \"{name}\"?'**
  String confirmDeleteDay(Object name);

  /// No description provided for @confirmDeleteExercise.
  ///
  /// In en, this message translates to:
  /// **'Do you want to remove the exercise \"{name}\"?'**
  String confirmDeleteExercise(Object name);

  /// No description provided for @bodyweightEquipment.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get bodyweightEquipment;

  /// No description provided for @dumbbellEquipment.
  ///
  /// In en, this message translates to:
  /// **'Dumbbells'**
  String get dumbbellEquipment;

  /// No description provided for @barbellEquipment.
  ///
  /// In en, this message translates to:
  /// **'Barbell'**
  String get barbellEquipment;

  /// No description provided for @rackEquipment.
  ///
  /// In en, this message translates to:
  /// **'Rack'**
  String get rackEquipment;

  /// No description provided for @benchEquipment.
  ///
  /// In en, this message translates to:
  /// **'Bench'**
  String get benchEquipment;

  /// No description provided for @machineEquipment.
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get machineEquipment;

  /// No description provided for @cardioEquipment.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get cardioEquipment;

  /// No description provided for @equipmentHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: if you don\'t have something, the app will choose more suitable exercises.'**
  String get equipmentHint;

  /// No description provided for @experienceQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is your experience level?'**
  String get experienceQuestion;

  /// No description provided for @experienceHint.
  ///
  /// In en, this message translates to:
  /// **'This helps set appropriate difficulty.'**
  String get experienceHint;

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @oneRepMaxTitle.
  ///
  /// In en, this message translates to:
  /// **'One-rep maxes (1RM) – competition only'**
  String get oneRepMaxTitle;

  /// No description provided for @trainingMaxHint.
  ///
  /// In en, this message translates to:
  /// **'Note: training weights are calculated from the “training max” (90% of 1RM).'**
  String get trainingMaxHint;

  /// No description provided for @fillAllMaxes.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all one-rep maxes (positive numbers).'**
  String get fillAllMaxes;

  /// No description provided for @carbCyclingReadinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Readiness Analysis'**
  String get carbCyclingReadinessTitle;

  /// No description provided for @carbCyclingIntro.
  ///
  /// In en, this message translates to:
  /// **'This questionnaire evaluates whether it is safe for your body to transition to a carb cycling system.'**
  String get carbCyclingIntro;

  /// No description provided for @healthState.
  ///
  /// In en, this message translates to:
  /// **'Health Status'**
  String get healthState;

  /// No description provided for @healthIssuesQuestion.
  ///
  /// In en, this message translates to:
  /// **'Diabetes or history of eating disorders?'**
  String get healthIssuesQuestion;

  /// No description provided for @healthIssuesDescription.
  ///
  /// In en, this message translates to:
  /// **'For safety reasons, this is a strict criterion.'**
  String get healthIssuesDescription;

  /// No description provided for @stressLevelQuestion.
  ///
  /// In en, this message translates to:
  /// **'Current stress level (1 = calm, 10 = burnout)'**
  String get stressLevelQuestion;

  /// No description provided for @stressLabel.
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get stressLabel;

  /// No description provided for @stressLevelValue.
  ///
  /// In en, this message translates to:
  /// **'Stress level'**
  String get stressLevelValue;

  /// No description provided for @averageSleepLength.
  ///
  /// In en, this message translates to:
  /// **'Average Sleep Duration'**
  String get averageSleepLength;

  /// No description provided for @sleepLabel.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleepLabel;

  /// No description provided for @hoursLabel.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hoursLabel;

  /// No description provided for @trainingUnits.
  ///
  /// In en, this message translates to:
  /// **'workouts'**
  String get trainingUnits;

  /// No description provided for @trainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get trainingLabel;

  /// No description provided for @hydrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get hydrationTitle;

  /// No description provided for @hydrationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you drink at least 2–3 liters of water daily?'**
  String get hydrationQuestion;

  /// No description provided for @evaluateReadiness.
  ///
  /// In en, this message translates to:
  /// **'EVALUATE READINESS'**
  String get evaluateReadiness;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'APPROVED'**
  String get approved;

  /// No description provided for @notRecommended.
  ///
  /// In en, this message translates to:
  /// **'NOT RECOMMENDED'**
  String get notRecommended;

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I Understand'**
  String get iUnderstand;

  /// No description provided for @carbCyclingHealthWarning.
  ///
  /// In en, this message translates to:
  /// **'Due to health risks (diabetes/history of eating disorders), carb cycling is not suitable for you. Client safety is our priority.'**
  String get carbCyclingHealthWarning;

  /// No description provided for @carbCyclingStressWarning.
  ///
  /// In en, this message translates to:
  /// **'Your current stress level is too high. Carb cycling places additional stress on the body. We recommend first stabilizing your routine with a standard diet.'**
  String get carbCyclingStressWarning;

  /// No description provided for @carbCyclingSleepWarning.
  ///
  /// In en, this message translates to:
  /// **'Sleeping less than 6 hours per day prevents the proper recovery required for carb cycling. Focus on improving rest first.'**
  String get carbCyclingSleepWarning;

  /// No description provided for @carbCyclingTrainingWarning.
  ///
  /// In en, this message translates to:
  /// **'Carb cycling requires at least 3 strength training sessions per week so the body can effectively utilize high-carb days.'**
  String get carbCyclingTrainingWarning;

  /// No description provided for @carbCyclingWaterWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: Carb cycling significantly affects water balance in the body. You need to increase your water intake!'**
  String get carbCyclingWaterWarning;

  /// No description provided for @carbCyclingApprovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You are ready for carb cycling. Your body has good potential for nutrient cycling.'**
  String get carbCyclingApprovedMessage;

  /// No description provided for @saveTrainingSetup.
  ///
  /// In en, this message translates to:
  /// **'Save setup'**
  String get saveTrainingSetup;

  /// No description provided for @numberInputHint.
  ///
  /// In en, this message translates to:
  /// **'You can also use commas (e.g. 120,5).'**
  String get numberInputHint;

  /// No description provided for @trainingFrequencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Number of strength workouts per week'**
  String get trainingFrequencyTitle;

  /// No description provided for @optionalNoteDescription.
  ///
  /// In en, this message translates to:
  /// **'Example: “I want light training 3× weekly”, “no weighing”, “prefer machines”.'**
  String get optionalNoteDescription;

  /// No description provided for @yourWeeklyKetoPlan.
  ///
  /// In en, this message translates to:
  /// **'Your Weekly Keto Plan'**
  String get yourWeeklyKetoPlan;

  /// No description provided for @openFullWeek.
  ///
  /// In en, this message translates to:
  /// **'OPEN FULL WEEK'**
  String get openFullWeek;

  /// No description provided for @weeklyKetoMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Weekly Keto Meal Plan'**
  String get weeklyKetoMealPlan;

  /// No description provided for @fullWeekMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Meal Plan For The Whole Week:'**
  String get fullWeekMealPlan;

  /// No description provided for @ingredientsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientsLabel;

  /// No description provided for @carbsLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates'**
  String get carbsLabel;

  /// No description provided for @mentalHealthWarning.
  ///
  /// In en, this message translates to:
  /// **'If you feel mentally overwhelmed or have urges to harm yourself, seek immediate help. Contact local mental health crisis services or emergency support in your country.'**
  String get mentalHealthWarning;

  /// No description provided for @switchToLightMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get switchToLightMode;

  /// No description provided for @switchToDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get switchToDarkMode;

  /// No description provided for @changeMode.
  ///
  /// In en, this message translates to:
  /// **'Change mode'**
  String get changeMode;

  /// No description provided for @addMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Add Measurement'**
  String get addMeasurement;

  /// No description provided for @bodyCircumference.
  ///
  /// In en, this message translates to:
  /// **'Body Circumference'**
  String get bodyCircumference;

  /// No description provided for @addCircumference.
  ///
  /// In en, this message translates to:
  /// **'Add Circumference'**
  String get addCircumference;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance / PR'**
  String get performance;

  /// No description provided for @dailyMacros.
  ///
  /// In en, this message translates to:
  /// **'Daily Macros'**
  String get dailyMacros;

  /// No description provided for @dietPlanStyle.
  ///
  /// In en, this message translates to:
  /// **'Diet Plan Style'**
  String get dietPlanStyle;

  /// No description provided for @phaseLogicTest.
  ///
  /// In en, this message translates to:
  /// **'Phase Logic Test'**
  String get phaseLogicTest;

  /// No description provided for @noPerformanceRecordsForExercise.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any records for this exercise yet.'**
  String get noPerformanceRecordsForExercise;

  /// No description provided for @showChart.
  ///
  /// In en, this message translates to:
  /// **'Show Chart'**
  String get showChart;

  /// No description provided for @folderPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Folder selection failed: {error}'**
  String folderPickFailed(Object error);

  /// No description provided for @dayOptions.
  ///
  /// In en, this message translates to:
  /// **'Day Options'**
  String get dayOptions;

  /// No description provided for @customPlanEmpty.
  ///
  /// In en, this message translates to:
  /// **'The active custom plan does not contain any days or exercises yet.'**
  String get customPlanEmpty;

  /// No description provided for @planGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate plan.'**
  String get planGenerationFailed;

  /// No description provided for @coachGoal.
  ///
  /// In en, this message translates to:
  /// **'Coach Goal'**
  String get coachGoal;

  /// No description provided for @newMeasurement.
  ///
  /// In en, this message translates to:
  /// **'New Measurement'**
  String get newMeasurement;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @muscleMassOptional.
  ///
  /// In en, this message translates to:
  /// **'Muscle Mass (kg) – optional'**
  String get muscleMassOptional;

  /// No description provided for @fatMassOptional.
  ///
  /// In en, this message translates to:
  /// **'Fat Mass (kg) – optional'**
  String get fatMassOptional;

  /// No description provided for @saveMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Save Measurement'**
  String get saveMeasurement;

  /// No description provided for @enterValidWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter valid weight'**
  String get enterValidWeight;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @noMeasurementsYet.
  ///
  /// In en, this message translates to:
  /// **'No measurements yet'**
  String get noMeasurementsYet;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @waistChart.
  ///
  /// In en, this message translates to:
  /// **'Chart (Waist)'**
  String get waistChart;

  /// No description provided for @waistTrend.
  ///
  /// In en, this message translates to:
  /// **'Waist circumference trend'**
  String get waistTrend;

  /// No description provided for @waistChartDescription.
  ///
  /// In en, this message translates to:
  /// **'The chart shows waist progress over time (left to right)'**
  String get waistChartDescription;

  /// No description provided for @biceps.
  ///
  /// In en, this message translates to:
  /// **'Biceps'**
  String get biceps;

  /// No description provided for @neck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get neck;

  /// No description provided for @selectExercise.
  ///
  /// In en, this message translates to:
  /// **'Select Exercise'**
  String get selectExercise;

  /// Search exercise label
  ///
  /// In en, this message translates to:
  /// **'Search Exercise'**
  String get searchExercise;

  /// No description provided for @showAllExercises.
  ///
  /// In en, this message translates to:
  /// **'Show All Exercises'**
  String get showAllExercises;

  /// No description provided for @showAllExercisesDescription.
  ///
  /// In en, this message translates to:
  /// **'When disabled, only recommended exercises for this slot will be shown.'**
  String get showAllExercisesDescription;

  /// No description provided for @noRecommendedExerciseFound.
  ///
  /// In en, this message translates to:
  /// **'No suitable exercise was found for this slot based on your equipment and filters. Enable “Show All Exercises” or adjust your equipment in training setup.'**
  String get noRecommendedExerciseFound;

  /// No description provided for @noExerciseFoundBySearch.
  ///
  /// In en, this message translates to:
  /// **'No exercise found for your search.'**
  String get noExerciseFoundBySearch;

  /// No description provided for @noExerciseFoundForSlot.
  ///
  /// In en, this message translates to:
  /// **'No suitable exercise found for this slot.'**
  String get noExerciseFoundForSlot;

  /// No description provided for @englishLabel.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLabel;

  /// No description provided for @equipmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get equipmentLabel;

  /// No description provided for @coachSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Coach has been signed out.'**
  String get coachSignedOut;

  /// No description provided for @logoutCoach.
  ///
  /// In en, this message translates to:
  /// **'Sign out coach'**
  String get logoutCoach;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @scaledByCalories.
  ///
  /// In en, this message translates to:
  /// **'Scaled by calories for {name} ({weight} kg).'**
  String scaledByCalories(Object name, Object weight);

  /// No description provided for @scaledByWeight.
  ///
  /// In en, this message translates to:
  /// **'Scaled by weight for {name} ({weight} kg).'**
  String scaledByWeight(Object name, Object weight);

  /// No description provided for @signOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign out: {error}'**
  String signOutFailed(Object error);

  /// No description provided for @coachRegistration.
  ///
  /// In en, this message translates to:
  /// **'Coach Registration'**
  String get coachRegistration;

  /// No description provided for @coachLogin.
  ///
  /// In en, this message translates to:
  /// **'Coach Login'**
  String get coachLogin;

  /// No description provided for @coachAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Coach account has been created.'**
  String get coachAccountCreated;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login successful.'**
  String get loginSuccessful;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter e-mail.'**
  String get enterEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter valid e-mail.'**
  String get enterValidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password.'**
  String get enterPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 6 characters.'**
  String get passwordTooShort;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password.'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @clientArchiving.
  ///
  /// In en, this message translates to:
  /// **'Client Archiving'**
  String get clientArchiving;

  /// No description provided for @loadingExportFolder.
  ///
  /// In en, this message translates to:
  /// **'Loading export folder settings...'**
  String get loadingExportFolder;

  /// No description provided for @currentExportFolder.
  ///
  /// In en, this message translates to:
  /// **'Current export folder:\n\n{path}'**
  String currentExportFolder(Object path);

  /// No description provided for @noCustomExportFolder.
  ///
  /// In en, this message translates to:
  /// **'No custom export folder selected.\n\nDefault Documents/Clients folder will be used.'**
  String get noCustomExportFolder;

  /// No description provided for @selectExportFolder.
  ///
  /// In en, this message translates to:
  /// **'Select export folder'**
  String get selectExportFolder;

  /// No description provided for @clearCustomPath.
  ///
  /// In en, this message translates to:
  /// **'Clear custom path'**
  String get clearCustomPath;

  /// No description provided for @debugWeightSource.
  ///
  /// In en, this message translates to:
  /// **'Debug – weight source used'**
  String get debugWeightSource;

  /// No description provided for @currentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current weight'**
  String get currentWeight;

  /// No description provided for @targetWeight.
  ///
  /// In en, this message translates to:
  /// **'Target weight'**
  String get targetWeight;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'not set'**
  String get notSet;

  /// No description provided for @weightForCalories.
  ///
  /// In en, this message translates to:
  /// **'Weight for calories'**
  String get weightForCalories;

  /// No description provided for @weightForProtein.
  ///
  /// In en, this message translates to:
  /// **'Weight for protein'**
  String get weightForProtein;

  /// No description provided for @phase.
  ///
  /// In en, this message translates to:
  /// **'Phase'**
  String get phase;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @weeksToTarget.
  ///
  /// In en, this message translates to:
  /// **'Weeks to target'**
  String get weeksToTarget;

  /// No description provided for @strategy.
  ///
  /// In en, this message translates to:
  /// **'Strategy'**
  String get strategy;

  /// No description provided for @createCoachAccount.
  ///
  /// In en, this message translates to:
  /// **'Create coach account'**
  String get createCoachAccount;

  /// No description provided for @loginToCoachCloud.
  ///
  /// In en, this message translates to:
  /// **'Sign in to coach cloud'**
  String get loginToCoachCloud;

  /// No description provided for @coachAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Each coach has their own account and private cloud storage for clients, notes and measurements.'**
  String get coachAccountDescription;

  /// No description provided for @coachLoginDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in using your e-mail and password. After login you will only see your own coach data.'**
  String get coachLoginDescription;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Create registration'**
  String get dontHaveAccount;

  /// No description provided for @addMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Add Measurements'**
  String get addMeasurements;

  /// No description provided for @measurementDate.
  ///
  /// In en, this message translates to:
  /// **'Measurement Date'**
  String get measurementDate;

  /// No description provided for @clientAndPeriod.
  ///
  /// In en, this message translates to:
  /// **'Client and period'**
  String get clientAndPeriod;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @bodyCircumferences.
  ///
  /// In en, this message translates to:
  /// **'Body circumferences'**
  String get bodyCircumferences;

  /// No description provided for @exercisePerformance.
  ///
  /// In en, this message translates to:
  /// **'Exercise performance'**
  String get exercisePerformance;

  /// No description provided for @coachSummary.
  ///
  /// In en, this message translates to:
  /// **'Coach summary'**
  String get coachSummary;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @noDataForSummary.
  ///
  /// In en, this message translates to:
  /// **'There is no data in the selected period.'**
  String get noDataForSummary;

  /// No description provided for @summaryGenerated.
  ///
  /// In en, this message translates to:
  /// **'Summary has been generated.'**
  String get summaryGenerated;

  /// No description provided for @noPerformancesInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No performances in selected period.'**
  String get noPerformancesInPeriod;

  /// No description provided for @numberOfRecords.
  ///
  /// In en, this message translates to:
  /// **'Number of records'**
  String get numberOfRecords;

  /// No description provided for @arms.
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get arms;

  /// No description provided for @chest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get chest;

  /// No description provided for @waist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get waist;

  /// No description provided for @hips.
  ///
  /// In en, this message translates to:
  /// **'Hips'**
  String get hips;

  /// No description provided for @thigh.
  ///
  /// In en, this message translates to:
  /// **'Thigh'**
  String get thigh;

  /// No description provided for @dailyEnergyExpenditure.
  ///
  /// In en, this message translates to:
  /// **'Daily energy expenditure'**
  String get dailyEnergyExpenditure;

  /// No description provided for @targetCalories.
  ///
  /// In en, this message translates to:
  /// **'Target calories'**
  String get targetCalories;

  /// No description provided for @macros.
  ///
  /// In en, this message translates to:
  /// **'Macros'**
  String get macros;

  /// No description provided for @arm.
  ///
  /// In en, this message translates to:
  /// **'Arm'**
  String get arm;

  /// No description provided for @calf.
  ///
  /// In en, this message translates to:
  /// **'Calf'**
  String get calf;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @noSavedMealPlans.
  ///
  /// In en, this message translates to:
  /// **'You do not have any saved meal plans or daily templates yet.'**
  String get noSavedMealPlans;

  /// No description provided for @dailyTemplates.
  ///
  /// In en, this message translates to:
  /// **'Daily templates'**
  String get dailyTemplates;

  /// No description provided for @noDailyTemplates.
  ///
  /// In en, this message translates to:
  /// **'You do not have any saved daily templates yet.'**
  String get noDailyTemplates;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @meals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get meals;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @coachNote.
  ///
  /// In en, this message translates to:
  /// **'Coach note'**
  String get coachNote;

  /// No description provided for @openEdit.
  ///
  /// In en, this message translates to:
  /// **'Open / Edit'**
  String get openEdit;

  /// No description provided for @completeMealPlans.
  ///
  /// In en, this message translates to:
  /// **'Complete meal plans'**
  String get completeMealPlans;

  /// No description provided for @noCompleteMealPlans.
  ///
  /// In en, this message translates to:
  /// **'You do not have any complete meal plans yet.'**
  String get noCompleteMealPlans;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @baseWeight.
  ///
  /// In en, this message translates to:
  /// **'Base weight'**
  String get baseWeight;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @useOneToOne.
  ///
  /// In en, this message translates to:
  /// **'Use 1:1'**
  String get useOneToOne;

  /// No description provided for @scaleToProfile.
  ///
  /// In en, this message translates to:
  /// **'Scale to profile'**
  String get scaleToProfile;

  /// No description provided for @deleteMealPlanQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete meal plan?'**
  String get deleteMealPlanQuestion;

  /// No description provided for @deleteDailyTemplateQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete daily template?'**
  String get deleteDailyTemplateQuestion;

  /// No description provided for @enterNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get enterNumber;

  /// No description provided for @valueCannotBeNegative.
  ///
  /// In en, this message translates to:
  /// **'Value cannot be negative'**
  String get valueCannotBeNegative;

  /// No description provided for @phaseLogicCoreTest.
  ///
  /// In en, this message translates to:
  /// **'PHASE LOGIC TEST (CORE)'**
  String get phaseLogicCoreTest;

  /// No description provided for @profileOrGoalNotSet.
  ///
  /// In en, this message translates to:
  /// **'Profile or goal is not set'**
  String get profileOrGoalNotSet;

  /// No description provided for @dataSource.
  ///
  /// In en, this message translates to:
  /// **'DATA SOURCE'**
  String get dataSource;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'GOAL'**
  String get goal;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @goalDate.
  ///
  /// In en, this message translates to:
  /// **'Goal date'**
  String get goalDate;

  /// No description provided for @weeksToGoal.
  ///
  /// In en, this message translates to:
  /// **'Weeks to goal'**
  String get weeksToGoal;

  /// No description provided for @currentEvaluation.
  ///
  /// In en, this message translates to:
  /// **'CURRENT EVALUATION'**
  String get currentEvaluation;

  /// No description provided for @currentPhase.
  ///
  /// In en, this message translates to:
  /// **'Current phase'**
  String get currentPhase;

  /// No description provided for @phaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Phase label'**
  String get phaseLabel;

  /// No description provided for @activeSegment.
  ///
  /// In en, this message translates to:
  /// **'Active segment'**
  String get activeSegment;

  /// No description provided for @foodStrategy.
  ///
  /// In en, this message translates to:
  /// **'FOOD STRATEGY'**
  String get foodStrategy;

  /// No description provided for @calorieMultiplier.
  ///
  /// In en, this message translates to:
  /// **'Calorie multiplier'**
  String get calorieMultiplier;

  /// No description provided for @highCarbs.
  ///
  /// In en, this message translates to:
  /// **'High carbs'**
  String get highCarbs;

  /// No description provided for @phasePlan.
  ///
  /// In en, this message translates to:
  /// **'PHASE PLAN'**
  String get phasePlan;

  /// No description provided for @finalMacros.
  ///
  /// In en, this message translates to:
  /// **'FINAL MACROS'**
  String get finalMacros;

  /// No description provided for @coreEngineInfo.
  ///
  /// In en, this message translates to:
  /// **'Everything is controlled by date through the Core engine.'**
  String get coreEngineInfo;

  /// No description provided for @clientId.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get clientId;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @tdee.
  ///
  /// In en, this message translates to:
  /// **'TDEE'**
  String get tdee;

  /// No description provided for @protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbs;

  /// No description provided for @fats.
  ///
  /// In en, this message translates to:
  /// **'Fats'**
  String get fats;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @howAppWorks.
  ///
  /// In en, this message translates to:
  /// **'How the app works'**
  String get howAppWorks;

  /// No description provided for @dataStorage.
  ///
  /// In en, this message translates to:
  /// **'Data storage'**
  String get dataStorage;

  /// No description provided for @clientExport.
  ///
  /// In en, this message translates to:
  /// **'Client export'**
  String get clientExport;

  /// No description provided for @clientImport.
  ///
  /// In en, this message translates to:
  /// **'Client import'**
  String get clientImport;

  /// No description provided for @factoryReset.
  ///
  /// In en, this message translates to:
  /// **'Factory reset'**
  String get factoryReset;

  /// No description provided for @importantWarning.
  ///
  /// In en, this message translates to:
  /// **'Important warning'**
  String get importantWarning;

  /// No description provided for @helpStorage1.
  ///
  /// In en, this message translates to:
  /// **'The application works offline-first. This means data is stored locally directly on the device.'**
  String get helpStorage1;

  /// No description provided for @helpStorage2.
  ///
  /// In en, this message translates to:
  /// **'Changes to clients, measurements, notes, performance and plans are not automatically sent to an external server.'**
  String get helpStorage2;

  /// No description provided for @helpStorage3.
  ///
  /// In en, this message translates to:
  /// **'If you uninstall, reset or lose the device without exporting data, you may lose saved information.'**
  String get helpStorage3;

  /// No description provided for @helpExport1.
  ///
  /// In en, this message translates to:
  /// **'Each client can be exported for backup or transfer.'**
  String get helpExport1;

  /// No description provided for @helpExport2.
  ///
  /// In en, this message translates to:
  /// **'The export contains JSON, PDF report, CSV files and a manifest.'**
  String get helpExport2;

  /// No description provided for @helpExport3.
  ///
  /// In en, this message translates to:
  /// **'It is recommended to export regularly, especially before major changes or before resetting the app.'**
  String get helpExport3;

  /// No description provided for @helpImport1.
  ///
  /// In en, this message translates to:
  /// **'Clients can be imported from JSON or from an archive folder.'**
  String get helpImport1;

  /// No description provided for @helpImport2.
  ///
  /// In en, this message translates to:
  /// **'If a client with the same ID already exists, the app creates a new safe ID to avoid conflicts.'**
  String get helpImport2;

  /// No description provided for @helpImport3.
  ///
  /// In en, this message translates to:
  /// **'After import, we recommend checking the client details and verifying that all data is correct.'**
  String get helpImport3;

  /// No description provided for @helpReset1.
  ///
  /// In en, this message translates to:
  /// **'Factory reset permanently deletes all locally stored app data.'**
  String get helpReset1;

  /// No description provided for @helpReset2.
  ///
  /// In en, this message translates to:
  /// **'Clients, notes, inbody records, circumferences, client details and internal ID counters are deleted.'**
  String get helpReset2;

  /// No description provided for @helpReset3.
  ///
  /// In en, this message translates to:
  /// **'Before resetting, always export important clients first.'**
  String get helpReset3;

  /// No description provided for @firstMeal.
  ///
  /// In en, this message translates to:
  /// **'First meal'**
  String get firstMeal;

  /// No description provided for @lastMeal.
  ///
  /// In en, this message translates to:
  /// **'Last meal'**
  String get lastMeal;

  /// No description provided for @ketoShoppingListTitle.
  ///
  /// In en, this message translates to:
  /// **'🛒 MY KETO SHOPPING LIST'**
  String get ketoShoppingListTitle;

  /// No description provided for @fastingShoppingListTitle.
  ///
  /// In en, this message translates to:
  /// **'🛒 MY FASTING SHOPPING LIST'**
  String get fastingShoppingListTitle;

  /// No description provided for @shoppingListTitle.
  ///
  /// In en, this message translates to:
  /// **'🛒 MY SHOPPING LIST'**
  String get shoppingListTitle;

  /// No description provided for @generatedBySmartCoach.
  ///
  /// In en, this message translates to:
  /// **'Generated by your smart coach 🍏'**
  String get generatedBySmartCoach;

  /// No description provided for @ketoShopping.
  ///
  /// In en, this message translates to:
  /// **'Keto Shopping'**
  String get ketoShopping;

  /// No description provided for @fastingShopping.
  ///
  /// In en, this message translates to:
  /// **'Fasting Shopping'**
  String get fastingShopping;

  /// No description provided for @weeklyShopping.
  ///
  /// In en, this message translates to:
  /// **'Weekly Shopping'**
  String get weeklyShopping;

  /// No description provided for @emptyShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping list is empty.'**
  String get emptyShoppingList;

  /// No description provided for @shoppingListDescription.
  ///
  /// In en, this message translates to:
  /// **'The list contains all ingredients from all days and automatically merges duplicates.'**
  String get shoppingListDescription;

  /// No description provided for @sameMacrosDaily.
  ///
  /// In en, this message translates to:
  /// **'The same macro structure every day.'**
  String get sameMacrosDaily;

  /// No description provided for @carbCyclingDescriptionShort.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates cycle throughout the week.'**
  String get carbCyclingDescriptionShort;

  /// No description provided for @ketoLowCarbNote.
  ///
  /// In en, this message translates to:
  /// **'Keto mode with low carbohydrate intake and full shopping list.'**
  String get ketoLowCarbNote;

  /// No description provided for @piecesEggs.
  ///
  /// In en, this message translates to:
  /// **'pcs eggs'**
  String get piecesEggs;

  /// No description provided for @pieces.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get pieces;

  /// No description provided for @lightSnack.
  ///
  /// In en, this message translates to:
  /// **'Light snack'**
  String get lightSnack;

  /// No description provided for @calculation.
  ///
  /// In en, this message translates to:
  /// **'Calculation'**
  String get calculation;

  /// No description provided for @oatmealProtein.
  ///
  /// In en, this message translates to:
  /// **'Oatmeal with protein'**
  String get oatmealProtein;

  /// No description provided for @breakfastDescription.
  ///
  /// In en, this message translates to:
  /// **'Oats, protein and fruit.'**
  String get breakfastDescription;

  /// No description provided for @goal_strength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get goal_strength;

  /// No description provided for @goal_strength_rationale.
  ///
  /// In en, this message translates to:
  /// **'Surplus + carbohydrates for CNS support, protein 2.0 g/kg.'**
  String get goal_strength_rationale;

  /// No description provided for @goal_physique.
  ///
  /// In en, this message translates to:
  /// **'Physique'**
  String get goal_physique;

  /// No description provided for @goal_physique_rationale.
  ///
  /// In en, this message translates to:
  /// **'Phase-based periodization, protein 2.2 g/kg.'**
  String get goal_physique_rationale;

  /// No description provided for @goal_weight_gain_support.
  ///
  /// In en, this message translates to:
  /// **'Weight Gain (Support)'**
  String get goal_weight_gain_support;

  /// No description provided for @goal_weight_gain_support_rationale.
  ///
  /// In en, this message translates to:
  /// **'Moderate surplus without extreme recommendations.'**
  String get goal_weight_gain_support_rationale;

  /// No description provided for @goal_weight_loss.
  ///
  /// In en, this message translates to:
  /// **'Weight Loss'**
  String get goal_weight_loss;

  /// No description provided for @goal_weight_loss_rationale.
  ///
  /// In en, this message translates to:
  /// **'Calorie deficit + high protein to preserve muscle mass.'**
  String get goal_weight_loss_rationale;

  /// No description provided for @goal_endurance.
  ///
  /// In en, this message translates to:
  /// **'Endurance'**
  String get goal_endurance;

  /// No description provided for @goal_endurance_rationale.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrate-focused nutrition, protein 1.6–1.8 g/kg.'**
  String get goal_endurance_rationale;

  /// No description provided for @phase_gaining_physique.
  ///
  /// In en, this message translates to:
  /// **'Bulking phase: moderate surplus while keeping fats controlled.'**
  String get phase_gaining_physique;

  /// No description provided for @phase_gaining_strength.
  ///
  /// In en, this message translates to:
  /// **'Strength bulking: surplus + carbohydrates for performance.'**
  String get phase_gaining_strength;

  /// No description provided for @phase_gaining_default.
  ///
  /// In en, this message translates to:
  /// **'Moderate surplus / slightly above maintenance.'**
  String get phase_gaining_default;

  /// No description provided for @phase_cutting_endurance.
  ///
  /// In en, this message translates to:
  /// **'Endurance cutting: mild reduction while maintaining carbohydrates.'**
  String get phase_cutting_endurance;

  /// No description provided for @phase_cutting_default.
  ///
  /// In en, this message translates to:
  /// **'15–20% deficit, higher protein, fats monitored carefully.'**
  String get phase_cutting_default;

  /// No description provided for @phase_peaking.
  ///
  /// In en, this message translates to:
  /// **'Peak conditioning: higher protein with controlled carbohydrates.'**
  String get phase_peaking;

  /// No description provided for @phase_maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance: stabilize performance and recovery.'**
  String get phase_maintenance;

  /// No description provided for @reason_summer_shape.
  ///
  /// In en, this message translates to:
  /// **'Summer goal: physique and visual appearance prioritized.'**
  String get reason_summer_shape;

  /// No description provided for @reason_competition.
  ///
  /// In en, this message translates to:
  /// **'Competition preparation: precise nutrition and conditioning.'**
  String get reason_competition;

  /// No description provided for @reason_support.
  ///
  /// In en, this message translates to:
  /// **'Support mode: no aggressive deficits or extreme recommendations.'**
  String get reason_support;

  /// No description provided for @accelerated_mode.
  ///
  /// In en, this message translates to:
  /// **'Accelerated mode: larger deficit with increased protein intake.'**
  String get accelerated_mode;

  /// No description provided for @competition_peaking.
  ///
  /// In en, this message translates to:
  /// **'Competition peak phase: maximum protein emphasis.'**
  String get competition_peaking;

  /// No description provided for @breakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get breakfast;

  /// No description provided for @snack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get snack;

  /// No description provided for @snack2.
  ///
  /// In en, this message translates to:
  /// **'Snack 2'**
  String get snack2;

  /// No description provided for @lunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunch;

  /// No description provided for @dinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dinner;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @copyYesterday.
  ///
  /// In en, this message translates to:
  /// **'Copy yesterday'**
  String get copyYesterday;

  /// No description provided for @resetDay.
  ///
  /// In en, this message translates to:
  /// **'Reset day'**
  String get resetDay;

  /// No description provided for @yesterdayCopied.
  ///
  /// In en, this message translates to:
  /// **'Yesterday\'s food copied'**
  String get yesterdayCopied;

  /// No description provided for @addFood.
  ///
  /// In en, this message translates to:
  /// **'Add Food'**
  String get addFood;

  /// No description provided for @remainingForToday.
  ///
  /// In en, this message translates to:
  /// **'Remaining for today'**
  String get remainingForToday;

  /// No description provided for @helpWithRemainingFood.
  ///
  /// In en, this message translates to:
  /// **'Help me with remaining food'**
  String get helpWithRemainingFood;

  /// No description provided for @recalculateRemainingDay.
  ///
  /// In en, this message translates to:
  /// **'Recalculate remaining day'**
  String get recalculateRemainingDay;

  /// No description provided for @foods.
  ///
  /// In en, this message translates to:
  /// **'Foods'**
  String get foods;

  /// No description provided for @noFoodYet.
  ///
  /// In en, this message translates to:
  /// **'There is no food yet. Add your first meal.'**
  String get noFoodYet;

  /// No description provided for @allSlotsAdded.
  ///
  /// In en, this message translates to:
  /// **'Added ✅ (all slots)'**
  String get allSlotsAdded;

  /// No description provided for @manualOverrideHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: when you edit something manually, the solver will no longer recalculate it.'**
  String get manualOverrideHint;

  /// No description provided for @noMealsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No meals available. Add more meals to the database.'**
  String get noMealsAvailable;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @exceeded.
  ///
  /// In en, this message translates to:
  /// **'Exceeded'**
  String get exceeded;

  /// No description provided for @eggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get eggs;

  /// No description provided for @eggsPieces.
  ///
  /// In en, this message translates to:
  /// **'pcs eggs'**
  String get eggsPieces;

  /// No description provided for @piecesUnit.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get piecesUnit;

  /// No description provided for @vegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get vegetables;

  /// No description provided for @oliveOil.
  ///
  /// In en, this message translates to:
  /// **'Olive oil'**
  String get oliveOil;

  /// No description provided for @scrambledEggsWithVegetables.
  ///
  /// In en, this message translates to:
  /// **'Scrambled eggs with vegetables'**
  String get scrambledEggsWithVegetables;

  /// No description provided for @andLightFatSource.
  ///
  /// In en, this message translates to:
  /// **'and a light fat source'**
  String get andLightFatSource;

  /// No description provided for @oatmealWithProtein.
  ///
  /// In en, this message translates to:
  /// **'Oatmeal with protein'**
  String get oatmealWithProtein;

  /// No description provided for @complexCarbsForDayStart.
  ///
  /// In en, this message translates to:
  /// **'Complex carbohydrates to start the day.'**
  String get complexCarbsForDayStart;

  /// No description provided for @oats.
  ///
  /// In en, this message translates to:
  /// **'Oats'**
  String get oats;

  /// No description provided for @wheyProtein.
  ///
  /// In en, this message translates to:
  /// **'Whey protein'**
  String get wheyProtein;

  /// No description provided for @blueberries.
  ///
  /// In en, this message translates to:
  /// **'Blueberries'**
  String get blueberries;

  /// No description provided for @skyrWithFruit.
  ///
  /// In en, this message translates to:
  /// **'Skyr with fruit'**
  String get skyrWithFruit;

  /// No description provided for @highProteinSnack.
  ///
  /// In en, this message translates to:
  /// **'Light snack with high protein content.'**
  String get highProteinSnack;

  /// No description provided for @hamAndCheese.
  ///
  /// In en, this message translates to:
  /// **'Ham and cheese'**
  String get hamAndCheese;

  /// No description provided for @lowCarbSnack.
  ///
  /// In en, this message translates to:
  /// **'Low-carb snack.'**
  String get lowCarbSnack;

  /// No description provided for @skyr.
  ///
  /// In en, this message translates to:
  /// **'Skyr'**
  String get skyr;

  /// No description provided for @banana.
  ///
  /// In en, this message translates to:
  /// **'Banana'**
  String get banana;

  /// No description provided for @ham.
  ///
  /// In en, this message translates to:
  /// **'Ham'**
  String get ham;

  /// No description provided for @gouda.
  ///
  /// In en, this message translates to:
  /// **'Gouda'**
  String get gouda;

  /// No description provided for @beef.
  ///
  /// In en, this message translates to:
  /// **'Beef'**
  String get beef;

  /// No description provided for @turkeyBreast.
  ///
  /// In en, this message translates to:
  /// **'Turkey breast'**
  String get turkeyBreast;

  /// No description provided for @chickenBreast.
  ///
  /// In en, this message translates to:
  /// **'Chicken breast'**
  String get chickenBreast;

  /// No description provided for @whiteRiceDry.
  ///
  /// In en, this message translates to:
  /// **'White rice (dry)'**
  String get whiteRiceDry;

  /// No description provided for @rice.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get rice;

  /// No description provided for @skyrBanana.
  ///
  /// In en, this message translates to:
  /// **'Skyr with banana'**
  String get skyrBanana;

  /// No description provided for @quickSnackDescription.
  ///
  /// In en, this message translates to:
  /// **'Quick snack for protein and carbohydrate replenishment.'**
  String get quickSnackDescription;

  /// No description provided for @noGoalMaintenanceMode.
  ///
  /// In en, this message translates to:
  /// **'No goal - maintenance mode'**
  String get noGoalMaintenanceMode;

  /// No description provided for @cutPhaseAccelerated.
  ///
  /// In en, this message translates to:
  /// **'Cutting phase (accelerated)'**
  String get cutPhaseAccelerated;

  /// No description provided for @cutPhase.
  ///
  /// In en, this message translates to:
  /// **'Cutting phase'**
  String get cutPhase;

  /// No description provided for @buildPhaseAccelerated.
  ///
  /// In en, this message translates to:
  /// **'Bulking phase (accelerated)'**
  String get buildPhaseAccelerated;

  /// No description provided for @buildPhase.
  ///
  /// In en, this message translates to:
  /// **'Bulking phase'**
  String get buildPhase;

  /// No description provided for @maintenancePhase.
  ///
  /// In en, this message translates to:
  /// **'Maintenance phase'**
  String get maintenancePhase;

  /// No description provided for @strengthPhase.
  ///
  /// In en, this message translates to:
  /// **'Strength phase'**
  String get strengthPhase;

  /// No description provided for @weightLossGoalAccelerated.
  ///
  /// In en, this message translates to:
  /// **'Weight loss goal (accelerated)'**
  String get weightLossGoalAccelerated;

  /// No description provided for @weightGainGoalAccelerated.
  ///
  /// In en, this message translates to:
  /// **'Weight gain goal (accelerated)'**
  String get weightGainGoalAccelerated;

  /// No description provided for @weightGainGoal.
  ///
  /// In en, this message translates to:
  /// **'Weight gain goal'**
  String get weightGainGoal;

  /// No description provided for @chickenRice.
  ///
  /// In en, this message translates to:
  /// **'Chicken breast with rice'**
  String get chickenRice;

  /// No description provided for @mainMealDescription.
  ///
  /// In en, this message translates to:
  /// **'Complex main meal with side dish and vegetables.'**
  String get mainMealDescription;

  /// No description provided for @helpWarning1.
  ///
  /// In en, this message translates to:
  /// **'This app currently relies on local device storage.'**
  String get helpWarning1;

  /// No description provided for @helpWarning2.
  ///
  /// In en, this message translates to:
  /// **'Without regular backups, device loss, uninstalling the app or factory reset may result in data loss.'**
  String get helpWarning2;

  /// No description provided for @helpWarning3.
  ///
  /// In en, this message translates to:
  /// **'We recommend regularly exporting your most important clients.'**
  String get helpWarning3;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @heightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCm;

  /// No description provided for @recoveryModeSupport.
  ///
  /// In en, this message translates to:
  /// **'Recovery / Eating Disorder Support'**
  String get recoveryModeSupport;

  /// No description provided for @recoveryModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Enables safety limits (no aggressive fat loss)'**
  String get recoveryModeDescription;

  /// No description provided for @saveClient.
  ///
  /// In en, this message translates to:
  /// **'Save Client'**
  String get saveClient;

  /// No description provided for @failedToSaveClient.
  ///
  /// In en, this message translates to:
  /// **'Failed to save client: {error}'**
  String failedToSaveClient(Object error);

  /// No description provided for @addInbodyMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Add InBody Measurement'**
  String get addInbodyMeasurement;

  /// No description provided for @basicData.
  ///
  /// In en, this message translates to:
  /// **'Basic Data'**
  String get basicData;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @waterPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: after entering weight and water you will also see the estimated body water percentage.'**
  String get waterPreviewHint;

  /// No description provided for @yourFastingMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Your fasting meal plan'**
  String get yourFastingMealPlan;

  /// No description provided for @skeletalMuscleMass.
  ///
  /// In en, this message translates to:
  /// **'SMM – skeletal muscle mass (kg)'**
  String get skeletalMuscleMass;

  /// No description provided for @weeklyMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Weekly meal plan'**
  String get weeklyMealPlan;

  /// No description provided for @saveTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save template'**
  String get saveTemplate;

  /// No description provided for @bodyFat.
  ///
  /// In en, this message translates to:
  /// **'Body Fat'**
  String get bodyFat;

  /// No description provided for @bodyFatDescription.
  ///
  /// In en, this message translates to:
  /// **'Fill in either kg or %. The second value will be calculated automatically.'**
  String get bodyFatDescription;

  /// No description provided for @fatKg.
  ///
  /// In en, this message translates to:
  /// **'Fat (kg)'**
  String get fatKg;

  /// No description provided for @fatPercent.
  ///
  /// In en, this message translates to:
  /// **'Fat (%)'**
  String get fatPercent;

  /// No description provided for @totalBodyWater.
  ///
  /// In en, this message translates to:
  /// **'Total Body Water (kg)'**
  String get totalBodyWater;

  /// No description provided for @optionalValues.
  ///
  /// In en, this message translates to:
  /// **'Optional (if available on printout)'**
  String get optionalValues;

  /// No description provided for @fatFreeMass.
  ///
  /// In en, this message translates to:
  /// **'Fat Free Mass (kg)'**
  String get fatFreeMass;

  /// No description provided for @waistHipRatio.
  ///
  /// In en, this message translates to:
  /// **'Waist/Hip Ratio (WHR)'**
  String get waistHipRatio;

  /// No description provided for @basalMetabolism.
  ///
  /// In en, this message translates to:
  /// **'Basal Metabolism (kcal)'**
  String get basalMetabolism;

  /// No description provided for @checkDiagnosticValues.
  ///
  /// In en, this message translates to:
  /// **'Check the values. Weight, SMM and water must be filled in. Body fat can be entered either in kg or in %.'**
  String get checkDiagnosticValues;

  /// No description provided for @addInbody.
  ///
  /// In en, this message translates to:
  /// **'Add InBody'**
  String get addInbody;

  /// No description provided for @fillAllInbodyValues.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all values according to the InBody report.'**
  String get fillAllInbodyValues;

  /// No description provided for @clientHeight.
  ///
  /// In en, this message translates to:
  /// **'Client Height'**
  String get clientHeight;

  /// No description provided for @bodyComposition.
  ///
  /// In en, this message translates to:
  /// **'Body Composition'**
  String get bodyComposition;

  /// No description provided for @muscleMass.
  ///
  /// In en, this message translates to:
  /// **'SMM – Muscle Mass (kg)'**
  String get muscleMass;

  /// No description provided for @bodyFatMass.
  ///
  /// In en, this message translates to:
  /// **'Body Fat Mass (kg)'**
  String get bodyFatMass;

  /// No description provided for @bodyWater.
  ///
  /// In en, this message translates to:
  /// **'Total Body Water (kg/l)'**
  String get bodyWater;

  /// No description provided for @leanBodyMass.
  ///
  /// In en, this message translates to:
  /// **'Lean Body Mass (kg)'**
  String get leanBodyMass;

  /// No description provided for @obesityDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Obesity Diagnosis'**
  String get obesityDiagnosis;

  /// No description provided for @bodyFatPercentage.
  ///
  /// In en, this message translates to:
  /// **'Body Fat Percentage'**
  String get bodyFatPercentage;

  /// No description provided for @segmentalMuscles.
  ///
  /// In en, this message translates to:
  /// **'Segmental Muscles (kg)'**
  String get segmentalMuscles;

  /// No description provided for @leftArmMuscle.
  ///
  /// In en, this message translates to:
  /// **'Left Arm – Muscle (kg)'**
  String get leftArmMuscle;

  /// No description provided for @rightArmMuscle.
  ///
  /// In en, this message translates to:
  /// **'Right Arm – Muscle (kg)'**
  String get rightArmMuscle;

  /// No description provided for @trunkMuscle.
  ///
  /// In en, this message translates to:
  /// **'Trunk – Muscle (kg)'**
  String get trunkMuscle;

  /// No description provided for @leftLegMuscle.
  ///
  /// In en, this message translates to:
  /// **'Left Leg – Muscle (kg)'**
  String get leftLegMuscle;

  /// No description provided for @rightLegMuscle.
  ///
  /// In en, this message translates to:
  /// **'Right Leg – Muscle (kg)'**
  String get rightLegMuscle;

  /// No description provided for @segmentalFat.
  ///
  /// In en, this message translates to:
  /// **'Segmental Fat (kg)'**
  String get segmentalFat;

  /// No description provided for @leftArmFat.
  ///
  /// In en, this message translates to:
  /// **'Left Arm – Fat (kg)'**
  String get leftArmFat;

  /// No description provided for @rightArmFat.
  ///
  /// In en, this message translates to:
  /// **'Right Arm – Fat (kg)'**
  String get rightArmFat;

  /// No description provided for @trunkFat.
  ///
  /// In en, this message translates to:
  /// **'Trunk – Fat (kg)'**
  String get trunkFat;

  /// No description provided for @leftLegFat.
  ///
  /// In en, this message translates to:
  /// **'Left Leg – Fat (kg)'**
  String get leftLegFat;

  /// No description provided for @rightLegFat.
  ///
  /// In en, this message translates to:
  /// **'Right Leg – Fat (kg)'**
  String get rightLegFat;

  /// No description provided for @visceralFat.
  ///
  /// In en, this message translates to:
  /// **'Visceral Fat (Level)'**
  String get visceralFat;

  /// No description provided for @inbodyScore.
  ///
  /// In en, this message translates to:
  /// **'InBody Score'**
  String get inbodyScore;

  /// No description provided for @saveInbody.
  ///
  /// In en, this message translates to:
  /// **'Save InBody'**
  String get saveInbody;

  /// No description provided for @importRestoreClient.
  ///
  /// In en, this message translates to:
  /// **'Import / Restore Client'**
  String get importRestoreClient;

  /// No description provided for @chooseHowToRestoreOrImportClient.
  ///
  /// In en, this message translates to:
  /// **'Choose how to restore or import the client.'**
  String get chooseHowToRestoreOrImportClient;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @insertJsonManually.
  ///
  /// In en, this message translates to:
  /// **'Insert JSON manually'**
  String get insertJsonManually;

  /// No description provided for @selectJsonFile.
  ///
  /// In en, this message translates to:
  /// **'Select JSON file'**
  String get selectJsonFile;

  /// No description provided for @restoreFromArchiveFolder.
  ///
  /// In en, this message translates to:
  /// **'Restore from archive folder'**
  String get restoreFromArchiveFolder;

  /// No description provided for @selectJson.
  ///
  /// In en, this message translates to:
  /// **'Select JSON'**
  String get selectJson;

  /// No description provided for @clientImportedFromFile.
  ///
  /// In en, this message translates to:
  /// **'Client imported from file'**
  String get clientImportedFromFile;

  /// No description provided for @fileImportFailed.
  ///
  /// In en, this message translates to:
  /// **'File import failed'**
  String get fileImportFailed;

  /// No description provided for @selectArchiveFolder.
  ///
  /// In en, this message translates to:
  /// **'Select archive folder'**
  String get selectArchiveFolder;

  /// No description provided for @clientRestoredFromArchive.
  ///
  /// In en, this message translates to:
  /// **'Client restored from archive'**
  String get clientRestoredFromArchive;

  /// No description provided for @archiveRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Archive restore failed'**
  String get archiveRestoreFailed;

  /// No description provided for @exportFolderNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Export folder is not configured'**
  String get exportFolderNotConfigured;

  /// No description provided for @folderOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open folder'**
  String get folderOpenFailed;

  /// No description provided for @archiveAndDeleteClient.
  ///
  /// In en, this message translates to:
  /// **'Archive and delete client'**
  String get archiveAndDeleteClient;

  /// No description provided for @deleteClient.
  ///
  /// In en, this message translates to:
  /// **'Delete client'**
  String get deleteClient;

  /// No description provided for @archiveAndDeleteClientConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to archive and delete this client?'**
  String get archiveAndDeleteClientConfirm;

  /// No description provided for @deleteClientConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this client?'**
  String get deleteClientConfirm;

  /// No description provided for @archiveAndDelete.
  ///
  /// In en, this message translates to:
  /// **'Archive & Delete'**
  String get archiveAndDelete;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @clientArchivedAndDeleted.
  ///
  /// In en, this message translates to:
  /// **'Client archived and deleted'**
  String get clientArchivedAndDeleted;

  /// No description provided for @clientDeleted.
  ///
  /// In en, this message translates to:
  /// **'Client deleted'**
  String get clientDeleted;

  /// No description provided for @clientDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete client'**
  String get clientDeleteError;

  /// No description provided for @clientAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Client analysis'**
  String get clientAnalysis;

  /// No description provided for @openExportFolder.
  ///
  /// In en, this message translates to:
  /// **'Open export folder'**
  String get openExportFolder;

  /// No description provided for @exportClient.
  ///
  /// In en, this message translates to:
  /// **'Export client'**
  String get exportClient;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportError;

  /// No description provided for @editClient.
  ///
  /// In en, this message translates to:
  /// **'Edit client'**
  String get editClient;

  /// No description provided for @editClientCard.
  ///
  /// In en, this message translates to:
  /// **'Edit client card'**
  String get editClientCard;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @copyEmail.
  ///
  /// In en, this message translates to:
  /// **'Copy e-mail'**
  String get copyEmail;

  /// No description provided for @emailCopied.
  ///
  /// In en, this message translates to:
  /// **'E-mail copied'**
  String get emailCopied;

  /// No description provided for @registered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get registered;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @lastWorkout.
  ///
  /// In en, this message translates to:
  /// **'Last workout'**
  String get lastWorkout;

  /// No description provided for @completedLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Completed in last 7 days'**
  String get completedLast7Days;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @compliance7Days.
  ///
  /// In en, this message translates to:
  /// **'7-day compliance'**
  String get compliance7Days;

  /// No description provided for @recoveryMode.
  ///
  /// In en, this message translates to:
  /// **'Recovery mode active'**
  String get recoveryMode;

  /// No description provided for @clientInactive7Days.
  ///
  /// In en, this message translates to:
  /// **'Client inactive for more than 7 days'**
  String get clientInactive7Days;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @completedToday.
  ///
  /// In en, this message translates to:
  /// **'Workout completed today'**
  String get completedToday;

  /// No description provided for @todayWorkoutSaved.
  ///
  /// In en, this message translates to:
  /// **'Today\'s workout saved'**
  String get todayWorkoutSaved;

  /// No description provided for @tapToSaveTodayWorkout.
  ///
  /// In en, this message translates to:
  /// **'Tap to save today\'s workout'**
  String get tapToSaveTodayWorkout;

  /// No description provided for @statusCheck.
  ///
  /// In en, this message translates to:
  /// **'Status check'**
  String get statusCheck;

  /// No description provided for @sentComparisonPhotos.
  ///
  /// In en, this message translates to:
  /// **'Sent comparison photos'**
  String get sentComparisonPhotos;

  /// No description provided for @followsDiet.
  ///
  /// In en, this message translates to:
  /// **'Follows diet'**
  String get followsDiet;

  /// No description provided for @respondedToMessage.
  ///
  /// In en, this message translates to:
  /// **'Responded to message'**
  String get respondedToMessage;

  /// No description provided for @photoRequestPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Photo reminder placeholder'**
  String get photoRequestPlaceholder;

  /// No description provided for @dietCheckPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Diet check placeholder'**
  String get dietCheckPlaceholder;

  /// No description provided for @responseRequestPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Response reminder placeholder'**
  String get responseRequestPlaceholder;

  /// No description provided for @clientTrainingPlans.
  ///
  /// In en, this message translates to:
  /// **'Client training plans'**
  String get clientTrainingPlans;

  /// No description provided for @clientHasNoPlans.
  ///
  /// In en, this message translates to:
  /// **'Client has no plans'**
  String get clientHasNoPlans;

  /// No description provided for @planCount.
  ///
  /// In en, this message translates to:
  /// **'Plan count'**
  String get planCount;

  /// No description provided for @newPlan.
  ///
  /// In en, this message translates to:
  /// **'New plan'**
  String get newPlan;

  /// No description provided for @createFirstPlanHint.
  ///
  /// In en, this message translates to:
  /// **'Create the first training plan'**
  String get createFirstPlanHint;

  /// No description provided for @coachData.
  ///
  /// In en, this message translates to:
  /// **'Coach data'**
  String get coachData;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @injuries.
  ///
  /// In en, this message translates to:
  /// **'Injuries'**
  String get injuries;

  /// No description provided for @allergiesIntolerances.
  ///
  /// In en, this message translates to:
  /// **'Allergies / intolerances'**
  String get allergiesIntolerances;

  /// No description provided for @inbody.
  ///
  /// In en, this message translates to:
  /// **'InBody'**
  String get inbody;

  /// No description provided for @dataHiddenRecoveryMode.
  ///
  /// In en, this message translates to:
  /// **'Data hidden in recovery mode'**
  String get dataHiddenRecoveryMode;

  /// No description provided for @noMeasurements.
  ///
  /// In en, this message translates to:
  /// **'No measurements'**
  String get noMeasurements;

  /// No description provided for @proteinShort.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get proteinShort;

  /// No description provided for @carbsShort.
  ///
  /// In en, this message translates to:
  /// **'C'**
  String get carbsShort;

  /// No description provided for @fatShort.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get fatShort;

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// No description provided for @shoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get shoppingList;

  /// No description provided for @shoppingListEmpty.
  ///
  /// In en, this message translates to:
  /// **'Shopping list is empty.'**
  String get shoppingListEmpty;

  /// No description provided for @trainerRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Trainer Recommendation'**
  String get trainerRecommendation;

  /// No description provided for @followPlanFor4Weeks.
  ///
  /// In en, this message translates to:
  /// **'Follow the plan for 4 weeks.'**
  String get followPlanFor4Weeks;

  /// No description provided for @nextCheckAndWeight.
  ///
  /// In en, this message translates to:
  /// **'Next check and weighing in 1 month'**
  String get nextCheckAndWeight;

  /// No description provided for @ketoMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Keto Meal Plan'**
  String get ketoMealPlan;

  /// No description provided for @fastingMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Fasting Meal Plan'**
  String get fastingMealPlan;

  /// No description provided for @linearMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Linear Meal Plan'**
  String get linearMealPlan;

  /// No description provided for @mealPlan.
  ///
  /// In en, this message translates to:
  /// **'Meal Plan'**
  String get mealPlan;

  /// No description provided for @muscles.
  ///
  /// In en, this message translates to:
  /// **'Muscles'**
  String get muscles;

  /// No description provided for @automaticInterpretation.
  ///
  /// In en, this message translates to:
  /// **'Automatic interpretation'**
  String get automaticInterpretation;

  /// No description provided for @changeFromLastTime.
  ///
  /// In en, this message translates to:
  /// **'Change since last measurement'**
  String get changeFromLastTime;

  /// No description provided for @hiddenRecoveryMode.
  ///
  /// In en, this message translates to:
  /// **'Hidden in recovery mode'**
  String get hiddenRecoveryMode;

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get noRecords;

  /// No description provided for @addCircumferences.
  ///
  /// In en, this message translates to:
  /// **'Add circumferences'**
  String get addCircumferences;

  /// No description provided for @coachNotes.
  ///
  /// In en, this message translates to:
  /// **'Coach notes'**
  String get coachNotes;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @dayCount.
  ///
  /// In en, this message translates to:
  /// **'Day count'**
  String get dayCount;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @setAsActive.
  ///
  /// In en, this message translates to:
  /// **'Set as active'**
  String get setAsActive;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @newTrainingPlan.
  ///
  /// In en, this message translates to:
  /// **'New training plan'**
  String get newTrainingPlan;

  /// No description provided for @planName.
  ///
  /// In en, this message translates to:
  /// **'Plan name'**
  String get planName;

  /// No description provided for @planNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Push Pull Legs'**
  String get planNameHint;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @renamePlan.
  ///
  /// In en, this message translates to:
  /// **'Rename plan'**
  String get renamePlan;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get newNote;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editNote;

  /// No description provided for @importClientFromJson.
  ///
  /// In en, this message translates to:
  /// **'Import client from JSON'**
  String get importClientFromJson;

  /// No description provided for @pasteExportedJson.
  ///
  /// In en, this message translates to:
  /// **'Paste exported JSON'**
  String get pasteExportedJson;

  /// No description provided for @importLabel.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importLabel;

  /// No description provided for @clientImportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Client imported successfully'**
  String get clientImportedSuccessfully;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// No description provided for @checkRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Check required fields'**
  String get checkRequiredFields;

  /// No description provided for @recoverySupport.
  ///
  /// In en, this message translates to:
  /// **'Recovery support'**
  String get recoverySupport;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. client@email.com'**
  String get emailHint;

  /// No description provided for @clientBasicInfoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Client basic information updated'**
  String get clientBasicInfoUpdated;

  /// No description provided for @noClientsWithEmail.
  ///
  /// In en, this message translates to:
  /// **'No client has an email filled in yet.'**
  String get noClientsWithEmail;

  /// No description provided for @emailsCopied.
  ///
  /// In en, this message translates to:
  /// **'Emails have been copied to clipboard.'**
  String get emailsCopied;

  /// No description provided for @pdfExportOpened.
  ///
  /// In en, this message translates to:
  /// **'PDF export was opened for printing / saving.'**
  String get pdfExportOpened;

  /// No description provided for @importPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview Before Import'**
  String get importPreview;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @noInbodyDataInPeriod.
  ///
  /// In en, this message translates to:
  /// **'There is no InBody data in this period.'**
  String get noInbodyDataInPeriod;

  /// No description provided for @inbodyBodyComposition.
  ///
  /// In en, this message translates to:
  /// **'InBody / Body Composition'**
  String get inbodyBodyComposition;

  /// No description provided for @noCircumferencesInPeriod.
  ///
  /// In en, this message translates to:
  /// **'There are no circumferences in this period.'**
  String get noCircumferencesInPeriod;

  /// No description provided for @noCircumferenceMeasurementsYet.
  ///
  /// In en, this message translates to:
  /// **'There are no circumference measurements yet.'**
  String get noCircumferenceMeasurementsYet;

  /// No description provided for @failedToSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Failed to save changes'**
  String get failedToSaveChanges;

  /// No description provided for @editBasicInformation.
  ///
  /// In en, this message translates to:
  /// **'Edit Basic Information'**
  String get editBasicInformation;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @archiveCompleted.
  ///
  /// In en, this message translates to:
  /// **'Archive completed'**
  String get archiveCompleted;

  /// No description provided for @clientArchiveSuccessfullyCreated.
  ///
  /// In en, this message translates to:
  /// **'Client archive has been successfully created.'**
  String get clientArchiveSuccessfullyCreated;

  /// No description provided for @destinationFolder.
  ///
  /// In en, this message translates to:
  /// **'Destination folder'**
  String get destinationFolder;

  /// No description provided for @createdFiles.
  ///
  /// In en, this message translates to:
  /// **'Created files'**
  String get createdFiles;

  /// No description provided for @currentJson.
  ///
  /// In en, this message translates to:
  /// **'Current JSON'**
  String get currentJson;

  /// No description provided for @snapshot.
  ///
  /// In en, this message translates to:
  /// **'Snapshot'**
  String get snapshot;

  /// No description provided for @pdfReport.
  ///
  /// In en, this message translates to:
  /// **'PDF report'**
  String get pdfReport;

  /// No description provided for @manifest.
  ///
  /// In en, this message translates to:
  /// **'Manifest'**
  String get manifest;

  /// No description provided for @inbodyCsv.
  ///
  /// In en, this message translates to:
  /// **'InBody CSV'**
  String get inbodyCsv;

  /// No description provided for @circumferenceCsv.
  ///
  /// In en, this message translates to:
  /// **'Circumference CSV'**
  String get circumferenceCsv;

  /// No description provided for @performancesCsv.
  ///
  /// In en, this message translates to:
  /// **'Performances CSV'**
  String get performancesCsv;

  /// No description provided for @reportPeriod.
  ///
  /// In en, this message translates to:
  /// **'Report period'**
  String get reportPeriod;

  /// No description provided for @openPdf.
  ///
  /// In en, this message translates to:
  /// **'Open PDF'**
  String get openPdf;

  /// No description provided for @failedToOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Failed to open folder'**
  String get failedToOpenFolder;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get openFolder;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @circumferences.
  ///
  /// In en, this message translates to:
  /// **'Circumferences'**
  String get circumferences;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @archiveHasNoClients.
  ///
  /// In en, this message translates to:
  /// **'The archive does not contain any clients yet.'**
  String get archiveHasNoClients;

  /// No description provided for @noActiveClientsYet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any active clients yet.'**
  String get noActiveClientsYet;

  /// No description provided for @archiveCsvImport.
  ///
  /// In en, this message translates to:
  /// **'CSV Archive Import'**
  String get archiveCsvImport;

  /// No description provided for @copyEmails.
  ///
  /// In en, this message translates to:
  /// **'Copy emails'**
  String get copyEmails;

  /// No description provided for @searchByNameEmailOrId.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email or ID'**
  String get searchByNameEmailOrId;

  /// No description provided for @fileImportFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'File import failed: {error}'**
  String fileImportFailedWithError(Object error);

  /// No description provided for @clientImported.
  ///
  /// In en, this message translates to:
  /// **'{name} imported successfully.'**
  String clientImported(Object name);

  /// No description provided for @clientRestored.
  ///
  /// In en, this message translates to:
  /// **'{name} restored successfully.'**
  String clientRestored(Object name);

  /// No description provided for @clientMovedToArchive.
  ///
  /// In en, this message translates to:
  /// **'{name} moved to archive.'**
  String clientMovedToArchive(Object name);

  /// No description provided for @archiveCsvImportFailed.
  ///
  /// In en, this message translates to:
  /// **'CSV archive import failed: {error}'**
  String archiveCsvImportFailed(Object error);

  /// No description provided for @selectCsv.
  ///
  /// In en, this message translates to:
  /// **'Select CSV'**
  String get selectCsv;

  /// No description provided for @noArchivedClientsImported.
  ///
  /// In en, this message translates to:
  /// **'No new archived clients were imported from CSV.'**
  String get noArchivedClientsImported;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @linkWithCoach.
  ///
  /// In en, this message translates to:
  /// **'Link with coach'**
  String get linkWithCoach;

  /// No description provided for @searchClientByName.
  ///
  /// In en, this message translates to:
  /// **'Search your client by name'**
  String get searchClientByName;

  /// No description provided for @startTypingName.
  ///
  /// In en, this message translates to:
  /// **'Start typing the name…'**
  String get startTypingName;

  /// No description provided for @continueWithoutCoach.
  ///
  /// In en, this message translates to:
  /// **'Continue without coach'**
  String get continueWithoutCoach;

  /// No description provided for @linkAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Link and continue'**
  String get linkAndContinue;

  /// No description provided for @loadingClientsError.
  ///
  /// In en, this message translates to:
  /// **'Error while loading clients'**
  String get loadingClientsError;

  /// No description provided for @archivedClientsImported.
  ///
  /// In en, this message translates to:
  /// **'{count} archived clients imported.'**
  String archivedClientsImported(int count);

  /// No description provided for @strengthGoal.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get strengthGoal;

  /// No description provided for @physiqueGoal.
  ///
  /// In en, this message translates to:
  /// **'Physique'**
  String get physiqueGoal;

  /// No description provided for @weightLossGoal.
  ///
  /// In en, this message translates to:
  /// **'Weight Loss'**
  String get weightLossGoal;

  /// No description provided for @enduranceGoal.
  ///
  /// In en, this message translates to:
  /// **'Endurance'**
  String get enduranceGoal;

  /// No description provided for @weightGainSupportGoal.
  ///
  /// In en, this message translates to:
  /// **'Weight Gain / Recovery Support'**
  String get weightGainSupportGoal;

  /// No description provided for @selectFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Folder'**
  String get selectFolder;

  /// No description provided for @cloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup'**
  String get cloudBackup;

  /// No description provided for @cloudBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Manually uploads or downloads data between devices.'**
  String get cloudBackupDescription;

  /// No description provided for @backupToCloud.
  ///
  /// In en, this message translates to:
  /// **'Backup to Cloud'**
  String get backupToCloud;

  /// No description provided for @restoreFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Restore from Cloud'**
  String get restoreFromCloud;

  /// No description provided for @cloudBackupFinished.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup completed. Uploaded sections'**
  String get cloudBackupFinished;

  /// No description provided for @cloudBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup failed'**
  String get cloudBackupFailed;

  /// No description provided for @cloudRestoreFinished.
  ///
  /// In en, this message translates to:
  /// **'Cloud restore completed. Loaded sections'**
  String get cloudRestoreFinished;

  /// No description provided for @cloudRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Cloud restore failed'**
  String get cloudRestoreFailed;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @loadingProfileFromCoach.
  ///
  /// In en, this message translates to:
  /// **'Loading profile from coach…'**
  String get loadingProfileFromCoach;

  /// No description provided for @doYouHaveCoach.
  ///
  /// In en, this message translates to:
  /// **'Do you have a coach?'**
  String get doYouHaveCoach;

  /// No description provided for @searchInCoachClients.
  ///
  /// In en, this message translates to:
  /// **'Find yourself in the client list and we will automatically load your profile.'**
  String get searchInCoachClients;

  /// No description provided for @searchClientPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type client name or ID…'**
  String get searchClientPlaceholder;

  /// No description provided for @showMyDietPlan.
  ///
  /// In en, this message translates to:
  /// **'Show my diet plan'**
  String get showMyDietPlan;

  /// No description provided for @enterValidAge.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid age (10–100 years)'**
  String get enterValidAge;

  /// No description provided for @startWithBasics.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Start With Basics'**
  String get startWithBasics;

  /// No description provided for @howOldAreYou.
  ///
  /// In en, this message translates to:
  /// **'How old are you?'**
  String get howOldAreYou;

  /// No description provided for @enterAge.
  ///
  /// In en, this message translates to:
  /// **'Enter age'**
  String get enterAge;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @bodyMetrics.
  ///
  /// In en, this message translates to:
  /// **'Body Metrics'**
  String get bodyMetrics;

  /// No description provided for @enterValidHeight.
  ///
  /// In en, this message translates to:
  /// **'Enter valid height (120–230 cm)'**
  String get enterValidHeight;

  /// No description provided for @enterValidWeightRange.
  ///
  /// In en, this message translates to:
  /// **'Enter valid weight (30–300 kg)'**
  String get enterValidWeightRange;

  /// No description provided for @heightExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 180'**
  String get heightExample;

  /// No description provided for @weightExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 85'**
  String get weightExample;

  /// No description provided for @welcomeCoachApp.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the coach application'**
  String get welcomeCoachApp;

  /// No description provided for @coachSetupDesktopDescription.
  ///
  /// In en, this message translates to:
  /// **'Now we will set up your name, security PIN and most importantly the folder where client archives will be stored.'**
  String get coachSetupDesktopDescription;

  /// No description provided for @securityPin.
  ///
  /// In en, this message translates to:
  /// **'Security PIN'**
  String get securityPin;

  /// No description provided for @enterPinAgain.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN again'**
  String get enterPinAgain;

  /// No description provided for @selectClientArchiveFolder.
  ///
  /// In en, this message translates to:
  /// **'Select a folder for client archives'**
  String get selectClientArchiveFolder;

  /// No description provided for @selectCustomFolder.
  ///
  /// In en, this message translates to:
  /// **'Select custom folder'**
  String get selectCustomFolder;

  /// No description provided for @useDocumentsClients.
  ///
  /// In en, this message translates to:
  /// **'Use Documents/Clients'**
  String get useDocumentsClients;

  /// No description provided for @iosFolderInfo.
  ///
  /// In en, this message translates to:
  /// **'On iPhone, Apple does not allow selecting arbitrary folders like on desktop computers. Archives will therefore be stored in the internal Clients folder of the application.'**
  String get iosFolderInfo;

  /// No description provided for @desktopFolderRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommendation: choose your own archive folder, ideally inside a Google Drive or OneDrive synchronized folder. This way your client archives will also be available outside this computer.'**
  String get desktopFolderRecommendation;

  /// No description provided for @finishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish setup'**
  String get finishSetup;

  /// No description provided for @coachSetupSaved.
  ///
  /// In en, this message translates to:
  /// **'Coach setup has been saved.'**
  String get coachSetupSaved;

  /// No description provided for @coachSetup.
  ///
  /// In en, this message translates to:
  /// **'Coach Setup'**
  String get coachSetup;

  /// No description provided for @loggedAccount.
  ///
  /// In en, this message translates to:
  /// **'Signed in account'**
  String get loggedAccount;

  /// No description provided for @firstNameExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. John'**
  String get firstNameExample;

  /// No description provided for @enter4DigitPin.
  ///
  /// In en, this message translates to:
  /// **'Enter 4 digits'**
  String get enter4DigitPin;

  /// No description provided for @exportClientFolder.
  ///
  /// In en, this message translates to:
  /// **'Client export folder'**
  String get exportClientFolder;

  /// No description provided for @useAppFolder.
  ///
  /// In en, this message translates to:
  /// **'Use app folder'**
  String get useAppFolder;

  /// No description provided for @useClientsFolder.
  ///
  /// In en, this message translates to:
  /// **'Use Clients folder'**
  String get useClientsFolder;

  /// No description provided for @enterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name.'**
  String get enterFirstName;

  /// No description provided for @firstNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'First name is too short.'**
  String get firstNameTooShort;

  /// No description provided for @enterSecurityPin.
  ///
  /// In en, this message translates to:
  /// **'Enter a 4-digit security PIN.'**
  String get enterSecurityPin;

  /// No description provided for @pinMustHave4Digits.
  ///
  /// In en, this message translates to:
  /// **'PIN must contain exactly 4 digits.'**
  String get pinMustHave4Digits;

  /// No description provided for @confirmSecurityPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm the security PIN.'**
  String get confirmSecurityPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @coachSetupIosDescription.
  ///
  /// In en, this message translates to:
  /// **'Now we will set up your name, security PIN and internal Clients folder for client archives.'**
  String get coachSetupIosDescription;

  /// No description provided for @nextTimeWeight.
  ///
  /// In en, this message translates to:
  /// **'➡️ Next time use {weight} kg ({delta})'**
  String nextTimeWeight(Object weight, Object delta);

  /// No description provided for @dietPlanSelection.
  ///
  /// In en, this message translates to:
  /// **'Diet Plan Selection'**
  String get dietPlanSelection;

  /// No description provided for @savedMealPlans.
  ///
  /// In en, this message translates to:
  /// **'Saved Meal Plans'**
  String get savedMealPlans;

  /// No description provided for @savedMealPlansDescription.
  ///
  /// In en, this message translates to:
  /// **'Load your own complete weekly or monthly templates and reuse them anytime.'**
  String get savedMealPlansDescription;

  /// No description provided for @openMealDatabase.
  ///
  /// In en, this message translates to:
  /// **'OPEN MEAL PLAN DATABASE'**
  String get openMealDatabase;

  /// No description provided for @createCustomMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Meal Plan'**
  String get createCustomMealPlan;

  /// No description provided for @createCustomMealPlanDescription.
  ///
  /// In en, this message translates to:
  /// **'Manually build a daily meal plan from prepared meals and save it as your own template.'**
  String get createCustomMealPlanDescription;

  /// No description provided for @openDailyEditor.
  ///
  /// In en, this message translates to:
  /// **'OPEN DAILY EDITOR'**
  String get openDailyEditor;

  /// No description provided for @foodComboLibrary.
  ///
  /// In en, this message translates to:
  /// **'Food Combo Library'**
  String get foodComboLibrary;

  /// No description provided for @foodComboLibraryDescription.
  ///
  /// In en, this message translates to:
  /// **'Browse, duplicate, edit and delete your saved food combos.'**
  String get foodComboLibraryDescription;

  /// No description provided for @openFoodComboLibrary.
  ///
  /// In en, this message translates to:
  /// **'OPEN FOOD COMBO LIBRARY'**
  String get openFoodComboLibrary;

  /// No description provided for @createFoodCombo.
  ///
  /// In en, this message translates to:
  /// **'Create Food Combo'**
  String get createFoodCombo;

  /// No description provided for @createFoodComboDescription.
  ///
  /// In en, this message translates to:
  /// **'Build your own meal from individual foods and save it into the combo library.'**
  String get createFoodComboDescription;

  /// No description provided for @openFoodComboEditor.
  ///
  /// In en, this message translates to:
  /// **'OPEN FOOD COMBO EDITOR'**
  String get openFoodComboEditor;

  /// No description provided for @weekBuilder.
  ///
  /// In en, this message translates to:
  /// **'Build Week From Daily Templates'**
  String get weekBuilder;

  /// No description provided for @weekBuilderDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a daily template for each day and create a complete weekly meal plan.'**
  String get weekBuilderDescription;

  /// No description provided for @openWeeklyBuilder.
  ///
  /// In en, this message translates to:
  /// **'OPEN WEEKLY BUILDER'**
  String get openWeeklyBuilder;

  /// No description provided for @monthBuilder.
  ///
  /// In en, this message translates to:
  /// **'Build Month From Weeks'**
  String get monthBuilder;

  /// No description provided for @monthBuilderDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose 4 saved weekly meal plans and combine them into a complete monthly plan.'**
  String get monthBuilderDescription;

  /// No description provided for @openMonthlyBuilder.
  ///
  /// In en, this message translates to:
  /// **'OPEN MONTHLY BUILDER'**
  String get openMonthlyBuilder;

  /// No description provided for @linearPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Constant Intake (Linear)'**
  String get linearPlanTitle;

  /// No description provided for @linearPlanDescription.
  ///
  /// In en, this message translates to:
  /// **'Same macros every day. The easiest path for stable muscle growth.'**
  String get linearPlanDescription;

  /// No description provided for @activateAndOpenPlan.
  ///
  /// In en, this message translates to:
  /// **'ACTIVATE AND OPEN PLAN'**
  String get activateAndOpenPlan;

  /// No description provided for @carbCyclingTitle.
  ///
  /// In en, this message translates to:
  /// **'Carb Cycling'**
  String get carbCyclingTitle;

  /// No description provided for @carbCyclingDescription.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrate cycling for fat loss.'**
  String get carbCyclingDescription;

  /// No description provided for @startAnalysisAndCycling.
  ///
  /// In en, this message translates to:
  /// **'START ANALYSIS AND CYCLING'**
  String get startAnalysisAndCycling;

  /// No description provided for @ketoDietTitle.
  ///
  /// In en, this message translates to:
  /// **'Keto Diet'**
  String get ketoDietTitle;

  /// No description provided for @ketoDietDescription.
  ///
  /// In en, this message translates to:
  /// **'High fat intake with minimal carbohydrates.'**
  String get ketoDietDescription;

  /// No description provided for @selectKetoAndPreferences.
  ///
  /// In en, this message translates to:
  /// **'SELECT KETO AND ADJUST PREFERENCES'**
  String get selectKetoAndPreferences;

  /// No description provided for @fastingTitle.
  ///
  /// In en, this message translates to:
  /// **'Intermittent Fasting'**
  String get fastingTitle;

  /// No description provided for @fastingDescription.
  ///
  /// In en, this message translates to:
  /// **'Time-restricted eating window. Helps improve recovery.'**
  String get fastingDescription;

  /// No description provided for @setMealTimes.
  ///
  /// In en, this message translates to:
  /// **'SET MEAL TIMES'**
  String get setMealTimes;

  /// No description provided for @enterMealPlan.
  ///
  /// In en, this message translates to:
  /// **'ENTER MEAL PLAN'**
  String get enterMealPlan;

  /// No description provided for @mainSquatExercise.
  ///
  /// In en, this message translates to:
  /// **'Main squat exercise'**
  String get mainSquatExercise;

  /// No description provided for @mainPressExercise.
  ///
  /// In en, this message translates to:
  /// **'Main press exercise'**
  String get mainPressExercise;

  /// No description provided for @mainHingeExercise.
  ///
  /// In en, this message translates to:
  /// **'Main hinge exercise'**
  String get mainHingeExercise;

  /// No description provided for @chestPress.
  ///
  /// In en, this message translates to:
  /// **'Chest press'**
  String get chestPress;

  /// No description provided for @verticalPull.
  ///
  /// In en, this message translates to:
  /// **'Vertical pull'**
  String get verticalPull;

  /// No description provided for @horizontalPull.
  ///
  /// In en, this message translates to:
  /// **'Horizontal pull'**
  String get horizontalPull;

  /// No description provided for @quads.
  ///
  /// In en, this message translates to:
  /// **'Quadriceps'**
  String get quads;

  /// No description provided for @hamstrings.
  ///
  /// In en, this message translates to:
  /// **'Hamstrings'**
  String get hamstrings;

  /// No description provided for @glutes.
  ///
  /// In en, this message translates to:
  /// **'Glutes'**
  String get glutes;

  /// No description provided for @shoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get shoulders;

  /// No description provided for @triceps.
  ///
  /// In en, this message translates to:
  /// **'Triceps'**
  String get triceps;

  /// No description provided for @core.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get core;

  /// No description provided for @conditioning.
  ///
  /// In en, this message translates to:
  /// **'Conditioning'**
  String get conditioning;

  /// No description provided for @squatPattern.
  ///
  /// In en, this message translates to:
  /// **'Squat pattern'**
  String get squatPattern;

  /// No description provided for @hingePattern.
  ///
  /// In en, this message translates to:
  /// **'Hip hinge pattern'**
  String get hingePattern;

  /// No description provided for @pressPattern.
  ///
  /// In en, this message translates to:
  /// **'Press pattern'**
  String get pressPattern;

  /// No description provided for @verticalPullPattern.
  ///
  /// In en, this message translates to:
  /// **'Vertical pull'**
  String get verticalPullPattern;

  /// No description provided for @horizontalRowPattern.
  ///
  /// In en, this message translates to:
  /// **'Horizontal row'**
  String get horizontalRowPattern;

  /// No description provided for @corePattern.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get corePattern;

  /// No description provided for @locomotionPattern.
  ///
  /// In en, this message translates to:
  /// **'Locomotion / conditioning'**
  String get locomotionPattern;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get strength;

  /// No description provided for @hypertrophy.
  ///
  /// In en, this message translates to:
  /// **'Hypertrophy'**
  String get hypertrophy;

  /// No description provided for @endurance.
  ///
  /// In en, this message translates to:
  /// **'Endurance'**
  String get endurance;

  /// No description provided for @trainingQuestionnaireMissing.
  ///
  /// In en, this message translates to:
  /// **'Training questionnaire is missing.'**
  String get trainingQuestionnaireMissing;

  /// No description provided for @exerciseSelectionTest.
  ///
  /// In en, this message translates to:
  /// **'Exercise selection (test)'**
  String get exerciseSelectionTest;

  /// No description provided for @movementType.
  ///
  /// In en, this message translates to:
  /// **'Movement type'**
  String get movementType;

  /// No description provided for @focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// No description provided for @perMuscleWeekly.
  ///
  /// In en, this message translates to:
  /// **'/ muscle weekly'**
  String get perMuscleWeekly;

  /// No description provided for @competitionModeNote.
  ///
  /// In en, this message translates to:
  /// **'Competition mode – performance/conditioning priority.'**
  String get competitionModeNote;

  /// No description provided for @weightLossStrengthNote.
  ///
  /// In en, this message translates to:
  /// **'During calorie deficit we maintain strength, not chase PRs.'**
  String get weightLossStrengthNote;

  /// No description provided for @peakModeShortNote.
  ///
  /// In en, this message translates to:
  /// **'Peak: technique > volume, longer rests.'**
  String get peakModeShortNote;

  /// No description provided for @generalTraining.
  ///
  /// In en, this message translates to:
  /// **'General training'**
  String get generalTraining;

  /// No description provided for @setupGoalAndDateForPeriodization.
  ///
  /// In en, this message translates to:
  /// **'Set your goal and target date first to enable periodization.'**
  String get setupGoalAndDateForPeriodization;

  /// No description provided for @trainingCompetitionMode.
  ///
  /// In en, this message translates to:
  /// **'Competition mode – performance and physique are the priority.'**
  String get trainingCompetitionMode;

  /// No description provided for @trainingDeficitStrength.
  ///
  /// In en, this message translates to:
  /// **'During a calorie deficit we maintain strength instead of chasing PRs.'**
  String get trainingDeficitStrength;

  /// No description provided for @trainingPeakMode.
  ///
  /// In en, this message translates to:
  /// **'Peak phase: technique over volume, longer rest periods.'**
  String get trainingPeakMode;

  /// No description provided for @trainingGeneralTitle.
  ///
  /// In en, this message translates to:
  /// **'General Training'**
  String get trainingGeneralTitle;

  /// No description provided for @trainingGeneralNote.
  ///
  /// In en, this message translates to:
  /// **'Set your goal and target date first to enable periodization.'**
  String get trainingGeneralNote;

  /// No description provided for @trainingSplitAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get trainingSplitAuto;

  /// No description provided for @trainingSplitFullbody.
  ///
  /// In en, this message translates to:
  /// **'Full Body 3×'**
  String get trainingSplitFullbody;

  /// No description provided for @trainingSplitUpperLower.
  ///
  /// In en, this message translates to:
  /// **'Upper / Lower 4×'**
  String get trainingSplitUpperLower;

  /// No description provided for @trainingSplitPPL.
  ///
  /// In en, this message translates to:
  /// **'Push Pull Legs 6×'**
  String get trainingSplitPPL;

  /// No description provided for @trainingSplitStrength3day.
  ///
  /// In en, this message translates to:
  /// **'Strength 3 Days'**
  String get trainingSplitStrength3day;

  /// No description provided for @coachInsightVeryLowFat.
  ///
  /// In en, this message translates to:
  /// **'Very low body fat – competition or short-term peak condition.'**
  String get coachInsightVeryLowFat;

  /// No description provided for @coachInsightExcellentShape.
  ///
  /// In en, this message translates to:
  /// **'Excellent condition.'**
  String get coachInsightExcellentShape;

  /// No description provided for @coachInsightHealthyAthletic.
  ///
  /// In en, this message translates to:
  /// **'Healthy athletic condition.'**
  String get coachInsightHealthyAthletic;

  /// No description provided for @coachInsightFatReduction.
  ///
  /// In en, this message translates to:
  /// **'There is room for fat reduction.'**
  String get coachInsightFatReduction;

  /// No description provided for @coachInsightHighFat.
  ///
  /// In en, this message translates to:
  /// **'High body fat percentage – fat loss should be the priority.'**
  String get coachInsightHighFat;

  /// No description provided for @coachInsightVeryLean.
  ///
  /// In en, this message translates to:
  /// **'Body fat is already very low – focus should shift toward performance and muscle growth.'**
  String get coachInsightVeryLean;

  /// No description provided for @coachInsightWaterRetention.
  ///
  /// In en, this message translates to:
  /// **'The body may be retaining extra water (stress, sodium, recovery).'**
  String get coachInsightWaterRetention;

  /// No description provided for @coachInsightLowWater.
  ///
  /// In en, this message translates to:
  /// **'Low water percentage – focus on hydration and recovery.'**
  String get coachInsightLowWater;

  /// No description provided for @coachInsightFatDown.
  ///
  /// In en, this message translates to:
  /// **'Body fat is decreasing – keep going.'**
  String get coachInsightFatDown;

  /// No description provided for @coachInsightFatUp.
  ///
  /// In en, this message translates to:
  /// **'Body fat is increasing – nutrition adjustments may be needed.'**
  String get coachInsightFatUp;

  /// No description provided for @coachInsightMuscleUp.
  ///
  /// In en, this message translates to:
  /// **'Muscle mass is increasing – training is working.'**
  String get coachInsightMuscleUp;

  /// No description provided for @coachInsightMuscleDown.
  ///
  /// In en, this message translates to:
  /// **'Muscle mass is decreasing – increase protein intake or reduce the calorie deficit.'**
  String get coachInsightMuscleDown;

  /// No description provided for @fullbody3x.
  ///
  /// In en, this message translates to:
  /// **'Fullbody 3×'**
  String get fullbody3x;

  /// No description provided for @upperLower4x.
  ///
  /// In en, this message translates to:
  /// **'Upper / Lower 4×'**
  String get upperLower4x;

  /// No description provided for @pushPullLegs6x.
  ///
  /// In en, this message translates to:
  /// **'Push Pull Legs 6×'**
  String get pushPullLegs6x;

  /// No description provided for @strength3days.
  ///
  /// In en, this message translates to:
  /// **'Strength 3 days'**
  String get strength3days;

  /// No description provided for @prescription.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get prescription;

  /// No description provided for @selectedExercise.
  ///
  /// In en, this message translates to:
  /// **'Selected exercise'**
  String get selectedExercise;

  /// No description provided for @noExerciseSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected exercise: (not selected yet)'**
  String get noExerciseSelected;

  /// No description provided for @slotDebugDescription.
  ///
  /// In en, this message translates to:
  /// **'Test screen: slot = role + movement type + focus + sets/reps/RIR. Tap slot and choose exercise.'**
  String get slotDebugDescription;

  /// No description provided for @fastingLengthQuestion.
  ///
  /// In en, this message translates to:
  /// **'How long fasting period do you prefer?'**
  String get fastingLengthQuestion;

  /// No description provided for @fastingWindowQuestion.
  ///
  /// In en, this message translates to:
  /// **'WHEN DOES YOUR EATING WINDOW START?'**
  String get fastingWindowQuestion;

  /// No description provided for @setGoalFirst.
  ///
  /// In en, this message translates to:
  /// **'Set your goal first.'**
  String get setGoalFirst;

  /// No description provided for @trainingSetupNeeded.
  ///
  /// In en, this message translates to:
  /// **'Before generating training, I need a short setup.'**
  String get trainingSetupNeeded;

  /// No description provided for @repetitions.
  ///
  /// In en, this message translates to:
  /// **'Repetitions'**
  String get repetitions;

  /// No description provided for @weeklySetsPerMuscle.
  ///
  /// In en, this message translates to:
  /// **'Weekly sets per muscle'**
  String get weeklySetsPerMuscle;

  /// No description provided for @rirReserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve (RIR)'**
  String get rirReserve;

  /// No description provided for @buildCustomTraining.
  ///
  /// In en, this message translates to:
  /// **'Build custom training'**
  String get buildCustomTraining;

  /// No description provided for @deloadRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommendation: deload — if you feel fatigued, reduce volume by 30–40% for 1 week.'**
  String get deloadRecommendation;

  /// No description provided for @peakModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Peak mode: technique > volume, longer rests, low reps.'**
  String get peakModeDescription;

  /// No description provided for @weeklyPlan.
  ///
  /// In en, this message translates to:
  /// **'Weekly plan'**
  String get weeklyPlan;

  /// No description provided for @todayTraining.
  ///
  /// In en, this message translates to:
  /// **'Today\'s training'**
  String get todayTraining;

  /// No description provided for @changeTrainingSplit.
  ///
  /// In en, this message translates to:
  /// **'Change training split'**
  String get changeTrainingSplit;

  /// Exercise note label
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @trainingPlanDescription.
  ///
  /// In en, this message translates to:
  /// **'The plan is generated automatically based on your goal and time.\nCustom plans are intended for clients with specific needs, limitations, or individual schedules.'**
  String get trainingPlanDescription;

  /// No description provided for @fastingBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner (12:12)'**
  String get fastingBeginner;

  /// No description provided for @fastingIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate (14:10)'**
  String get fastingIntermediate;

  /// No description provided for @fastingClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic (16:8)'**
  String get fastingClassic;

  /// No description provided for @fastingAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced (18:6)'**
  String get fastingAdvanced;

  /// No description provided for @fastingWarrior.
  ///
  /// In en, this message translates to:
  /// **'Warrior (20:4)'**
  String get fastingWarrior;

  /// No description provided for @newClient.
  ///
  /// In en, this message translates to:
  /// **'New Client'**
  String get newClient;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @mealSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions for {count} meals'**
  String mealSuggestions(Object count);

  /// No description provided for @approxMacros.
  ///
  /// In en, this message translates to:
  /// **'Approx macros: P {protein} g | C {carbs} g | F {fat} g | {calories} kcal'**
  String approxMacros(Object protein, Object carbs, Object fat, Object calories);

  /// No description provided for @eatenCalories.
  ///
  /// In en, this message translates to:
  /// **'Eaten: {calories} kcal'**
  String eatenCalories(Object calories);

  /// No description provided for @targetCaloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Target: {calories} kcal'**
  String targetCaloriesLabel(Object calories);

  /// No description provided for @remainingGrams.
  ///
  /// In en, this message translates to:
  /// **'remaining {grams} g'**
  String remainingGrams(Object grams);

  /// No description provided for @exceededGrams.
  ///
  /// In en, this message translates to:
  /// **'exceeded {grams} g'**
  String exceededGrams(Object grams);

  /// No description provided for @fastingConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured {hours} h fasting starting at {time}'**
  String fastingConfigured(Object hours, Object time);

  /// No description provided for @ingredientsWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'This week we will cook with:'**
  String get ingredientsWeekTitle;

  /// No description provided for @ingredientsExcludeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select ingredients you DO NOT WANT:'**
  String get ingredientsExcludeTitle;

  /// No description provided for @salmonOption.
  ///
  /// In en, this message translates to:
  /// **'Salmon (I don\'t like fish)'**
  String get salmonOption;

  /// No description provided for @generatePlanButton.
  ///
  /// In en, this message translates to:
  /// **'THAT\'S FINE, GENERATE!'**
  String get generatePlanButton;

  /// No description provided for @editTime.
  ///
  /// In en, this message translates to:
  /// **'EDIT TIME ({time})'**
  String editTime(Object time);

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newBadge;

  /// No description provided for @nextTimeKeepWeight.
  ///
  /// In en, this message translates to:
  /// **'➡️ Keep {weight} kg next time'**
  String nextTimeKeepWeight(Object weight);

  /// No description provided for @pickSkippedDay.
  ///
  /// In en, this message translates to:
  /// **'Skipped training day'**
  String get pickSkippedDay;

  /// No description provided for @pickSkippedDayDescription.
  ///
  /// In en, this message translates to:
  /// **'Last time you skipped day “{day}”. Do you want to finish it today?'**
  String pickSkippedDayDescription(Object day);

  /// No description provided for @cancelChange.
  ///
  /// In en, this message translates to:
  /// **'Cancel change'**
  String get cancelChange;

  /// No description provided for @continueCurrent.
  ///
  /// In en, this message translates to:
  /// **'Continue current'**
  String get continueCurrent;

  /// No description provided for @finishSkippedDay.
  ///
  /// In en, this message translates to:
  /// **'Finish skipped day'**
  String get finishSkippedDay;

  /// No description provided for @planHasNoDays.
  ///
  /// In en, this message translates to:
  /// **'The plan has no days yet.'**
  String get planHasNoDays;

  /// No description provided for @selectTrainingDay.
  ///
  /// In en, this message translates to:
  /// **'Select another training day'**
  String get selectTrainingDay;

  /// No description provided for @selectTrainingDayDescription.
  ///
  /// In en, this message translates to:
  /// **'The skipped day will be saved and offered later.'**
  String get selectTrainingDayDescription;

  /// No description provided for @noExercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises'**
  String get noExercises;

  /// No description provided for @returnOriginalDay.
  ///
  /// In en, this message translates to:
  /// **'Return original day'**
  String get returnOriginalDay;

  /// No description provided for @profileGoalRequired.
  ///
  /// In en, this message translates to:
  /// **'Set profile and goal first.'**
  String get profileGoalRequired;

  /// No description provided for @trainingSetupRequired.
  ///
  /// In en, this message translates to:
  /// **'Before generating today\'s training, complete the short setup.'**
  String get trainingSetupRequired;

  /// No description provided for @openTrainingSetup.
  ///
  /// In en, this message translates to:
  /// **'Open training setup'**
  String get openTrainingSetup;

  /// No description provided for @todayTrainingGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate today\'s training.'**
  String get todayTrainingGenerationFailed;

  /// No description provided for @changeDay.
  ///
  /// In en, this message translates to:
  /// **'Change day'**
  String get changeDay;

  /// No description provided for @temporaryDifferentDay.
  ///
  /// In en, this message translates to:
  /// **'A different training day is temporarily selected today.'**
  String get temporaryDifferentDay;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @performanceSaved.
  ///
  /// In en, this message translates to:
  /// **'Performance saved.'**
  String get performanceSaved;

  /// No description provided for @log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get log;

  /// No description provided for @customTrainingFormat.
  ///
  /// In en, this message translates to:
  /// **'Format: sets × reps / time | RIR'**
  String get customTrainingFormat;

  /// No description provided for @defaultTrainingFormat.
  ///
  /// In en, this message translates to:
  /// **'Format: sets × reps | RIR | kg'**
  String get defaultTrainingFormat;

  /// No description provided for @logPerformance.
  ///
  /// In en, this message translates to:
  /// **'Log performance'**
  String get logPerformance;

  /// No description provided for @setupProfileFirst.
  ///
  /// In en, this message translates to:
  /// **'Set up profile first.'**
  String get setupProfileFirst;

  /// No description provided for @setupGoalFirst.
  ///
  /// In en, this message translates to:
  /// **'Set your goal first.'**
  String get setupGoalFirst;

  /// No description provided for @openSetup.
  ///
  /// In en, this message translates to:
  /// **'Open Setup'**
  String get openSetup;

  /// No description provided for @trainingSetupRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'Before we generate your plan, please complete the short training setup.'**
  String get trainingSetupRequiredDescription;

  /// No description provided for @customPlan.
  ///
  /// In en, this message translates to:
  /// **'Custom Plan'**
  String get customPlan;

  /// No description provided for @selectAnotherDay.
  ///
  /// In en, this message translates to:
  /// **'Select Another Day'**
  String get selectAnotherDay;

  /// No description provided for @trainingFormatCustom.
  ///
  /// In en, this message translates to:
  /// **'Format: sets | reps / time | RIR'**
  String get trainingFormatCustom;

  /// No description provided for @trainingFormatDefault.
  ///
  /// In en, this message translates to:
  /// **'Format: sets | reps | RIR | kg'**
  String get trainingFormatDefault;

  /// No description provided for @pickDifferentTrainingDay.
  ///
  /// In en, this message translates to:
  /// **'Pick a different training day for today'**
  String get pickDifferentTrainingDay;

  /// No description provided for @originalDaysStaySaved.
  ///
  /// In en, this message translates to:
  /// **'Original days in the plan will remain saved.'**
  String get originalDaysStaySaved;

  /// No description provided for @mainLift.
  ///
  /// In en, this message translates to:
  /// **'MAIN LIFT'**
  String get mainLift;

  /// No description provided for @reps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get reps;

  /// No description provided for @rir.
  ///
  /// In en, this message translates to:
  /// **'RIR'**
  String get rir;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// No description provided for @mealsCountQuestion.
  ///
  /// In en, this message translates to:
  /// **'How many meals do you want?'**
  String get mealsCountQuestion;

  /// No description provided for @howDoYouWantSuggestions.
  ///
  /// In en, this message translates to:
  /// **'How do you want suggestions?'**
  String get howDoYouWantSuggestions;

  /// No description provided for @singleItemsFromBank.
  ///
  /// In en, this message translates to:
  /// **'Single food items from database'**
  String get singleItemsFromBank;

  /// No description provided for @completeMeals.
  ///
  /// In en, this message translates to:
  /// **'Complete meals'**
  String get completeMeals;

  /// No description provided for @selectMealsTotal.
  ///
  /// In en, this message translates to:
  /// **'Selected meals: {count}'**
  String selectMealsTotal(Object count);

  /// No description provided for @selectType.
  ///
  /// In en, this message translates to:
  /// **'Select type'**
  String get selectType;

  /// No description provided for @vegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get vegan;

  /// No description provided for @veganCategoryOnly.
  ///
  /// In en, this message translates to:
  /// **'Only vegan meals'**
  String get veganCategoryOnly;

  /// No description provided for @savory.
  ///
  /// In en, this message translates to:
  /// **'Savory'**
  String get savory;

  /// No description provided for @sweet.
  ///
  /// In en, this message translates to:
  /// **'Sweet'**
  String get sweet;

  /// No description provided for @anything.
  ///
  /// In en, this message translates to:
  /// **'Anything'**
  String get anything;

  /// No description provided for @howManyGrams.
  ///
  /// In en, this message translates to:
  /// **'How many grams?'**
  String get howManyGrams;

  /// No description provided for @grams.
  ///
  /// In en, this message translates to:
  /// **'Grams'**
  String get grams;

  /// No description provided for @selectActiveClientFirst.
  ///
  /// In en, this message translates to:
  /// **'Select an active client first'**
  String get selectActiveClientFirst;

  /// No description provided for @customTraining.
  ///
  /// In en, this message translates to:
  /// **'Custom Training'**
  String get customTraining;

  /// No description provided for @sharedTemplates.
  ///
  /// In en, this message translates to:
  /// **'Shared Templates'**
  String get sharedTemplates;

  /// No description provided for @noSharedTemplatesYet.
  ///
  /// In en, this message translates to:
  /// **'No shared templates yet'**
  String get noSharedTemplatesYet;

  /// No description provided for @clientPlans.
  ///
  /// In en, this message translates to:
  /// **'Client Plans'**
  String get clientPlans;

  /// No description provided for @noCustomPlanYet.
  ///
  /// In en, this message translates to:
  /// **'No custom plan created yet'**
  String get noCustomPlanYet;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @planDescription.
  ///
  /// In en, this message translates to:
  /// **'Plan Description'**
  String get planDescription;

  /// No description provided for @planDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'For example: strength plan for bulking'**
  String get planDescriptionHint;

  /// No description provided for @planDetail.
  ///
  /// In en, this message translates to:
  /// **'Plan Detail'**
  String get planDetail;

  /// No description provided for @planNotFound.
  ///
  /// In en, this message translates to:
  /// **'Plan not found'**
  String get planNotFound;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @numberOfDays.
  ///
  /// In en, this message translates to:
  /// **'Number of days'**
  String get numberOfDays;

  /// No description provided for @activateAndOpen.
  ///
  /// In en, this message translates to:
  /// **'Activate and Open'**
  String get activateAndOpen;

  /// No description provided for @shareAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Share as Template'**
  String get shareAsTemplate;

  /// No description provided for @editInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit Info'**
  String get editInfo;

  /// No description provided for @addDay.
  ///
  /// In en, this message translates to:
  /// **'Add Day'**
  String get addDay;

  /// No description provided for @deleteWholePlan.
  ///
  /// In en, this message translates to:
  /// **'Delete Whole Plan'**
  String get deleteWholePlan;

  /// No description provided for @editPlan.
  ///
  /// In en, this message translates to:
  /// **'Edit Plan'**
  String get editPlan;

  /// No description provided for @reallyDeletePlan.
  ///
  /// In en, this message translates to:
  /// **'Really delete the plan?'**
  String get reallyDeletePlan;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @deletePlanWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deletePlanWarning;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete Forever'**
  String get deleteForever;

  /// No description provided for @addTrainingDay.
  ///
  /// In en, this message translates to:
  /// **'Add Training Day'**
  String get addTrainingDay;

  /// No description provided for @dayName.
  ///
  /// In en, this message translates to:
  /// **'Day Name'**
  String get dayName;

  /// No description provided for @dayNameHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Push Day'**
  String get dayNameHint;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @exercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercises;

  /// No description provided for @addExercise.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get addExercise;

  /// No description provided for @deleteDay.
  ///
  /// In en, this message translates to:
  /// **'Delete Day'**
  String get deleteDay;

  /// No description provided for @noExercisesYet.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet'**
  String get noExercisesYet;

  /// No description provided for @reallyDeleteDay.
  ///
  /// In en, this message translates to:
  /// **'Really delete the day?'**
  String get reallyDeleteDay;

  /// No description provided for @deleteDayWarning.
  ///
  /// In en, this message translates to:
  /// **'The day will be permanently removed.'**
  String get deleteDayWarning;

  /// No description provided for @selectFromExerciseDatabase.
  ///
  /// In en, this message translates to:
  /// **'Select from exercise database'**
  String get selectFromExerciseDatabase;

  /// No description provided for @enterCustomExerciseManually.
  ///
  /// In en, this message translates to:
  /// **'Enter custom exercise manually'**
  String get enterCustomExerciseManually;

  /// Dialog title for adding custom exercise
  ///
  /// In en, this message translates to:
  /// **'Add Custom Exercise'**
  String get addCustomExercise;

  /// Edit exercise dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Exercise'**
  String get editExercise;

  /// No description provided for @deleteExerciseQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Exercise?'**
  String get deleteExerciseQuestion;

  /// Delete confirmation button
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete'**
  String get yesDelete;

  /// Exercise database picker title
  ///
  /// In en, this message translates to:
  /// **'Select Exercise from Database'**
  String get selectExerciseFromDatabase;

  /// No exercise found message
  ///
  /// In en, this message translates to:
  /// **'No exercise found'**
  String get noExerciseFound;

  /// No description provided for @enterValidGramRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount between 10 and 3000 g'**
  String get enterValidGramRange;

  /// Exercise name field
  ///
  /// In en, this message translates to:
  /// **'Exercise Name'**
  String get exerciseName;

  /// Hint for exercise name
  ///
  /// In en, this message translates to:
  /// **'Example: Side Plank'**
  String get exerciseNameHint;

  /// Sets label
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get sets;

  /// Reps or time label
  ///
  /// In en, this message translates to:
  /// **'Reps / Time'**
  String get repsOrTime;

  /// Hint for reps or time
  ///
  /// In en, this message translates to:
  /// **'Example: 3 min or 8–12'**
  String get repsOrTimeHint;

  /// Remove exercise confirmation title
  ///
  /// In en, this message translates to:
  /// **'Remove Exercise?'**
  String get removeExerciseQuestion;

  /// Equipment label
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get equipment;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed ✅'**
  String get completed;

  /// No description provided for @noMealsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No meals in category {category}'**
  String noMealsInCategory(Object category);

  /// No description provided for @selectMeal.
  ///
  /// In en, this message translates to:
  /// **'Select meal for {slot} ({category})'**
  String selectMeal(Object slot, Object category);

  /// No description provided for @addedMeal.
  ///
  /// In en, this message translates to:
  /// **'{meal} added ({grams} g)'**
  String addedMeal(Object meal, Object grams);

  /// No description provided for @planSummary.
  ///
  /// In en, this message translates to:
  /// **'Plan Summary'**
  String get planSummary;

  /// No description provided for @editGrams.
  ///
  /// In en, this message translates to:
  /// **'Edit grams'**
  String get editGrams;

  /// No description provided for @addAll.
  ///
  /// In en, this message translates to:
  /// **'Add all'**
  String get addAll;

  /// No description provided for @exerciseCount.
  ///
  /// In en, this message translates to:
  /// **'{count} exercises'**
  String exerciseCount(Object count);

  /// No description provided for @waterPercentageInfo.
  ///
  /// In en, this message translates to:
  /// **'Water percentage: {value}%'**
  String waterPercentageInfo(Object value);

  /// No description provided for @confirmDeleteTemplate.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete template \"{name}\"?'**
  String confirmDeleteTemplate(Object name);

  /// No description provided for @failedToSaveMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Failed to save measurements: {error}'**
  String failedToSaveMeasurements(Object error);

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @passwordResetEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email above first.'**
  String get passwordResetEnterEmail;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a password reset link to {email}.'**
  String passwordResetSent(Object email);

  /// No description provided for @passwordResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the reset email: {error}'**
  String passwordResetFailed(Object error);

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete coach account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and all client data stored in the cloud. Coach data on this device will be removed too. This cannot be undone.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm with your password'**
  String get deleteAccountPasswordLabel;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteAccountConfirm;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get accountDeleted;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the account: {error}'**
  String deleteAccountFailed(Object error);

  /// No description provided for @restrictiveDietsHidden.
  ///
  /// In en, this message translates to:
  /// **'Keto and intermittent fasting are hidden for eating disorder support. Restrictive diets are not suitable here – use the linear plan or consult a professional.'**
  String get restrictiveDietsHidden;

  /// No description provided for @dietPreferenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Dietary restriction'**
  String get dietPreferenceTitle;

  /// No description provided for @dietPreferenceHint.
  ///
  /// In en, this message translates to:
  /// **'Meal plans, suggestions and meals will only offer foods that match.'**
  String get dietPreferenceHint;

  /// No description provided for @dietNone.
  ///
  /// In en, this message translates to:
  /// **'No restriction'**
  String get dietNone;

  /// No description provided for @dietVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get dietVegetarian;

  /// No description provided for @dietVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get dietVegan;

  /// No description provided for @budgetShort.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetShort;

  /// No description provided for @benchInsertPlan.
  ///
  /// In en, this message translates to:
  /// **'🏋️ INSERT RUSSIAN CYCLE – BENCH PRESS (MEET)'**
  String get benchInsertPlan;

  /// No description provided for @strengthDietDescription.
  ///
  /// In en, this message translates to:
  /// **'Meal plan for strength prep (Russian bench cycle, powerlifting). Maintenance calories – strength grows without a surplus and body weight stays in the weight class. Protein 2.0 g/kg, fat 1.0 g/kg, the rest carbs to fuel heavy sets and recovery.'**
  String get strengthDietDescription;

  /// No description provided for @strengthActivate.
  ///
  /// In en, this message translates to:
  /// **'Create Strength prep meal plan'**
  String get strengthActivate;

  /// No description provided for @bikiniDietDescription.
  ///
  /// In en, this message translates to:
  /// **'Strict 16-week bikini fitness contest diet – same phases as the workout plan. Weight loss 0.5% (shape building) → 0.75% (cutting) → 1% of body weight per week (final cut), protein 2.2–2.4 g/kg, fat at least 0.7 g/kg, peak week at maintenance with higher carbs for full, round muscles on stage. Counted backwards from the contest date.'**
  String get bikiniDietDescription;

  /// No description provided for @bikiniSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Set contest date and create meal plan'**
  String get bikiniSelectDate;

  /// No description provided for @bikiniNoDate.
  ///
  /// In en, this message translates to:
  /// **'Contest date is missing.'**
  String get bikiniNoDate;

  /// No description provided for @gluteDietDescription.
  ///
  /// In en, this message translates to:
  /// **'Meal plan for the Round glutes program. Muscles do not grow in a deficit – a mild surplus of 7.5% above TDEE, protein 2.0 g/kg, fat 0.9 g/kg, the rest carbs to fuel heavy leg and glute training.'**
  String get gluteDietDescription;

  /// No description provided for @gluteActivate.
  ///
  /// In en, this message translates to:
  /// **'Create Round glutes meal plan'**
  String get gluteActivate;

  /// No description provided for @bikiniNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Prep starts on {start} (16 weeks before the contest on {meet}). Until then the regular goal-based targets apply.'**
  String bikiniNotStarted(Object start, Object meet);

  /// No description provided for @bikiniFinished.
  ///
  /// In en, this message translates to:
  /// **'The contest ({meet}) is over – the regular goal-based targets apply.'**
  String bikiniFinished(Object meet);

  /// No description provided for @gluteTitle.
  ///
  /// In en, this message translates to:
  /// **'Round glutes'**
  String get gluteTitle;

  /// No description provided for @gluteInsertPlan.
  ///
  /// In en, this message translates to:
  /// **'🍑 INSERT ROUND GLUTES PLAN'**
  String get gluteInsertPlan;

  /// No description provided for @bikiniTitle.
  ///
  /// In en, this message translates to:
  /// **'Bikini fitness'**
  String get bikiniTitle;

  /// No description provided for @bikiniInsertPlan.
  ///
  /// In en, this message translates to:
  /// **'👙 INSERT CONTEST PREP – BIKINI FITNESS'**
  String get bikiniInsertPlan;

  /// No description provided for @hollywoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Hollywood training'**
  String get hollywoodTitle;

  /// No description provided for @hollywoodDescription.
  ///
  /// In en, this message translates to:
  /// **'A strict 12-week physique prep for a film or photo shoot – the way actors prepare for roles. Weight loss ramps up 0.5 → 0.75 → 1% of body weight per week, protein 2.2–2.4 g/kg, shoot week at maintenance with higher carbs (muscles look full). Counted backwards from the shoot date, same as the Hollywood training workout plan.'**
  String get hollywoodDescription;

  /// No description provided for @hollywoodSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Set shoot date and create meal plan'**
  String get hollywoodSelectDate;

  /// No description provided for @hollywoodShootDate.
  ///
  /// In en, this message translates to:
  /// **'Shoot date'**
  String get hollywoodShootDate;

  /// No description provided for @hollywoodNoDate.
  ///
  /// In en, this message translates to:
  /// **'Shoot date is missing.'**
  String get hollywoodNoDate;

  /// No description provided for @hollywoodInsertPlan.
  ///
  /// In en, this message translates to:
  /// **'🎬 INSERT HOLLYWOOD TRAINING – SHOOT PREP'**
  String get hollywoodInsertPlan;

  /// No description provided for @hollywoodNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Prep starts on {start} (12 weeks before the shoot on {shoot}). Until then the regular goal-based targets apply.'**
  String hollywoodNotStarted(Object start, Object shoot);

  /// No description provided for @hollywoodFinished.
  ///
  /// In en, this message translates to:
  /// **'The shoot ({shoot}) is over – the regular goal-based targets apply.'**
  String hollywoodFinished(Object shoot);

  /// No description provided for @budgetMealsTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget meal plan'**
  String get budgetMealsTitle;

  /// No description provided for @budgetMealsHint.
  ///
  /// In en, this message translates to:
  /// **'Cheap everyday ingredients (eggs, quark, chicken thighs, legumes, potatoes, rice…). Dinner is cooked together with lunch, only the portion differs.'**
  String get budgetMealsHint;

  /// No description provided for @addToDay.
  ///
  /// In en, this message translates to:
  /// **'Add to day'**
  String get addToDay;

  /// No description provided for @remainderCoverage.
  ///
  /// In en, this message translates to:
  /// **'Remaining: P {p} | C {c} | F {f} g · suggestions cover: P {sp} | C {sc} | F {sf} g'**
  String remainderCoverage(Object p, Object c, Object f, Object sp, Object sc, Object sf);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['cs', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs': return AppLocalizationsCs();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
