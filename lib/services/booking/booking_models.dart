import '../../providers/coach/appointments_provider.dart';

/// Čas ve dni v minutách od půlnoci (8:30 = 510).
String fmtMin(int m) => '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';

/// Úsek času ve dni (v minutách od půlnoci), [from] včetně, [to] bez.
class TimeRange {
  final int from;
  final int to;
  const TimeRange(this.from, this.to);

  bool get isValid => to > from;
  bool overlaps(int a, int b) => a < to && b > from;

  Map<String, dynamic> toJson() => {'f': from, 't': to};
  factory TimeRange.fromJson(Map<String, dynamic> j) => TimeRange(
        (j['f'] as num?)?.toInt() ?? 0,
        (j['t'] as num?)?.toInt() ?? 0,
      );

  @override
  String toString() => '${fmtMin(from)}–${fmtMin(to)}';
}

/// Pravidlo pracovní doby: ve vybrané dny od–do, s pauzami.
/// Např. Po, Út, Čt 8:00–18:00, pauza 13:00–15:00.
class WorkRule {
  /// 1 = pondělí … 7 = neděle.
  final Set<int> days;
  final TimeRange hours;
  final List<TimeRange> breaks;

  const WorkRule({
    required this.days,
    required this.hours,
    this.breaks = const [],
  });

  /// Pracovní okna po odečtení pauz.
  List<TimeRange> windows() {
    var out = [hours];
    for (final b in breaks) {
      out = [
        for (final w in out) ..._subtract(w, b),
      ];
    }
    return out.where((w) => w.isValid).toList();
  }

  Map<String, dynamic> toJson() => {
        'days': days.toList()..sort(),
        'hours': hours.toJson(),
        'breaks': [for (final b in breaks) b.toJson()],
      };

  factory WorkRule.fromJson(Map<String, dynamic> j) => WorkRule(
        days: {
          for (final d in (j['days'] as List?) ?? const [])
            if (d is num) d.toInt(),
        },
        hours: TimeRange.fromJson(
          Map<String, dynamic>.from((j['hours'] as Map?) ?? const {}),
        ),
        breaks: [
          for (final b in (j['breaks'] as List?) ?? const [])
            if (b is Map) TimeRange.fromJson(Map<String, dynamic>.from(b)),
        ],
      );
}

List<TimeRange> _subtract(TimeRange w, TimeRange b) {
  if (!w.overlaps(b.from, b.to)) return [w];
  return [
    if (b.from > w.from) TimeRange(w.from, b.from),
    if (b.to < w.to) TimeRange(b.to, w.to),
  ];
}

/// Jednorázová blokace (lékař, dovolená…). [range] == null = celý den.
class TimeBlock {
  final String id;
  final DateTime day;
  final TimeRange? range;
  final String note;

  const TimeBlock({
    required this.id,
    required this.day,
    this.range,
    this.note = '',
  });

  bool get allDay => range == null;

  String get label =>
      '${allDay ? 'Celý den' : range.toString()}${note.isEmpty ? '' : ' · $note'}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'd': dayKey(day),
        if (range != null) 'r': range!.toJson(),
        'n': note,
      };

  factory TimeBlock.fromJson(Map<String, dynamic> j) => TimeBlock(
        id: (j['id'] ?? '').toString(),
        day: dayFromKey((j['d'] as num?)?.toInt() ?? 0),
        range: j['r'] is Map
            ? TimeRange.fromJson(Map<String, dynamic>.from(j['r'] as Map))
            : null,
        note: (j['n'] ?? '').toString(),
      );
}

/// Služba, kterou si klient může rezervovat.
class BookingOffer {
  final String id;
  final String name;
  final int minutes;
  final AppointmentType type;

  const BookingOffer({
    required this.id,
    required this.name,
    required this.minutes,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'min': minutes,
        'type': type.name,
      };

  factory BookingOffer.fromJson(Map<String, dynamic> j) => BookingOffer(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        minutes: (j['min'] as num?)?.toInt() ?? 60,
        type: AppointmentType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => AppointmentType.training,
        ),
      );
}

/// Nastavení online rezervací trenéra (`booking/{coachUid}`).
class BookingSettings {
  final bool enabled;
  final List<WorkRule> rules;
  final List<TimeBlock> blocks;
  final List<BookingOffer> offers;

  /// Po kolika minutách se nabízejí začátky (15 / 30 / 60).
  /// Začátky jsou zarovnané – 60 = jen celé hodiny (8:00, 9:00…),
  /// 30 = celé a půl (8:00, 8:30…).
  final int step;

  /// Kolik dní dopředu si klient může rezervovat.
  final int horizonDays;

  /// Nejpozději kolik hodin předem.
  final int minNoticeHours;

  /// Klient může zrušit nejpozději tolik hodin předem.
  final int cancelHours;

  /// Obsazené časy z kalendáře trenéra (bez jmen) – [startMs, endMs].
  final List<(int, int)> busy;

  const BookingSettings({
    this.enabled = false,
    this.rules = const [],
    this.blocks = const [],
    this.offers = const [],
    this.step = 60,
    this.horizonDays = 30,
    this.minNoticeHours = 12,
    this.cancelHours = 24,
    this.busy = const [],
  });

  static BookingSettings defaults() => const BookingSettings(
        rules: [
          WorkRule(
            days: {1, 2, 3, 4, 5},
            hours: TimeRange(8 * 60, 18 * 60),
          ),
        ],
        offers: [
          BookingOffer(
            id: 'training',
            name: 'Osobní trénink',
            minutes: 60,
            type: AppointmentType.training,
          ),
          BookingOffer(
            id: 'massage',
            name: 'Masáž',
            minutes: 60,
            type: AppointmentType.massage,
          ),
        ],
      );

  BookingSettings copyWith({
    bool? enabled,
    List<WorkRule>? rules,
    List<TimeBlock>? blocks,
    List<BookingOffer>? offers,
    int? step,
    int? horizonDays,
    int? minNoticeHours,
    int? cancelHours,
  }) =>
      BookingSettings(
        enabled: enabled ?? this.enabled,
        rules: rules ?? this.rules,
        blocks: blocks ?? this.blocks,
        offers: offers ?? this.offers,
        step: step ?? this.step,
        horizonDays: horizonDays ?? this.horizonDays,
        minNoticeHours: minNoticeHours ?? this.minNoticeHours,
        cancelHours: cancelHours ?? this.cancelHours,
        busy: busy,
      );

  /// Bez `busy` – to zapisuje jen synchronizace kalendáře.
  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'rules': [for (final r in rules) r.toJson()],
        'blocks': [for (final b in blocks) b.toJson()],
        'offers': [for (final o in offers) o.toJson()],
        'step': step,
        'horizonDays': horizonDays,
        'minNoticeHours': minNoticeHours,
        'cancelHours': cancelHours,
      };

  factory BookingSettings.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String k, T Function(Map<String, dynamic>) f) => [
          for (final e in (j[k] as List?) ?? const [])
            if (e is Map) f(Map<String, dynamic>.from(e)),
        ];
    return BookingSettings(
      enabled: j['enabled'] == true,
      rules: list('rules', WorkRule.fromJson),
      blocks: list('blocks', TimeBlock.fromJson),
      offers: list('offers', BookingOffer.fromJson),
      step: (j['step'] as num?)?.toInt() ?? 60,
      horizonDays: (j['horizonDays'] as num?)?.toInt() ?? 30,
      minNoticeHours: (j['minNoticeHours'] as num?)?.toInt() ?? 12,
      cancelHours: (j['cancelHours'] as num?)?.toInt() ?? 24,
      busy: [
        for (final e in (j['busy'] as List?) ?? const [])
          if (e is Map && e['s'] is num && e['e'] is num)
            ((e['s'] as num).toInt(), (e['e'] as num).toInt()),
      ],
    );
  }

  List<TimeBlock> blocksOn(DateTime day) {
    final k = dayKey(day);
    return [
      for (final b in blocks)
        if (dayKey(b.day) == k) b,
    ];
  }

  /// Pracovní okna v daný den (podle pravidel, bez blokací).
  List<TimeRange> windowsOn(DateTime day) => [
        for (final r in rules)
          if (r.days.contains(day.weekday)) ...r.windows(),
      ]..sort((a, b) => a.from.compareTo(b.from));

  /// Volné začátky pro službu dlouhou [minutes] v den [day].
  ///
  /// [lockedUnits] – začátky 15min úseků obsazených rezervacemi (ms).
  List<DateTime> freeStarts(
    DateTime day,
    int minutes,
    Set<int> lockedUnits, {
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final d = DateTime(day.year, day.month, day.day);
    final today = DateTime(n.year, n.month, n.day);
    if (d.isBefore(today)) return const [];
    if (d.isAfter(today.add(Duration(days: horizonDays)))) return const [];

    // Všechno, co je v ten den obsazené (v minutách od půlnoci).
    final taken = <TimeRange>[];
    for (final b in blocksOn(d)) {
      if (b.allDay) return const [];
      taken.add(b.range!);
    }
    final dayStart = d;
    final dayEnd = DateTime(d.year, d.month, d.day + 1);
    int minOf(DateTime t) =>
        t.isBefore(dayStart) ? 0 : t.isAfter(dayEnd) ? 24 * 60 : t.difference(dayStart).inMinutes;
    for (final (a, b) in busy) {
      final s = DateTime.fromMillisecondsSinceEpoch(a);
      final e = DateTime.fromMillisecondsSinceEpoch(b);
      if (e.isAfter(dayStart) && s.isBefore(dayEnd)) {
        taken.add(TimeRange(minOf(s), minOf(e)));
      }
    }
    for (final u in lockedUnits) {
      final s = DateTime.fromMillisecondsSinceEpoch(u);
      if (!s.isBefore(dayStart) && s.isBefore(dayEnd)) {
        final m = minOf(s);
        taken.add(TimeRange(m, m + lockUnitMinutes));
      }
    }

    final earliest = n.add(Duration(hours: minNoticeHours));
    final out = <DateTime>[];
    final seen = <int>{};
    for (final w in windowsOn(d)) {
      // První začátek zarovnaný na krok (60 → celá hodina).
      final first = ((w.from + step - 1) ~/ step) * step;
      for (var t = first; t + minutes <= w.to; t += step) {
        if (taken.any((r) => r.overlaps(t, t + minutes))) continue;
        final start = DateTime(d.year, d.month, d.day, 0, t);
        if (start.isBefore(earliest)) continue;
        if (seen.add(t)) out.add(start);
      }
    }
    out.sort();
    return out;
  }
}

/// Rezervace se zamyká po 15min úsecích – dva klienti tak nikdy
/// nezaberou stejný čas (druhý zápis databáze odmítne).
const lockUnitMinutes = 15;

/// Začátky 15min úseků, které rezervace zabírá (ms).
List<int> lockUnitsFor(DateTime start, int minutes) {
  final first = DateTime(
    start.year,
    start.month,
    start.day,
    start.hour,
    start.minute - start.minute % lockUnitMinutes,
  );
  final end = start.add(Duration(minutes: minutes));
  final out = <int>[];
  for (var t = first; t.isBefore(end);
      t = t.add(const Duration(minutes: lockUnitMinutes))) {
    out.add(t.millisecondsSinceEpoch);
  }
  return out;
}

int dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

DateTime dayFromKey(int k) =>
    k <= 0 ? DateTime(2000) : DateTime(k ~/ 10000, (k ~/ 100) % 100, k % 100);

enum BookingStatus { booked, cancelled, cancelledByCoach }

extension BookingStatusX on BookingStatus {
  String get label => switch (this) {
        BookingStatus.booked => 'Rezervováno',
        BookingStatus.cancelled => 'Zrušeno',
        BookingStatus.cancelledByCoach => 'Zrušeno trenérem',
      };
}

/// Rezervace klienta (`booking/{coachUid}/requests/{id}`).
class Booking {
  final String id;
  final String coachUid;
  final String linkId;
  final String clientId;
  final String clientUid;
  final String clientName;
  final String offerName;
  final AppointmentType type;
  final DateTime start;
  final int minutes;
  final BookingStatus status;
  final List<int> units;
  final String note;

  const Booking({
    required this.id,
    required this.coachUid,
    required this.linkId,
    required this.clientId,
    required this.clientUid,
    required this.clientName,
    required this.offerName,
    required this.type,
    required this.start,
    required this.minutes,
    required this.status,
    required this.units,
    this.note = '',
  });

  DateTime get end => start.add(Duration(minutes: minutes));

  Map<String, dynamic> toJson() => {
        'id': id,
        'coachUid': coachUid,
        'linkId': linkId,
        'clientId': clientId,
        'clientUid': clientUid,
        'clientName': clientName,
        'offerName': offerName,
        'type': type.name,
        'start': start.millisecondsSinceEpoch,
        'minutes': minutes,
        'status': status.name,
        'units': units,
        'note': note,
      };

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: (j['id'] ?? '').toString(),
        coachUid: (j['coachUid'] ?? '').toString(),
        linkId: (j['linkId'] ?? '').toString(),
        clientId: (j['clientId'] ?? '').toString(),
        clientUid: (j['clientUid'] ?? '').toString(),
        clientName: (j['clientName'] ?? '').toString(),
        offerName: (j['offerName'] ?? '').toString(),
        type: AppointmentType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => AppointmentType.training,
        ),
        start: DateTime.fromMillisecondsSinceEpoch(
          (j['start'] as num?)?.toInt() ?? 0,
        ),
        minutes: (j['minutes'] as num?)?.toInt() ?? 60,
        status: BookingStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => BookingStatus.booked,
        ),
        units: [
          for (final u in (j['units'] as List?) ?? const [])
            if (u is num) u.toInt(),
        ],
        note: (j['note'] ?? '').toString(),
      );
}
