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
  String get switchToThisProfile => 'Switch to this profile';

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
  String get activeCoachClient => 'Active: coach and client mode';

  @override
  String get activeClientCoachLocked => 'Active: client mode (coach mode locked)';

  @override
  String get noAccess => 'No access';

  @override
  String get selectMode => 'Select Mode';

  @override
  String get modeDescription => 'Regular user = onboarding + personal plan.\nCoach mode = client management.';

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
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get ketoMealPlanPdfTitle => 'Keto Meal Plan';

  @override
  String get carbCyclingPdfTitle => 'Carb Cycling';

  @override
  String get ketoMealPlanPdfSubtitle => 'Low-carb nutrition focused on fats and stable protein intake.';

  @override
  String get carbCyclingPdfSubtitle => 'Carbohydrates are cycled depending on the training day.';

  @override
  String get yourKetoMealPlan => 'Your Keto Meal Plan';

  @override
  String get yourPlan => 'Your Plan';

  @override
  String get printPdf => 'Print / PDF';

  @override
  String get sharePdf => 'Share PDF';

  @override
  String get dailyCarbIntake => 'Daily carbohydrate intake';

  @override
  String get weeklyCarbBank => 'Your weekly carb budget';

  @override
  String get proteinLabel => 'Protein';

  @override
  String get fatsLabel => 'Fats';

  @override
  String get generateShoppingList => 'Generate shopping list';

  @override
  String get showFullWeeklyMealPlan => 'Show full weekly meal plan';

  @override
  String get dayMealBreakdown => 'Daily breakdown and meal plan:';

  @override
  String get refeedDay => 'Refeed day';

  @override
  String get closeAndActivate => 'Close and activate';

  @override
  String get setupProfileAndGoalFirst => 'Please set up profile and goal first.';

  @override
  String get eatingSupportOnlyMode => 'This questionnaire is only for Weight Gain / Eating Disorder Support mode.';

  @override
  String get safeModeTitle => 'Weight gain support / safe mode';

  @override
  String get safeModeDescription => 'This mode is designed to avoid restriction and calorie tracking.\nThe goal is a safe return of energy, routine and strength.';

  @override
  String get safetyAndPreferences => 'Safety and preferences';

  @override
  String get hideNutritionNumbers => 'Hide nutrition numbers (calories/macros)';

  @override
  String get hideNutritionNumbersDescription => 'Recommended – the app will avoid pressure around numbers.';

  @override
  String get medicalSupport => 'I have professional support (therapist / doctor / nutritionist)';

  @override
  String get medicalSupportDescription => 'Helps provide more sensitive recommendations.';

  @override
  String get focusQuestion => 'What do you want to focus on the most right now?';

  @override
  String get focusEnergyRoutine => 'Energy & routine';

  @override
  String get focusStrengthPerformance => 'Strength & performance';

  @override
  String get focusGentleMode => 'Gentle pressure-free mode';

  @override
  String get optionalNote => 'Note (optional)';

  @override
  String get trainingSetupTitle => 'Training Setup';

  @override
  String get trainingFrequencyQuestion => 'How many times per week do you want to train?';

  @override
  String get trainingFrequencyHint => 'Choose a realistic number based on your time and recovery.';

  @override
  String timesPerWeek(Object count) {
    return '$count× per week';
  }

  @override
  String get performancePr => 'Performance / PR';

  @override
  String get addPerformance => 'Add Performance';

  @override
  String get noPerformanceRecords => 'You don\'t have any performance records yet.\n\nClick + to add your first exercise.';

  @override
  String get equipmentQuestion => 'What equipment do you have?';

  @override
  String get insert90DayCutPlan => 'Insert 90-Day Cutting Plan';

  @override
  String get insertPowerliftingPrep => 'Insert Powerlifting Meet Prep';

  @override
  String get planCreationFailed => 'Failed to create the plan.';

  @override
  String get planInserted => 'The plan has been added to custom training plans.';

  @override
  String get enterMaxes => 'Enter Maxes';

  @override
  String get squat1rm => 'Squat 1RM (kg)';

  @override
  String get bench1rm => 'Bench press 1RM (kg)';

  @override
  String get deadlift1rm => 'Deadlift 1RM (kg)';

  @override
  String get meetDate => 'Meet Date';

  @override
  String get createPlan => 'Create Plan';

  @override
  String get strengthTrainings => 'Strength Trainings';

  @override
  String get bulk => 'Bulk';

  @override
  String get cut => 'Cut';

  @override
  String get recomp => 'Recomp';

  @override
  String get fillWeeklyMealPlanName => 'Fill weekly meal plan name';

  @override
  String get selectTemplateForEachDay => 'Select a template for each day';

  @override
  String get failedToLoadDailyTemplate => 'Failed to load daily template';

  @override
  String get weeklyMealPlanSaved => 'Weekly meal plan saved';

  @override
  String get buildWeeklyMealPlan => 'Build Weekly Meal Plan';

  @override
  String get saveWeek => 'Save Week';

  @override
  String get createDailyTemplateFirst => 'Create daily template first';

  @override
  String get weeklyMealPlanName => 'Weekly meal plan name';

  @override
  String get selectDailyTemplate => 'Select daily template';

  @override
  String get saveWeeklyMealPlan => 'Save weekly meal plan';

  @override
  String get mealCount => 'Meal count';

  @override
  String get fat => 'Fat';

  @override
  String get day => 'day';

  @override
  String get tdeeDescription => 'Note: TDEE is energy expenditure. Target calories and macros are determined by goal, phase, and target date.';

  @override
  String get profileOrGoalNotFound => 'Profile or goal not found';

  @override
  String get powerlifting => 'Powerlifting';

  @override
  String get bodybuilding => 'Bodybuilding';

  @override
  String get other => 'Other';

  @override
  String get daysCount => 'Days Count';

  @override
  String get deleteTemplate => 'Delete Template';

  @override
  String get insert => 'Insert';

  @override
  String templateInserted(Object name) {
    return 'Template \"$name\" has been inserted for the client.';
  }

  @override
  String planSavedAsTemplate(Object name) {
    return 'Plan \"$name\" has been saved as a shared template.';
  }

  @override
  String confirmDeletePlan(Object name) {
    return 'Do you really want to delete the plan \"$name\"?';
  }

  @override
  String confirmDeleteDay(Object name) {
    return 'Do you really want to delete the day \"$name\"?';
  }

  @override
  String confirmDeleteExercise(Object name) {
    return 'Do you want to remove the exercise \"$name\"?';
  }

  @override
  String get bodyweightEquipment => 'Bodyweight';

  @override
  String get dumbbellEquipment => 'Dumbbells';

  @override
  String get barbellEquipment => 'Barbell';

  @override
  String get rackEquipment => 'Rack';

  @override
  String get benchEquipment => 'Bench';

  @override
  String get machineEquipment => 'Machines';

  @override
  String get cardioEquipment => 'Cardio';

  @override
  String get equipmentHint => 'Tip: if you don\'t have something, the app will choose more suitable exercises.';

  @override
  String get experienceQuestion => 'What is your experience level?';

  @override
  String get experienceHint => 'This helps set appropriate difficulty.';

  @override
  String get beginner => 'Beginner';

  @override
  String get intermediate => 'Intermediate';

  @override
  String get advanced => 'Advanced';

  @override
  String get oneRepMaxTitle => 'One-rep maxes (1RM) – competition only';

  @override
  String get trainingMaxHint => 'Note: training weights are calculated from the “training max” (90% of 1RM).';

  @override
  String get fillAllMaxes => 'Please fill in all one-rep maxes (positive numbers).';

  @override
  String get carbCyclingReadinessTitle => 'Readiness Analysis';

  @override
  String get carbCyclingIntro => 'This questionnaire evaluates whether it is safe for your body to transition to a carb cycling system.';

  @override
  String get healthState => 'Health Status';

  @override
  String get healthIssuesQuestion => 'Diabetes or history of eating disorders?';

  @override
  String get healthIssuesDescription => 'For safety reasons, this is a strict criterion.';

  @override
  String get stressLevelQuestion => 'Current stress level (1 = calm, 10 = burnout)';

  @override
  String get stressLabel => 'Stress';

  @override
  String get stressLevelValue => 'Stress level';

  @override
  String get averageSleepLength => 'Average Sleep Duration';

  @override
  String get sleepLabel => 'Sleep';

  @override
  String get hoursLabel => 'hours';

  @override
  String get trainingUnits => 'workouts';

  @override
  String get trainingLabel => 'Workouts';

  @override
  String get hydrationTitle => 'Hydration';

  @override
  String get hydrationQuestion => 'Do you drink at least 2–3 liters of water daily?';

  @override
  String get evaluateReadiness => 'Evaluate readiness';

  @override
  String get approved => 'Approved';

  @override
  String get notRecommended => 'Not recommended';

  @override
  String get iUnderstand => 'I Understand';

  @override
  String get carbCyclingHealthWarning => 'Due to health risks (diabetes/history of eating disorders), carb cycling is not suitable for you. Client safety is our priority.';

  @override
  String get carbCyclingStressWarning => 'Your current stress level is too high. Carb cycling places additional stress on the body. We recommend first stabilizing your routine with a standard diet.';

  @override
  String get carbCyclingSleepWarning => 'Sleeping less than 6 hours per day prevents the proper recovery required for carb cycling. Focus on improving rest first.';

  @override
  String get carbCyclingTrainingWarning => 'Carb cycling requires at least 3 strength training sessions per week so the body can effectively utilize high-carb days.';

  @override
  String get carbCyclingWaterWarning => 'Warning: Carb cycling significantly affects water balance in the body. You need to increase your water intake!';

  @override
  String get carbCyclingApprovedMessage => 'Congratulations! You are ready for carb cycling. Your body has good potential for nutrient cycling.';

  @override
  String get saveTrainingSetup => 'Save setup';

  @override
  String get numberInputHint => 'You can also use commas (e.g. 120,5).';

  @override
  String get trainingFrequencyTitle => 'Number of strength workouts per week';

  @override
  String get optionalNoteDescription => 'Example: “I want light training 3× weekly”, “no weighing”, “prefer machines”.';

  @override
  String get yourWeeklyKetoPlan => 'Your Weekly Keto Plan';

  @override
  String get openFullWeek => 'Open full week';

  @override
  String get weeklyKetoMealPlan => 'Weekly Keto Meal Plan';

  @override
  String get fullWeekMealPlan => 'Meal Plan For The Whole Week:';

  @override
  String get ingredientsLabel => 'Ingredients';

  @override
  String get carbsLabel => 'Carbohydrates';

  @override
  String get mentalHealthWarning => 'If you feel mentally overwhelmed or have urges to harm yourself, seek immediate help. Contact local mental health crisis services or emergency support in your country.';

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
  String get noPerformanceRecordsForExercise => 'You don\'t have any records for this exercise yet.';

  @override
  String get showChart => 'Show Chart';

  @override
  String folderPickFailed(Object error) {
    return 'Folder selection failed: $error';
  }

  @override
  String get dayOptions => 'Day Options';

  @override
  String get customPlanEmpty => 'The active custom plan does not contain any days or exercises yet.';

  @override
  String get planGenerationFailed => 'Failed to generate plan.';

  @override
  String get coachGoal => 'Coach Goal';

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
  String get open => 'Open';

  @override
  String get activate => 'Activate';

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
  String get biceps => 'Biceps';

  @override
  String get neck => 'Neck';

  @override
  String get selectExercise => 'Select Exercise';

  @override
  String get searchExercise => 'Search Exercise';

  @override
  String get showAllExercises => 'Show All Exercises';

  @override
  String get showAllExercisesDescription => 'When disabled, only recommended exercises for this slot will be shown.';

  @override
  String get noRecommendedExerciseFound => 'No suitable exercise was found for this slot based on your equipment and filters. Enable “Show All Exercises” or adjust your equipment in training setup.';

  @override
  String get noExerciseFoundBySearch => 'No exercise found for your search.';

  @override
  String get noExerciseFoundForSlot => 'No suitable exercise found for this slot.';

  @override
  String get englishLabel => 'English';

  @override
  String get equipmentLabel => 'Equipment';

  @override
  String get coachSignedOut => 'Coach has been signed out.';

  @override
  String get logoutCoach => 'Sign out coach';

  @override
  String get clients => 'Clients';

  @override
  String scaledByCalories(Object name, Object weight) {
    return 'Scaled by calories for $name ($weight kg).';
  }

  @override
  String scaledByWeight(Object name, Object weight) {
    return 'Scaled by weight for $name ($weight kg).';
  }

  @override
  String signOutFailed(Object error) {
    return 'Failed to sign out: $error';
  }

  @override
  String get coachRegistration => 'Coach Registration';

  @override
  String get coachLogin => 'Coach Login';

  @override
  String get coachAccountCreated => 'Coach account has been created.';

  @override
  String get loginSuccessful => 'Login successful.';

  @override
  String get records => 'Records';

  @override
  String get enterEmail => 'Enter e-mail.';

  @override
  String get enterValidEmail => 'Enter valid e-mail.';

  @override
  String get enterPassword => 'Enter password.';

  @override
  String get passwordTooShort => 'Password must contain at least 6 characters.';

  @override
  String get confirmPassword => 'Confirm password.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get clientArchiving => 'Client Archiving';

  @override
  String get loadingExportFolder => 'Loading export folder settings...';

  @override
  String currentExportFolder(Object path) {
    return 'Current export folder:\n\n$path';
  }

  @override
  String get noCustomExportFolder => 'No custom export folder selected.\n\nDefault Documents/Clients folder will be used.';

  @override
  String get selectExportFolder => 'Select export folder';

  @override
  String get clearCustomPath => 'Clear custom path';

  @override
  String get debugWeightSource => 'Debug – weight source used';

  @override
  String get currentWeight => 'Current weight';

  @override
  String get targetWeight => 'Target weight';

  @override
  String get notSet => 'not set';

  @override
  String get weightForCalories => 'Weight for calories';

  @override
  String get weightForProtein => 'Weight for protein';

  @override
  String get phase => 'Phase';

  @override
  String get mode => 'Mode';

  @override
  String get weeksToTarget => 'Weeks to target';

  @override
  String get strategy => 'Strategy';

  @override
  String get createCoachAccount => 'Create coach account';

  @override
  String get loginToCoachCloud => 'Sign in to coach cloud';

  @override
  String get coachAccountDescription => 'Each coach has their own account and private cloud storage for clients, notes and measurements.';

  @override
  String get coachLoginDescription => 'Sign in using your e-mail and password. After login you will only see your own coach data.';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get createAccount => 'Create account';

  @override
  String get signIn => 'Sign in';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Create registration';

  @override
  String get addMeasurements => 'Add Measurements';

  @override
  String get measurementDate => 'Measurement Date';

  @override
  String get clientAndPeriod => 'Client and period';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get bodyCircumferences => 'Body circumferences';

  @override
  String get exercisePerformance => 'Exercise performance';

  @override
  String get coachSummary => 'Coach summary';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get noDataForSummary => 'There is no data in the selected period.';

  @override
  String get summaryGenerated => 'Summary has been generated.';

  @override
  String get noPerformancesInPeriod => 'No performances in selected period.';

  @override
  String get numberOfRecords => 'Number of records';

  @override
  String get arms => 'Arms';

  @override
  String get chest => 'Chest';

  @override
  String get waist => 'Waist';

  @override
  String get hips => 'Hips';

  @override
  String get thigh => 'Thigh';

  @override
  String get dailyEnergyExpenditure => 'Daily energy expenditure';

  @override
  String get targetCalories => 'Target calories';

  @override
  String get macros => 'Macros';

  @override
  String get arm => 'Arm';

  @override
  String get calf => 'Calf';

  @override
  String get saving => 'Saving...';

  @override
  String get save => 'Save';

  @override
  String get noSavedMealPlans => 'You do not have any saved meal plans or daily templates yet.';

  @override
  String get dailyTemplates => 'Daily templates';

  @override
  String get noDailyTemplates => 'You do not have any saved daily templates yet.';

  @override
  String get untitled => 'Untitled';

  @override
  String get meals => 'Meals';

  @override
  String get client => 'Client';

  @override
  String get coachNote => 'Coach note';

  @override
  String get openEdit => 'Open / Edit';

  @override
  String get completeMealPlans => 'Complete meal plans';

  @override
  String get noCompleteMealPlans => 'You do not have any complete meal plans yet.';

  @override
  String get type => 'Type';

  @override
  String get duration => 'Duration';

  @override
  String get baseWeight => 'Base weight';

  @override
  String get calories => 'Calories';

  @override
  String get useOneToOne => 'Use 1:1';

  @override
  String get scaleToProfile => 'Scale to profile';

  @override
  String get deleteMealPlanQuestion => 'Delete meal plan?';

  @override
  String get deleteDailyTemplateQuestion => 'Delete daily template?';

  @override
  String get enterNumber => 'Enter a number';

  @override
  String get valueCannotBeNegative => 'Value cannot be negative';

  @override
  String get phaseLogicCoreTest => 'Phase logic test';

  @override
  String get profileOrGoalNotSet => 'Profile or goal is not set';

  @override
  String get dataSource => 'Data source';

  @override
  String get goal => 'Goal';

  @override
  String get reason => 'Reason';

  @override
  String get goalDate => 'Goal date';

  @override
  String get weeksToGoal => 'Weeks to goal';

  @override
  String get currentEvaluation => 'Current evaluation';

  @override
  String get currentPhase => 'Current phase';

  @override
  String get phaseLabel => 'Phase label';

  @override
  String get activeSegment => 'Active segment';

  @override
  String get foodStrategy => 'Food strategy';

  @override
  String get calorieMultiplier => 'Calorie multiplier';

  @override
  String get highCarbs => 'High carbs';

  @override
  String get phasePlan => 'Phase plan';

  @override
  String get finalMacros => 'Final macros';

  @override
  String get coreEngineInfo => 'Everything is controlled by date through the Core engine.';

  @override
  String get clientId => 'Client ID';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get tdee => 'TDEE';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fats => 'Fats';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get help => 'Help';

  @override
  String get howAppWorks => 'How the app works';

  @override
  String get dataStorage => 'Data storage';

  @override
  String get clientExport => 'Client export';

  @override
  String get clientImport => 'Client import';

  @override
  String get factoryReset => 'Factory reset';

  @override
  String get importantWarning => 'Important warning';

  @override
  String get helpStorage1 => 'The application works offline-first. This means data is stored locally directly on the device.';

  @override
  String get helpStorage2 => 'Changes to clients, measurements, notes, performance and plans are not automatically sent to an external server.';

  @override
  String get helpStorage3 => 'If you uninstall, reset or lose the device without exporting data, you may lose saved information.';

  @override
  String get helpExport1 => 'Each client can be exported for backup or transfer.';

  @override
  String get helpExport2 => 'The export contains JSON, PDF report, CSV files and a manifest.';

  @override
  String get helpExport3 => 'It is recommended to export regularly, especially before major changes or before resetting the app.';

  @override
  String get helpImport1 => 'Clients can be imported from JSON or from an archive folder.';

  @override
  String get helpImport2 => 'If a client with the same ID already exists, the app creates a new safe ID to avoid conflicts.';

  @override
  String get helpImport3 => 'After import, we recommend checking the client details and verifying that all data is correct.';

  @override
  String get helpReset1 => 'Factory reset permanently deletes all locally stored app data.';

  @override
  String get helpReset2 => 'Clients, notes, inbody records, circumferences, client details and internal ID counters are deleted.';

  @override
  String get helpReset3 => 'Before resetting, always export important clients first.';

  @override
  String get firstMeal => 'First meal';

  @override
  String get lastMeal => 'Last meal';

  @override
  String get ketoShoppingListTitle => 'My keto shopping list';

  @override
  String get fastingShoppingListTitle => 'My fasting shopping list';

  @override
  String get shoppingListTitle => 'My shopping list';

  @override
  String get generatedBySmartCoach => 'Generated by Chytrý trenér';

  @override
  String get ketoShopping => 'Keto Shopping';

  @override
  String get fastingShopping => 'Fasting Shopping';

  @override
  String get weeklyShopping => 'Weekly Shopping';

  @override
  String get emptyShoppingList => 'Shopping list is empty.';

  @override
  String get shoppingListDescription => 'The list contains all ingredients from all days and automatically merges duplicates.';

  @override
  String get sameMacrosDaily => 'The same macro structure every day.';

  @override
  String get carbCyclingDescriptionShort => 'Carbohydrates cycle throughout the week.';

  @override
  String get ketoLowCarbNote => 'Keto mode with low carbohydrate intake and full shopping list.';

  @override
  String get piecesEggs => 'pcs eggs';

  @override
  String get pieces => 'pcs';

  @override
  String get lightSnack => 'Light snack';

  @override
  String get calculation => 'Calculation';

  @override
  String get oatmealProtein => 'Oatmeal with protein';

  @override
  String get breakfastDescription => 'Oats, protein and fruit.';

  @override
  String get goal_strength => 'Strength';

  @override
  String get goal_strength_rationale => 'Surplus + carbohydrates for CNS support, protein 2.0 g/kg.';

  @override
  String get goal_physique => 'Physique';

  @override
  String get goal_physique_rationale => 'Phase-based periodization, protein 2.2 g/kg.';

  @override
  String get goal_weight_gain_support => 'Weight Gain (Support)';

  @override
  String get goal_weight_gain_support_rationale => 'Moderate surplus without extreme recommendations.';

  @override
  String get goal_weight_loss => 'Weight Loss';

  @override
  String get goal_weight_loss_rationale => 'Calorie deficit + high protein to preserve muscle mass.';

  @override
  String get goal_endurance => 'Endurance';

  @override
  String get goal_endurance_rationale => 'Carbohydrate-focused nutrition, protein 1.6–1.8 g/kg.';

  @override
  String get phase_gaining_physique => 'Bulking phase: moderate surplus while keeping fats controlled.';

  @override
  String get phase_gaining_strength => 'Strength bulking: surplus + carbohydrates for performance.';

  @override
  String get phase_gaining_default => 'Moderate surplus / slightly above maintenance.';

  @override
  String get phase_cutting_endurance => 'Endurance cutting: mild reduction while maintaining carbohydrates.';

  @override
  String get phase_cutting_default => '15–20% deficit, higher protein, fats monitored carefully.';

  @override
  String get phase_peaking => 'Peak conditioning: higher protein with controlled carbohydrates.';

  @override
  String get phase_maintenance => 'Maintenance: stabilize performance and recovery.';

  @override
  String get reason_summer_shape => 'Summer goal: physique and visual appearance prioritized.';

  @override
  String get reason_competition => 'Competition preparation: precise nutrition and conditioning.';

  @override
  String get reason_support => 'Support mode: no aggressive deficits or extreme recommendations.';

  @override
  String get accelerated_mode => 'Accelerated mode: larger deficit with increased protein intake.';

  @override
  String get competition_peaking => 'Competition peak phase: maximum protein emphasis.';

  @override
  String get breakfast => 'Breakfast';

  @override
  String get snack => 'Snack';

  @override
  String get snack2 => 'Snack 2';

  @override
  String get lunch => 'Lunch';

  @override
  String get dinner => 'Dinner';

  @override
  String get selectDate => 'Select date';

  @override
  String get copyYesterday => 'Copy yesterday';

  @override
  String get resetDay => 'Reset day';

  @override
  String get yesterdayCopied => 'Yesterday\'s food copied';

  @override
  String get addFood => 'Add Food';

  @override
  String get remainingForToday => 'Remaining for today';

  @override
  String get helpWithRemainingFood => 'Help me with remaining food';

  @override
  String get recalculateRemainingDay => 'Recalculate remaining day';

  @override
  String get foods => 'Foods';

  @override
  String get noFoodYet => 'There is no food yet. Add your first meal.';

  @override
  String get allSlotsAdded => 'Added to all meals of the day';

  @override
  String get manualOverrideHint => 'Tip: when you edit something manually, the solver will no longer recalculate it.';

  @override
  String get noMealsAvailable => 'No meals available. Add more meals to the database.';

  @override
  String get remaining => 'Remaining';

  @override
  String get exceeded => 'Exceeded';

  @override
  String get eggs => 'Eggs';

  @override
  String get eggsPieces => 'pcs eggs';

  @override
  String get piecesUnit => 'pcs';

  @override
  String get vegetables => 'Vegetables';

  @override
  String get oliveOil => 'Olive oil';

  @override
  String get scrambledEggsWithVegetables => 'Scrambled eggs with vegetables';

  @override
  String get andLightFatSource => 'and a light fat source';

  @override
  String get oatmealWithProtein => 'Oatmeal with protein';

  @override
  String get complexCarbsForDayStart => 'Complex carbohydrates to start the day.';

  @override
  String get oats => 'Oats';

  @override
  String get wheyProtein => 'Whey protein';

  @override
  String get blueberries => 'Blueberries';

  @override
  String get skyrWithFruit => 'Skyr with fruit';

  @override
  String get highProteinSnack => 'Light snack with high protein content.';

  @override
  String get hamAndCheese => 'Ham and cheese';

  @override
  String get lowCarbSnack => 'Low-carb snack.';

  @override
  String get skyr => 'Skyr';

  @override
  String get banana => 'Banana';

  @override
  String get ham => 'Ham';

  @override
  String get gouda => 'Gouda';

  @override
  String get beef => 'Beef';

  @override
  String get turkeyBreast => 'Turkey breast';

  @override
  String get chickenBreast => 'Chicken breast';

  @override
  String get whiteRiceDry => 'White rice (dry)';

  @override
  String get rice => 'Rice';

  @override
  String get skyrBanana => 'Skyr with banana';

  @override
  String get quickSnackDescription => 'Quick snack for protein and carbohydrate replenishment.';

  @override
  String get noGoalMaintenanceMode => 'No goal - maintenance mode';

  @override
  String get cutPhaseAccelerated => 'Cutting phase (accelerated)';

  @override
  String get cutPhase => 'Cutting phase';

  @override
  String get buildPhaseAccelerated => 'Bulking phase (accelerated)';

  @override
  String get buildPhase => 'Bulking phase';

  @override
  String get maintenancePhase => 'Maintenance phase';

  @override
  String get strengthPhase => 'Strength phase';

  @override
  String get weightLossGoalAccelerated => 'Weight loss goal (accelerated)';

  @override
  String get weightGainGoalAccelerated => 'Weight gain goal (accelerated)';

  @override
  String get weightGainGoal => 'Weight gain goal';

  @override
  String get chickenRice => 'Chicken breast with rice';

  @override
  String get mainMealDescription => 'Complex main meal with side dish and vegetables.';

  @override
  String get helpWarning1 => 'This app currently relies on local device storage.';

  @override
  String get helpWarning2 => 'Without regular backups, device loss, uninstalling the app or factory reset may result in data loss.';

  @override
  String get helpWarning3 => 'We recommend regularly exporting your most important clients.';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get age => 'Age';

  @override
  String get heightCm => 'Height (cm)';

  @override
  String get recoveryModeSupport => 'Recovery / Eating Disorder Support';

  @override
  String get recoveryModeDescription => 'Enables safety limits (no aggressive fat loss)';

  @override
  String get saveClient => 'Save Client';

  @override
  String failedToSaveClient(Object error) {
    return 'Failed to save client: $error';
  }

  @override
  String get addInbodyMeasurement => 'Add InBody Measurement';

  @override
  String get basicData => 'Basic Data';

  @override
  String get change => 'Change';

  @override
  String get waterPreviewHint => 'Tip: after entering weight and water you will also see the estimated body water percentage.';

  @override
  String get yourFastingMealPlan => 'Your fasting meal plan';

  @override
  String get skeletalMuscleMass => 'SMM – skeletal muscle mass (kg)';

  @override
  String get weeklyMealPlan => 'Weekly meal plan';

  @override
  String get saveTemplate => 'Save template';

  @override
  String get bodyFat => 'Body Fat';

  @override
  String get bodyFatDescription => 'Fill in either kg or %. The second value will be calculated automatically.';

  @override
  String get fatKg => 'Fat (kg)';

  @override
  String get fatPercent => 'Fat (%)';

  @override
  String get totalBodyWater => 'Total Body Water (kg)';

  @override
  String get optionalValues => 'Optional (if available on printout)';

  @override
  String get fatFreeMass => 'Fat Free Mass (kg)';

  @override
  String get waistHipRatio => 'Waist/Hip Ratio (WHR)';

  @override
  String get basalMetabolism => 'Basal Metabolism (kcal)';

  @override
  String get checkDiagnosticValues => 'Check the values. Weight, SMM and water must be filled in. Body fat can be entered either in kg or in %.';

  @override
  String get addInbody => 'Add InBody';

  @override
  String get fillAllInbodyValues => 'Please fill in all values according to the InBody report.';

  @override
  String get clientHeight => 'Client Height';

  @override
  String get bodyComposition => 'Body Composition';

  @override
  String get muscleMass => 'SMM – Muscle Mass (kg)';

  @override
  String get bodyFatMass => 'Body Fat Mass (kg)';

  @override
  String get bodyWater => 'Total Body Water (kg/l)';

  @override
  String get leanBodyMass => 'Lean Body Mass (kg)';

  @override
  String get obesityDiagnosis => 'Obesity Diagnosis';

  @override
  String get bodyFatPercentage => 'Body Fat Percentage';

  @override
  String get segmentalMuscles => 'Segmental Muscles (kg)';

  @override
  String get leftArmMuscle => 'Left Arm – Muscle (kg)';

  @override
  String get rightArmMuscle => 'Right Arm – Muscle (kg)';

  @override
  String get trunkMuscle => 'Trunk – Muscle (kg)';

  @override
  String get leftLegMuscle => 'Left Leg – Muscle (kg)';

  @override
  String get rightLegMuscle => 'Right Leg – Muscle (kg)';

  @override
  String get segmentalFat => 'Segmental Fat (kg)';

  @override
  String get leftArmFat => 'Left Arm – Fat (kg)';

  @override
  String get rightArmFat => 'Right Arm – Fat (kg)';

  @override
  String get trunkFat => 'Trunk – Fat (kg)';

  @override
  String get leftLegFat => 'Left Leg – Fat (kg)';

  @override
  String get rightLegFat => 'Right Leg – Fat (kg)';

  @override
  String get visceralFat => 'Visceral Fat (Level)';

  @override
  String get inbodyScore => 'InBody Score';

  @override
  String get saveInbody => 'Save InBody';

  @override
  String get importRestoreClient => 'Import / Restore Client';

  @override
  String get chooseHowToRestoreOrImportClient => 'Choose how to restore or import the client.';

  @override
  String get close => 'Close';

  @override
  String get insertJsonManually => 'Insert JSON manually';

  @override
  String get selectJsonFile => 'Select JSON file';

  @override
  String get restoreFromArchiveFolder => 'Restore from archive folder';

  @override
  String get selectJson => 'Select JSON';

  @override
  String get clientImportedFromFile => 'Client imported from file';

  @override
  String get fileImportFailed => 'File import failed';

  @override
  String get selectArchiveFolder => 'Select archive folder';

  @override
  String get clientRestoredFromArchive => 'Client restored from archive';

  @override
  String get archiveRestoreFailed => 'Archive restore failed';

  @override
  String get exportFolderNotConfigured => 'Export folder is not configured';

  @override
  String get folderOpenFailed => 'Failed to open folder';

  @override
  String get archiveAndDeleteClient => 'Archive and delete client';

  @override
  String get deleteClient => 'Delete client';

  @override
  String get archiveAndDeleteClientConfirm => 'Are you sure you want to archive and delete this client?';

  @override
  String get deleteClientConfirm => 'Are you sure you want to delete this client?';

  @override
  String get archiveAndDelete => 'Archive & Delete';

  @override
  String get delete => 'Delete';

  @override
  String get clientArchivedAndDeleted => 'Client archived and deleted';

  @override
  String get clientDeleted => 'Client deleted';

  @override
  String get clientDeleteError => 'Failed to delete client';

  @override
  String get clientAnalysis => 'Client analysis';

  @override
  String get openExportFolder => 'Open export folder';

  @override
  String get exportClient => 'Export client';

  @override
  String get exportError => 'Export failed';

  @override
  String get editClient => 'Edit client';

  @override
  String get editClientCard => 'Edit client card';

  @override
  String get addNote => 'Add note';

  @override
  String get copyEmail => 'Copy e-mail';

  @override
  String get emailCopied => 'E-mail copied';

  @override
  String get registered => 'Registered';

  @override
  String get years => 'years';

  @override
  String get weight => 'Weight';

  @override
  String get lastWorkout => 'Last workout';

  @override
  String get completedLast7Days => 'Completed in last 7 days';

  @override
  String get days => 'days';

  @override
  String get compliance7Days => '7-day compliance';

  @override
  String get recoveryMode => 'Recovery mode active';

  @override
  String get clientInactive7Days => 'Client inactive for more than 7 days';

  @override
  String get today => 'Today';

  @override
  String get completedToday => 'Workout completed today';

  @override
  String get todayWorkoutSaved => 'Today\'s workout saved';

  @override
  String get tapToSaveTodayWorkout => 'Tap to save today\'s workout';

  @override
  String get statusCheck => 'Status check';

  @override
  String get sentComparisonPhotos => 'Sent comparison photos';

  @override
  String get followsDiet => 'Follows diet';

  @override
  String get respondedToMessage => 'Responded to message';

  @override
  String get photoRequestPlaceholder => 'Photo reminder placeholder';

  @override
  String get dietCheckPlaceholder => 'Diet check placeholder';

  @override
  String get responseRequestPlaceholder => 'Response reminder placeholder';

  @override
  String get clientTrainingPlans => 'Client training plans';

  @override
  String get clientHasNoPlans => 'Client has no plans';

  @override
  String get planCount => 'Plan count';

  @override
  String get newPlan => 'New plan';

  @override
  String get createFirstPlanHint => 'Create the first training plan';

  @override
  String get coachData => 'Coach data';

  @override
  String get activity => 'Activity';

  @override
  String get injuries => 'Injuries';

  @override
  String get allergiesIntolerances => 'Allergies / intolerances';

  @override
  String get inbody => 'InBody';

  @override
  String get dataHiddenRecoveryMode => 'Data hidden in recovery mode';

  @override
  String get noMeasurements => 'No measurements';

  @override
  String get proteinShort => 'P';

  @override
  String get carbsShort => 'C';

  @override
  String get fatShort => 'F';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get shoppingList => 'Shopping List';

  @override
  String get shoppingListEmpty => 'Shopping list is empty.';

  @override
  String get trainerRecommendation => 'Trainer Recommendation';

  @override
  String get followPlanFor4Weeks => 'Follow the plan for 4 weeks.';

  @override
  String get nextCheckAndWeight => 'Next check and weighing in 1 month';

  @override
  String get ketoMealPlan => 'Keto Meal Plan';

  @override
  String get fastingMealPlan => 'Fasting Meal Plan';

  @override
  String get linearMealPlan => 'Linear Meal Plan';

  @override
  String get mealPlan => 'Meal Plan';

  @override
  String get muscles => 'Muscles';

  @override
  String get automaticInterpretation => 'Automatic interpretation';

  @override
  String get changeFromLastTime => 'Change since last measurement';

  @override
  String get hiddenRecoveryMode => 'Hidden in recovery mode';

  @override
  String get noRecords => 'No records';

  @override
  String get addCircumferences => 'Add circumferences';

  @override
  String get coachNotes => 'Coach notes';

  @override
  String get updated => 'Updated';

  @override
  String get edit => 'Edit';

  @override
  String get active => 'Active';

  @override
  String get dayCount => 'Day count';

  @override
  String get created => 'Created';

  @override
  String get setAsActive => 'Set as active';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get rename => 'Rename';

  @override
  String get copy => 'Copy';

  @override
  String get newTrainingPlan => 'New training plan';

  @override
  String get planName => 'Plan name';

  @override
  String get planNameHint => 'e.g. Push Pull Legs';

  @override
  String get create => 'Create';

  @override
  String get renamePlan => 'Rename plan';

  @override
  String get newNote => 'New note';

  @override
  String get editNote => 'Edit note';

  @override
  String get importClientFromJson => 'Import client from JSON';

  @override
  String get pasteExportedJson => 'Paste exported JSON';

  @override
  String get importLabel => 'Import';

  @override
  String get clientImportedSuccessfully => 'Client imported successfully';

  @override
  String get importFailed => 'Import failed';

  @override
  String get checkRequiredFields => 'Check required fields';

  @override
  String get recoverySupport => 'Recovery support';

  @override
  String get emailHint => 'e.g. client@email.com';

  @override
  String get clientBasicInfoUpdated => 'Client basic information updated';

  @override
  String get noClientsWithEmail => 'No client has an email filled in yet.';

  @override
  String get emailsCopied => 'Emails have been copied to clipboard.';

  @override
  String get pdfExportOpened => 'PDF export was opened for printing / saving.';

  @override
  String get importPreview => 'Preview Before Import';

  @override
  String get cancel => 'Cancel';

  @override
  String get noInbodyDataInPeriod => 'There is no InBody data in this period.';

  @override
  String get inbodyBodyComposition => 'InBody / Body Composition';

  @override
  String get noCircumferencesInPeriod => 'There are no circumferences in this period.';

  @override
  String get noCircumferenceMeasurementsYet => 'There are no circumference measurements yet.';

  @override
  String get failedToSaveChanges => 'Failed to save changes';

  @override
  String get editBasicInformation => 'Edit Basic Information';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get archiveCompleted => 'Archive completed';

  @override
  String get clientArchiveSuccessfullyCreated => 'Client archive has been successfully created.';

  @override
  String get destinationFolder => 'Destination folder';

  @override
  String get createdFiles => 'Created files';

  @override
  String get currentJson => 'Current JSON';

  @override
  String get snapshot => 'Snapshot';

  @override
  String get pdfReport => 'PDF report';

  @override
  String get manifest => 'Manifest';

  @override
  String get inbodyCsv => 'InBody CSV';

  @override
  String get circumferenceCsv => 'Circumference CSV';

  @override
  String get performancesCsv => 'Performances CSV';

  @override
  String get reportPeriod => 'Report period';

  @override
  String get openPdf => 'Open PDF';

  @override
  String get failedToOpenFolder => 'Failed to open folder';

  @override
  String get openFolder => 'Open folder';

  @override
  String get name => 'Name';

  @override
  String get height => 'Height';

  @override
  String get circumferences => 'Circumferences';

  @override
  String get request => 'Request';

  @override
  String get archiveHasNoClients => 'The archive does not contain any clients yet.';

  @override
  String get noActiveClientsYet => 'You don\'t have any active clients yet.';

  @override
  String get archiveCsvImport => 'CSV Archive Import';

  @override
  String get copyEmails => 'Copy emails';

  @override
  String get searchByNameEmailOrId => 'Search by name, email or ID';

  @override
  String fileImportFailedWithError(Object error) {
    return 'File import failed: $error';
  }

  @override
  String clientImported(Object name) {
    return '$name imported successfully.';
  }

  @override
  String clientRestored(Object name) {
    return '$name restored successfully.';
  }

  @override
  String clientMovedToArchive(Object name) {
    return '$name moved to archive.';
  }

  @override
  String archiveCsvImportFailed(Object error) {
    return 'CSV archive import failed: $error';
  }

  @override
  String get selectCsv => 'Select CSV';

  @override
  String get noArchivedClientsImported => 'No new archived clients were imported from CSV.';

  @override
  String get selected => 'Selected';

  @override
  String get linkWithCoach => 'Link with coach';

  @override
  String get searchClientByName => 'Search your client by name';

  @override
  String get startTypingName => 'Start typing the name…';

  @override
  String get continueWithoutCoach => 'Continue without coach';

  @override
  String get linkAndContinue => 'Link and continue';

  @override
  String get loadingClientsError => 'Error while loading clients';

  @override
  String archivedClientsImported(int count) {
    return '$count archived clients imported.';
  }

  @override
  String get strengthGoal => 'Strength';

  @override
  String get physiqueGoal => 'Physique';

  @override
  String get weightLossGoal => 'Weight Loss';

  @override
  String get enduranceGoal => 'Endurance';

  @override
  String get weightGainSupportGoal => 'Weight Gain / Recovery Support';

  @override
  String get selectFolder => 'Select Folder';

  @override
  String get cloudBackup => 'Cloud Backup';

  @override
  String get cloudBackupDescription => 'Manually uploads or downloads data between devices.';

  @override
  String get backupToCloud => 'Backup to Cloud';

  @override
  String get restoreFromCloud => 'Restore from Cloud';

  @override
  String get cloudBackupFinished => 'Cloud backup completed. Uploaded sections';

  @override
  String get cloudBackupFailed => 'Cloud backup failed';

  @override
  String get cloudRestoreFinished => 'Cloud restore completed. Loaded sections';

  @override
  String get cloudRestoreFailed => 'Cloud restore failed';

  @override
  String get profile => 'Profile';

  @override
  String get loadingProfileFromCoach => 'Loading profile from coach…';

  @override
  String get doYouHaveCoach => 'Do you have a coach?';

  @override
  String get searchInCoachClients => 'Find yourself in the client list and we will automatically load your profile.';

  @override
  String get searchClientPlaceholder => 'Type client name or ID…';

  @override
  String get showMyDietPlan => 'Show my diet plan';

  @override
  String get enterValidAge => 'Enter a valid age (10–100 years)';

  @override
  String get startWithBasics => 'Let\'s Start With Basics';

  @override
  String get howOldAreYou => 'How old are you?';

  @override
  String get enterAge => 'Enter age';

  @override
  String get continueText => 'Continue';

  @override
  String get bodyMetrics => 'Body Metrics';

  @override
  String get enterValidHeight => 'Enter valid height (120–230 cm)';

  @override
  String get enterValidWeightRange => 'Enter valid weight (30–300 kg)';

  @override
  String get heightExample => 'e.g. 180';

  @override
  String get weightExample => 'e.g. 85';

  @override
  String get welcomeCoachApp => 'Welcome to the coach application';

  @override
  String get coachSetupDesktopDescription => 'Now we will set up your name, security PIN and most importantly the folder where client archives will be stored.';

  @override
  String get securityPin => 'Security PIN';

  @override
  String get enterPinAgain => 'Enter the PIN again';

  @override
  String get selectClientArchiveFolder => 'Select a folder for client archives';

  @override
  String get selectCustomFolder => 'Select custom folder';

  @override
  String get useDocumentsClients => 'Use Documents/Clients';

  @override
  String get iosFolderInfo => 'On iPhone, Apple does not allow selecting arbitrary folders like on desktop computers. Archives will therefore be stored in the internal Clients folder of the application.';

  @override
  String get desktopFolderRecommendation => 'Recommendation: choose your own archive folder, ideally inside a Google Drive or OneDrive synchronized folder. This way your client archives will also be available outside this computer.';

  @override
  String get finishSetup => 'Finish setup';

  @override
  String get coachSetupSaved => 'Coach setup has been saved.';

  @override
  String get coachSetup => 'Coach Setup';

  @override
  String get loggedAccount => 'Signed in account';

  @override
  String get firstNameExample => 'e.g. John';

  @override
  String get enter4DigitPin => 'Enter 4 digits';

  @override
  String get exportClientFolder => 'Client export folder';

  @override
  String get useAppFolder => 'Use app folder';

  @override
  String get useClientsFolder => 'Use Clients folder';

  @override
  String get enterFirstName => 'Enter your first name.';

  @override
  String get firstNameTooShort => 'First name is too short.';

  @override
  String get enterSecurityPin => 'Enter a 4-digit security PIN.';

  @override
  String get pinMustHave4Digits => 'PIN must contain exactly 4 digits.';

  @override
  String get confirmSecurityPin => 'Confirm the security PIN.';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get coachSetupIosDescription => 'Now we will set up your name, security PIN and internal Clients folder for client archives.';

  @override
  String nextTimeWeight(Object weight, Object delta) {
    return 'Next time use $weight kg ($delta)';
  }

  @override
  String get dietPlanSelection => 'Diet Plan Selection';

  @override
  String get savedMealPlans => 'Saved Meal Plans';

  @override
  String get savedMealPlansDescription => 'Load your own complete weekly or monthly templates and reuse them anytime.';

  @override
  String get openMealDatabase => 'Open meal plan database';

  @override
  String get createCustomMealPlan => 'Create Custom Meal Plan';

  @override
  String get createCustomMealPlanDescription => 'Manually build a daily meal plan from prepared meals and save it as your own template.';

  @override
  String get openDailyEditor => 'Open daily editor';

  @override
  String get foodComboLibrary => 'Food Combo Library';

  @override
  String get foodComboLibraryDescription => 'Browse, duplicate, edit and delete your saved food combos.';

  @override
  String get openFoodComboLibrary => 'Open ready meal library';

  @override
  String get createFoodCombo => 'Create Food Combo';

  @override
  String get createFoodComboDescription => 'Build your own meal from individual foods and save it into the combo library.';

  @override
  String get openFoodComboEditor => 'Open ready meal editor';

  @override
  String get weekBuilder => 'Build Week From Daily Templates';

  @override
  String get weekBuilderDescription => 'Choose a daily template for each day and create a complete weekly meal plan.';

  @override
  String get openWeeklyBuilder => 'Open weekly template';

  @override
  String get monthBuilder => 'Build Month From Weeks';

  @override
  String get monthBuilderDescription => 'Choose 4 saved weekly meal plans and combine them into a complete monthly plan.';

  @override
  String get openMonthlyBuilder => 'Open monthly template';

  @override
  String get linearPlanTitle => 'Constant Intake (Linear)';

  @override
  String get linearPlanDescription => 'Same macros every day. The easiest path for stable muscle growth.';

  @override
  String get activateAndOpenPlan => 'Activate and open plan';

  @override
  String get carbCyclingTitle => 'Carb Cycling';

  @override
  String get carbCyclingDescription => 'Carbohydrate cycling for fat loss.';

  @override
  String get startAnalysisAndCycling => 'Start analysis and carb cycling';

  @override
  String get ketoDietTitle => 'Keto Diet';

  @override
  String get ketoDietDescription => 'High fat intake with minimal carbohydrates.';

  @override
  String get selectKetoAndPreferences => 'Select keto and adjust preferences';

  @override
  String get fastingTitle => 'Intermittent Fasting';

  @override
  String get fastingDescription => 'Time-restricted eating window. Helps improve recovery.';

  @override
  String get setMealTimes => 'Set meal times';

  @override
  String get enterMealPlan => 'Open meal plan';

  @override
  String get mainSquatExercise => 'Main squat exercise';

  @override
  String get mainPressExercise => 'Main press exercise';

  @override
  String get mainHingeExercise => 'Main hinge exercise';

  @override
  String get chestPress => 'Chest press';

  @override
  String get verticalPull => 'Vertical pull';

  @override
  String get horizontalPull => 'Horizontal pull';

  @override
  String get quads => 'Quadriceps';

  @override
  String get hamstrings => 'Hamstrings';

  @override
  String get glutes => 'Glutes';

  @override
  String get shoulders => 'Shoulders';

  @override
  String get triceps => 'Triceps';

  @override
  String get core => 'Core';

  @override
  String get conditioning => 'Conditioning';

  @override
  String get squatPattern => 'Squat pattern';

  @override
  String get hingePattern => 'Hip hinge pattern';

  @override
  String get pressPattern => 'Press pattern';

  @override
  String get verticalPullPattern => 'Vertical pull';

  @override
  String get horizontalRowPattern => 'Horizontal row';

  @override
  String get corePattern => 'Core';

  @override
  String get locomotionPattern => 'Locomotion / conditioning';

  @override
  String get strength => 'Strength';

  @override
  String get hypertrophy => 'Hypertrophy';

  @override
  String get endurance => 'Endurance';

  @override
  String get trainingQuestionnaireMissing => 'Training questionnaire is missing.';

  @override
  String get exerciseSelectionTest => 'Exercise selection (test)';

  @override
  String get movementType => 'Movement type';

  @override
  String get focus => 'Focus';

  @override
  String get perMuscleWeekly => '/ muscle weekly';

  @override
  String get competitionModeNote => 'Competition mode – performance/conditioning priority.';

  @override
  String get weightLossStrengthNote => 'During calorie deficit we maintain strength, not chase PRs.';

  @override
  String get peakModeShortNote => 'Peak: technique > volume, longer rests.';

  @override
  String get generalTraining => 'General training';

  @override
  String get setupGoalAndDateForPeriodization => 'Set your goal and target date first to enable periodization.';

  @override
  String get trainingCompetitionMode => 'Competition mode – performance and physique are the priority.';

  @override
  String get trainingDeficitStrength => 'During a calorie deficit we maintain strength instead of chasing PRs.';

  @override
  String get trainingPeakMode => 'Peak phase: technique over volume, longer rest periods.';

  @override
  String get trainingGeneralTitle => 'General Training';

  @override
  String get trainingGeneralNote => 'Set your goal and target date first to enable periodization.';

  @override
  String get trainingSplitAuto => 'Automatic';

  @override
  String get trainingSplitFullbody => 'Full Body 3×';

  @override
  String get trainingSplitUpperLower => 'Upper / Lower 4×';

  @override
  String get trainingSplitPPL => 'Push Pull Legs 6×';

  @override
  String get trainingSplitStrength3day => 'Strength 3 Days';

  @override
  String get coachInsightVeryLowFat => 'Very low body fat – competition or short-term peak condition.';

  @override
  String get coachInsightExcellentShape => 'Excellent condition.';

  @override
  String get coachInsightHealthyAthletic => 'Healthy athletic condition.';

  @override
  String get coachInsightFatReduction => 'There is room for fat reduction.';

  @override
  String get coachInsightHighFat => 'High body fat percentage – fat loss should be the priority.';

  @override
  String get coachInsightVeryLean => 'Body fat is already very low – focus should shift toward performance and muscle growth.';

  @override
  String get coachInsightWaterRetention => 'The body may be retaining extra water (stress, sodium, recovery).';

  @override
  String get coachInsightLowWater => 'Low water percentage – focus on hydration and recovery.';

  @override
  String get coachInsightFatDown => 'Body fat is decreasing – keep going.';

  @override
  String get coachInsightFatUp => 'Body fat is increasing – nutrition adjustments may be needed.';

  @override
  String get coachInsightMuscleUp => 'Muscle mass is increasing – training is working.';

  @override
  String get coachInsightMuscleDown => 'Muscle mass is decreasing – increase protein intake or reduce the calorie deficit.';

  @override
  String get fullbody3x => 'Fullbody 3×';

  @override
  String get upperLower4x => 'Upper / Lower 4×';

  @override
  String get pushPullLegs6x => 'Push Pull Legs 6×';

  @override
  String get strength3days => 'Strength 3 days';

  @override
  String get prescription => 'Prescription';

  @override
  String get selectedExercise => 'Selected exercise';

  @override
  String get noExerciseSelected => 'Selected exercise: (not selected yet)';

  @override
  String get slotDebugDescription => 'Test screen: slot = role + movement type + focus + sets/reps/RIR. Tap slot and choose exercise.';

  @override
  String get fastingLengthQuestion => 'How long fasting period do you prefer?';

  @override
  String get fastingWindowQuestion => 'When does your eating window start?';

  @override
  String get setGoalFirst => 'Set your goal first.';

  @override
  String get trainingSetupNeeded => 'Before generating training, I need a short setup.';

  @override
  String get repetitions => 'Repetitions';

  @override
  String get weeklySetsPerMuscle => 'Weekly sets per muscle';

  @override
  String get rirReserve => 'Reserve (RIR)';

  @override
  String get buildCustomTraining => 'Build custom training';

  @override
  String get deloadRecommendation => 'Recommendation: deload — if you feel fatigued, reduce volume by 30–40% for 1 week.';

  @override
  String get peakModeDescription => 'Peak mode: technique > volume, longer rests, low reps.';

  @override
  String get weeklyPlan => 'Weekly plan';

  @override
  String get todayTraining => 'Today\'s training';

  @override
  String get changeTrainingSplit => 'Change training split';

  @override
  String get note => 'Note';

  @override
  String get trainingPlanDescription => 'The plan is generated automatically based on your goal and time.\nCustom plans are intended for clients with specific needs, limitations, or individual schedules.';

  @override
  String get fastingBeginner => 'Beginner (12:12)';

  @override
  String get fastingIntermediate => 'Intermediate (14:10)';

  @override
  String get fastingClassic => 'Classic (16:8)';

  @override
  String get fastingAdvanced => 'Advanced (18:6)';

  @override
  String get fastingWarrior => 'Warrior (20:4)';

  @override
  String get newClient => 'New Client';

  @override
  String get error => 'Error';

  @override
  String get ok => 'OK';

  @override
  String mealSuggestions(Object count) {
    return 'Suggestions for $count meals';
  }

  @override
  String approxMacros(Object protein, Object carbs, Object fat, Object calories) {
    return 'Approx macros: P $protein g | C $carbs g | F $fat g | $calories kcal';
  }

  @override
  String eatenCalories(Object calories) {
    return 'Eaten: $calories kcal';
  }

  @override
  String targetCaloriesLabel(Object calories) {
    return 'Target: $calories kcal';
  }

  @override
  String remainingGrams(Object grams) {
    return 'remaining $grams g';
  }

  @override
  String exceededGrams(Object grams) {
    return 'exceeded $grams g';
  }

  @override
  String fastingConfigured(Object hours, Object time) {
    return 'Configured $hours h fasting starting at $time';
  }

  @override
  String get ingredientsWeekTitle => 'This week we will cook with:';

  @override
  String get ingredientsExcludeTitle => 'Select ingredients you DO NOT WANT:';

  @override
  String get salmonOption => 'Salmon (I don\'t like fish)';

  @override
  String get generatePlanButton => 'Fine, generate the plan';

  @override
  String editTime(Object time) {
    return 'Edit time ($time)';
  }

  @override
  String get newBadge => 'New';

  @override
  String nextTimeKeepWeight(Object weight) {
    return 'Keep $weight kg next time';
  }

  @override
  String get pickSkippedDay => 'Skipped training day';

  @override
  String pickSkippedDayDescription(Object day) {
    return 'Last time you skipped day “$day”. Do you want to finish it today?';
  }

  @override
  String get cancelChange => 'Cancel change';

  @override
  String get continueCurrent => 'Continue current';

  @override
  String get finishSkippedDay => 'Finish skipped day';

  @override
  String get planHasNoDays => 'The plan has no days yet.';

  @override
  String get selectTrainingDay => 'Select another training day';

  @override
  String get selectTrainingDayDescription => 'The skipped day will be saved and offered later.';

  @override
  String get noExercises => 'No exercises';

  @override
  String get returnOriginalDay => 'Return original day';

  @override
  String get profileGoalRequired => 'Set profile and goal first.';

  @override
  String get trainingSetupRequired => 'Before generating today\'s training, complete the short setup.';

  @override
  String get openTrainingSetup => 'Open training setup';

  @override
  String get todayTrainingGenerationFailed => 'Failed to generate today\'s training.';

  @override
  String get changeDay => 'Change day';

  @override
  String get temporaryDifferentDay => 'A different training day is temporarily selected today.';

  @override
  String get dateLabel => 'Date';

  @override
  String get performanceSaved => 'Performance saved.';

  @override
  String get log => 'Log';

  @override
  String get customTrainingFormat => 'Format: sets × reps / time | RIR';

  @override
  String get defaultTrainingFormat => 'Format: sets × reps | RIR | kg';

  @override
  String get logPerformance => 'Log performance';

  @override
  String get setupProfileFirst => 'Set up profile first.';

  @override
  String get setupGoalFirst => 'Set your goal first.';

  @override
  String get openSetup => 'Open Setup';

  @override
  String get trainingSetupRequiredDescription => 'Before we generate your plan, please complete the short training setup.';

  @override
  String get customPlan => 'Custom Plan';

  @override
  String get selectAnotherDay => 'Select Another Day';

  @override
  String get trainingFormatCustom => 'Format: sets | reps / time | RIR';

  @override
  String get trainingFormatDefault => 'Format: sets | reps | RIR | kg';

  @override
  String get pickDifferentTrainingDay => 'Pick a different training day for today';

  @override
  String get originalDaysStaySaved => 'Original days in the plan will remain saved.';

  @override
  String get mainLift => 'Main lift';

  @override
  String get reps => 'Reps';

  @override
  String get rir => 'RIR';

  @override
  String get weightLabel => 'Weight';

  @override
  String get mealsCountQuestion => 'How many meals do you want?';

  @override
  String get howDoYouWantSuggestions => 'How do you want suggestions?';

  @override
  String get singleItemsFromBank => 'Single food items from database';

  @override
  String get completeMeals => 'Complete meals';

  @override
  String selectMealsTotal(Object count) {
    return 'Selected meals: $count';
  }

  @override
  String get selectType => 'Select type';

  @override
  String get vegan => 'Vegan';

  @override
  String get veganCategoryOnly => 'Only vegan meals';

  @override
  String get savory => 'Savory';

  @override
  String get sweet => 'Sweet';

  @override
  String get anything => 'Anything';

  @override
  String get howManyGrams => 'How many grams?';

  @override
  String get grams => 'Grams';

  @override
  String get selectActiveClientFirst => 'Select an active client first';

  @override
  String get customTraining => 'Custom Training';

  @override
  String get sharedTemplates => 'Shared Templates';

  @override
  String get noSharedTemplatesYet => 'No shared templates yet';

  @override
  String get clientPlans => 'Client Plans';

  @override
  String get noCustomPlanYet => 'No custom plan created yet';

  @override
  String get category => 'Category';

  @override
  String get planDescription => 'Plan Description';

  @override
  String get planDescriptionHint => 'For example: strength plan for bulking';

  @override
  String get planDetail => 'Plan Detail';

  @override
  String get planNotFound => 'Plan not found';

  @override
  String get description => 'Description';

  @override
  String get noDescription => 'No description';

  @override
  String get numberOfDays => 'Number of days';

  @override
  String get activateAndOpen => 'Activate and Open';

  @override
  String get shareAsTemplate => 'Share as Template';

  @override
  String get editInfo => 'Edit Info';

  @override
  String get addDay => 'Add Day';

  @override
  String get deleteWholePlan => 'Delete Whole Plan';

  @override
  String get editPlan => 'Edit Plan';

  @override
  String get reallyDeletePlan => 'Really delete the plan?';

  @override
  String get confirmDeletion => 'Confirm Deletion';

  @override
  String get deletePlanWarning => 'This action cannot be undone.';

  @override
  String get back => 'Back';

  @override
  String get deleteForever => 'Delete Forever';

  @override
  String get addTrainingDay => 'Add Training Day';

  @override
  String get dayName => 'Day Name';

  @override
  String get dayNameHint => 'For example: Push Day';

  @override
  String get add => 'Add';

  @override
  String get exercises => 'Exercises';

  @override
  String get addExercise => 'Add Exercise';

  @override
  String get deleteDay => 'Delete Day';

  @override
  String get noExercisesYet => 'No exercises yet';

  @override
  String get reallyDeleteDay => 'Really delete the day?';

  @override
  String get deleteDayWarning => 'The day will be permanently removed.';

  @override
  String get selectFromExerciseDatabase => 'Select from exercise database';

  @override
  String get enterCustomExerciseManually => 'Enter custom exercise manually';

  @override
  String get addCustomExercise => 'Add Custom Exercise';

  @override
  String get editExercise => 'Edit Exercise';

  @override
  String get deleteExerciseQuestion => 'Delete Exercise?';

  @override
  String get yesDelete => 'Yes, Delete';

  @override
  String get selectExerciseFromDatabase => 'Select Exercise from Database';

  @override
  String get noExerciseFound => 'No exercise found';

  @override
  String get enterValidGramRange => 'Enter a valid amount between 10 and 3000 g';

  @override
  String get exerciseName => 'Exercise Name';

  @override
  String get exerciseNameHint => 'Example: Side Plank';

  @override
  String get sets => 'Sets';

  @override
  String get repsOrTime => 'Reps / Time';

  @override
  String get repsOrTimeHint => 'Example: 3 min or 8–12';

  @override
  String get removeExerciseQuestion => 'Remove Exercise?';

  @override
  String get equipment => 'Equipment';

  @override
  String get completed => 'Completed';

  @override
  String noMealsInCategory(Object category) {
    return 'No meals in category $category';
  }

  @override
  String selectMeal(Object slot, Object category) {
    return 'Select meal for $slot ($category)';
  }

  @override
  String addedMeal(Object meal, Object grams) {
    return '$meal added ($grams g)';
  }

  @override
  String get planSummary => 'Plan Summary';

  @override
  String get editGrams => 'Edit grams';

  @override
  String get addAll => 'Add all';

  @override
  String exerciseCount(Object count) {
    return '$count exercises';
  }

  @override
  String waterPercentageInfo(Object value) {
    return 'Water percentage: $value%';
  }

  @override
  String confirmDeleteTemplate(Object name) {
    return 'Are you sure you want to delete template \"$name\"?';
  }

  @override
  String failedToSaveMeasurements(Object error) {
    return 'Failed to save measurements: $error';
  }

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get passwordResetEnterEmail => 'Enter your email above first.';

  @override
  String passwordResetSent(Object email) {
    return 'We sent a password reset link to $email.';
  }

  @override
  String passwordResetFailed(Object error) {
    return 'Could not send the reset email: $error';
  }

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete coach account?';

  @override
  String get deleteAccountWarning => 'This permanently deletes your account and all client data stored in the cloud. Coach data on this device will be removed too. This cannot be undone.';

  @override
  String get deleteAccountPasswordLabel => 'Confirm with your password';

  @override
  String get deleteAccountConfirm => 'Delete permanently';

  @override
  String get accountDeleted => 'Your account has been deleted.';

  @override
  String deleteAccountFailed(Object error) {
    return 'Could not delete the account: $error';
  }

  @override
  String get restrictiveDietsHidden => 'Keto and intermittent fasting are hidden for eating disorder support. Restrictive diets are not suitable here – use the linear plan or consult a professional.';

  @override
  String get dietPreferenceTitle => 'Dietary restriction';

  @override
  String get dietPreferenceHint => 'Meal plans, suggestions and meals will only offer foods that match.';

  @override
  String get dietNone => 'No restriction';

  @override
  String get dietVegetarian => 'Vegetarian';

  @override
  String get dietVegan => 'Vegan';

  @override
  String get budgetShort => 'Budget';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get helpTitle => 'Help';

  @override
  String get dangerZone => 'Irreversible actions';

  @override
  String get importExport => 'Import / export';

  @override
  String get changeMealPlanTitle => 'Change meal plan?';

  @override
  String get changeMealPlanConfirm => 'Change';

  @override
  String changeMealPlanBody(Object program) {
    return 'The program $program is active now. After the change, calories and macros across the app are recalculated for the new meal plan.';
  }

  @override
  String get myMealPlan => 'My meal plan';

  @override
  String get openMealPlan => 'Whole week';

  @override
  String get navToday => 'Today';

  @override
  String get navFood => 'Food';

  @override
  String get navTraining => 'Training';

  @override
  String get navProgress => 'Progress';

  @override
  String get navProfile => 'Profile';

  @override
  String get darkModeLabel => 'Dark mode';

  @override
  String get programsTitle => 'Programs';

  @override
  String get programsButton => 'Programs – training and meal plan';

  @override
  String get programsHint => 'Pick a program. A training plan is created and the client also gets the matching meal plan with the same date and phases.';

  @override
  String get programIncludes => 'Also includes';

  @override
  String get programDietByGoal => 'Meal plan based on the client goal';

  @override
  String get clientPlanTitle => 'Client plan';

  @override
  String get clientGoalButton => 'Goal';

  @override
  String get clientDietButton => 'Meal plan';

  @override
  String get clientTrainingButton => 'Training';

  @override
  String get clientProgramsButton => 'Programs and custom plans';

  @override
  String get clientFoodTodayButton => 'Food today';

  @override
  String get openAsClient => 'Open the whole app as this client';

  @override
  String get highBodyFatInterpretation => 'Body fat is high – the priority is fat loss (mild deficit, strength training, more activity).';

  @override
  String get mediumBodyFatInterpretation => 'Body fat is in the normal range – a cut or recomposition is appropriate.';

  @override
  String get lowBodyFatInterpretation => 'Body fat is low (athletic) – focus on building muscle, further fat loss only with care.';

  @override
  String get goodMuscleBase => 'Good muscle base.';

  @override
  String get lowMuscleMassInterpretation => 'Low muscle mass – the priority is strength training and enough protein.';

  @override
  String get benchInsertPlan => 'Insert Russian cycle – bench press (meet)';

  @override
  String get strengthDietDescription => 'Meal plan for strength prep (Russian bench cycle, powerlifting). Maintenance calories – strength grows without a surplus and body weight stays in the weight class. Protein 2.0 g/kg, fat 1.0 g/kg, the rest carbs to fuel heavy sets and recovery.';

  @override
  String get strengthActivate => 'Create Strength prep meal plan';

  @override
  String get bikiniDietDescription => 'Strict 16-week bikini fitness contest diet – same phases as the workout plan. Weight loss 0.5% (shape building) → 0.75% (cutting) → 1% of body weight per week (final cut), protein 2.2–2.4 g/kg, fat at least 0.7 g/kg, peak week at maintenance with higher carbs for full, round muscles on stage. Counted backwards from the contest date.';

  @override
  String get bikiniSelectDate => 'Set contest date and create meal plan';

  @override
  String get bikiniNoDate => 'Contest date is missing.';

  @override
  String get gluteDietDescription => 'Meal plan for the Round glutes program. Muscles do not grow in a deficit – a mild surplus of 7.5% above TDEE, protein 2.0 g/kg, fat 0.9 g/kg, the rest carbs to fuel heavy leg and glute training.';

  @override
  String get gluteActivate => 'Create Round glutes meal plan';

  @override
  String bikiniNotStarted(Object start, Object meet) {
    return 'Prep starts on $start (16 weeks before the contest on $meet). Until then the regular goal-based targets apply.';
  }

  @override
  String bikiniFinished(Object meet) {
    return 'The contest ($meet) is over – the regular goal-based targets apply.';
  }

  @override
  String get gluteTitle => 'Round glutes';

  @override
  String get gluteInsertPlan => 'Insert Round Glutes plan';

  @override
  String get bikiniTitle => 'Bikini fitness';

  @override
  String get bikiniInsertPlan => 'Insert contest prep – bikini fitness';

  @override
  String get hollywoodTitle => 'Hollywood training';

  @override
  String get hollywoodDescription => 'A strict 12-week physique prep for a film or photo shoot – the way actors prepare for roles. Weight loss ramps up 0.5 → 0.75 → 1% of body weight per week, protein 2.2–2.4 g/kg, shoot week at maintenance with higher carbs (muscles look full). Counted backwards from the shoot date, same as the Hollywood training workout plan.';

  @override
  String get hollywoodSelectDate => 'Set shoot date and create meal plan';

  @override
  String get hollywoodShootDate => 'Shoot date';

  @override
  String get hollywoodNoDate => 'Shoot date is missing.';

  @override
  String get hollywoodInsertPlan => 'Insert Hollywood training – shoot prep';

  @override
  String hollywoodNotStarted(Object start, Object shoot) {
    return 'Prep starts on $start (12 weeks before the shoot on $shoot). Until then the regular goal-based targets apply.';
  }

  @override
  String hollywoodFinished(Object shoot) {
    return 'The shoot ($shoot) is over – the regular goal-based targets apply.';
  }

  @override
  String get budgetMealsTitle => 'Budget meal plan';

  @override
  String get budgetMealsHint => 'Cheap everyday ingredients (eggs, quark, chicken thighs, legumes, potatoes, rice…). Dinner is cooked together with lunch, only the portion differs.';

  @override
  String get addToDay => 'Add to day';

  @override
  String remainderCoverage(Object p, Object c, Object f, Object sp, Object sc, Object sf) {
    return 'Remaining: P $p | C $c | F $f g · suggestions cover: P $sp | C $sc | F $sf g';
  }
}
