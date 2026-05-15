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
  /// **'Regular user = onboarding + AI plan.\nCoach mode = client management.'**
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

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

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

  /// No description provided for @folderPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select folder: {error}'**
  String folderPickFailed(Object error);

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

  /// No description provided for @waist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get waist;

  /// No description provided for @chest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get chest;

  /// No description provided for @biceps.
  ///
  /// In en, this message translates to:
  /// **'Biceps'**
  String get biceps;

  /// No description provided for @thigh.
  ///
  /// In en, this message translates to:
  /// **'Thigh'**
  String get thigh;

  /// No description provided for @neck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get neck;
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
