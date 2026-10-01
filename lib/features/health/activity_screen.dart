import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/coach/coach_client.dart';
import '../../providers/coach/app_role_provider.dart';
import '../../providers/health_provider.dart';
import '../../services/health/health_sync_service.dart';
import '../coaching/chat_screen.dart';
import '../help/help_button.dart';

// =====================================================================
// Formátování
// =====================================================================

String fmtInt(int v) {
  final s = v.abs().toString();
  final b = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

String fmtSleep(int minutes) {
  if (minutes <= 0) return '–';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}

String fmtKm(int meters) =>
    '${(meters / 1000).toStringAsFixed(meters >= 10000 ? 0 : 1).replaceAll('.', ',')} km';

const _wdShort = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];

String _date(DateTime d) => '${_wdShort[d.weekday - 1]} ${d.day}. ${d.month}.';

String _ago(DateTime? t) {
  if (t == null) return 'zatím nenačteno';
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'právě teď';
  if (diff.inMinutes < 60) return 'před ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'před ${diff.inHours} h';
  return 'před ${diff.inDays} dny';
}

IconData workoutIcon(String type) {
  final t = type.toUpperCase();
  if (t.contains('STRENGTH') || t.contains('WEIGHT')) {
    return Icons.fitness_center;
  }
  if (t.contains('RUNNING')) return Icons.directions_run;
  if (t.contains('WALKING') || t.contains('HIKING')) {
    return Icons.directions_walk;
  }
  if (t.contains('BIKING') || t.contains('CYCLING')) {
    return Icons.directions_bike;
  }
  if (t.contains('SWIM')) return Icons.pool;
  if (t.contains('YOGA') || t.contains('PILATES')) {
    return Icons.self_improvement;
  }
  return Icons.sports;
}

// =====================================================================
// KLIENT – obrazovka „Aktivita a hodinky“
// =====================================================================

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    final r = await ref.read(healthProvider.notifier).connect();
    if (!context.mounted) return;
    switch (r) {
      case HealthConnectResult.ok:
        final s = ref.read(healthProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.hasData
                  ? 'Hotovo – data z hodinek se načetla.'
                  : 'Propojeno. Pokud nevidíš data, zkontroluj oprávnění '
                      'v aplikaci ${HealthSyncService.platformAppName}.',
            ),
          ),
        );
      case HealthConnectResult.needsHealthConnect:
        final install = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Chybí Health Connect'),
            content: const Text(
              'Na Androidu se data z hodinek předávají přes aplikaci '
              'Health Connect od Googlu. Nainstaluj ji (nebo aktualizuj), '
              'v aplikaci svých hodinek (Samsung Health, Garmin Connect, '
              'Fitbit, Mi Fitness…) zapni sdílení do Health Connect '
              'a pak se sem vrať.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Zpět'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Nainstalovat'),
              ),
            ],
          ),
        );
        if (install == true) await HealthSyncService.installHealthConnect();
      case HealthConnectResult.denied:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Přístup nebyl povolen. Můžeš ho zapnout v aplikaci '
              '${HealthSyncService.platformAppName}.',
            ),
          ),
        );
      case HealthConnectResult.unsupported:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Propojení funguje jen v aplikaci na telefonu.'),
          ),
        );
      case HealthConnectResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Propojení se nepodařilo. Zkus to prosím znovu.'),
          ),
        );
    }
  }

  Future<void> _editGoal(BuildContext context, WidgetRef ref, int goal) async {
    final c = TextEditingController(text: goal.toString());
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Denní cíl kroků'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            suffixText: 'kroků',
            helperText: 'Běžně 7 000–10 000 kroků denně.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              int.tryParse(c.text.replaceAll(RegExp(r'\s'), '')),
            ),
            child: const Text('Uložit'),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(milliseconds: 400), c.dispose);
    if (v != null) await ref.read(healthProvider.notifier).setStepGoal(v);
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Odpojit hodinky?'),
        content: const Text(
          'SPAL přestane načítat data z hodinek a smaže je z telefonu '
          'i u trenéra. Data v hodinkách a ve zdravotní aplikaci zůstanou.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zpět'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Odpojit'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(healthProvider.notifier).disconnect();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(healthProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivita a hodinky'),
        actions: [
          if (s.enabled)
            IconButton(
              tooltip: 'Načíst znovu',
              onPressed: s.syncing
                  ? null
                  : () => ref.read(healthProvider.notifier).sync(),
              icon: s.syncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          const HelpButton(topic: 'activity'),
        ],
      ),
      body: !s.loaded
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(healthProvider.notifier).sync(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!s.supported)
                    const _InfoCard(
                      icon: Icons.phone_iphone,
                      title: 'Funguje v aplikaci na telefonu',
                      text: 'Propojení s hodinkami běží přes Apple Zdraví '
                          '(iPhone) nebo Health Connect (Android). Otevři SPAL '
                          'v telefonu a propoj hodinky tam.',
                    )
                  else if (!s.enabled)
                    _ConnectCard(onConnect: () => _connect(context, ref))
                  else ...[
                    if (s.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          s.error!,
                          style: TextStyle(color: cs.error),
                        ),
                      ),
                    if (!s.hasData && !s.syncing)
                      _InfoCard(
                        icon: Icons.info_outline,
                        title: 'Zatím žádná data',
                        text: HealthSyncService.isIOS
                            ? 'Otevři aplikaci Zdraví → profil vpravo nahoře → '
                                'Aplikace → SPAL a zapni všechny položky. '
                                'Hodinky jiných značek (Garmin, Samsung…) musí '
                                'mít ve své aplikaci zapnuté sdílení do '
                                'Apple Zdraví.'
                            : 'Otevři Health Connect → Oprávnění aplikací → '
                                'SPAL a povol vše. V aplikaci hodinek '
                                '(Samsung Health, Garmin Connect, Fitbit…) '
                                'zapni sdílení do Health Connect.',
                      ),
                    ActivityOverview(
                      days: s.days,
                      stepGoal: s.stepGoal,
                      showToday: true,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.flag_outlined),
                            title: const Text('Denní cíl kroků'),
                            subtitle: Text('${fmtInt(s.stepGoal)} kroků'),
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () => _editGoal(context, ref, s.stepGoal),
                          ),
                          ListTile(
                            leading: const Icon(Icons.sync),
                            title: Text(
                              'Zdroj: ${HealthSyncService.platformAppName}',
                            ),
                            subtitle: Text(
                              'Naposledy načteno ${_ago(s.lastSync)}. '
                              'Načítá se samo při otevření aplikace.',
                            ),
                          ),
                          ListTile(
                            leading: Icon(Icons.link_off, color: cs.error),
                            title: Text(
                              'Odpojit hodinky',
                              style: TextStyle(color: cs.error),
                            ),
                            onTap: () => _disconnect(context, ref),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectCard extends StatelessWidget {
  final VoidCallback onConnect;
  const _ConnectCard({required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget row(IconData i, String t) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(i, size: 20, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(t)),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.watch, size: 32, color: cs.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Propoj chytré hodinky',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'SPAL si načte data z aplikace '
              '${HealthSyncService.platformAppName}. Funguje s Apple Watch, '
              'Garmin, Samsung, Fitbit, Xiaomi, Amazfit, Polar i dalšími – '
              'stačí, když hodinky posílají data do telefonu.',
            ),
            const SizedBox(height: 6),
            row(Icons.directions_walk, 'Kroky a vzdálenost'),
            row(Icons.local_fire_department_outlined,
                'Kalorie spálené pohybem'),
            row(Icons.bedtime_outlined, 'Spánek'),
            row(Icons.favorite_border, 'Klidový tep'),
            row(Icons.monitor_weight_outlined, 'Váha z chytré váhy'),
            row(Icons.sports, 'Tréninky zaznamenané hodinkami'),
            const SizedBox(height: 14),
            Text(
              'Data se jen čtou, nic se nezapisuje. Vidíš je ty a tvůj '
              'trenér (pokud jsi s ním propojený). Nikdy se nepoužívají '
              'k reklamě. Odpojit je můžeš kdykoli.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onConnect,
                icon: const Icon(Icons.link),
                label: const Text('Propojit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Společný přehled (klient i trenér)
// =====================================================================

enum _Metric { steps, kcal, sleep }

class ActivityOverview extends StatefulWidget {
  final List<HealthDay> days;
  final int stepGoal;
  final bool showToday;

  const ActivityOverview({
    super.key,
    required this.days,
    required this.stepGoal,
    this.showToday = false,
  });

  @override
  State<ActivityOverview> createState() => _ActivityOverviewState();
}

class _ActivityOverviewState extends State<ActivityOverview> {
  _Metric _metric = _Metric.steps;
  int _range = 7;

  HealthDay? _dayFor(DateTime d) {
    final k = HealthDay.keyOf(d);
    for (final x in widget.days) {
      if (x.key == k) return x;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final t = _dayFor(today) ?? HealthDay(date: today);
    final week = HealthStats.of(widget.days);
    final month = HealthStats.of(widget.days, n: 30);

    Widget tile(IconData icon, String label, String value, {Widget? extra}) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            if (extra != null) ...[const SizedBox(height: 6), extra],
          ],
        ),
      );
    }

    Widget grid(List<Widget> children) => LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 560 ? 3 : 2;
            final w = (c.maxWidth - (cols - 1) * 10) / cols;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final ch in children) SizedBox(width: w, child: ch),
              ],
            );
          },
        );

    // ---- graf ----
    final from = today.subtract(Duration(days: _range - 1));
    final points = <(DateTime, double)>[
      for (var i = 0; i < _range; i++)
        () {
          final d = from.add(Duration(days: i));
          final x = _dayFor(d);
          final v = switch (_metric) {
            _Metric.steps => (x?.steps ?? 0).toDouble(),
            _Metric.kcal => (x?.activeKcal ?? 0).toDouble(),
            _Metric.sleep => (x?.sleepMin ?? 0) / 60,
          };
          return (d, v);
        }(),
    ];
    final goalLine =
        _metric == _Metric.steps ? widget.stepGoal.toDouble() : null;
    var maxY = points.fold<double>(0, (a, p) => p.$2 > a ? p.$2 : a);
    if (goalLine != null && goalLine > maxY) maxY = goalLine;
    if (maxY <= 0) maxY = _metric == _Metric.sleep ? 8 : 100;

    final workouts = [
      for (final d in widget.days.reversed) ...d.workouts.reversed,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showToday) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Dnes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
          grid([
            tile(
              Icons.directions_walk,
              'Kroky',
              fmtInt(t.steps),
              extra: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: widget.stepGoal <= 0
                      ? 0
                      : (t.steps / widget.stepGoal).clamp(0.0, 1.0),
                ),
              ),
            ),
            tile(Icons.local_fire_department_outlined, 'Pohyb',
                '${fmtInt(t.activeKcal)} kcal'),
            tile(Icons.route_outlined, 'Vzdálenost', fmtKm(t.distanceM)),
            tile(Icons.bedtime_outlined, 'Spánek v noci', fmtSleep(t.sleepMin)),
            tile(Icons.favorite_border, 'Klidový tep',
                t.restingHr == null ? '–' : '${t.restingHr} tep/min'),
            tile(
              Icons.monitor_weight_outlined,
              'Váha',
              t.weight == null
                  ? '–'
                  : '${t.weight!.toStringAsFixed(1).replaceAll('.', ',')} kg',
            ),
          ]),
          const SizedBox(height: 16),
        ],
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in _Metric.values)
                      ChoiceChip(
                        label: Text(switch (m) {
                          _Metric.steps => 'Kroky',
                          _Metric.kcal => 'Pohyb kcal',
                          _Metric.sleep => 'Spánek',
                        }),
                        selected: _metric == m,
                        onSelected: (_) => setState(() => _metric = m),
                      ),
                    const SizedBox(width: 6),
                    for (final r in const [7, 30])
                      ChoiceChip(
                        label: Text('$r dní'),
                        selected: _range == r,
                        onSelected: (_) => setState(() => _range = r),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY * 1.15,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          if (goalLine != null)
                            HorizontalLine(
                              y: goalLine,
                              color: Colors.green.shade600,
                              strokeWidth: 1.5,
                              dashArray: const [6, 4],
                            ),
                        ],
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (v, meta) => Text(
                              _metric == _Metric.sleep
                                  ? '${v.round()} h'
                                  : v >= 1000
                                      ? '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k'
                                      : v.round().toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (v, meta) {
                              final i = v.toInt();
                              if (i < 0 || i >= points.length) {
                                return const SizedBox.shrink();
                              }
                              final d = points[i].$1;
                              final show = _range <= 7 ||
                                  i == points.length - 1 ||
                                  (points.length - 1 - i) % 7 == 0;
                              if (!show) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _range <= 7
                                      ? _wdShort[d.weekday - 1]
                                      : '${d.day}.${d.month}.',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < points.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: points[i].$2,
                                width: _range <= 7 ? 18 : 6,
                                color: goalLine != null &&
                                        points[i].$2 >= goalLine
                                    ? Colors.green.shade600
                                    : cs.primary,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Průměr na den',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _AvgRow(label: '', a: 'posledních 7 dní', b: '30 dní', header: true),
                _AvgRow(
                  label: 'Kroky',
                  a: fmtInt(week.avgSteps),
                  b: fmtInt(month.avgSteps),
                ),
                _AvgRow(
                  label: 'Pohyb',
                  a: '${fmtInt(week.avgActiveKcal)} kcal',
                  b: '${fmtInt(month.avgActiveKcal)} kcal',
                ),
                _AvgRow(
                  label: 'Spánek',
                  a: fmtSleep(week.avgSleepMin),
                  b: fmtSleep(month.avgSleepMin),
                ),
                _AvgRow(
                  label: 'Klidový tep',
                  a: week.avgRestingHr == null ? '–' : '${week.avgRestingHr}',
                  b: month.avgRestingHr == null ? '–' : '${month.avgRestingHr}',
                ),
                _AvgRow(
                  label: 'Tréninky',
                  a: '${week.workouts}× (${week.workoutMinutes} min)',
                  b: '${month.workouts}×',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tréninky z hodinek',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                if (workouts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Za posledních 30 dní žádný zaznamenaný trénink.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                for (final w in workouts.take(15))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Icon(workoutIcon(w.type),
                          color: cs.onPrimaryContainer, size: 20),
                    ),
                    title: Text(w.label),
                    subtitle: Text(
                      [
                        _date(w.start),
                        '${w.minutes} min',
                        if (w.kcal > 0) '${fmtInt(w.kcal)} kcal',
                        if (w.distanceM > 0) fmtKm(w.distanceM),
                      ].join(' · '),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AvgRow extends StatelessWidget {
  final String label;
  final String a;
  final String b;
  final bool header;
  const _AvgRow({
    required this.label,
    required this.a,
    required this.b,
    this.header = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = header
        ? TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )
        : const TextStyle(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label)),
          Expanded(flex: 4, child: Text(a, style: style)),
          Expanded(flex: 3, child: Text(b, style: style)),
        ],
      ),
    );
  }
}

// =====================================================================
// KLIENT – karta na obrazovce Dnes
// =====================================================================

class TodayActivityCard extends ConsumerWidget {
  const TodayActivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trenér pracující v klientském režimu by viděl data ze SVÉHO telefonu.
    if (ref.watch(appRoleProvider) == AppRole.coach) {
      return const SizedBox.shrink();
    }
    final s = ref.watch(healthProvider);
    if (!s.supported || !s.loaded) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    void open() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ActivityScreen()),
        );

    if (!s.enabled) {
      if (s.promptDismissed) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(Icons.watch, color: cs.primary),
            title: const Text('Máš chytré hodinky?'),
            subtitle: const Text(
              'Propoj je a kroky, pohyb i spánek se zapíšou samy.',
            ),
            onTap: open,
            trailing: IconButton(
              tooltip: 'Skrýt',
              icon: const Icon(Icons.close),
              onPressed: () => ref.read(healthProvider.notifier).dismissPrompt(),
            ),
          ),
        ),
      );
    }

    final t = s.today ?? HealthDay(date: DateTime.now());
    Widget stat(IconData i, String v, String l) => Expanded(
          child: Column(
            children: [
              Icon(i, size: 20, color: cs.primary),
              const SizedBox(height: 4),
              Text(v, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(l,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: open,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.watch, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Aktivita dnes',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (s.syncing)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    stat(Icons.directions_walk, fmtInt(t.steps), 'kroků'),
                    stat(Icons.local_fire_department_outlined,
                        fmtInt(t.activeKcal), 'kcal pohybem'),
                    stat(Icons.bedtime_outlined, fmtSleep(t.sleepMin),
                        'spánek'),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: s.stepGoal <= 0
                        ? 0
                        : (t.steps / s.stepGoal).clamp(0.0, 1.0),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.steps >= s.stepGoal
                      ? 'Cíl ${fmtInt(s.stepGoal)} kroků splněn!'
                      : 'Do cíle zbývá ${fmtInt(s.stepGoal - t.steps)} kroků',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// KLIENT – tip v Jídle podle pohybu
// =====================================================================

class ActivityFoodHint extends ConsumerWidget {
  const ActivityFoodHint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(appRoleProvider) == AppRole.coach) {
      return const SizedBox.shrink();
    }
    final s = ref.watch(healthProvider);
    if (!s.supported || !s.enabled) return const SizedBox.shrink();
    final t = s.today;
    if (t == null || t.activeKcal <= 0) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final typical = HealthStats.typicalActiveKcal(s.days);
    // Navíc jen polovinu rozdílu – hodinky výdej spíš nadhodnocují.
    final extra = typical <= 0
        ? 0
        : (((t.activeKcal - typical) * 0.5) / 10).round() * 10;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(Icons.local_fire_department_outlined,
              color: cs.primary),
          title: Text(
            'Pohyb dnes: ${fmtInt(t.activeKcal)} kcal · ${fmtInt(t.steps)} kroků',
          ),
          subtitle: Text(
            extra >= 50
                ? 'Jsi aktivnější než obvykle. Klidně si dnes dej navíc '
                    'asi $extra kcal – třeba ${(extra / 4).round()} g '
                    'sacharidů (ovoce, rýže, pečivo).'
                : 'Tvůj denní cíl už počítá s běžným pohybem – drž se ho.',
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ActivityScreen()),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// TRENÉR – aktivita klienta
// =====================================================================

typedef ClientActivity = ({
  List<HealthDay> days,
  DateTime? updatedAt,
  String source,
});

final _clientActivityProvider = StreamProvider.autoDispose
    .family<ClientActivity?, String>((ref, clientId) async* {
  final link = await ref.watch(coachLinkForClientProvider(clientId).future);
  if (link == null || !link.isConnected) {
    yield null;
    return;
  }
  yield* HealthSyncService.watchForLink(link.linkId).handleError((_) {});
});

/// Karta v detailu klienta – zobrazí se, jen když klient propojil hodinky.
class ClientActivityCard extends ConsumerWidget {
  final CoachClient client;
  const ClientActivityCard({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(_clientActivityProvider(client.clientId)).valueOrNull;
    if (a == null || a.days.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final w = HealthStats.of(a.days);
    final prev = HealthStats.of(
      [
        for (final d in a.days)
          if (d.date.isBefore(
            DateTime.now().subtract(const Duration(days: 7)),
          ))
            d,
      ],
      n: 14,
    );

    Widget stat(String v, String l, {String? trend}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900)),
              Text(l,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              if (trend != null)
                Text(trend,
                    style: TextStyle(fontSize: 11, color: cs.primary)),
            ],
          ),
        );

    String? trend(int now, int before) {
      if (now <= 0 || before <= 0) return null;
      final p = ((now - before) / before * 100).round();
      if (p.abs() < 5) return 'beze změny';
      return '${p > 0 ? '+' : ''}$p % proti dřívějšku';
    }

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClientActivityScreen(client: client),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.watch, color: cs.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Aktivita z hodinek (7 dní)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const HelpButton(topic: 'activity'),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  stat(fmtInt(w.avgSteps), 'kroků / den',
                      trend: trend(w.avgSteps, prev.avgSteps)),
                  stat('${fmtInt(w.avgActiveKcal)} kcal', 'pohyb / den',
                      trend: trend(w.avgActiveKcal, prev.avgActiveKcal)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  stat(fmtSleep(w.avgSleepMin), 'spánek / noc'),
                  stat('${w.workouts}×', 'tréninků z hodinek'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Zdroj: ${a.source.isEmpty ? 'hodinky' : a.source} · '
                'aktualizováno ${_ago(a.updatedAt)}',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClientActivityScreen extends ConsumerWidget {
  final CoachClient client;
  const ClientActivityScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_clientActivityProvider(client.clientId));
    final a = async.valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text('Aktivita – ${client.displayName}'),
        actions: const [HelpButton(topic: 'activity')],
      ),
      body: async.isLoading && a == null
          ? const Center(child: CircularProgressIndicator())
          : a == null || a.days.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Klient zatím nepropojil hodinky.\n'
                      'Propojí je v aplikaci: Pokrok → Aktivita a hodinky.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ActivityOverview(
                      days: a.days,
                      stepGoal: HealthSyncService.defaultStepGoal,
                      showToday: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Zdroj: ${a.source} · aktualizováno ${_ago(a.updatedAt)}. '
                      'Data se obnoví, když klient otevře aplikaci.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
    );
  }
}
