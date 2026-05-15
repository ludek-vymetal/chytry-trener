// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get dashboard => 'Dashboard';

  @override
  String get addClient => 'Přidat klienta';

  @override
  String get todayFood => 'Dnešní jídlo';

  @override
  String get trainingMode => 'Tréninkový režim';

  @override
  String get changeGoal => 'Změnit cíl';

  @override
  String get retry => 'Zkusit znovu';

  @override
  String get enterAllNumbers => 'Zadej prosím všechna čísla (používej tečku místo čárky)';

  @override
  String get addNewCircumferences => 'Zadat nové obvody';

  @override
  String get fitnessApp => 'Fitness Aplikace';

  @override
  String get userMode => 'Uživatelský mód';

  @override
  String get coachMode => 'Trenérský mód';

  @override
  String get switchToThisProfile => 'PŘEPNOUT NA TENTO PROFIL';

  @override
  String get profileActivatedUserMode => 'Profil aktivován. Režim: Uživatel.';

  @override
  String get appName => 'Chytrý trenér';

  @override
  String get exitApp => 'Ukončit aplikaci';

  @override
  String get subscriptionError => 'Chyba předplatného';

  @override
  String get subscriptionInactive => 'Předplatné není aktivní.';

  @override
  String get activeCoachClient => 'Aktivní: Coach + Client ✅';

  @override
  String get activeClientCoachLocked => 'Aktivní: Client ✅ (Coach zamčený)';

  @override
  String get noAccess => 'Bez přístupu';

  @override
  String get selectMode => 'Vyber režim';

  @override
  String get modeDescription => 'Běžný uživatel = onboarding + AI plán.\nTrenérský mód = správa klientů.';

  @override
  String get userModeLocked => 'Běžný uživatel (zamčeno)';

  @override
  String get coachModeLocked => 'Trenérský mód (zamčeno)';

  @override
  String get unlockClient => 'Odemknout Client (Paywall)';

  @override
  String get unlockCoach => 'Odemknout Coach (upgrade)';

  @override
  String get exportFolderSaved => 'Exportní složka byla uložena.';

  @override
  String get customExportFolderRemoved => 'Vlastní exportní složka byla smazána. Použije se výchozí Documents/Klienti.';

  @override
  String get profileNotFound => 'Profil nenalezen';

  @override
  String get changeGoalDescription => 'Opravdu chceš změnit cíl? Při změně cíle se může upravit strategie, fáze a doporučení.';

  @override
  String get yes => 'Ano';

  @override
  String get no => 'Ne';

  @override
  String get automatic => 'Automaticky';

  @override
  String get czech => 'Čeština';

  @override
  String get english => 'English';

  @override
  String get switchToLightMode => 'Přepnout na světlý režim';

  @override
  String get switchToDarkMode => 'Přepnout na tmavý režim';

  @override
  String get changeMode => 'Změnit režim';

  @override
  String get addMeasurement => 'Přidat měření';

  @override
  String get bodyCircumference => 'Obvody těla';

  @override
  String get addCircumference => 'Přidat obvody';

  @override
  String get performance => 'Výkonnost / PR';

  @override
  String get dailyMacros => 'Denní makra';

  @override
  String get dietPlanStyle => 'Styl jídelního plánu';

  @override
  String get phaseLogicTest => 'Test logiky fází';

  @override
  String folderPickFailed(Object error) {
    return 'Nepodařilo se vybrat složku: $error';
  }

  @override
  String get newMeasurement => 'Nové měření';

  @override
  String get date => 'Datum';

  @override
  String get weightKg => 'Váha (kg)';

  @override
  String get muscleMassOptional => 'Svalová hmota (kg) – volitelné';

  @override
  String get fatMassOptional => 'Tuková hmota (kg) – volitelné';

  @override
  String get saveMeasurement => 'Uložit měření';

  @override
  String get enterValidWeight => 'Zadej platnou váhu';

  @override
  String get noMeasurementsYet => 'Zatím nejsou žádná měření';

  @override
  String get history => 'Historie';

  @override
  String get waistChart => 'Graf (Pas)';

  @override
  String get waistTrend => 'Trend obvodu pasu';

  @override
  String get waistChartDescription => 'Graf zobrazuje vývoj pasu v čase (zleva doprava)';

  @override
  String get waist => 'Pas';

  @override
  String get chest => 'Hrudník';

  @override
  String get biceps => 'Biceps';

  @override
  String get thigh => 'Stehno';

  @override
  String get neck => 'Krk';
}
