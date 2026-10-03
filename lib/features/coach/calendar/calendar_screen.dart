import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/coach/client_pass.dart';
import '../../../models/coach/coach_client.dart';
import '../../../providers/coach/appointments_provider.dart';
import '../../../providers/coach/coach_clients_controller.dart';
import '../../../providers/coach/finance_provider.dart';
import '../../../providers/coach/passes_provider.dart';
import '../../help/help_button.dart';
import '../../../providers/booking_provider.dart';
import '../../../services/booking/booking_models.dart';
import '../../../services/booking/booking_service.dart';
import '../../booking/booking_settings_screen.dart';
import '../../booking/client_booking_screen.dart';

const _dayNames = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
const _dayNamesLong = [
  'Pondělí', 'Úterý', 'Středa', 'Čtvrtek', 'Pátek', 'Sobota', 'Neděle',
];

DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);
DateTime _monday(DateTime x) => DateTime(x.year, x.month, x.day - (x.weekday - 1));
DateTime _plusDays(DateTime x, int n) => DateTime(x.year, x.month, x.day + n);
String _two(int v) => v.toString().padLeft(2, '0');
String _time(DateTime t) => '${t.hour}:${_two(t.minute)}';

/// Permanentka, ze které se termín odečte (aktivní, na vstupy, podle druhu).
ClientPass? passFor(List<ClientPass> passes, Appointment a) {
  if (a.clientId == null) return null;
  final active = [
    for (final p in passes)
      if (p.clientId == a.clientId && p.type == PassType.visits && p.isActive)
        p,
  ];
  if (active.isEmpty) return null;
  final wantMassage = a.type == AppointmentType.massage;
  for (final p in active) {
    final isMassage = categoryForTitle(p.title) == 'Masáže';
    if (isMassage == wantMassage) return p;
  }
  return null;
}

/// Kalendář tréninků, masáží a konzultací (týdenní přehled).
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _week = _monday(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final all = ref.watch(appointmentsProvider);
    final end = _plusDays(_week, 7);
    final week = [
      for (final a in all)
        if (!a.start.isBefore(_week) && a.start.isBefore(end)) a,
    ];
    final active = week.where((a) => a.status != AppointmentStatus.cancelled);
    final counts = <AppointmentType, int>{};
    for (final a in active) {
      counts[a.type] = (counts[a.type] ?? 0) + 1;
    }
    final today = _d(DateTime.now());
    final lastDay = _plusDays(_week, 6);
    final summary = active.isEmpty
        ? 'Žádné termíny'
        : '${active.length} termínů · ${[
            for (final e in counts.entries)
              '${e.value}× ${e.key.label.toLowerCase()}',
          ].join(', ')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalendář'),
        actions: [
          TextButton(
            onPressed: () =>
                setState(() => _week = _monday(DateTime.now())),
            child: const Text('Dnes'),
          ),
          IconButton(
            tooltip: 'Zablokovat čas (lékař, dovolená…)',
            onPressed: () => addBlockForCoach(context, ref),
            icon: const Icon(Icons.block),
          ),
          IconButton(
            tooltip: 'Online rezervace – pracovní doba',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BookingSettingsScreen()),
            ),
            icon: const Icon(Icons.event_available),
          ),
          const HelpButton(topic: 'calendar'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAppointmentEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Termín'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            children: [
              const NewBookingsBanner(),
              const _BookingStatusTile(),
              Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        setState(() => _week = _plusDays(_week, -7)),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${_week.day}. ${_week.month}. – '
                          '${lastDay.day}. ${lastDay.month}. ${lastDay.year}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          summary,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        setState(() => _week = _plusDays(_week, 7)),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              for (var i = 0; i < 7; i++)
                _DaySection(
                  day: _plusDays(_week, i),
                  isToday: _plusDays(_week, i) == today,
                  items: [
                    for (final a in week)
                      if (_d(a.start) == _plusDays(_week, i)) a,
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaySection extends ConsumerWidget {
  final DateTime day;
  final bool isToday;
  final List<Appointment> items;
  const _DaySection({
    required this.day,
    required this.isToday,
    required this.items,
  });

  Future<void> _removeBlock(
    BuildContext context,
    WidgetRef ref,
    BookingSettings s,
    TimeBlock b,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zrušit blokaci?'),
        content: Text('${bookingDayLabel(b.day)} ${b.label}\n'
            'Klienti si tento čas pak budou moci rezervovat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nechat'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Zrušit blokaci'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await BookingService.saveSettings(s.copyWith(blocks: [
      for (final x in s.blocks)
        if (x.id != b.id) x,
    ]));
    final uid = currentCoachUidForBooking();
    if (uid != null) ref.invalidate(bookingSettingsProvider(uid));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final uid = currentCoachUidForBooking();
    final settings = uid == null
        ? null
        : ref.watch(bookingSettingsProvider(uid)).valueOrNull;
    final blocks = settings?.blocksOn(day) ?? const <TimeBlock>[];
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isToday ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_dayNamesLong[day.weekday - 1]} ${day.day}. ${day.month}.',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isToday ? cs.onPrimary : cs.onSurface,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Zablokovat čas v tento den',
                visualDensity: VisualDensity.compact,
                onPressed: () => addBlockForCoach(context, ref, day: day),
                icon: const Icon(Icons.block, size: 20),
              ),
              IconButton(
                tooltip: 'Přidat termín na tento den',
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    showAppointmentEditor(context, ref, initialDay: day),
                icon: const Icon(Icons.add, size: 20),
              ),
            ],
          ),
          for (final b in blocks)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: InputChip(
                avatar: Icon(Icons.block, size: 16, color: cs.error),
                label: Text('Blokováno: ${b.label}'),
                onDeleted: settings == null
                    ? null
                    : () => _removeBlock(context, ref, settings, b),
                deleteButtonTooltipMessage: 'Zrušit blokaci',
              ),
            ),
          if (items.isEmpty && blocks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 2, bottom: 4),
              child: Text('volno',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ),
          for (final a in items) AppointmentTile(appointment: a),
        ],
      ),
    );
  }
}

/// Jeden termín (i pro přehled dne na úvodní obrazovce).
class AppointmentTile extends ConsumerWidget {
  final Appointment appointment;
  const AppointmentTile({super.key, required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final a = appointment;
    final cancelled = a.status == AppointmentStatus.cancelled;
    final done = a.status == AppointmentStatus.done;

    return Card(
      margin: const EdgeInsets.only(top: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _actions(context, ref, a),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: cancelled ? cs.outline : a.type.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 86,
                child: Text(
                  '${_time(a.start)}–${_time(a.end)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(a.type.icon,
                  size: 18, color: cancelled ? cs.outline : a.type.color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.clientName.isEmpty ? a.type.label : a.clientName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration:
                            cancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      [
                        a.type.label,
                        if (a.note.isNotEmpty) a.note,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (done)
                const Icon(Icons.check_circle, color: Color(0xFF16A34A))
              else if (cancelled)
                Icon(Icons.cancel_outlined, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _actions(
    BuildContext context,
    WidgetRef ref,
    Appointment a,
  ) async {
    final pass = passFor(ref.read(passesProvider), a);
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '${a.clientName.isEmpty ? a.type.label : a.clientName} · '
                '${_dayNames[a.start.weekday - 1]} ${a.start.day}. ${a.start.month}. '
                '${_time(a.start)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (a.status != AppointmentStatus.done) ...[
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Proběhlo'),
                subtitle: pass == null
                    ? null
                    : Text('Odečte se vstup: ${pass.title} '
                        '(zbývá ${pass.remaining})'),
                onTap: () => Navigator.pop(ctx, 'done'),
              ),
              if (pass != null)
                ListTile(
                  leading: const Icon(Icons.check),
                  title: const Text('Proběhlo – bez odečtení vstupu'),
                  onTap: () => Navigator.pop(ctx, 'doneNoPass'),
                ),
            ],
            if (a.status != AppointmentStatus.cancelled)
              ListTile(
                leading: const Icon(Icons.event_busy),
                title: const Text('Zrušeno / omluveno'),
                onTap: () => Navigator.pop(ctx, 'cancel'),
              ),
            if (a.status != AppointmentStatus.planned)
              ListTile(
                leading: const Icon(Icons.undo),
                title: const Text('Vrátit na naplánováno'),
                onTap: () => Navigator.pop(ctx, 'planned'),
              ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Upravit'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Smazat'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    final n = ref.read(appointmentsProvider.notifier);
    switch (action) {
      case 'done':
        await n.update(a.copyWith(status: AppointmentStatus.done));
        if (pass != null) {
          await ref
              .read(passesProvider.notifier)
              .useVisit(pass.id, date: a.start);
        }
      case 'doneNoPass':
        await n.update(a.copyWith(status: AppointmentStatus.done));
      case 'cancel':
        await n.update(a.copyWith(status: AppointmentStatus.cancelled));
      case 'planned':
        await n.update(a.copyWith(status: AppointmentStatus.planned));
      case 'edit':
        await showAppointmentEditor(context, ref, existing: a);
      case 'delete':
        await n.delete(a.id);
    }
  }
}

// =====================================================================
// Formulář termínu
// =====================================================================

Future<void> showAppointmentEditor(
  BuildContext context,
  WidgetRef ref, {
  Appointment? existing,
  DateTime? initialDay,
  CoachClient? client,
}) async {
  final result = await Navigator.of(context).push<List<Appointment>>(
    MaterialPageRoute(
      builder: (_) => _AppointmentEditor(
        existing: existing,
        initialDay: initialDay,
        client: client,
      ),
    ),
  );
  if (result == null || result.isEmpty) return;
  final n = ref.read(appointmentsProvider.notifier);
  if (existing != null) {
    await n.update(result.first);
  } else {
    // Stejný termín už v kalendáři je (např. zapsaný v mobilu) → nepřidávat
    // podruhé, jen upozornit.
    final dupes = [
      for (final a in result)
        if (n.findSame(a) != null) a,
    ];
    await n.addAll(result);
    if (dupes.isNotEmpty && context.mounted) {
      final d = dupes.first.start;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dupes.length == 1
                ? 'Termín ${dupes.first.clientName} ${d.day}. ${d.month}. '
                    '${d.hour}:${d.minute.toString().padLeft(2, '0')} už v kalendáři je – nepřidal jsem ho podruhé.'
                : '${dupes.length} termíny už v kalendáři byly – nepřidal jsem je podruhé.',
          ),
        ),
      );
    }
  }
}

class _AppointmentEditor extends ConsumerStatefulWidget {
  final Appointment? existing;
  final DateTime? initialDay;
  final CoachClient? client;
  const _AppointmentEditor({this.existing, this.initialDay, this.client});

  @override
  ConsumerState<_AppointmentEditor> createState() => _AppointmentEditorState();
}

class _AppointmentEditorState extends ConsumerState<_AppointmentEditor> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  String? _clientId;
  AppointmentType _type = AppointmentType.training;
  late DateTime _day;
  TimeOfDay _time = const TimeOfDay(hour: 17, minute: 0);
  int _minutes = 60;
  int _repeat = 1;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.clientName;
      _note.text = e.note;
      _clientId = e.clientId;
      _type = e.type;
      _day = _d(e.start);
      _time = TimeOfDay(hour: e.start.hour, minute: e.start.minute);
      _minutes = e.minutes;
    } else {
      _day = _d(widget.initialDay ?? DateTime.now());
      _clientId = widget.client?.clientId;
      _name.text = widget.client?.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickClient() async {
    final all = await ref.read(coachClientsControllerProvider.future);
    if (!mounted) return;
    final list = [
      for (final c in all)
        if (!c.client.isArchived && !c.client.isDeleted) c.client,
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
                leading: const Icon(Icons.person_outline),
                title: Text(c.displayName),
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _clientId = picked.clientId;
      _name.text = picked.displayName;
    });
  }

  void _save() {
    if (_name.text.trim().isEmpty && _type != AppointmentType.other) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vyber klienta nebo napiš jméno.')),
      );
      return;
    }
    final start = DateTime(
        _day.year, _day.month, _day.day, _time.hour, _time.minute);
    final base = DateTime.now().microsecondsSinceEpoch;
    final e = widget.existing;
    if (e != null) {
      Navigator.pop(context, [
        e.copyWith(
          clientId: _clientId,
          clientName: _name.text.trim(),
          type: _type,
          start: start,
          minutes: _minutes,
          note: _note.text.trim(),
        ),
      ]);
      return;
    }
    Navigator.pop(context, [
      for (var i = 0; i < _repeat; i++)
        Appointment(
          id: 'apt_${base}_$i',
          clientId: _clientId,
          clientName: _name.text.trim(),
          type: _type,
          start: DateTime(start.year, start.month, start.day + 7 * i,
              start.hour, start.minute),
          minutes: _minutes,
          note: _note.text.trim(),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Nový termín' : 'Upravit termín'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<AppointmentType>(
                segments: [
                  for (final t in AppointmentType.values)
                    ButtonSegment(
                      value: t,
                      icon: Icon(t.icon),
                      label: Text(t.label),
                    ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _name,
                      onChanged: (_) => _clientId = null,
                      decoration: const InputDecoration(
                        labelText: 'Klient',
                        hintText: 'vyber nebo napiš jméno',
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
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _day,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => _day = d);
                      },
                      icon: const Icon(Icons.event),
                      label: Text(
                          '${_dayNames[_day.weekday - 1]} ${_day.day}. ${_day.month}. ${_day.year}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _time,
                        );
                        if (t != null) setState(() => _time = t);
                      },
                      icon: const Icon(Icons.schedule),
                      label: Text('${_time.hour}:${_two(_time.minute)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Délka', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in const [30, 45, 60, 75, 90, 120])
                    ChoiceChip(
                      label: Text('$m min'),
                      selected: _minutes == m,
                      onSelected: (_) => setState(() => _minutes = m),
                    ),
                ],
              ),
              if (widget.existing == null) ...[
                const SizedBox(height: 14),
                const Text('Opakovat každý týden',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final r in const [1, 4, 8, 12])
                      ChoiceChip(
                        label: Text(r == 1 ? 'Jen jednou' : '$r týdnů'),
                        selected: _repeat == r,
                        onSelected: (_) => setState(() => _repeat = r),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Poznámka (nepovinné)',
                  hintText: 'např. nohy, masáž zad',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_repeat > 1 && widget.existing == null
                    ? 'Uložit $_repeat termínů'
                    : 'Uložit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Úvodní obrazovka trenéra – dnešní program
// =====================================================================

class TodayAppointmentsCard extends ConsumerWidget {
  final VoidCallback onOpenCalendar;
  const TodayAppointmentsCard({super.key, required this.onOpenCalendar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = _d(now);
    final all = ref.watch(appointmentsProvider);
    final todays = [
      for (final a in all)
        if (_d(a.start) == today) a,
    ];
    final next = [
      for (final a in all)
        if (_d(a.start).isAfter(today) &&
            a.status == AppointmentStatus.planned)
          a,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_outlined, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dnes · ${todays.where((a) => a.status != AppointmentStatus.cancelled).length} termínů',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: onOpenCalendar,
                  child: const Text('Kalendář'),
                ),
              ],
            ),
            if (todays.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 8),
                child: Text(
                  next.isEmpty
                      ? 'Dnes nic naplánováno.'
                      : 'Dnes volno. Další: ${next.first.clientName} – '
                          '${_dayNames[next.first.start.weekday - 1]} '
                          '${next.first.start.day}. ${next.first.start.month}. '
                          '${_time(next.first.start)}',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            for (final a in todays)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AppointmentTile(appointment: a),
              ),
          ],
        ),
      ),
    );
  }
}

/// Stav online rezervací nahoře v kalendáři.
class _BookingStatusTile extends ConsumerWidget {
  const _BookingStatusTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = currentCoachUidForBooking();
    if (uid == null) return const SizedBox.shrink();
    final async = ref.watch(bookingSettingsProvider(uid));
    if (async.isLoading) return const SizedBox.shrink();
    final s = async.valueOrNull;
    final cs = Theme.of(context).colorScheme;
    final on = s?.enabled ?? false;
    final rules = s?.rules ?? const <WorkRule>[];
    final hours = on
        ? [
            for (final r in rules)
              if (r.days.isNotEmpty)
                '${[for (final d in (r.days.toList()..sort())) _dayNames[d - 1]].join(', ')} '
                    '${r.windows().join(', ')}',
          ].join(' · ')
        : '';
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: Icon(
          on ? Icons.event_available : Icons.event_busy_outlined,
          color: on ? cs.primary : cs.onSurfaceVariant,
        ),
        title: Text(
          on
              ? 'Online rezervace zapnuté'
              : 'Online rezervace vypnuté',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          on
              ? (hours.isEmpty ? 'Nastav pracovní dobu.' : hours)
              : 'Zapni je a klienti si budou termíny rezervovat sami.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BookingSettingsScreen()),
        ),
      ),
    );
  }
}
