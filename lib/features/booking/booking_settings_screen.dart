import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/booking_provider.dart';
import '../../providers/coach/appointments_provider.dart';
import '../../services/booking/booking_models.dart';
import '../../services/booking/booking_service.dart';
import '../help/help_button.dart';

const _dayShort = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
const _dayLong = [
  'pondělí', 'úterý', 'středa', 'čtvrtek', 'pátek', 'sobota', 'neděle',
];

String bookingDayLabel(DateTime d) =>
    '${_dayShort[d.weekday - 1]} ${d.day}. ${d.month}.';

/// Výběr času (24 h). Vrací minuty od půlnoci.
Future<int?> pickMinutes(BuildContext context, int initial,
    {String? help}) async {
  final t = await showTimePicker(
    context: context,
    helpText: help,
    initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    builder: (ctx, child) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
  return t == null ? null : t.hour * 60 + t.minute;
}

/// Jednorázová blokace (lékař, dovolená…). Vrací novou blokaci.
Future<TimeBlock?> showBlockEditor(BuildContext context,
    {DateTime? day}) async {
  return showDialog<TimeBlock>(
    context: context,
    builder: (_) => _BlockDialog(initialDay: day ?? DateTime.now()),
  );
}

/// Přidá blokaci rovnou do nastavení přihlášeného trenéra.
Future<void> addBlockForCoach(
  BuildContext context,
  WidgetRef ref, {
  DateTime? day,
}) async {
  final uid = currentCoachUidForBooking();
  if (uid == null) return;
  final block = await showBlockEditor(context, day: day);
  if (block == null) return;
  final current = ref.read(bookingSettingsProvider(uid)).valueOrNull ??
      BookingSettings.defaults();
  try {
    await BookingService.saveSettings(
      current.copyWith(blocks: [...current.blocks, block]),
    );
    ref.invalidate(bookingSettingsProvider(uid));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Zablokováno: ${bookingDayLabel(block.day)} ${block.label}. '
          'Klienti tento čas uvidí jako obsazený.',
        ),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Uložení se nepodařilo: $e')),
    );
  }
}

class _BlockDialog extends StatefulWidget {
  final DateTime initialDay;
  const _BlockDialog({required this.initialDay});

  @override
  State<_BlockDialog> createState() => _BlockDialogState();
}

class _BlockDialogState extends State<_BlockDialog> {
  late DateTime _day = DateTime(
    widget.initialDay.year,
    widget.initialDay.month,
    widget.initialDay.day,
  );
  bool _allDay = false;
  int _from = 8 * 60;
  int _to = 10 * 60;
  final _note = TextEditingController();

  @override
  void dispose() {
    Future.delayed(const Duration(milliseconds: 400), _note.dispose);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Zablokovat čas'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Jednorázově – např. lékař, dovolená, školení. Klienti tento '
              'čas uvidí jako obsazený.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.event),
              label: Text(
                '${_dayLong[_day.weekday - 1]} ${_day.day}. ${_day.month}. ${_day.year}',
              ),
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  initialDate: _day,
                  firstDate: DateTime(now.year, now.month, now.day),
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _day = d);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Celý den'),
              value: _allDay,
              onChanged: (v) => setState(() => _allDay = v),
            ),
            if (!_allDay)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final m = await pickMinutes(context, _from,
                            help: 'Blokovat od');
                        if (m != null) setState(() => _from = m);
                      },
                      child: Text('od ${fmtMin(_from)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final m =
                            await pickMinutes(context, _to, help: 'Blokovat do');
                        if (m != null) setState(() => _to = m);
                      },
                      child: Text('do ${fmtMin(_to)}'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Poznámka (jen pro tebe)',
                hintText: 'např. lékař',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zrušit'),
        ),
        FilledButton(
          onPressed: () {
            if (!_allDay && _to <= _from) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Čas „do“ musí být po „od“.')),
              );
              return;
            }
            Navigator.pop(
              context,
              TimeBlock(
                id: 'b${DateTime.now().microsecondsSinceEpoch}',
                day: _day,
                range: _allDay ? null : TimeRange(_from, _to),
                note: _note.text.trim(),
              ),
            );
          },
          child: const Text('Zablokovat'),
        ),
      ],
    );
  }
}

// =====================================================================
// Nastavení online rezervací (trenér)
// =====================================================================

class BookingSettingsScreen extends ConsumerStatefulWidget {
  const BookingSettingsScreen({super.key});

  @override
  ConsumerState<BookingSettingsScreen> createState() =>
      _BookingSettingsScreenState();
}

class _BookingSettingsScreenState
    extends ConsumerState<BookingSettingsScreen> {
  BookingSettings? _s;
  bool _dirty = false;
  bool _saving = false;

  void _set(BookingSettings s) => setState(() {
        _s = s;
        _dirty = true;
      });

  Future<void> _save() async {
    final s = _s;
    if (s == null) return;
    for (final r in s.rules) {
      if (r.days.isEmpty || !r.hours.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Zkontroluj pracovní dobu – každé pravidlo potřebuje aspoň '
              'jeden den a čas „do“ po čase „od“.',
            ),
          ),
        );
        return;
      }
    }
    if (s.offers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Přidej aspoň jednu službu, kterou si klienti '
              'mohou rezervovat.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await BookingService.saveSettings(s);
      // Obsazené časy z kalendáře hned pro klienty.
      await BookingService.publishBusy(ref.read(appointmentsProvider));
      final uid = currentCoachUidForBooking();
      if (uid != null) ref.invalidate(bookingSettingsProvider(uid));
      if (!mounted) return;
      setState(() {
        _saving = false;
        _dirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.enabled
                ? 'Uloženo. Klienti teď vidí volné termíny.'
                : 'Uloženo. Online rezervace jsou vypnuté.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uložení se nepodařilo: $e')),
      );
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neuložené změny'),
        content: const Text('Odejít bez uložení?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zůstat'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Odejít'),
          ),
        ],
      ),
    );
    return r == true;
  }

  @override
  Widget build(BuildContext context) {
    final uid = currentCoachUidForBooking();
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Online rezervace')),
        body: const Center(child: Text('Nejsi přihlášený/á jako trenér.')),
      );
    }
    final async = ref.watch(bookingSettingsProvider(uid));
    if (_s == null && !async.isLoading) {
      _s = async.valueOrNull ?? BookingSettings.defaults();
    }
    final s = _s;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) {
          setState(() => _dirty = false);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Online rezervace'),
          actions: const [HelpButton(topic: 'booking')],
        ),
        floatingActionButton: s == null
            ? null
            : FloatingActionButton.extended(
                onPressed: _saving || !_dirty ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_dirty ? 'Uložit' : 'Uloženo'),
              ),
        body: s == null
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    children: [
                      Card(
                        child: SwitchListTile(
                          secondary: const Icon(Icons.event_available),
                          title: const Text(
                            'Klienti si mohou rezervovat termíny',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: const Text(
                            'Propojení klienti uvidí v aplikaci jen volné '
                            'termíny podle tvé pracovní doby.',
                          ),
                          value: s.enabled,
                          onChanged: (v) => _set(s.copyWith(enabled: v)),
                        ),
                      ),
                      const _Title('Pracovní doba'),
                      for (var i = 0; i < s.rules.length; i++)
                        _RuleCard(
                          rule: s.rules[i],
                          onChanged: (r) => _set(s.copyWith(rules: [
                            for (var j = 0; j < s.rules.length; j++)
                              j == i ? r : s.rules[j],
                          ])),
                          onDelete: () => _set(s.copyWith(rules: [
                            for (var j = 0; j < s.rules.length; j++)
                              if (j != i) s.rules[j],
                          ])),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _set(s.copyWith(rules: [
                            ...s.rules,
                            const WorkRule(
                              days: {},
                              hours: TimeRange(8 * 60, 16 * 60),
                            ),
                          ])),
                          icon: const Icon(Icons.add),
                          label: const Text('Přidat pracovní dobu'),
                        ),
                      ),
                      const _Title('Rezervace po'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SegmentedButton<int>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(
                                    value: 60,
                                    label: Text('celých hodinách'),
                                  ),
                                  ButtonSegment(
                                    value: 30,
                                    label: Text('půlhodinách'),
                                  ),
                                  ButtonSegment(
                                    value: 15,
                                    label: Text('15 minutách'),
                                  ),
                                ],
                                selected: {
                                  const [60, 30, 15].contains(s.step)
                                      ? s.step
                                      : 60,
                                },
                                onSelectionChanged: (v) =>
                                    _set(s.copyWith(step: v.first)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                switch (s.step) {
                                  30 => 'Klient uvidí začátky 8:00, 8:30, 9:00…',
                                  15 => 'Klient uvidí začátky 8:00, 8:15, 8:30…',
                                  _ => 'Klient uvidí jen celé hodiny: 8:00, 9:00, 10:00…',
                                },
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const _Title('Jednorázové blokace'),
                      _BlocksCard(
                        blocks: s.blocks,
                        onAdd: () async {
                          final b = await showBlockEditor(context);
                          if (b != null) {
                            _set(s.copyWith(blocks: [...s.blocks, b]));
                          }
                        },
                        onDelete: (id) => _set(s.copyWith(blocks: [
                          for (final b in s.blocks)
                            if (b.id != id) b,
                        ])),
                      ),
                      const _Title('Co si klienti mohou rezervovat'),
                      _OffersCard(
                        offers: s.offers,
                        onChanged: (o) => _set(s.copyWith(offers: o)),
                      ),
                      const _Title('Pravidla rezervací'),
                      Card(
                        child: Column(
                          children: [
                            _ChoiceRow(
                              label: 'Rezervace dopředu',
                              value: s.horizonDays,
                              options: const {
                                7: 'týden',
                                14: '2 týdny',
                                30: 'měsíc',
                                60: '2 měsíce',
                                90: '3 měsíce',
                              },
                              onChanged: (v) =>
                                  _set(s.copyWith(horizonDays: v)),
                            ),
                            _ChoiceRow(
                              label: 'Nejpozději předem',
                              value: s.minNoticeHours,
                              options: const {
                                1: '1 hodinu',
                                3: '3 hodiny',
                                12: '12 hodin',
                                24: 'den',
                                48: '2 dny',
                              },
                              onChanged: (v) =>
                                  _set(s.copyWith(minNoticeHours: v)),
                            ),
                            _ChoiceRow(
                              label: 'Klient může zrušit nejpozději',
                              value: s.cancelHours,
                              options: const {
                                0: 'kdykoli',
                                6: '6 h předem',
                                12: '12 h předem',
                                24: '24 h předem',
                                48: '48 h předem',
                              },
                              onChanged: (v) =>
                                  _set(s.copyWith(cancelHours: v)),
                            ),
                          ],
                        ),
                      ),
                      const _Title('Náhled – co uvidí klient'),
                      _Preview(settings: s, coachUid: uid),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      );
}

class _RuleCard extends StatelessWidget {
  final WorkRule rule;
  final ValueChanged<WorkRule> onChanged;
  final VoidCallback onDelete;
  const _RuleCard({
    required this.rule,
    required this.onChanged,
    required this.onDelete,
  });

  WorkRule _copy({Set<int>? days, TimeRange? hours, List<TimeRange>? breaks}) =>
      WorkRule(
        days: days ?? rule.days,
        hours: hours ?? rule.hours,
        breaks: breaks ?? rule.breaks,
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (var d = 1; d <= 7; d++)
                        FilterChip(
                          label: Text(_dayShort[d - 1]),
                          selected: rule.days.contains(d),
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          onSelected: (v) => onChanged(_copy(
                            days: v
                                ? {...rule.days, d}
                                : ({...rule.days}..remove(d)),
                          )),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Smazat pravidlo',
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: cs.error),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                const Text('Od'),
                OutlinedButton(
                  onPressed: () async {
                    final m = await pickMinutes(context, rule.hours.from,
                        help: 'Začátek pracovní doby');
                    if (m != null) {
                      onChanged(_copy(hours: TimeRange(m, rule.hours.to)));
                    }
                  },
                  child: Text(fmtMin(rule.hours.from)),
                ),
                const Text('do'),
                OutlinedButton(
                  onPressed: () async {
                    final m = await pickMinutes(context, rule.hours.to,
                        help: 'Konec pracovní doby');
                    if (m != null) {
                      onChanged(_copy(hours: TimeRange(rule.hours.from, m)));
                    }
                  },
                  child: Text(fmtMin(rule.hours.to)),
                ),
              ],
            ),
            for (var i = 0; i < rule.breaks.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.free_breakfast_outlined,
                        size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    const Text('Pauza'),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final b = rule.breaks[i];
                        final from = await pickMinutes(context, b.from,
                            help: 'Pauza od');
                        if (from == null || !context.mounted) return;
                        final to = await pickMinutes(
                            context, b.to > from ? b.to : from + 60,
                            help: 'Pauza do');
                        if (to == null) return;
                        onChanged(_copy(breaks: [
                          for (var j = 0; j < rule.breaks.length; j++)
                            j == i ? TimeRange(from, to) : rule.breaks[j],
                        ]));
                      },
                      child: Text(rule.breaks[i].toString()),
                    ),
                    IconButton(
                      tooltip: 'Smazat pauzu',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onChanged(_copy(breaks: [
                        for (var j = 0; j < rule.breaks.length; j++)
                          if (j != i) rule.breaks[j],
                      ])),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: () async {
                final from = await pickMinutes(context, 12 * 60,
                    help: 'Pauza od');
                if (from == null || !context.mounted) return;
                final to =
                    await pickMinutes(context, from + 60, help: 'Pauza do');
                if (to == null || to <= from) return;
                onChanged(
                    _copy(breaks: [...rule.breaks, TimeRange(from, to)]));
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Přidat pauzu (oběd…)'),
            ),
            if (rule.days.isEmpty)
              Text(
                'Vyber dny, pro které tahle pracovní doba platí.',
                style: TextStyle(color: cs.error, fontSize: 12),
              )
            else
              Text(
                '${[for (final d in (rule.days.toList()..sort())) _dayShort[d - 1]].join(', ')}: '
                '${rule.windows().join(', ')}',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _BlocksCard extends StatelessWidget {
  final List<TimeBlock> blocks;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;
  const _BlocksCard({
    required this.blocks,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final upcoming = [
      for (final b in blocks)
        if (!b.day.isBefore(DateTime(today.year, today.month, today.day))) b,
    ]..sort((a, b) => a.day.compareTo(b.day));
    return Card(
      child: Column(
        children: [
          if (upcoming.isEmpty)
            ListTile(
              title: Text(
                'Žádné blokace. Přidej třeba lékaře nebo dovolenou.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          for (final b in upcoming)
            ListTile(
              leading: Icon(Icons.block, color: cs.error),
              title: Text(bookingDayLabel(b.day)),
              subtitle: Text(b.label),
              trailing: IconButton(
                tooltip: 'Zrušit blokaci',
                onPressed: () => onDelete(b.id),
                icon: const Icon(Icons.close),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Zablokovat čas'),
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _OffersCard extends StatelessWidget {
  final List<BookingOffer> offers;
  final ValueChanged<List<BookingOffer>> onChanged;
  const _OffersCard({required this.offers, required this.onChanged});

  Future<void> _edit(BuildContext context, BookingOffer? o) async {
    final name = TextEditingController(text: o?.name ?? '');
    var minutes = o?.minutes ?? 60;
    var type = o?.type ?? AppointmentType.training;
    final r = await showDialog<BookingOffer>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(o == null ? 'Nová služba' : 'Upravit službu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: name,
                autofocus: o == null,
                decoration: const InputDecoration(
                  labelText: 'Název',
                  hintText: 'např. Osobní trénink',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: minutes,
                decoration: const InputDecoration(
                  labelText: 'Délka',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final m in const [30, 45, 60, 75, 90, 120])
                    DropdownMenuItem(value: m, child: Text('$m min')),
                ],
                onChanged: (v) => setD(() => minutes = v ?? minutes),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AppointmentType>(
                initialValue: type,
                decoration: const InputDecoration(
                  labelText: 'Druh v kalendáři',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final t in AppointmentType.values)
                    DropdownMenuItem(value: t, child: Text(t.label)),
                ],
                onChanged: (v) => setD(() => type = v ?? type),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zrušit'),
            ),
            FilledButton(
              onPressed: () {
                final n = name.text.trim();
                if (n.isEmpty) return;
                Navigator.pop(
                  ctx,
                  BookingOffer(
                    id: o?.id ?? 'o${DateTime.now().microsecondsSinceEpoch}',
                    name: n,
                    minutes: minutes,
                    type: type,
                  ),
                );
              },
              child: const Text('Uložit'),
            ),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 400), name.dispose);
    if (r == null) return;
    onChanged([
      if (o == null) ...[...offers, r] else
        for (final x in offers) x.id == o.id ? r : x,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: [
          for (final o in offers)
            ListTile(
              leading: Icon(o.type.icon, color: o.type.color),
              title: Text(o.name),
              subtitle: Text('${o.minutes} min · ${o.type.label}'),
              onTap: () => _edit(context, o),
              trailing: IconButton(
                tooltip: 'Smazat',
                onPressed: () => onChanged([
                  for (final x in offers)
                    if (x.id != o.id) x,
                ]),
                icon: Icon(Icons.delete_outline, color: cs.error),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Přidat službu'),
            onTap: () => _edit(context, null),
          ),
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final String label;
  final int value;
  final Map<int, String> options;
  final ValueChanged<int> onChanged;
  const _ChoiceRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final opts = {...options};
    if (!opts.containsKey(value)) opts[value] = '$value';
    return ListTile(
      title: Text(label),
      trailing: DropdownButton<int>(
        value: value,
        underline: const SizedBox.shrink(),
        items: [
          for (final e in opts.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

/// Náhled volných termínů na 7 dní pro první službu.
class _Preview extends ConsumerWidget {
  final BookingSettings settings;
  final String coachUid;
  const _Preview({required this.settings, required this.coachUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    if (settings.offers.isEmpty) return const SizedBox.shrink();
    final offer = settings.offers.first;
    final locked =
        ref.watch(lockedUnitsProvider(coachUid)).valueOrNull ?? const <int>{};
    // Obsazené časy z kalendáře (i před uložením).
    final appts = ref.watch(appointmentsProvider);
    final now = DateTime.now();
    final s = BookingSettings(
      enabled: true,
      rules: settings.rules,
      blocks: settings.blocks,
      offers: settings.offers,
      step: settings.step,
      horizonDays: settings.horizonDays,
      minNoticeHours: settings.minNoticeHours,
      cancelHours: settings.cancelHours,
      busy: [
        for (final a in appts)
          if (a.status == AppointmentStatus.planned && a.end.isAfter(now))
            (a.start.millisecondsSinceEpoch, a.end.millisecondsSinceEpoch),
      ],
    );
    final today = DateTime(now.year, now.month, now.day);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${offer.name} (${offer.minutes} min) – příštích 7 dní:',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < 7; i++)
              Builder(builder: (_) {
                final d = today.add(Duration(days: i));
                final free = s.freeStarts(d, offer.minutes, locked, now: now);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 78,
                        child: Text(
                          bookingDayLabel(d),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          free.isEmpty
                              ? 'nic volného'
                              : free
                                  .map((t) => fmtMin(t.hour * 60 + t.minute))
                                  .join('  '),
                          style: TextStyle(
                            color: free.isEmpty ? cs.onSurfaceVariant : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
