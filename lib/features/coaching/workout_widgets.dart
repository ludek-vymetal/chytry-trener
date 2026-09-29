import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/coach/coach_client.dart';
import '../../models/custom_training_plan.dart';
import '../../models/exercise_performance.dart';
import '../../providers/coach/custom_training_plan_provider.dart';
import '../../providers/performance_provider.dart';
import '../../services/coach/online_coaching_service.dart';
import '../../services/coach/workout_assignment_service.dart';
import '../help/help_button.dart';

/// Propojení tohoto telefonu s trenérem (`null` = nepropojeno).
final clientLinkProvider = FutureProvider<ClientLinkInfo?>(
  (ref) => OnlineCoachingService.localClientLink(),
);

/// Tréninky, které trenér klientovi poslal.
final myWorkoutsProvider = FutureProvider<List<WorkoutAssignment>>(
  (ref) => WorkoutAssignmentService.listMine(),
);

const _wd = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

String _dateLabel(DateTime d) {
  final today = _day(DateTime.now());
  final diff = _day(d).difference(today).inDays;
  final base = '${_wd[d.weekday - 1]} ${d.day}. ${d.month}.';
  if (diff == 0) return 'Dnes · $base';
  if (diff == 1) return 'Zítra · $base';
  if (diff == -1) return 'Včera · $base';
  return base;
}

String _num(double v) => v == v.roundToDouble()
    ? v.toStringAsFixed(0)
    : v.toStringAsFixed(1).replaceAll('.', ',');

// =====================================================================
// TRENÉR – posílání tréninků po dnech
// =====================================================================

class AssignedWorkoutsCard extends ConsumerStatefulWidget {
  final CoachClient client;
  const AssignedWorkoutsCard({super.key, required this.client});

  @override
  ConsumerState<AssignedWorkoutsCard> createState() =>
      _AssignedWorkoutsCardState();
}

class _AssignedWorkoutsCardState extends ConsumerState<AssignedWorkoutsCard> {
  List<WorkoutAssignment>? _items;
  CoachingLink? _link;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final link = await OnlineCoachingService.loadLink(widget.client.clientId);
      final items = link == null
          ? const <WorkoutAssignment>[]
          : await WorkoutAssignmentService.listForClient(
              widget.client.clientId);
      if (!mounted) return;
      setState(() {
        _link = link;
        _items = items;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Tréninky se nepodařilo načíst.');
    }
  }

  Future<void> _send() async {
    final plans = ref
        .read(customTrainingPlanProvider)
        .where((p) => p.clientId == widget.client.clientId && p.days.isNotEmpty)
        .toList();
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Klient nemá tréninkový plán. Vytvoř ho nebo vlož '
              'program (Trénink → Programy).'),
        ),
      );
      return;
    }
    final items = await showModalBottomSheet<List<WorkoutAssignment>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SendWorkoutSheet(plans: plans),
    );
    if (items == null || items.isEmpty) return;
    try {
      await WorkoutAssignmentService.assign(widget.client.clientId, items);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(items.length == 1
              ? 'Trénink odeslán.'
              : 'Odesláno ${items.length} tréninků.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nepodařilo se odeslat: $e')),
      );
    }
    await _load();
  }

  Future<void> _showResults(WorkoutAssignment a) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(a.title),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(_dateLabel(a.date),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              for (final r in a.results) ...[
                Text(r.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 2),
                  child: Text(
                    r.sets.where((s) => s.done || s.reps != null).isEmpty
                        ? 'nezapsáno'
                        : [
                            for (final s in r.sets)
                              if (s.done || s.reps != null)
                                '${s.weightKg == null ? '' : '${_num(s.weightKg!)} kg × '}${s.reps ?? '–'}',
                          ].join('   ·   '),
                  ),
                ),
              ],
              if ((a.clientNote ?? '').trim().isNotEmpty) ...[
                const Divider(),
                Text('Poznámka klienta: ${a.clientNote!.trim()}'),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zavřít'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = _items;
    final today = _day(DateTime.now());

    Widget body;
    if (_error != null) {
      body = Text(_error!, style: TextStyle(color: cs.error));
    } else if (items == null) {
      body = const LinearProgressIndicator();
    } else if (_link == null) {
      body = Text(
        'Klient zatím není pozvaný do aplikace. Pozvi ho v záložce Přehled '
        '(Online coaching) – pak mu sem budeš posílat tréninky.',
        style: TextStyle(color: cs.onSurfaceVariant),
      );
    } else {
      final shown = items.take(12).toList();
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Klient vidí jen tréninky, které mu pošleš (max. '
            '${WorkoutAssignmentService.maxDaysAhead} dní dopředu) – ne celý plán.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _send,
              icon: const Icon(Icons.send),
              label: const Text('Poslat trénink'),
            ),
          ),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Zatím žádný odeslaný trénink.',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            )
          else
            for (final a in shown)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  a.isDone
                      ? Icons.check_circle
                      : (_day(a.date).isBefore(today)
                          ? Icons.error_outline
                          : Icons.schedule),
                  color: a.isDone
                      ? const Color(0xFF16A34A)
                      : (_day(a.date).isBefore(today) ? cs.error : cs.outline),
                ),
                title: Text(a.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${_dateLabel(a.date)} · '
                  '${a.isDone ? 'odcvičeno' : (_day(a.date).isBefore(today) ? 'neodcvičeno' : 'čeká')}',
                ),
                trailing: a.isDone
                    ? const Icon(Icons.chevron_right)
                    : IconButton(
                        tooltip: 'Zrušit',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await WorkoutAssignmentService.delete(
                              widget.client.clientId, a.id);
                          await _load();
                        },
                      ),
                onTap: a.isDone ? () => _showResults(a) : null,
              ),
        ],
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.event_available_outlined, color: cs.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tréninky pro klienta',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                const HelpButton(topic: 'workouts'),
                IconButton(
                  tooltip: 'Obnovit',
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 6),
            body,
          ],
        ),
      ),
    );
  }
}

class _SendWorkoutSheet extends StatefulWidget {
  final List<CustomTrainingPlan> plans;
  const _SendWorkoutSheet({required this.plans});

  @override
  State<_SendWorkoutSheet> createState() => _SendWorkoutSheetState();
}

class _SendWorkoutSheetState extends State<_SendWorkoutSheet> {
  late CustomTrainingPlan _plan;
  final _days = <int>[]; // indexy dnů plánu v pořadí výběru
  final _dates = <DateTime>{};
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _plan = widget.plans.firstWhere((p) => p.isActive,
        orElse: () => widget.plans.first);
    _days.add(0);
    _dates.add(_day(DateTime.now()));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  List<WorkoutAssignment> _build() {
    final dates = _dates.toList()..sort();
    final note = _note.text.trim();
    final baseId = WorkoutAssignmentService.newId();
    return [
      for (var i = 0; i < dates.length; i++)
        () {
          final day = _plan.days[_days[i % _days.length]];
          return WorkoutAssignment(
            id: '${baseId}_$i',
            date: dates[i],
            title: day.name,
            exercises: day.exercises,
            coachNote: note.isEmpty ? null : note,
          );
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = _day(DateTime.now());
    final dates = [
      for (var i = 0; i <= WorkoutAssignmentService.maxDaysAhead; i++)
        today.add(Duration(days: i)),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Poslat trénink',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            if (widget.plans.length > 1)
              DropdownButtonFormField<String>(
                initialValue: _plan.id,
                decoration: const InputDecoration(
                  labelText: 'Plán',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final p in widget.plans)
                    DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: (id) => setState(() {
                  _plan = widget.plans.firstWhere((p) => p.id == id);
                  _days
                    ..clear()
                    ..add(0);
                }),
              )
            else
              Text('Plán: ${_plan.name}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            const Text('1) Který trénink',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < _plan.days.length; i++)
                  FilterChip(
                    label: Text(
                      _days.contains(i)
                          ? '${_days.indexOf(i) + 1}. ${_plan.days[i].name}'
                          : _plan.days[i].name,
                    ),
                    selected: _days.contains(i),
                    onSelected: (on) => setState(() {
                      if (on) {
                        _days.add(i);
                      } else if (_days.length > 1) {
                        _days.remove(i);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('2) Na který den',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in dates)
                  FilterChip(
                    label: Text(_dateLabel(d)),
                    selected: _dates.contains(d),
                    onSelected: (on) => setState(() {
                      if (on) {
                        _dates.add(d);
                      } else if (_dates.length > 1) {
                        _dates.remove(d);
                      }
                    }),
                  ),
              ],
            ),
            if (_dates.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Tréninky se přiřadí ke dnům v pořadí, jak jsi je vybrala.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
                ),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _note,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Vzkaz klientovi (nepovinné)',
                hintText: 'např. Hip thrust zkus o 2,5 kg víc',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, _build()),
              icon: const Icon(Icons.send),
              label: Text(_dates.length == 1
                  ? 'Odeslat trénink'
                  : 'Odeslat ${_dates.length} tréninky'),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// KLIENT – moje tréninky
// =====================================================================

List<WorkoutAssignment> _visible(List<WorkoutAssignment> all) {
  final limit = _day(DateTime.now())
      .add(const Duration(days: WorkoutAssignmentService.maxDaysAhead));
  return all.where((a) => !_day(a.date).isAfter(limit)).toList();
}

class ClientWorkoutsScreen extends ConsumerWidget {
  const ClientWorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(myWorkoutsProvider);
    final today = _day(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje tréninky'),
        actions: [
          const HelpButton(topic: 'online_client'),
          IconButton(
            tooltip: 'Obnovit',
            onPressed: () => ref.invalidate(myWorkoutsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Chyba: $e')),
        data: (all) {
          final list = _visible(all);
          final todayItems =
              list.where((a) => _day(a.date) == today).toList();
          final upcoming =
              list.where((a) => _day(a.date).isAfter(today)).toList();
          final missed = list
              .where((a) => _day(a.date).isBefore(today) && !a.isDone)
              .toList();
          final done = list
              .where((a) => _day(a.date).isBefore(today) && a.isDone)
              .toList()
              .reversed
              .toList();

          Widget section(String title, List<WorkoutAssignment> items) =>
              items.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                          child: Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        for (final a in items) _WorkoutTile(assignment: a),
                      ],
                    );

          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(myWorkoutsProvider),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 60),
                  Icon(Icons.event_available_outlined,
                      size: 56, color: cs.outline),
                  const SizedBox(height: 12),
                  const Text(
                    'Zatím ti trenér neposlal žádný trénink.\n'
                    'Jakmile ho pošle, objeví se tady.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myWorkoutsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                section('Dnes', todayItems),
                section('Nadcházející', upcoming),
                section('Neodcvičené', missed),
                section('Odeslané trenérovi', done),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final WorkoutAssignment assignment;
  const _WorkoutTile({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = assignment;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              a.isDone ? const Color(0xFF16A34A) : cs.primaryContainer,
          foregroundColor: a.isDone ? Colors.white : cs.onPrimaryContainer,
          child: Icon(a.isDone ? Icons.check : Icons.fitness_center, size: 20),
        ),
        title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('${_dateLabel(a.date)} · ${a.exercises.length} cviků'
            '${a.isDone ? ' · odesláno' : ''}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => WorkoutLogScreen(assignment: a)),
        ),
      ),
    );
  }
}

/// Karta „Dnešní trénink“ na obrazovce Dnes (klient s trenérem).
class ClientTodayWorkoutCard extends ConsumerWidget {
  const ClientTodayWorkoutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final list = ref.watch(myWorkoutsProvider).valueOrNull ?? const [];
    final today = _day(DateTime.now());
    final todays = list.where((a) => _day(a.date) == today).toList();
    final next = list
        .where((a) => _day(a.date).isAfter(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final a = todays.isEmpty ? null : todays.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            const SizedBox(height: 10),
            Text(
              a == null ? 'Dnes volno' : a.title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              a == null
                  ? (next.isEmpty
                      ? 'Trenér ti zatím neposlal další trénink.'
                      : 'Další trénink: ${_dateLabel(next.first.date)} – ${next.first.title}')
                  : '${a.exercises.length} cviků${a.isDone ? ' · odesláno trenérovi ✓' : ''}',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            if (a?.coachNote != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('Vzkaz od trenéra: ${a!.coachNote}',
                    style: TextStyle(color: cs.onPrimaryContainer)),
              ),
            ],
            if (a != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  icon: Icon(a.isDone ? Icons.visibility : Icons.play_arrow),
                  label: Text(a.isDone ? 'Zobrazit trénink' : 'Začít trénink'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => WorkoutLogScreen(assignment: a)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Zápis tréninku a odeslání trenérovi.
class WorkoutLogScreen extends ConsumerStatefulWidget {
  final WorkoutAssignment assignment;
  const WorkoutLogScreen({super.key, required this.assignment});

  @override
  ConsumerState<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _SetCtrl {
  final TextEditingController kg;
  final TextEditingController reps;
  bool done;
  _SetCtrl(String w, String r, this.done)
      : kg = TextEditingController(text: w),
        reps = TextEditingController(text: r);
}

class _WorkoutLogScreenState extends ConsumerState<WorkoutLogScreen> {
  late final List<List<_SetCtrl>> _sets;
  final _note = TextEditingController();
  bool _busy = false;

  static int _setCount(String s) {
    final m = RegExp(r'\d+').firstMatch(s);
    final n = m == null ? 1 : int.parse(m.group(0)!);
    return n.clamp(1, 10);
  }

  static String _firstNum(String s) =>
      RegExp(r'\d+').firstMatch(s)?.group(0) ?? '';

  @override
  void initState() {
    super.initState();
    final a = widget.assignment;
    _note.text = a.clientNote ?? '';
    _sets = [
      for (var i = 0; i < a.exercises.length; i++)
        () {
          final e = a.exercises[i];
          final prev = i < a.results.length ? a.results[i].sets : const [];
          final n = prev.isNotEmpty ? prev.length : _setCount(e.sets);
          return [
            for (var s = 0; s < n; s++)
              s < prev.length
                  ? _SetCtrl(
                      prev[s].weightKg == null ? '' : _num(prev[s].weightKg!),
                      prev[s].reps?.toString() ?? '',
                      prev[s].done,
                    )
                  : _SetCtrl(
                      e.weightKg == null ? '' : _num(e.weightKg!),
                      _firstNum(e.reps),
                      false,
                    ),
          ];
        }(),
    ];
  }

  @override
  void dispose() {
    for (final l in _sets) {
      for (final s in l) {
        s.kg.dispose();
        s.reps.dispose();
      }
    }
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final a = widget.assignment;
    final results = [
      for (var i = 0; i < a.exercises.length; i++)
        ExerciseResult(
          name: a.exercises[i].customName,
          sets: [
            for (final s in _sets[i])
              LoggedSet(
                weightKg: double.tryParse(s.kg.text.replaceAll(',', '.')),
                reps: int.tryParse(s.reps.text),
                done: s.done,
              ),
          ],
        ),
    ];
    final done = a.copyWith(
      status: 'done',
      results: results,
      clientNote: _note.text.trim(),
      completedAt: DateTime.now(),
    );
    try {
      await WorkoutAssignmentService.submit(done);

      // Výkony do Pokroku (nejlepší odcvičená série každého cviku).
      final link = await OnlineCoachingService.localClientLink();
      if (!a.isDone) {
        for (final r in results) {
          LoggedSet? best;
          for (final s in r.sets) {
            if (!s.done || s.reps == null || s.reps! <= 0) continue;
            if (best == null ||
                (s.weightKg ?? 0) > (best.weightKg ?? 0) ||
                ((s.weightKg ?? 0) == (best.weightKg ?? 0) &&
                    s.reps! > (best.reps ?? 0))) {
              best = s;
            }
          }
          if (best == null) continue;
          await ref.read(performanceProvider.notifier).addPerformance(
                ExercisePerformance(
                  exerciseName: r.name,
                  date: a.date,
                  weight: best.weightKg ?? 0,
                  reps: best.reps ?? 0,
                  clientId: link?.clientId,
                ),
              );
        }
      }

      ref.invalidate(myWorkoutsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trénink odeslán trenérovi. Skvělá práce!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Odeslání se nepovedlo (jsi online?): $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = widget.assignment;

    return Scaffold(
      appBar: AppBar(title: Text(a.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(_dateLabel(a.date),
              style: TextStyle(color: cs.onSurfaceVariant)),
          if (a.coachNote != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('Vzkaz od trenéra: ${a.coachNote}',
                  style: TextStyle(color: cs.onPrimaryContainer)),
            ),
          ],
          const SizedBox(height: 12),
          for (var i = 0; i < a.exercises.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}. ${a.exercises[i].customName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        '${a.exercises[i].sets} × ${a.exercises[i].reps}',
                        if (a.exercises[i].rir.trim().isNotEmpty &&
                            a.exercises[i].rir != '—')
                          'RIR ${a.exercises[i].rir}',
                        if (a.exercises[i].weightKg != null)
                          '${_num(a.exercises[i].weightKg!)} kg',
                      ].join(' · '),
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    if ((a.exercises[i].note ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(a.exercises[i].note!.trim(),
                            style: TextStyle(
                                fontSize: 13, color: cs.onSurfaceVariant)),
                      ),
                    const SizedBox(height: 8),
                    for (var s = 0; s < _sets[i].length; s++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 58,
                              child: Text('Série ${s + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _sets[i][s].kg,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.,]')),
                                ],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  suffixText: 'kg',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _sets[i][s].reps,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  suffixText: 'opak.',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            Checkbox(
                              value: _sets[i][s].done,
                              onChanged: (v) => setState(
                                  () => _sets[i][s].done = v ?? false),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Jak to šlo? (poznámka pro trenéra)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(a.isDone
                  ? 'Odeslat opravu trenérovi'
                  : 'Odeslat trenérovi'),
            ),
          ),
        ],
      ),
    );
  }
}
