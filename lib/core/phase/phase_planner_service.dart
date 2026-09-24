import '../../models/goal.dart';
import 'phase.dart';
import 'phase_plan.dart';
import '../time/time_context.dart';
import 'plan_mode.dart';

/// Plánovač fází (periodizace).
///
/// Plán se počítá ZPĚTNĚ od cílového data (T), takže funguje pro libovolný
/// termín – ne podle pevných kalendářních měsíců. Když je do cíle méně času,
/// než celé schéma potřebuje, začátek schématu se jednoduše "ořízne" a
/// uživatel začne rovnou v pozdější (rychlejší) fázi.
///
/// Schéma pro POSTAVU (forma k datu T):
///   > 21 týdnů před T   budování (4týdenní bloky hypertrofie / síla+hypertrofie)
///   21–17 týdnů         recomp / mírný deficit   ~0,375 % váhy / týden
///   17–13 týdnů         Cut I                    ~0,5 %
///   13–8 týdnů          Cut II                   ~0,75 %
///   8–4 týdny           Cut III                  ~0,875 %
///   4–2 týdny           finální cut              ~0,875 %
///   2–0 týdny           peak / stabilizace       údržba
///   po T (4 týdny)      forma                    údržba
class PhasePlannerService {
  // ---------------------------------------------------------------
  // Konstanty schématu (v týdnech před cílem)
  // ---------------------------------------------------------------

  static const int _formaWeeksAfterTarget = 4;
  static const int _buildBlockWeeks = 4;

  /// Maximální tempo úbytku (horní hranice doporučení 0,5–1 % týdně).
  static const double _maxWeeklyLossPct = 1.0;

  /// Navýšení tempa ve zrychleném režimu (volí uživatel).
  static const double _acceleratedBonusPct = 0.25;

  static List<PhasePlan> buildPlan(TimeContext context, {Goal? goal}) {
    final now = _normalize(context.now);
    final target = _normalize(context.targetDate);

    // Cílové datum už uplynulo → udržovací fáze, dokud si uživatel
    // nenastaví nový cíl.
    if (target.isBefore(now)) {
      return [
        PhasePlan(
          phase: PhaseType.maintenance,
          start: target,
          end: _addDays(now, 365),
          label: 'Údržba',
        ),
      ];
    }

    final accelerated = context.mode == PlanMode.accelerated &&
        goal?.reason != GoalReason.eatingDisorderSupport;

    final type = goal?.type ?? GoalType.physique;

    var plans = <PhasePlan>[];

    switch (type) {
      case GoalType.physique:
        final choice = goal?.phase;
        if (choice == GoalPhase.maintain) {
          plans = _maintainOnly(now, target);
        } else if (choice == GoalPhase.build) {
          plans = _buildOnly(now, target);
        } else {
          plans = _physiqueToForm(now, target, accelerated);
        }
        break;

      case GoalType.weightLoss:
        plans = _weightLoss(now, target, accelerated);
        break;

      case GoalType.strength:
        plans = _strength(now, target);
        break;

      case GoalType.endurance:
        plans = _endurance(now, target);
        break;

      case GoalType.weightGainSupport:
        plans = _gainSupport(now, target);
        break;
    }

    return _withFormaAfter(plans, target);
  }

  // ===============================================================
  // POSTAVA – forma k datu (schéma trenéra)
  // ===============================================================

  static List<PhasePlan> _physiqueToForm(
    DateTime now,
    DateTime target,
    bool accelerated,
  ) {
    double rate(double base) {
      final r = accelerated ? base + _acceleratedBonusPct : base;
      return r > _maxWeeklyLossPct ? _maxWeeklyLossPct : r;
    }

    // Segmenty od cíle zpět: (týdnů před T – začátek, konec), fáze, popis.
    final segments = <_Segment>[
      _Segment(21, 17, PhaseType.cutting, 'Recomp / mírný deficit', rate(0.375)),
      _Segment(17, 13, PhaseType.cutting, 'Cut I', rate(0.5)),
      _Segment(13, 8, PhaseType.cutting, 'Cut II', rate(0.75)),
      _Segment(8, 4, PhaseType.cutting, 'Cut III', rate(0.875)),
      _Segment(4, 2, PhaseType.cutting, 'Finální cut', rate(0.875)),
      _Segment(2, 0, PhaseType.peaking, 'Peak / stabilizace', null),
    ];

    final plans = <PhasePlan>[];

    // Budovací bloky před začátkem redukce.
    final cutStart = _weeksBefore(target, 21);
    plans.addAll(_buildBlocks(now, cutStart));

    plans.addAll(_segmentsToPlans(segments, now, target, accelerated));

    return _ensureNotEmpty(plans, now, target);
  }

  /// Budovací 4týdenní bloky v intervalu [from, to). Bloky se skládají od
  /// konce, aby poslední blok před redukcí byl vždy "Hypertrofie"
  /// a před ním "Síla + hypertrofie" (střídání).
  static List<PhasePlan> _buildBlocks(DateTime from, DateTime to) {
    if (!from.isBefore(to)) return [];

    final blocks = <PhasePlan>[];
    var end = to;
    var index = 0;

    while (end.isAfter(from)) {
      var start = _addDays(end, -(7 * _buildBlockWeeks));
      if (start.isBefore(from)) start = from;

      blocks.add(
        PhasePlan(
          phase: PhaseType.gaining,
          start: start,
          end: end,
          label: index.isEven ? 'Hypertrofie' : 'Síla + hypertrofie',
        ),
      );

      end = start;
      index++;
    }

    return blocks.reversed.toList();
  }

  static List<PhasePlan> _buildOnly(DateTime now, DateTime target) {
    return _ensureNotEmpty(_buildBlocks(now, target), now, target);
  }

  static List<PhasePlan> _maintainOnly(DateTime now, DateTime target) {
    return [
      PhasePlan(
        phase: PhaseType.maintenance,
        start: now,
        end: _max(target, _addDays(now, 1)),
        label: 'Udržení',
      ),
    ];
  }

  // ===============================================================
  // HUBNUTÍ – průběžný deficit + diet breaky
  // ===============================================================

  static const int _dietCutWeeks = 10;
  static const int _dietBreakWeeks = 2;

  static List<PhasePlan> _weightLoss(
    DateTime now,
    DateTime target,
    bool accelerated,
  ) {
    final lossPct = accelerated ? _maxWeeklyLossPct : 0.75;

    final plans = <PhasePlan>[];
    var cursor = now;
    var block = 1;

    while (cursor.isBefore(target)) {
      var cutEnd = _min(
        _addDays(cursor, 7 * _dietCutWeeks),
        target,
      );

      // Když by po bloku zbyl jen krátký zbytek (< 4 týdny), na diet break
      // se nevejde → redukci rovnou protáhneme až do cíle.
      if (_addDays(cutEnd, 28).isAfter(target)) {
        cutEnd = target;
      }

      plans.add(
        PhasePlan(
          phase: PhaseType.cutting,
          start: cursor,
          end: cutEnd,
          accelerated: accelerated,
          label: 'Redukce $block',
          weeklyLossPct: lossPct,
        ),
      );
      cursor = cutEnd;

      // Diet break jen tehdy, když po něm zbývají aspoň 2 týdny redukce.
      final breakEnd = _addDays(cursor, 7 * _dietBreakWeeks);
      if (!_addDays(breakEnd, 14).isAfter(target)) {
        plans.add(
          PhasePlan(
            phase: PhaseType.maintenance,
            start: cursor,
            end: breakEnd,
            label: 'Diet break (údržba)',
          ),
        );
        cursor = breakEnd;
      }
      // Jinak redukce plynule pokračuje dalším blokem až do cíle.

      block++;
    }

    return _ensureNotEmpty(plans, now, target);
  }

  // ===============================================================
  // SÍLA – objem → síla → intenzifikace → peak → taper (od závodu zpět)
  // ===============================================================

  static List<PhasePlan> _strength(DateTime now, DateTime target) {
    final segments = <_Segment>[
      _Segment(11, 7, PhaseType.gaining, 'Síla', null),
      _Segment(7, 3, PhaseType.gaining, 'Intenzifikace', null),
      _Segment(3, 1, PhaseType.peaking, 'Peak', null),
      _Segment(1, 0, PhaseType.peaking, 'Taper', null),
    ];

    final plans = <PhasePlan>[];

    final volumeEnd = _weeksBefore(target, 11);
    if (now.isBefore(volumeEnd)) {
      plans.add(
        PhasePlan(
          phase: PhaseType.gaining,
          start: now,
          end: volumeEnd,
          label: 'Objem',
        ),
      );
    }

    plans.addAll(_segmentsToPlans(segments, now, target, false));

    return _ensureNotEmpty(plans, now, target);
  }

  // ===============================================================
  // VYTRVALOST – základ + taper 2 týdny
  // ===============================================================

  static List<PhasePlan> _endurance(DateTime now, DateTime target) {
    final plans = <PhasePlan>[];

    final taperStart = _weeksBefore(target, 2);
    if (now.isBefore(taperStart)) {
      plans.add(
        PhasePlan(
          phase: PhaseType.maintenance,
          start: now,
          end: taperStart,
          label: 'Vytrvalost – základ',
        ),
      );
    }

    plans.addAll(
      _segmentsToPlans(
        [_Segment(2, 0, PhaseType.peaking, 'Taper', null)],
        now,
        target,
        false,
      ),
    );

    return _ensureNotEmpty(plans, now, target);
  }

  // ===============================================================
  // NABÍRÁNÍ (podpora po poruše příjmu potravy) – vždy přebytek
  // ===============================================================

  static List<PhasePlan> _gainSupport(DateTime now, DateTime target) {
    return [
      PhasePlan(
        phase: PhaseType.gaining,
        start: now,
        end: _max(target, _addDays(now, 1)),
        label: 'Nabírání',
      ),
    ];
  }

  // ===============================================================
  // Pomocné funkce
  // ===============================================================

  /// Převede segmenty (týdny před T) na plány a ořízne je na dnešek.
  static List<PhasePlan> _segmentsToPlans(
    List<_Segment> segments,
    DateTime now,
    DateTime target,
    bool accelerated,
  ) {
    final plans = <PhasePlan>[];

    for (final s in segments) {
      var start = _weeksBefore(target, s.fromWeeks);
      final end = _weeksBefore(target, s.toWeeks);

      if (!end.isAfter(now)) continue; // celý segment je v minulosti
      if (start.isBefore(now)) start = now; // oříznutí na dnešek

      plans.add(
        PhasePlan(
          phase: s.phase,
          start: start,
          end: end,
          accelerated: accelerated,
          label: s.label,
          weeklyLossPct: s.weeklyLossPct,
        ),
      );
    }

    return plans;
  }

  /// Po cíli přidá 4 týdny "Formy" (udržení) a pak údržbu.
  static List<PhasePlan> _withFormaAfter(
    List<PhasePlan> plans,
    DateTime target,
  ) {
    final formaEnd = _addDays(target, 7 * _formaWeeksAfterTarget);

    return [
      ...plans,
      PhasePlan(
        phase: PhaseType.maintenance,
        start: target,
        end: formaEnd,
        label: 'Forma / udržení',
      ),
      PhasePlan(
        phase: PhaseType.maintenance,
        start: formaEnd,
        end: _addDays(formaEnd, 365),
        label: 'Údržba',
      ),
    ];
  }

  /// Když je cíl dnes (nic se nevešlo), vrátíme aspoň 1 den údržby.
  static List<PhasePlan> _ensureNotEmpty(
    List<PhasePlan> plans,
    DateTime now,
    DateTime target,
  ) {
    if (plans.isNotEmpty) return plans;

    return [
      PhasePlan(
        phase: PhaseType.maintenance,
        start: now,
        end: _max(target, _addDays(now, 1)),
        label: 'Údržba',
      ),
    ];
  }

  static DateTime _weeksBefore(DateTime target, int weeks) {
    return _addDays(target, -7 * weeks);
  }

  /// Kalendářní posun o dny (bez problémů s letním/zimním časem).
  static DateTime _addDays(DateTime d, int days) {
    return DateTime(d.year, d.month, d.day + days);
  }

  static DateTime _min(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  static DateTime _max(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}

class _Segment {
  final int fromWeeks; // začátek: kolik týdnů před cílem
  final int toWeeks; // konec: kolik týdnů před cílem
  final PhaseType phase;
  final String label;
  final double? weeklyLossPct;

  const _Segment(
    this.fromWeeks,
    this.toWeeks,
    this.phase,
    this.label,
    this.weeklyLossPct,
  );
}
