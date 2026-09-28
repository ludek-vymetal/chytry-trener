import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/training/training_plan_models.dart';
import '../../l10n/app_localizations.dart';
import '../../models/goal.dart';
import '../../models/user_profile.dart';
import '../../providers/daily_history_provider.dart';
import '../../providers/nav_provider.dart';
import '../../providers/slot_selection_provider.dart';
import '../../providers/training_session_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/macro_service.dart';
import '../../services/metabolism_service.dart';
import '../../services/today_training_service.dart';
import '../body/add_measurement_screen.dart';
import '../common/adaptive_shell.dart';
import '../debug/phase_test_screen.dart';
import '../diet_plans/diet_strategy_screen.dart';
import '../help/help_button.dart';
import '../help/help_screen.dart';
import '../training/today_training_screen.dart';

/// Obrazovka „Dnes“ – přehled dne pro klienta: cesta k cíli, dnešní
/// trénink, jídlo, týden a rychlé akce.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _weekdays = [
    'Pondělí', 'Úterý', 'Středa', 'Čtvrtek', 'Pátek', 'Sobota', 'Neděle',
  ];
  static const _months = [
    'ledna', 'února', 'března', 'dubna', 'května', 'června', 'července',
    'srpna', 'září', 'října', 'listopadu', 'prosince',
  ];

  String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 10) return 'Dobré ráno';
    if (h < 18) return 'Dobrý den';
    return 'Dobrý večer';
  }

  String _goalLabel(GoalType t) => switch (t) {
        GoalType.strength => 'Síla',
        GoalType.physique => 'Postava',
        GoalType.weightLoss => 'Hubnutí',
        GoalType.endurance => 'Vytrvalost',
        GoalType.weightGainSupport => 'Podpora nabírání',
      };

  static String _n(double v, [int d = 1]) =>
      v.toStringAsFixed(d).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(userProfileProvider);

    if (profile == null || profile.goal == null) {
      return Scaffold(body: Center(child: Text(l10n.profileNotFound)));
    }

    final tdee = MetabolismService.calculateTDEE(
      profile,
      MetabolismService.activityFor(profile),
    );
    final macro = MacroService.calculate(profile, tdee);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final intake = ref.watch(dailyHistoryProvider).intakeFor(today);
    final sessions = ref.watch(trainingSessionProvider);
    final slots = ref.watch(slotSelectionProvider);

    TrainingDayPlan? todayPlan;
    try {
      todayPlan = TodayTrainingService.today(profile, slotSelections: slots);
    } catch (_) {
      todayPlan = null;
    }

    // Týden: pondělí – neděle, odtrénované dny.
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final trained = <int>{
      for (final s in sessions)
        if ((s.completed || s.entries.isNotEmpty) &&
            !s.date.isBefore(monday) &&
            s.date.isBefore(monday.add(const Duration(days: 7))))
          s.date.weekday,
    };

    final name = profile.firstName.trim();
    final header = _Header(
      date: '${_weekdays[now.weekday - 1]} ${now.day}. ${_months[now.month - 1]}',
      greeting: name.isEmpty ? _greeting(now) : '${_greeting(now)}, $name',
      initials: name.isEmpty
          ? null
          : '${name[0]}${profile.lastName.trim().isEmpty ? '' : profile.lastName.trim()[0]}'
              .toUpperCase(),
    );

    final goalCard = _GoalCard(
      profile: profile,
      goalLabel: _goalLabel(profile.goal!.type),
      weeksToTarget: macro.weeksToTarget,
    );

    final trainingCard = _TrainingCard(plan: todayPlan);

    final foodCard = _FoodCard(
      eatenKcal: intake.calories,
      targetKcal: macro.targetCalories,
      protein: (intake.protein, macro.protein),
      carbs: (intake.carbs, macro.carbs),
      fat: (intake.fat, macro.fat),
      onOpenFood: () => ref.read(userTabProvider.notifier).state = 1,
    );

    final week = _WeekStrip(trainedWeekdays: trained, todayWeekday: now.weekday);

    final actionItems = <_Action>[
        _Action(Icons.restaurant_menu, 'Jídelníček', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DietStrategyScreen()),
          );
        }),
        _Action(Icons.monitor_weight_outlined, 'Zapsat váhu', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMeasurementScreen()),
          );
        }),
        _Action(Icons.show_chart, 'Můj pokrok',
            () => ref.read(userTabProvider.notifier).state = 3),
        _Action(Icons.help_outline, 'Nápověda', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpScreen(topic: 'today')),
          );
        }),
    ];
    final actions = _QuickActions(items: actionItems);
    final withSide = SidePanelLayout.isWide(context);

    final details = Card(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.calculate_outlined),
        title: const Text('Jak je spočítaný tvůj cíl'),
        subtitle: Text(
          '${macro.targetCalories} kcal · B ${macro.protein} g · '
          'S ${macro.carbs} g · T ${macro.fat} g',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Denní výdej ${tdee.toStringAsFixed(0)} kcal · '
              '${macro.strategyLabel} · ${macro.phaseLabel}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Text(macro.rationale),
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            _MacroDebugCard(
              currentKg: profile.weight,
              targetKg: profile.goal?.targetWeightKg,
              weightForCaloriesKg: macro.weightForCaloriesKg,
              weightForProteinKg: macro.weightForProteinKg,
              macro: macro,
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PhaseTestScreen()),
              ),
              child: Text(l10n.phaseLogicTest),
            ),
          ],
        ],
      ),
    );

    return Scaffold(
      body: SidePanelLayout(
        side: [
          week,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SideTitle('Rychlé akce'),
              _QuickActions(items: actionItems, columns: 1),
            ],
          ),
          details,
        ],
        main: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 900;
            const gap = SizedBox(height: 14);
            final content = withSide
                ? (wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [goalCard, gap, trainingCard],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: foodCard),
                        ],
                      )
                    : Column(
                        children: [goalCard, gap, trainingCard, gap, foodCard],
                      ))
                : wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [goalCard, gap, trainingCard, gap, week],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [foodCard, gap, actions, gap, details],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      goalCard,
                      gap,
                      trainingCard,
                      gap,
                      foodCard,
                      gap,
                      week,
                      gap,
                      actions,
                      gap,
                      details,
                    ],
                  );
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 12, wide ? 28 : 16, 32),
              child: PageWidth(
                child: Column(
                  children: [header, const SizedBox(height: 16), content],
                ),
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}

// =================================================================
// Části obrazovky
// =================================================================

class _Header extends StatelessWidget {
  final String date;
  final String greeting;
  final String? initials;

  const _Header({required this.date, required this.greeting, this.initials});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
              ),
            ],
          ),
        ),
        const HelpButton(topic: 'today'),
        if (initials != null) ...[
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            child: Text(
              initials!,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tmavá karta „Cesta k cíli“ s kruhem postupu.
class _GoalCard extends StatelessWidget {
  final UserProfile profile;
  final String goalLabel;
  final int weeksToTarget;

  const _GoalCard({
    required this.profile,
    required this.goalLabel,
    required this.weeksToTarget,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? cs.primaryContainer : const Color(0xFF13171C);
    final fg = dark ? cs.onPrimaryContainer : Colors.white;
    final muted = fg.withValues(alpha: 0.7);

    final ms = [...profile.measurements]..sort((a, b) => a.date.compareTo(b.date));
    final current = ms.isNotEmpty ? ms.last.weight : profile.weight;
    final start = ms.isNotEmpty ? ms.first.weight : profile.weight;
    final target = profile.goal?.targetWeightKg;

    double? progress;
    if (target != null && (start - target).abs() > 0.1) {
      progress = ((start - current) / (start - target)).clamp(0.0, 1.0);
    }
    final change = current - start;

    Widget stat(String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: muted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 78,
                      height: 78,
                      child: CircularProgressIndicator(
                        value: progress ?? 0,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor: fg.withValues(alpha: 0.15),
                        color: dark ? cs.primary : cs.inversePrimary,
                      ),
                    ),
                    Text(
                      progress == null ? '–' : '${(progress * 100).round()} %',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CESTA K CÍLI · ${goalLabel.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      target == null
                          ? 'Drž směr'
                          : progress != null && progress >= 1
                              ? 'Cíl splněn!'
                              : 'Zbývá ${_DashboardScreenState._n((current - target).abs())} kg',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: fg,
                      ),
                    ),
                    if (weeksToTarget > 0)
                      Text(
                        'přibližně $weeksToTarget týdnů',
                        style: TextStyle(color: muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              stat('Váha teď', '${_DashboardScreenState._n(current)} kg'),
              const SizedBox(width: 8),
              stat(
                'Od začátku',
                '${change > 0 ? '+' : change < 0 ? '−' : ''}'
                    '${_DashboardScreenState._n(change.abs())} kg',
              ),
              const SizedBox(width: 8),
              stat(
                'Cíl',
                target == null ? '–' : '${_DashboardScreenState._n(target)} kg',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  final TrainingDayPlan? plan;
  const _TrainingCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = plan;
    final rest = p == null || p.exercises.isEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'DNEŠNÍ TRÉNINK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              rest ? 'Dnes volno – regenerace' : p.dayLabel,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              rest
                  ? 'Procházka, protažení a dostatek spánku.'
                  : '${p.focus.isEmpty ? '' : '${p.focus} · '}'
                      '${p.exercises.length} cviků',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                icon: Icon(rest ? Icons.fitness_center : Icons.play_arrow),
                label: Text(rest ? 'Otevřít trénink' : 'Začít trénink'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TodayTrainingScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final int eatenKcal;
  final int targetKcal;
  final (int, int) protein;
  final (int, int) carbs;
  final (int, int) fat;
  final VoidCallback onOpenFood;

  const _FoodCard({
    required this.eatenKcal,
    required this.targetKcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.onOpenFood,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final left = targetKcal - eatenKcal;

    Widget bar(String label, (int, int) v, Color color) {
      final ratio = v.$2 <= 0 ? 0.0 : math.min(v.$1 / v.$2, 1.0);
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            SizedBox(
              width: 78,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 9,
                  color: color,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
            ),
            SizedBox(
              width: 76,
              child: Text(
                '${v.$1}/${v.$2} g',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jídlo dnes',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${left.abs()} ',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(
                              text: left >= 0 ? 'kcal zbývá' : 'kcal nad cílem',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onOpenFood,
                  icon: const Icon(Icons.add),
                  label: const Text('Zapsat jídlo'),
                ),
              ],
            ),
            bar('Bílkoviny', protein, cs.primary),
            bar('Sacharidy', carbs, cs.tertiary),
            bar('Tuky', fat, cs.secondary),
          ],
        ),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final Set<int> trainedWeekdays;
  final int todayWeekday;

  const _WeekStrip({required this.trainedWeekdays, required this.todayWeekday});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const labels = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tento týden · ${trainedWeekdays.length}× trénink',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var d = 1; d <= 7; d++)
                  Column(
                    children: [
                      Text(
                        labels[d - 1],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              d == todayWeekday ? FontWeight.w900 : FontWeight.w500,
                          color: d == todayWeekday
                              ? cs.onSurface
                              : cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: trainedWeekdays.contains(d)
                              ? cs.primary
                              : cs.surfaceContainerHighest,
                          border: d == todayWeekday &&
                                  !trainedWeekdays.contains(d)
                              ? Border.all(color: cs.primary, width: 2)
                              : null,
                        ),
                        child: trainedWeekdays.contains(d)
                            ? Icon(Icons.check, size: 18, color: cs.onPrimary)
                            : null,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action(this.icon, this.label, this.onTap);
}

/// Rychlé akce – všechny hlavní funkce viditelně na jedno klepnutí.
class _QuickActions extends StatelessWidget {
  final List<_Action> items;
  final int columns;
  const _QuickActions({required this.items, this.columns = 2});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: columns == 1 ? 5.0 : 2.6,
      children: [
        for (final a in items)
          Material(
            color: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: a.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(a.icon, color: cs.onPrimaryContainer, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        a.label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MacroDebugCard extends StatelessWidget {
  final double currentKg;

  final double? targetKg;

  final double weightForCaloriesKg;

  final double weightForProteinKg;

  final MacroTarget macro;

  const _MacroDebugCard({
    required this.currentKg,
    required this.targetKg,
    required this.weightForCaloriesKg,
    required this.weightForProteinKg,
    required this.macro,
  });

  String kg(double value) {
    return '${value.toStringAsFixed(1)} kg';
  }

  Widget rowItem(
    BuildContext context,
    String left,
    String right,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 12),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Expanded(
            flex: 2,

            child: Text(
              left,

              style: TextStyle(
                color: colorScheme
                    .onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            flex: 3,

            child: Text(
              right,

              textAlign: TextAlign.right,

              style: TextStyle(
                fontWeight:
                    FontWeight.w700,
                fontSize: 14,
                color:
                    colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;
    final l10n =
        AppLocalizations.of(context)!;    

    return Card(
      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),

        side: BorderSide(
          color:
              colorScheme.outlineVariant,
        ),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color:
                      colorScheme.primary,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    l10n.debugWeightSource,

                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme
                          .onSurface,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            rowItem(
              context,
              l10n.currentWeight,
              kg(currentKg),
            ),

            rowItem(
              context,
              l10n.targetWeight,
              targetKg == null
                  ? l10n.notSet
                  : kg(targetKg!),
            ),

            Divider(
              height: 24,
              color:
                  colorScheme.outlineVariant,
            ),

            rowItem(
              context,
              l10n.weightForCalories,
              kg(weightForCaloriesKg),
            ),

            rowItem(
              context,
              l10n.weightForProtein,
              kg(weightForProteinKg),
            ),

            Divider(
              height: 24,
              color:
                  colorScheme.outlineVariant,
            ),

            rowItem(
              context,
              l10n.phase,
              macro.phaseLabel,
            ),

            rowItem(
              context,
              l10n.mode,
              macro.planModeLabel,
            ),

            rowItem(
              context,
              l10n.weeksToTarget,
              '${macro.weeksToTarget}',
            ),

            rowItem(
              context,
              l10n.strategy,
              macro.strategyLabel,
            ),
          ],
        ),
      ),
    );
  }
}