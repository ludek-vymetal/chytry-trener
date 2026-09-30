import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/coach/coach_client.dart';
import '../../../providers/coach/coach_clients_controller.dart';
import '../../../providers/coach/finance_provider.dart';
import '../../help/help_button.dart';

enum _Period { month, quarter, year }

const _months = [
  'leden', 'únor', 'březen', 'duben', 'květen', 'červen',
  'červenec', 'srpen', 'září', 'říjen', 'listopad', 'prosinec',
];
const _monthsShort = [
  'led', 'úno', 'bře', 'dub', 'kvě', 'čvn',
  'čvc', 'srp', 'zář', 'říj', 'lis', 'pro',
];

String kc(double v) {
  final s = v.round().abs().toString();
  final b = StringBuffer(v < 0 ? '−' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '$b Kč';
}

/// Příjmy trenéra: měsíce v grafu, porovnání období, kategorie a klienti.
class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key});

  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends ConsumerState<IncomeScreen> {
  _Period _period = _Period.month;
  DateTime _anchor = DateTime.now();

  (DateTime, DateTime) _range(DateTime a) {
    switch (_period) {
      case _Period.month:
        final s = DateTime(a.year, a.month);
        return (s, DateTime(a.year, a.month + 1));
      case _Period.quarter:
        final q = (a.month - 1) ~/ 3;
        final s = DateTime(a.year, q * 3 + 1);
        return (s, DateTime(a.year, q * 3 + 4));
      case _Period.year:
        return (DateTime(a.year), DateTime(a.year + 1));
    }
  }

  DateTime _shift(DateTime a, int dir) => switch (_period) {
        _Period.month => DateTime(a.year, a.month + dir),
        _Period.quarter => DateTime(a.year, a.month + 3 * dir),
        _Period.year => DateTime(a.year + dir, a.month),
      };

  String _label(DateTime a) {
    switch (_period) {
      case _Period.month:
        return '${_months[a.month - 1]} ${a.year}';
      case _Period.quarter:
        return '${(a.month - 1) ~/ 3 + 1}. čtvrtletí ${a.year}';
      case _Period.year:
        return 'rok ${a.year}';
    }
  }

  String get _prevWord => switch (_period) {
        _Period.month => 'minulý měsíc',
        _Period.quarter => 'minulé čtvrtletí',
        _Period.year => 'minulý rok',
      };

  double _sum(List<IncomeEntry> all, (DateTime, DateTime) r) => all
      .where((e) => !e.date.isBefore(r.$1) && e.date.isBefore(r.$2))
      .fold<double>(0, (a, e) => a + e.amount);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final all = ref.watch(incomeEntriesProvider);
    final r = _range(_anchor);
    final prevR = _range(_shift(_anchor, -1));
    final lastYearR = (
      DateTime(r.$1.year - 1, r.$1.month, r.$1.day),
      DateTime(r.$2.year - 1, r.$2.month, r.$2.day),
    );
    final inRange = all
        .where((e) => !e.date.isBefore(r.$1) && e.date.isBefore(r.$2))
        .toList();
    final total = inRange.fold<double>(0, (a, e) => a + e.amount);
    final prev = _sum(all, prevR);
    final lastYear = _sum(all, lastYearR);

    // 12 měsíců končících měsícem kotvy.
    final end = DateTime(r.$2.year, r.$2.month - 1);
    final months = [
      for (var i = 11; i >= 0; i--) DateTime(end.year, end.month - i),
    ];
    final monthly = [
      for (final m in months)
        _sum(all, (m, DateTime(m.year, m.month + 1))),
    ];
    final maxY = monthly.fold<double>(0, (a, v) => v > a ? v : a);
    final nonZero = monthly.where((v) => v > 0).toList();
    final avg = nonZero.isEmpty
        ? 0.0
        : nonZero.reduce((a, b) => a + b) / nonZero.length;

    final byCat = <String, double>{};
    final byClient = <String, double>{};
    for (final e in inRange) {
      byCat[e.category] = (byCat[e.category] ?? 0) + e.amount;
      final n = e.clientName.trim().isEmpty ? 'Bez klienta' : e.clientName;
      byClient[n] = (byClient[n] ?? 0) + e.amount;
    }
    final cats = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final clients = byClient.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    Widget compare(String label, double base) {
      if (base <= 0) {
        return Text('$label: –',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13));
      }
      final diff = total - base;
      final pct = diff / base * 100;
      final up = diff >= 0;
      return Row(
        children: [
          Icon(up ? Icons.trending_up : Icons.trending_down,
              size: 18,
              color: up ? Colors.green.shade600 : cs.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label: ${kc(base)}  (${up ? '+' : ''}${pct.round()} %, '
              '${up ? '+' : ''}${kc(diff)})',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Příjmy'),
        actions: const [HelpButton(topic: 'income')],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showPaymentEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Platba'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              SegmentedButton<_Period>(
                segments: const [
                  ButtonSegment(value: _Period.month, label: Text('Měsíc')),
                  ButtonSegment(
                      value: _Period.quarter, label: Text('Čtvrtletí')),
                  ButtonSegment(value: _Period.year, label: Text('Rok')),
                ],
                selected: {_period},
                onSelectionChanged: (s) => setState(() => _period = s.first),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        setState(() => _anchor = _shift(_anchor, -1)),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      _label(_anchor),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        setState(() => _anchor = _shift(_anchor, 1)),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              Card(
                color: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vyděláno',
                          style: TextStyle(color: cs.onPrimaryContainer)),
                      Text(
                        kc(total),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        '${inRange.length} ${inRange.length == 1 ? 'platba' : inRange.length < 5 && inRange.isNotEmpty ? 'platby' : 'plateb'}',
                        style: TextStyle(color: cs.onPrimaryContainer),
                      ),
                      const SizedBox(height: 10),
                      compare('Oproti: $_prevWord', prev),
                      const SizedBox(height: 4),
                      compare('Stejné období loni', lastYear),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Posledních 12 měsíců · průměr ${kc(avg)} / měsíc',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 220,
                        child: maxY <= 0
                            ? Center(
                                child: Text(
                                  'Zatím žádné zaplacené platby.',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              )
                            : BarChart(
                                BarChartData(
                                  maxY: maxY * 1.15,
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                  ),
                                  borderData: FlBorderData(show: false),
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
                                        reservedSize: 48,
                                        getTitlesWidget: (v, meta) => Text(
                                          v >= 1000
                                              ? '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)} tis.'
                                              : v.round().toString(),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 26,
                                        getTitlesWidget: (v, meta) {
                                          final i = v.toInt();
                                          if (i < 0 || i >= months.length) {
                                            return const SizedBox.shrink();
                                          }
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Text(
                                              _monthsShort[months[i].month - 1],
                                              style:
                                                  const TextStyle(fontSize: 10),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  barGroups: [
                                    for (var i = 0; i < months.length; i++)
                                      BarChartGroupData(
                                        x: i,
                                        barRods: [
                                          BarChartRodData(
                                            toY: monthly[i],
                                            width: 16,
                                            color: !months[i]
                                                        .isBefore(r.$1) &&
                                                    months[i].isBefore(r.$2)
                                                ? cs.primary
                                                : cs.primary
                                                    .withValues(alpha: 0.35),
                                            borderRadius:
                                                const BorderRadius.vertical(
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
              if (cats.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Podle služeb',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        for (final c in cats)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(c.key)),
                                    Text(
                                      '${kc(c.value)} · ${(c.value / total * 100).round()} %',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: c.value / total,
                                    minHeight: 8,
                                    backgroundColor:
                                        cs.surfaceContainerHighest,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (clients.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Podle klientů',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        for (final c in clients.take(10))
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(c.key),
                            trailing: Text(kc(c.value),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Platby v období',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      if (inRange.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Žádné platby. Zaplacené permanentky se sem '
                            'počítají samy, jednorázové platby přidáš '
                            'tlačítkem „Platba“.',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),
                      for (final e in inRange)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(e.manual
                              ? Icons.payments_outlined
                              : Icons.confirmation_number_outlined),
                          title: Text(
                            '${e.clientName.isEmpty ? 'Bez klienta' : e.clientName} · ${e.title}',
                          ),
                          subtitle: Text(
                              '${e.date.day}. ${e.date.month}. ${e.date.year} · ${e.category}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(kc(e.amount),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              if (e.manual)
                                IconButton(
                                  tooltip: 'Smazat platbu',
                                  onPressed: () => ref
                                      .read(paymentsProvider.notifier)
                                      .delete(e.id),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Nová jednorázová platba
// =====================================================================

Future<void> showPaymentEditor(
  BuildContext context,
  WidgetRef ref, {
  CoachClient? client,
}) async {
  final result = await Navigator.of(context).push<Payment>(
    MaterialPageRoute(builder: (_) => _PaymentEditor(client: client)),
  );
  if (result != null) {
    await ref.read(paymentsProvider.notifier).add(result);
  }
}

class _PaymentEditor extends ConsumerStatefulWidget {
  final CoachClient? client;
  const _PaymentEditor({this.client});

  @override
  ConsumerState<_PaymentEditor> createState() => _PaymentEditorState();
}

class _PaymentEditorState extends ConsumerState<_PaymentEditor> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _name = TextEditingController();
  String _category = incomeCategories.first;
  DateTime _date = DateTime.now();
  CoachClient? _client;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
    _name.text = _client?.displayName ?? '';
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickClient() async {
    final all = await ref.read(coachClientsControllerProvider.future);
    if (!mounted) return;
    final list = [
      for (final c in all)
        if (!c.client.isDeleted) c.client,
    ]..sort((a, b) => a.displayName.compareTo(b.displayName));
    final picked = await showModalBottomSheet<CoachClient>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: ListView(
          children: [
            for (final c in list)
              ListTile(
                title: Text(c.displayName),
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _client = picked;
      _name.text = picked.displayName;
    });
  }

  void _save() {
    final amount = double.tryParse(
        _amount.text.trim().replaceAll(' ', '').replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zadej částku.')),
      );
      return;
    }
    Navigator.pop(
      context,
      Payment(
        id: 'pay_${DateTime.now().microsecondsSinceEpoch}',
        clientId: _client?.clientId,
        clientName: _name.text.trim(),
        amount: amount,
        date: _date,
        category: _category,
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nová platba')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _amount,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Částka',
                  suffixText: 'Kč',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Za co', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in incomeCategories)
                    ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Klient (nepovinné)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Vybrat klienta',
                    onPressed: _pickClient,
                    icon: const Icon(Icons.person_search),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _date = d);
                },
                icon: const Icon(Icons.event),
                label: Text('Datum: ${_date.day}. ${_date.month}. ${_date.year}'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Poznámka (nepovinné)',
                  hintText: 'např. masáž zad 60 min, hotově',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Uložit platbu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
