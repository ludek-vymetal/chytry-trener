import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/booking_provider.dart';
import '../../providers/coach/appointments_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/booking/booking_models.dart';
import '../../services/booking/booking_service.dart';
import '../../services/coach/online_coaching_service.dart';
import '../coaching/chat_screen.dart';
import '../coaching/workout_widgets.dart' show clientLinkProvider;
import '../help/help_button.dart';
import 'booking_settings_screen.dart' show bookingDayLabel;

String _time(DateTime t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

String bookingWhen(Booking b) =>
    '${bookingDayLabel(b.start)} ${_time(b.start)}–${_time(b.end)}';

bool canClientCancel(Booking b, BookingSettings? s) {
  if (b.status != BookingStatus.booked) return false;
  final limit = s?.cancelHours ?? 24;
  return DateTime.now().add(Duration(hours: limit)).isBefore(b.start);
}

// =====================================================================
// KLIENT – rezervace termínu
// =====================================================================

class ClientBookingScreen extends ConsumerStatefulWidget {
  const ClientBookingScreen({super.key});

  @override
  ConsumerState<ClientBookingScreen> createState() =>
      _ClientBookingScreenState();
}

class _ClientBookingScreenState extends ConsumerState<ClientBookingScreen> {
  String? _offerId;
  DateTime? _day;
  bool _busy = false;

  Future<void> _book(
    ClientLinkInfo link,
    BookingOffer offer,
    DateTime start,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rezervovat termín?'),
        content: Text(
          '${offer.name} (${offer.minutes} min)\n'
          '${bookingDayLabel(start)} v ${_time(start)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zpět'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rezervovat'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final p = ref.read(userProfileProvider);
    final name = [p?.firstName.trim() ?? '', p?.lastName.trim() ?? '']
        .where((s) => s.isNotEmpty)
        .join(' ');
    final err = await BookingService.book(
      link: link,
      clientName: name.isEmpty ? 'Klient' : name,
      offer: offer,
      start: start,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(lockedUnitsProvider(link.coachUid));
    ref.invalidate(myBookingsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          err ??
              'Hotovo! ${offer.name} ${bookingDayLabel(start)} v ${_time(start)} '
                  'je rezervovaný. Trenér ho uvidí v kalendáři.',
        ),
      ),
    );
  }

  Future<void> _cancel(Booking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zrušit termín?'),
        content: Text('${b.offerName}\n${bookingWhen(b)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nechat'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Zrušit termín'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = await BookingService.cancelByClient(b);
    if (!mounted) return;
    ref.invalidate(lockedUnitsProvider(b.coachUid));
    ref.invalidate(myBookingsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Termín je zrušený.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linkAsync = ref.watch(clientLinkProvider);
    final link = linkAsync.valueOrNull;

    Widget body;
    if (linkAsync.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (link == null) {
      body = const _Message(
        icon: Icons.link_off,
        text: 'Rezervovat termíny můžeš, až budeš propojený/á se svým '
            'trenérem (Profil → Mám pozvánku od trenéra).',
      );
    } else {
      body = _content(link);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezervace termínu'),
        actions: const [HelpButton(topic: 'booking')],
      ),
      body: body,
    );
  }

  Widget _content(ClientLinkInfo link) {
    final cs = Theme.of(context).colorScheme;
    final sAsync = ref.watch(bookingSettingsProvider(link.coachUid));
    final s = sAsync.valueOrNull;
    final locked =
        ref.watch(lockedUnitsProvider(link.coachUid)).valueOrNull ??
            const <int>{};
    final mine = ref.watch(myBookingsProvider).valueOrNull ?? const [];
    final now = DateTime.now();
    final upcoming = [
      for (final b in mine)
        if (b.end.isAfter(now)) b,
    ];

    final myList = _MyBookings(
      bookings: upcoming,
      settings: s,
      onCancel: _cancel,
      onMessage: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CoachingChatScreen(
            linkId: link.linkId,
            asCoach: false,
            title: link.coachName ?? 'Trenér',
          ),
        ),
      ),
    );

    if (sAsync.isLoading && s == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (s == null || !s.enabled || s.offers.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Message(
            icon: Icons.event_busy,
            text: 'Tvůj trenér zatím nemá zapnuté online rezervace. '
                'Domluv se s ním ve zprávách.',
          ),
          if (upcoming.isNotEmpty) myList,
        ],
      );
    }

    final offer = s.offers.firstWhere(
      (o) => o.id == _offerId,
      orElse: () => s.offers.first,
    );
    final today = DateTime(now.year, now.month, now.day);
    final days = [
      for (var i = 0; i <= s.horizonDays; i++) today.add(Duration(days: i)),
    ];
    final freeByDay = {
      for (final d in days) d: s.freeStarts(d, offer.minutes, locked, now: now),
    };
    final firstFree = days.firstWhere(
      (d) => freeByDay[d]!.isNotEmpty,
      orElse: () => today,
    );
    final day = _day != null && freeByDay.containsKey(_day) ? _day! : firstFree;
    final free = freeByDay[day] ?? const <DateTime>[];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (upcoming.isNotEmpty) ...[myList, const SizedBox(height: 16)],
            const Text(
              'Co si chceš rezervovat?',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in s.offers)
                  ChoiceChip(
                    avatar: Icon(o.type.icon, size: 18),
                    label: Text('${o.name} · ${o.minutes} min'),
                    selected: o.id == offer.id,
                    onSelected: (_) => setState(() {
                      _offerId = o.id;
                      _day = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Vyber den',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 8),
            // Všechny dny najednou (bez posouvání do strany – na počítači
            // myší nešlo posunout na další dny).
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in days)
                  Builder(builder: (_) {
                    final n = freeByDay[d]!.length;
                    final open = s.windowsOn(d).isNotEmpty &&
                        !s.blocksOn(d).any((b) => b.allDay);
                    final sel = d == day;
                    final fg = sel
                        ? cs.onPrimary
                        : n == 0
                            ? cs.onSurfaceVariant
                            : cs.onSurface;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: n == 0 ? null : () => setState(() => _day = d),
                      child: Container(
                        width: 72,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? cs.primary
                              : n == 0
                                  ? cs.surfaceContainerHighest
                                      .withValues(alpha: 0.4)
                                  : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: n > 0 && !sel
                              ? Border.all(color: cs.primary.withValues(alpha: 0.5))
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              const ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'][
                                  d.weekday - 1],
                              style: TextStyle(fontSize: 12, color: fg),
                            ),
                            Text(
                              '${d.day}. ${d.month}.',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: fg,
                              ),
                            ),
                            Text(
                              n > 0
                                  ? '$n volných'
                                  : open
                                      ? 'obsazeno'
                                      : 'nepracuje',
                              style: TextStyle(
                                fontSize: 10,
                                color: sel ? cs.onPrimary : cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Volné časy – ${bookingDayLabel(day)}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (free.isEmpty)
              Text(
                freeByDay.values.every((l) => l.isEmpty)
                    ? 'V nejbližších ${s.horizonDays} dnech není nic volného. '
                        'Napiš trenérovi.'
                    : 'Tento den je plno – vyber jiný.',
                style: TextStyle(color: cs.onSurfaceVariant),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in free)
                    ActionChip(
                      label: Text(_time(t)),
                      onPressed: _busy ? null : () => _book(link, offer, t),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            Text(
              'Vidíš jen volné časy. Rezervovat můžeš nejpozději '
              '${s.minNoticeHours} h předem a až ${s.horizonDays} dní dopředu. '
              '${s.cancelHours == 0 ? 'Zrušit můžeš kdykoli.' : 'Zrušit můžeš nejpozději ${s.cancelHours} h předem.'}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Message({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      );
}

class _MyBookings extends StatelessWidget {
  final List<Booking> bookings;
  final BookingSettings? settings;
  final ValueChanged<Booking> onCancel;
  final VoidCallback onMessage;
  const _MyBookings({
    required this.bookings,
    required this.settings,
    required this.onCancel,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Moje termíny',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            for (final b in bookings)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  b.type.icon,
                  color: b.status == BookingStatus.booked
                      ? b.type.color
                      : cs.onSurfaceVariant,
                ),
                title: Text(
                  bookingWhen(b),
                  style: TextStyle(
                    decoration: b.status == BookingStatus.booked
                        ? null
                        : TextDecoration.lineThrough,
                  ),
                ),
                subtitle: Text(
                  b.status == BookingStatus.booked
                      ? b.offerName
                      : '${b.offerName} · ${b.status.label}',
                  style: TextStyle(
                    color: b.status == BookingStatus.cancelledByCoach
                        ? cs.error
                        : null,
                  ),
                ),
                trailing: b.status != BookingStatus.booked
                    ? null
                    : canClientCancel(b, settings)
                        ? TextButton(
                            onPressed: () => onCancel(b),
                            child: const Text('Zrušit'),
                          )
                        : IconButton(
                            tooltip: 'Na zrušení je pozdě – napiš trenérovi',
                            onPressed: onMessage,
                            icon: const Icon(Icons.chat_bubble_outline),
                          ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Karta na obrazovce Dnes: příští termín + rezervace.
class ClientBookingCard extends ConsumerWidget {
  const ClientBookingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(clientLinkProvider).valueOrNull;
    if (link == null) return const SizedBox.shrink();
    final s = ref.watch(bookingSettingsProvider(link.coachUid)).valueOrNull;
    final mine = ref.watch(myBookingsProvider).valueOrNull ?? const [];
    final now = DateTime.now();
    final next = [
      for (final b in mine)
        if (b.status == BookingStatus.booked && b.end.isAfter(now)) b,
    ];
    final cancelledByCoach = [
      for (final b in mine)
        if (b.status == BookingStatus.cancelledByCoach && b.start.isAfter(now))
          b,
    ];
    if ((s == null || !s.enabled) &&
        next.isEmpty &&
        cancelledByCoach.isEmpty) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    void open() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ClientBookingScreen()),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(Icons.event_available, color: cs.primary),
          title: Text(
            next.isEmpty
                ? 'Rezervovat termín'
                : 'Příští termín: ${bookingWhen(next.first)}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            cancelledByCoach.isNotEmpty
                ? 'Trenér zrušil termín ${bookingWhen(cancelledByCoach.first)} – vyber jiný.'
                : next.isEmpty
                    ? 'Vyber si volný čas u trenéra'
                    : '${next.first.offerName}'
                        '${next.length > 1 ? ' · další termíny: ${next.length - 1}' : ''}',
            style: TextStyle(
              color: cancelledByCoach.isNotEmpty ? cs.error : null,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: open,
        ),
      ),
    );
  }
}

// =====================================================================
// TRENÉR – nové rezervace
// =====================================================================

class NewBookingsBanner extends ConsumerWidget {
  const NewBookingsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(unseenBookingsProvider);
    if (list.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active_outlined,
                    color: cs.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    list.length == 1
                        ? 'Nová změna v rezervacích'
                        : 'Nové změny v rezervacích: ${list.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(seenBookingsProvider.notifier)
                      .markSeen([for (final b in list) '${b.id}:${b.status.name}']),
                  child: const Text('Beru na vědomí'),
                ),
              ],
            ),
            for (final b in list.take(8))
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      b.status == BookingStatus.booked
                          ? Icons.event_available
                          : Icons.event_busy,
                      size: 18,
                      color: b.status == BookingStatus.booked
                          ? cs.onPrimaryContainer
                          : cs.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${b.clientName} – ${b.offerName}, ${bookingWhen(b)}'
                        '${b.status == BookingStatus.cancelled ? ' · ZRUŠIL/A' : ''}',
                        style: TextStyle(color: cs.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Typ termínu z rezervace (pro ikonu v kalendáři).
bool isBookingAppointment(Appointment a) => a.id.startsWith('bk_');
