import 'exercise_db.dart';

class ExercisePresets {
  // =========================
  // HRUDNÍK
  // =========================
  static const List<String> chestMain = [
    ExerciseIds.bench,
    ExerciseIds.dbBench,
    ExerciseIds.chestPressMachine,
    ExerciseIds.declineBench,
    ExerciseIds.dipsChest,
  ];

  static const List<String> chestSecondary = [
    ExerciseIds.inclineDbPress,
    ExerciseIds.dbBench,
    ExerciseIds.chestPressMachine,
    ExerciseIds.widePushUp,
  ];

  static const List<String> chestIsolation = [
    ExerciseIds.dbFly,
    ExerciseIds.cableFly,
    ExerciseIds.peckDeck,
    ExerciseIds.pullover,
  ];

  // =========================
  // ZÁDA
  // =========================
  static const List<String> backVertical = [
    ExerciseIds.pullUps,
    ExerciseIds.assistedPullUps,
    ExerciseIds.latPulldown,
    ExerciseIds.straightArmPulldown,
  ];

  static const List<String> backHorizontal = [
    ExerciseIds.barbellRow,
    ExerciseIds.oneArmDbRow,
    ExerciseIds.seatedCableRow,
    ExerciseIds.tBarRow,
    ExerciseIds.sealRow,
  ];

  static const List<String> backHinge = [
    ExerciseIds.deadlift,
    ExerciseIds.rdl,
    ExerciseIds.blockPull,
    ExerciseIds.rackPull,
    ExerciseIds.hyperextension,
  ];

  static const List<String> rearDeltsTraps = [
    ExerciseIds.facePull,
    ExerciseIds.reversePeckDeck,
    ExerciseIds.shrugs,
  ];

  // =========================
  // RAMENA
  // =========================
  static const List<String> shouldersPress = [
    ExerciseIds.overheadPress,
    ExerciseIds.dbShoulderPress,
    ExerciseIds.arnoldPress,
  ];

  static const List<String> shouldersLateral = [
    ExerciseIds.lateralRaise,
    ExerciseIds.cableLateralRaise,
    ExerciseIds.lateralRaiseMachine,
    ExerciseIds.uprightRowWide,
  ];

  static const List<String> shouldersRear = [
    ExerciseIds.facePull,
    ExerciseIds.reversePeckDeck,
    ExerciseIds.rearDeltFly,
    ExerciseIds.cableRearDeltFly,
  ];

  // =========================
  // TRICEPS
  // =========================
  static const List<String> tricepsMain = [
    ExerciseIds.dipsTriceps,
    ExerciseIds.closeGripBench,
    ExerciseIds.skullcrusher,
  ];

  static const List<String> tricepsIsolation = [
    ExerciseIds.tricepsPushdown,
    ExerciseIds.overheadTricepsExtension,
    ExerciseIds.kickback,
  ];

  // =========================
  // BICEPS
  // =========================
  static const List<String> bicepsMain = [
    ExerciseIds.ezBarCurl,
    ExerciseIds.dbCurl,
    ExerciseIds.hammerCurl,
  ];

  static const List<String> bicepsIsolation = [
    ExerciseIds.preacherCurl,
    ExerciseIds.concentrationCurl,
    ExerciseIds.reverseCurl,
  ];

  // =========================
  // KVADRICEPSY
  // =========================
  static const List<String> quadsMain = [
    ExerciseIds.squat,
    ExerciseIds.frontSquat,
    ExerciseIds.legPress,
    ExerciseIds.hackSquat,
    ExerciseIds.splitSquat,
  ];

  static const List<String> quadsIsolation = [
    ExerciseIds.legExtension,
  ];

  // =========================
  // HAMSTRINGY
  // =========================
  static const List<String> hamstringsMain = [
    ExerciseIds.rdl,
    ExerciseIds.stiffLegDeadlift,
    ExerciseIds.gluteHamRaise,
  ];

  static const List<String> hamstringsIsolation = [
    ExerciseIds.hamstringCurl,
  ];

  // =========================
  // HÝŽDĚ
  // =========================
  static const List<String> glutesMain = [
    ExerciseIds.hipThrust,
    ExerciseIds.bulgarianSplitSquat,
    ExerciseIds.sumoSquat,
  ];

  static const List<String> glutesIsolation = [
    ExerciseIds.gluteKickback,
    ExerciseIds.abductionMachine,
  ];

  // =========================
  // CORE
  // =========================
  static const List<String> coreMain = [
    ExerciseIds.plank,
    ExerciseIds.hangingLegRaise,
    ExerciseIds.cableCrunch,
    ExerciseIds.russianTwist,
    ExerciseIds.abWheel,
    ExerciseIds.sidePlank,
  ];
}