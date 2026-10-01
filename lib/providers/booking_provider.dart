import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/coaching/workout_widgets.dart' show clientLinkProvider;
import '../services/booking/booking_models.dart';
import '../services/booking/booking_service.dart';
import 'coach/appointments_provider.dart';

// =====================================================================
// Společné
// =====================================================================

/// Nastavení rezervací daného trenéra (živě). `null` = nenastaveno.
final bookingSettingsProvider =
    StreamProvider.autoDispose.family<BookingSettings?, String>(
  (ref, coachUid) => BookingService.watchSettings(coachUid),
);

/// Obsazené 15min úseky trenéra (živě).
final lockedUnitsProvider =
    StreamProvider.autoDispose.family<Set<int>, String>(
  (ref, coachUid) => BookingService.watchLockedUnits(coachUid),
);

/// Přihlášený trenér – jeho uid.
String? currentCoachUidForBooking() => FirebaseAuth.instance.currentUser?.uid;

// =====================================================================
// Klient
// =====================================================================

/// Moje rezervace u mého trenéra.
final myBookingsProvider = StreamProvider.autoDispose<List<Booking>>((ref) async* {
  final link = await ref.watch(clientLinkProvider.future);
  if (link == null) {
    yield const [];
    return;
  }
  yield* BookingService.watchMine(link.coachUid).handleError((_) {});
});

// =====================================================================
// Trenér – rezervace se propisují do kalendáře
// =====================================================================

/// Id termínu v kalendáři, který vznikl z rezervace.
String appointmentIdForBooking(String requestId) => 'bk_$requestId';

String? bookingIdOf(Appointment a) =>
    a.id.startsWith('bk_') ? a.id.substring(3) : null;

/// Nové rezervace, které trenér ještě neviděl.
class SeenBookings extends StateNotifier<Set<String>> {
  SeenBookings() : super(const {}) {
    _load();
  }

  static const key = 'booking_seen_v1';
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (!mounted) return;
    try {
      if (raw != null) {
        state = {for (final e in jsonDecode(raw) as List) e.toString()};
      }
    } catch (_) {}
    _loaded = true;
  }

  Future<void> markSeen(Iterable<String> ids) async {
    state = {...state, ...ids};
    final prefs = await SharedPreferences.getInstance();
    // Stačí pamatovat posledních pár set.
    final list = state.toList();
    await prefs.setString(
      key,
      jsonEncode(list.length > 500 ? list.sublist(list.length - 500) : list),
    );
  }
}

final seenBookingsProvider =
    StateNotifierProvider<SeenBookings, Set<String>>((ref) => SeenBookings());

/// Rezervace trenéra (živě).
final coachBookingsProvider = StreamProvider<List<Booking>>((ref) {
  return BookingService.watchRequests().handleError((e) {
    debugPrint('BOOKING watchRequests -> $e');
  });
});

/// Nové (neviděné) rezervace a zrušení klientem.
final unseenBookingsProvider = Provider<List<Booking>>((ref) {
  final all = ref.watch(coachBookingsProvider).valueOrNull ?? const [];
  final seen = ref.watch(seenBookingsProvider);
  final now = DateTime.now();
  return [
    for (final b in all)
      if (b.end.isAfter(now) &&
          b.status != BookingStatus.cancelledByCoach &&
          !seen.contains('${b.id}:${b.status.name}'))
        b,
  ]..sort((a, b) => a.start.compareTo(b.start));
});

/// Běží, dokud je otevřený trenérský režim:
///  - nové rezervace klientů → termíny v kalendáři,
///  - klient zrušil → termín se označí jako zrušený,
///  - trenér zrušil / smazal / přesunul termín z rezervace → klient to uvidí,
///  - obsazené časy z kalendáře → klienti je uvidí jako obsazené.
final coachBookingSyncProvider = Provider<void>((ref) {
  if (currentCoachUidForBooking() == null) return;

  Timer? busyTimer;
  void publishBusySoon() {
    busyTimer?.cancel();
    busyTimer = Timer(const Duration(seconds: 3), () {
      BookingService.publishBusy(ref.read(appointmentsProvider));
    });
  }

  // Termíny, které právě zapisuje synchronizace (ne trenér).
  final syncing = <String>{};

  Future<void> applyBookings(List<Booking> list) async {
    await ref.read(appointmentsProvider.notifier).ready;
    final appts = ref.read(appointmentsProvider);
    final byId = {for (final a in appts) a.id: a};
    final add = <Appointment>[];
    final updates = <Appointment>[];
    for (final b in list) {
      final id = appointmentIdForBooking(b.id);
      final existing = byId[id];
      switch (b.status) {
        case BookingStatus.booked:
          if (existing == null) {
            add.add(
              Appointment(
                id: id,
                clientId: b.clientId.isEmpty ? null : b.clientId,
                clientName: b.clientName,
                type: b.type,
                start: b.start,
                minutes: b.minutes,
                note: 'Rezervace z aplikace · ${b.offerName}',
              ),
            );
          }
        case BookingStatus.cancelled:
          if (existing != null &&
              existing.status == AppointmentStatus.planned) {
            updates.add(
              existing.copyWith(
                status: AppointmentStatus.cancelled,
                note: '${existing.note} · zrušil/a klient',
              ),
            );
          }
        case BookingStatus.cancelledByCoach:
          break;
      }
    }
    if (add.isEmpty && updates.isEmpty) return;
    final n = ref.read(appointmentsProvider.notifier);
    syncing.addAll([...add.map((a) => a.id), ...updates.map((a) => a.id)]);
    try {
      if (add.isNotEmpty) await n.addAll(add);
      for (final u in updates) {
        await n.update(u);
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 500), syncing.clear);
    }
  }

  ref.listen<AsyncValue<List<Booking>>>(
    coachBookingsProvider,
    (_, next) {
      final list = next.valueOrNull;
      if (list != null) applyBookings(list);
    },
    fireImmediately: true,
  );

  // Změny v kalendáři od trenéra.
  ref.listen<List<Appointment>>(appointmentsProvider, (prev, next) {
    publishBusySoon();
    if (prev == null) return;
    final nextById = {for (final a in next) a.id: a};
    final bookings = {
      for (final b in ref.read(coachBookingsProvider).valueOrNull ?? const <Booking>[])
        b.id: b,
    };
    for (final old in prev) {
      final reqId = bookingIdOf(old);
      if (reqId == null || syncing.contains(old.id)) continue;
      final b = bookings[reqId];
      if (b == null || b.status != BookingStatus.booked) continue;
      final now = nextById[old.id];
      if (now == null || now.status == AppointmentStatus.cancelled) {
        BookingService.cancelByCoach(reqId);
      } else if (now.start != b.start || now.minutes != b.minutes) {
        BookingService.rescheduleByCoach(reqId, now.start, now.minutes);
      }
    }
  });

  publishBusySoon();
  BookingService.cleanupOldSlots();
  ref.onDispose(() => busyTimer?.cancel());
});
