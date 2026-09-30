import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/coach/coach_client.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/coach/checkin_service.dart';
import '../../services/coach/online_coaching_service.dart';
import '../../services/coach/workout_assignment_service.dart';
import '../help/help_button.dart';
import 'chat_screen.dart';
import 'workout_widgets.dart';

/// Klient: moje check-iny.
final myCheckInsProvider = FutureProvider<List<CheckIn>>(
  (ref) => CheckInService.listMine(),
);

String _date(DateTime d) => '${d.day}. ${d.month}.';

const _labels = {
  'sleep': ('Spánek', 'Špatně spím', 'Spím skvěle'),
  'energy': ('Energie', 'Bez energie', 'Plný/á energie'),
  'hunger': ('Hlad', 'Pořád mám hlad', 'Bez hladu'),
  'stress': ('Stres', 'Hodně stresu', 'V klidu'),
  'diet': ('Jídelníček', 'Nedodržuji', 'Dodržuji'),
};

// =====================================================================
// KLIENT – připomínky na obrazovce Dnes
// =====================================================================

/// „Na co nezapomenout“: týdenní check-in a neodeslané tréninky.
class ClientRemindersCard extends ConsumerWidget {
  const ClientRemindersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(clientLinkProvider).valueOrNull;
    if (link == null) return const SizedBox.shrink();
    final checkIns = ref.watch(myCheckInsProvider).valueOrNull;
    final workouts = ref.watch(myWorkoutsProvider).valueOrNull ?? const [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final missed = workouts
        .where((w) =>
            !w.isDone &&
            DateTime(w.date.year, w.date.month, w.date.day).isBefore(today))
        .toList();
    final checkInDue = checkIns != null && CheckInService.isDue(checkIns);

    if (!checkInDue && missed.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Na co nezapomenout',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: cs.onSecondaryContainer,
              ),
            ),
            if (checkInDue)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.fact_check_outlined,
                    color: cs.onSecondaryContainer),
                title: const Text('Týdenní check-in pro trenéra'),
                subtitle: Text(
                  checkIns.isEmpty
                      ? 'Zabere minutu – váha a jak se cítíš.'
                      : 'Poslední ${_date(checkIns.first.date)} – je čas na další.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CheckInScreen()),
                ),
              ),
            if (missed.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.assignment_late_outlined,
                    color: cs.onSecondaryContainer),
                title: Text(
                  missed.length == 1
                      ? 'Neodeslaný trénink'
                      : 'Neodeslané tréninky: ${missed.length}',
                ),
                subtitle: Text(
                  'Odcvičil/a jsi ${missed.first.title} '
                  '(${_date(missed.first.date)})? Zapiš ho a odešli.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorkoutLogScreen(assignment: missed.first),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// KLIENT – formulář check-inu
// =====================================================================

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  late final TextEditingController _weight;
  final _note = TextEditingController();
  final Map<String, int> _values = {
    for (final k in _labels.keys) k: 3,
  };
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final w = ref.read(userProfileProvider)?.weight ?? 0;
    _weight = TextEditingController(
      text: w > 0 ? w.toStringAsFixed(1).replaceAll('.', ',') : '',
    );
  }

  @override
  void dispose() {
    _weight.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final weight =
        double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    if (weight != null && (weight < 30 || weight > 300)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zkontroluj prosím váhu.')),
      );
      return;
    }
    setState(() => _busy = true);
    final now = DateTime.now();
    try {
      await CheckInService.submit(
        CheckIn(
          id: 'c_${now.microsecondsSinceEpoch}',
          date: now,
          weight: weight,
          sleep: _values['sleep']!,
          energy: _values['energy']!,
          hunger: _values['hunger']!,
          stress: _values['stress']!,
          diet: _values['diet']!,
          note: _note.text.trim(),
        ),
      );
      // Nová váha i do profilu – trenér ji uvidí a jídelníčky se přepočítají.
      final profile = ref.read(userProfileProvider);
      if (weight != null && profile != null && profile.weight != weight) {
        await ref
            .read(userProfileProvider.notifier)
            .updateProfile(profile.copyWith(weight: weight));
        OnlineCoachingService.scheduleSync(delay: const Duration(seconds: 1));
      }
      ref.invalidate(myCheckInsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in odeslán trenérovi. Díky!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nepodařilo se odeslat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Týdenní check-in'),
        actions: const [HelpButton(topic: 'checkin')],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Jak se ti poslední týden dařilo? Trenér podle toho upraví '
                'trénink a jídelníček.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _weight,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Váha dnes ráno (nalačno)',
                  suffixText: 'kg',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              for (final e in _labels.entries)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.value.$1,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<int>(
                        showSelectedIcon: false,
                        segments: [
                          for (var i = 1; i <= 5; i++)
                            ButtonSegment(value: i, label: Text('$i')),
                        ],
                        selected: {_values[e.key]!},
                        onSelectionChanged: (s) =>
                            setState(() => _values[e.key] = s.first),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(e.value.$2,
                              style: TextStyle(
                                  fontSize: 11, color: cs.onSurfaceVariant)),
                          const Spacer(),
                          Text(e.value.$3,
                              style: TextStyle(
                                  fontSize: 11, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              TextField(
                controller: _note,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Něco pro trenéra? (nepovinné)',
                  hintText: 'Bolí mě koleno, v pátek jsem měl/a oslavu…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Odeslat trenérovi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// TRENÉR – karta v detailu klienta
// =====================================================================

final _coachCheckInsProvider = FutureProvider.autoDispose
    .family<(CoachingLink?, List<CheckIn>), String>((ref, clientId) async {
  final link = await ref.watch(coachLinkForClientProvider(clientId).future);
  if (link == null || !link.isConnected) return (link, const <CheckIn>[]);
  try {
    return (link, await CheckInService.listForLink(link.linkId));
  } catch (_) {
    return (link, const <CheckIn>[]);
  }
});

final _coachWorkoutsProvider = FutureProvider.autoDispose
    .family<List<WorkoutAssignment>, String>((ref, clientId) async {
  try {
    return await WorkoutAssignmentService.listForClient(clientId);
  } catch (_) {
    return const <WorkoutAssignment>[];
  }
});

/// Souhrn posledních 30 dní: váha, tréninky, pohoda, jídelníček.
class _ThirtyDays extends StatelessWidget {
  final List<CheckIn> checkIns;
  final List<WorkoutAssignment> workouts;
  const _ThirtyDays({required this.checkIns, required this.workouts});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final since = now.subtract(const Duration(days: 30));
    final today = DateTime(now.year, now.month, now.day);

    final recent = checkIns.where((c) => c.date.isAfter(since)).toList();
    final weights = [
      for (final c in checkIns.reversed)
        if (c.weight != null && c.date.isAfter(now.subtract(const Duration(days: 90))))
          c.weight!,
    ];
    final withW = recent.where((c) => c.weight != null).toList();
    double? change;
    if (withW.length >= 2) {
      change = withW.first.weight! - withW.last.weight!;
    }

    final due = workouts
        .where((w) => w.date.isAfter(since) && !w.date.isAfter(today))
        .toList();
    final done = due.where((w) => w.isDone).length;

    double? avg(int Function(CheckIn c) pick) => recent.isEmpty
        ? null
        : recent.fold<int>(0, (a, c) => a + pick(c)) / recent.length;
    final feel = recent.isEmpty
        ? null
        : recent.fold<double>(0, (a, c) => a + c.score) / recent.length;
    final diet = avg((c) => c.diet);

    String f1(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

    Widget tile(String label, String value, {Color? color}) => Expanded(
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        );

    Color? scoreColor(double? v) => v == null
        ? null
        : v >= 3.8
            ? Colors.green.shade700
            : v >= 2.8
                ? Colors.orange.shade800
                : cs.error;

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 4),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              'Posledních 30 dní',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Row(
            children: [
              tile(
                'váha',
                change == null
                    ? '–'
                    : '${change > 0 ? '+' : ''}${f1(change)} kg',
              ),
              tile(
                'tréninky',
                due.isEmpty ? '–' : '$done / ${due.length}',
                color: due.isEmpty
                    ? null
                    : scoreColor(done / due.length * 5),
              ),
              tile(
                'pohoda',
                feel == null ? '–' : '${f1(feel)} / 5',
                color: scoreColor(feel),
              ),
              tile(
                'jídelníček',
                diet == null ? '–' : '${f1(diet)} / 5',
                color: scoreColor(diet),
              ),
            ],
          ),
          if (weights.length >= 2) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              width: double.infinity,
              child: CustomPaint(
                painter: _WeightLine(weights, cs.primary, cs.outlineVariant),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 2),
              child: Text(
                'Váha z check-inů (90 dní): ${f1(weights.first)} → ${f1(weights.last)} kg',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeightLine extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color grid;
  _WeightLine(this.values, this.color, this.grid);

  @override
  void paint(Canvas canvas, Size size) {
    var lo = values.reduce((a, b) => a < b ? a : b);
    var hi = values.reduce((a, b) => a > b ? a : b);
    if (hi - lo < 1) {
      final mid = (hi + lo) / 2;
      lo = mid - 0.5;
      hi = mid + 0.5;
    }
    const pad = 6.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    Offset pt(int i) => Offset(
          pad + (values.length == 1 ? 0 : w * i / (values.length - 1)),
          pad + h - (values[i] - lo) / (hi - lo) * h,
        );

    canvas.drawLine(
      Offset(pad, size.height - pad),
      Offset(size.width - pad, size.height - pad),
      Paint()
        ..color = grid
        ..strokeWidth = 1,
    );
    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(pt(i).dx, pt(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(pt(i), 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightLine old) =>
      old.values != values || old.color != color;
}

/// Přehled týdenních check-inů klienta (jen u online klientů).
class ClientCheckInsCard extends ConsumerWidget {
  final CoachClient client;
  const ClientCheckInsCard({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_coachCheckInsProvider(client.clientId)).valueOrNull;
    final link = data?.$1;
    if (link == null || !link.isConnected) return const SizedBox.shrink();
    final list = data!.$2;
    final workouts =
        ref.watch(_coachWorkoutsProvider(client.clientId)).valueOrNull ??
            const <WorkoutAssignment>[];
    final cs = Theme.of(context).colorScheme;
    final due = CheckInService.isDue(list);

    Color scoreColor(int v) => v >= 4
        ? Colors.green.shade600
        : v == 3
            ? Colors.orange.shade600
            : cs.error;

    Widget dot(String short, String label, int v) => Tooltip(
          message: '$label: $v/5',
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: scoreColor(v).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$short $v',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: scoreColor(v),
              ),
            ),
          ),
        );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fact_check_outlined, color: cs.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Check-in a posledních 30 dní',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                const HelpButton(topic: 'checkin'),
                IconButton(
                  tooltip: 'Obnovit',
                  onPressed: () {
                    ref.invalidate(_coachCheckInsProvider(client.clientId));
                    ref.invalidate(_coachWorkoutsProvider(client.clientId));
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            _ThirtyDays(checkIns: list, workouts: workouts),
            if (due)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: cs.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        list.isEmpty
                            ? 'Klient zatím check-in neposlal.'
                            : 'Check-in chybí (poslední ${_date(list.first.date)}).',
                        style: TextStyle(color: cs.error, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CoachingChatScreen(
                            linkId: link.linkId,
                            asCoach: true,
                            title: client.displayName,
                          ),
                        ),
                      ),
                      child: const Text('Připomenout'),
                    ),
                  ],
                ),
              ),
            for (var i = 0; i < list.length && i < 6; i++) ...[
              const Divider(height: 16),
              Builder(builder: (context) {
                final c = list[i];
                final prev = i + 1 < list.length ? list[i + 1] : null;
                final diff = (c.weight != null && prev?.weight != null)
                    ? c.weight! - prev!.weight!
                    : null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _date(c.date),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 10),
                        if (c.weight != null)
                          Text(
                            '${c.weight!.toStringAsFixed(1).replaceAll('.', ',')} kg'
                            '${diff == null ? '' : ' (${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1).replaceAll('.', ',')})'}',
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      runSpacing: 4,
                      children: [
                        dot('Spánek', 'Spánek', c.sleep),
                        dot('Energie', 'Energie', c.energy),
                        dot('Hlad', 'Hlad (5 = bez hladu)', c.hunger),
                        dot('Stres', 'Stres (5 = v klidu)', c.stress),
                        dot('Strava', 'Dodržování jídelníčku', c.diet),
                      ],
                    ),
                    if (c.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '„${c.note}“',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
