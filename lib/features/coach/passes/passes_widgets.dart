import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/coach/client_pass.dart';
import '../../../models/coach/coach_client.dart';
import '../../../providers/coach/passes_provider.dart';
import '../../help/help_button.dart';

String _d(DateTime d) => '${d.day}. ${d.month}. ${d.year}';

String _kc(double v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '$b Kč';
}

/// Stav permanentky jednou větou.
String passStatus(ClientPass p) {
  final parts = <String>[];
  if (p.type == PassType.visits) {
    parts.add(p.isUsedUp
        ? 'vyčerpáno (${p.totalVisits}/${p.totalVisits})'
        : 'zbývá ${p.remaining} z ${p.totalVisits}');
  }
  final left = p.daysLeft;
  if (p.validUntil != null) {
    if (left! < 0) {
      parts.add('vypršelo ${_d(p.validUntil!)}');
    } else if (left == 0) {
      parts.add('končí dnes');
    } else {
      parts.add('platí do ${_d(p.validUntil!)} (${left == 1 ? 'zítra' : 'ještě $left dní'})');
    }
  }
  if (!p.paid) parts.add('NEZAPLACENO');
  return parts.join(' · ');
}

class _Preset {
  final String title;
  final PassType type;
  final int visits;
  final int months;
  const _Preset(this.title, this.type, this.visits, this.months);
}

const _presets = [
  _Preset('Osobní trénink – 10 vstupů', PassType.visits, 10, 3),
  _Preset('Osobní trénink – 5 vstupů', PassType.visits, 5, 2),
  _Preset('Masáž – 5×', PassType.visits, 5, 3),
  _Preset('Online koučink – 1 měsíc', PassType.period, 0, 1),
  _Preset('Online koučink – 3 měsíce', PassType.period, 0, 3),
  _Preset('Jídelníček na míru', PassType.period, 0, 1),
];

// =====================================================================
// Formulář
// =====================================================================

Future<void> showPassEditor(
  BuildContext context,
  WidgetRef ref, {
  required CoachClient client,
  ClientPass? existing,
}) async {
  final result = await Navigator.of(context).push<ClientPass>(
    MaterialPageRoute(
      builder: (_) => _PassEditorScreen(client: client, existing: existing),
    ),
  );
  if (result != null) {
    await ref.read(passesProvider.notifier).upsert(result);
  }
}

class _PassEditorScreen extends StatefulWidget {
  final CoachClient client;
  final ClientPass? existing;
  const _PassEditorScreen({required this.client, this.existing});

  @override
  State<_PassEditorScreen> createState() => _PassEditorScreenState();
}

class _PassEditorScreenState extends State<_PassEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _visits;
  late final TextEditingController _price;
  late final TextEditingController _note;
  late PassType _type;
  late DateTime _from;
  DateTime? _until;
  late bool _paid;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _visits = TextEditingController(text: '${e?.totalVisits ?? 10}');
    _price = TextEditingController(
      text: e?.price == null ? '' : e!.price!.round().toString(),
    );
    _note = TextEditingController(text: e?.note ?? '');
    _type = e?.type ?? PassType.visits;
    _from = e?.validFrom ?? DateTime.now();
    _until = e?.validUntil;
    _paid = e?.paid ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _visits.dispose();
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  DateTime _plusMonths(DateTime d, int m) =>
      DateTime(d.year, d.month + m, d.day);

  void _applyPreset(_Preset p) {
    setState(() {
      _title.text = p.title;
      _type = p.type;
      if (p.type == PassType.visits) _visits.text = '${p.visits}';
      _until = p.months > 0 ? _plusMonths(_from, p.months) : null;
    });
  }

  Future<void> _pickDate({required bool from}) async {
    final initial = from ? _from : (_until ?? _plusMonths(_from, 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
      } else {
        _until = picked;
      }
    });
  }

  void _save() {
    final title = _title.text.trim();
    final visits = int.tryParse(_visits.text.trim()) ?? 0;
    String? error;
    if (title.isEmpty) error = 'Vyplň název.';
    if (_type == PassType.visits && visits <= 0) {
      error = 'Zadej počet vstupů.';
    }
    if (_type == PassType.period && _until == null) {
      error = 'U časové permanentky vyplň, do kdy platí.';
    }
    if (_until != null && _until!.isBefore(_from)) {
      error = 'Konec platnosti je před začátkem.';
    }
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final price =
        double.tryParse(_price.text.trim().replaceAll(' ', '').replaceAll(',', '.'));
    final now = DateTime.now();
    final e = widget.existing;
    final result = ClientPass(
      id: e?.id ?? 'pass_${now.microsecondsSinceEpoch}',
      clientId: widget.client.clientId,
      clientName: widget.client.displayName,
      type: _type,
      title: title,
      totalVisits: _type == PassType.visits ? visits : 0,
      uses: e?.uses ?? const [],
      validFrom: _from,
      validUntil: _until,
      price: price,
      paid: _paid,
      paidAt: _paid ? (e?.paidAt ?? now) : null,
      note: _note.text.trim(),
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null
            ? 'Nová permanentka – ${widget.client.firstName}'
            : 'Upravit permanentku'),
        actions: const [HelpButton(topic: 'passes')],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.existing == null) ...[
                const Text('Rychlý výběr',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in _presets)
                      ActionChip(
                        label: Text(p.title),
                        onPressed: () => _applyPreset(p),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Název',
                  hintText: 'např. Osobní trénink – 10 vstupů',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<PassType>(
                segments: const [
                  ButtonSegment(
                    value: PassType.visits,
                    icon: Icon(Icons.confirmation_number_outlined),
                    label: Text('Počet vstupů'),
                  ),
                  ButtonSegment(
                    value: PassType.period,
                    icon: Icon(Icons.date_range_outlined),
                    label: Text('Časové období'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 12),
              if (_type == PassType.visits) ...[
                TextField(
                  controller: _visits,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Počet vstupů',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(from: true),
                      icon: const Icon(Icons.event),
                      label: Text('Od ${_d(_from)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(from: false),
                      icon: const Icon(Icons.event_busy),
                      label: Text(_until == null
                          ? (_type == PassType.visits
                              ? 'Platnost neomezená'
                              : 'Do kdy?')
                          : 'Do ${_d(_until!)}'),
                    ),
                  ),
                ],
              ),
              if (_until != null && _type == PassType.visits)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _until = null),
                    child: const Text('Bez omezení platnosti'),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cena (nepovinné)',
                  suffixText: 'Kč',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _paid,
                onChanged: (v) => setState(() => _paid = v),
                title: const Text('Zaplaceno'),
                subtitle: Text(
                  _paid ? 'Počítá se do příjmů tohoto měsíce.' : 'Čeká na platbu.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
              TextField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Poznámka (nepovinné)',
                  hintText: 'např. platba převodem, sleva pro kamarádku',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Uložit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Karta v detailu klienta
// =====================================================================

class ClientPassesCard extends ConsumerStatefulWidget {
  final CoachClient client;
  const ClientPassesCard({super.key, required this.client});

  @override
  ConsumerState<ClientPassesCard> createState() => _ClientPassesCardState();
}

class _ClientPassesCardState extends ConsumerState<ClientPassesCard> {
  bool _showHistory = false;

  Future<void> _use(ClientPass p) async {
    await ref.read(passesProvider.notifier).useVisit(p.id);
    if (!mounted) return;
    final left = p.remaining - 1;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(left <= 0
            ? 'Odečteno – permanentka je vyčerpaná.'
            : 'Odečteno. Zbývá $left ${left == 1 ? 'vstup' : left < 5 ? 'vstupy' : 'vstupů'}.'),
        action: SnackBarAction(
          label: 'Vrátit',
          onPressed: () => ref.read(passesProvider.notifier).undoVisit(p.id),
        ),
      ),
    );
  }

  Future<void> _delete(ClientPass p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Smazat permanentku?'),
        content: Text('„${p.title}“ se smaže i s historií vstupů.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(passesProvider.notifier).delete(p.id);
  }

  Widget _tile(ClientPass p) {
    final cs = Theme.of(context).colorScheme;
    final warn = !p.paid || p.isEndingSoon || !p.isActive;
    final color = !p.isActive
        ? cs.onSurfaceVariant
        : warn
            ? Colors.orange.shade800
            : Colors.green.shade700;
    double progress;
    if (p.type == PassType.visits) {
      progress = p.totalVisits == 0 ? 0 : p.uses.length / p.totalVisits;
    } else {
      final u = p.validUntil;
      final total = u == null ? 1 : u.difference(p.validFrom).inDays.clamp(1, 9999);
      final used = DateTime.now().difference(p.validFrom).inDays;
      progress = used / total;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                p.type == PassType.visits
                    ? Icons.confirmation_number_outlined
                    : Icons.date_range_outlined,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: p.isActive ? null : cs.onSurfaceVariant,
                  ),
                ),
              ),
              if (p.price != null)
                Text(_kc(p.price!),
                    style: TextStyle(color: cs.onSurfaceVariant)),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  switch (v) {
                    case 'edit':
                      await showPassEditor(context, ref,
                          client: widget.client, existing: p);
                    case 'paid':
                      await ref
                          .read(passesProvider.notifier)
                          .markPaid(p.id, !p.paid);
                    case 'undo':
                      await ref.read(passesProvider.notifier).undoVisit(p.id);
                    case 'delete':
                      await _delete(p);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Upravit')),
                  PopupMenuItem(
                    value: 'paid',
                    child: Text(p.paid
                        ? 'Označit jako nezaplacené'
                        : 'Označit jako zaplacené'),
                  ),
                  if (p.type == PassType.visits && p.uses.isNotEmpty)
                    const PopupMenuItem(
                        value: 'undo', child: Text('Vrátit poslední vstup')),
                  const PopupMenuItem(value: 'delete', child: Text('Smazat')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 6,
              color: color,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            passStatus(p),
            style: TextStyle(
              fontSize: 12,
              color: !p.paid ? cs.error : color,
              fontWeight: warn ? FontWeight.w700 : null,
            ),
          ),
          if (p.uses.isNotEmpty && p.type == PassType.visits)
            Text(
              'Poslední vstup: ${_d(p.uses.last)}',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          if (p.note.isNotEmpty)
            Text(
              p.note,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          if (p.isActive || !p.paid)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (p.type == PassType.visits && p.isActive)
                    FilledButton.tonalIcon(
                      onPressed: () => _use(p),
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      label: const Text('Odečíst vstup'),
                    ),
                  if (!p.paid)
                    OutlinedButton.icon(
                      onPressed: () => ref
                          .read(passesProvider.notifier)
                          .markPaid(p.id, true),
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: const Text('Zaplaceno'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final all = ref.watch(clientPassesProvider(widget.client.clientId));
    final active = [for (final p in all) if (p.isActive || !p.paid) p];
    final history = [for (final p in all) if (!(p.isActive || !p.paid)) p];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.confirmation_number_outlined, color: cs.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Permanentky a platby',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                const HelpButton(topic: 'passes'),
                IconButton(
                  tooltip: 'Nová permanentka',
                  onPressed: () =>
                      showPassEditor(context, ref, client: widget.client),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            if (active.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  all.isEmpty
                      ? 'Zatím žádná permanentka. Přidej ji tlačítkem +.'
                      : 'Žádná aktivní permanentka – čas domluvit další?',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            for (final p in active) _tile(p),
            if (history.isNotEmpty) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => setState(() => _showHistory = !_showHistory),
                icon: Icon(_showHistory ? Icons.expand_less : Icons.expand_more),
                label: Text('Historie (${history.length})'),
              ),
              if (_showHistory)
                for (final p in history) _tile(p),
            ],
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Přehled trenéra
// =====================================================================

/// Karta na přehledu: nezaplacené, docházející a vypršelé permanentky
/// + příjmy tohoto měsíce.
class PassesOverviewCard extends ConsumerWidget {
  final ValueChanged<String> onOpenClient;
  final Set<String> activeClientIds;

  const PassesOverviewCard({
    super.key,
    required this.onOpenClient,
    required this.activeClientIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = [
      for (final p in ref.watch(passesProvider))
        if (activeClientIds.contains(p.clientId)) p,
    ];
    if (all.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final income = all
        .where((p) =>
            p.paid &&
            p.price != null &&
            p.paidAt != null &&
            p.paidAt!.year == now.year &&
            p.paidAt!.month == now.month)
        .fold<double>(0, (a, p) => a + p.price!);

    // Jen poslední permanentka klienta pro daný název – ať se neukazuje
    // stará vypršelá, když už má novou.
    final latest = <String, ClientPass>{};
    for (final p in all) {
      final k = '${p.clientId}|${p.title}';
      final prev = latest[k];
      if (prev == null || p.createdAt.isAfter(prev.createdAt)) latest[k] = p;
    }
    final alerts = [
      for (final p in latest.values)
        if (!p.paid ||
            p.isEndingSoon ||
            (!p.isActive &&
                now.difference(p.validUntil ?? p.updatedAt).inDays <= 14))
          p,
    ]..sort((a, b) {
        int rank(ClientPass p) => !p.paid ? 0 : (!p.isActive ? 1 : 2);
        return rank(a).compareTo(rank(b));
      });

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, color: cs.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Permanentky a platby',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                const HelpButton(topic: 'passes'),
              ],
            ),
            Text(
              'Zaplaceno tento měsíc: ${_kc(income)}',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            if (alerts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Vše v pořádku – nic nedochází ani nečeká na platbu.',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ),
            for (final p in alerts.take(8))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  !p.paid
                      ? Icons.money_off
                      : !p.isActive
                          ? Icons.event_busy
                          : Icons.hourglass_bottom,
                  color: !p.paid ? cs.error : Colors.orange.shade800,
                ),
                title: Text('${p.clientName} · ${p.title}'),
                subtitle: Text(passStatus(p)),
                onTap: () => onOpenClient(p.clientId),
              ),
          ],
        ),
      ),
    );
  }
}
