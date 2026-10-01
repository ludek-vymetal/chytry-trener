import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../providers/coach/appointments_provider.dart';
import '../coach/online_coaching_service.dart';
import 'booking_models.dart';

/// Online rezervace termínů.
///
/// `booking/{coachUid}`               – nastavení, pravidla, blokace,
///                                       obsazené časy (bez jmen)
/// `booking/{coachUid}/slots/{ms}`    – zámek 15min úseku (proti dvojí
///                                       rezervaci stejného času)
/// `booking/{coachUid}/requests/{id}` – rezervace klientů
class BookingService {
  BookingService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _doc(String coachUid) =>
      _db.collection('booking').doc(coachUid);

  static CollectionReference<Map<String, dynamic>> _slots(String coachUid) =>
      _doc(coachUid).collection('slots');

  static CollectionReference<Map<String, dynamic>> _requests(
          String coachUid) =>
      _doc(coachUid).collection('requests');

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Na počítači (Windows) jsou živé odběry Firebase nestabilní – data se
  /// tam načítají opakovaně (každých 30 s). Na telefonu živě.
  static bool get _poll =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  static Stream<T> _watch<T>(
    Query<Map<String, dynamic>> q,
    T Function(QuerySnapshot<Map<String, dynamic>>) map,
  ) async* {
    if (!_poll) {
      yield* q.snapshots().map(map);
      return;
    }
    while (true) {
      try {
        yield map(await q.get());
      } catch (e) {
        debugPrint('BOOKING poll -> $e');
      }
      await Future<void>.delayed(const Duration(seconds: 30));
    }
  }

  // =================================================================
  // Nastavení
  // =================================================================

  /// `null` = trenér rezervace ještě nenastavil.
  static Stream<BookingSettings?> watchSettings(String coachUid) async* {
    BookingSettings? parse(DocumentSnapshot<Map<String, dynamic>> s) {
      final d = s.data();
      if (!s.exists || d == null) return null;
      return BookingSettings.fromJson(d);
    }

    if (!_poll) {
      yield* _doc(coachUid).snapshots().map(parse);
      return;
    }
    while (true) {
      try {
        yield parse(await _doc(coachUid).get());
      } catch (e) {
        debugPrint('BOOKING poll settings -> $e');
        yield null;
      }
      await Future<void>.delayed(const Duration(seconds: 30));
    }
  }

  static Future<void> saveSettings(BookingSettings s) async {
    final uid = _uid;
    if (uid == null) throw StateError('Trenér není přihlášený.');
    // Staré blokace (před víc než týdnem) se mažou.
    final limit = DateTime.now().subtract(const Duration(days: 7));
    final clean = s.copyWith(
      blocks: [
        for (final b in s.blocks)
          if (b.day.isAfter(limit)) b,
      ]..sort((a, b) => a.day.compareTo(b.day)),
    );
    await _doc(uid).set({
      ...clean.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Trenér: obsazené časy z kalendáře (bez jmen klientů), aby je
  /// klienti viděli jako obsazené.
  static Future<void> publishBusy(List<Appointment> all) async {
    final uid = _uid;
    if (uid == null) return;
    final now = DateTime.now();
    final until = now.add(const Duration(days: 92));
    // Pozor: Firestore nepovoluje seznam v seznamu → seznam map {s, e}.
    final busy = <Map<String, int>>[
      for (final a in all)
        if (a.status == AppointmentStatus.planned &&
            a.end.isAfter(now) &&
            a.start.isBefore(until))
          {
            's': a.start.millisecondsSinceEpoch,
            'e': a.end.millisecondsSinceEpoch,
          },
    ];
    try {
      await _doc(uid).set(
        {'busy': busy, 'busyUpdatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('BOOKING publishBusy -> $e');
    }
  }

  // =================================================================
  // Obsazené úseky
  // =================================================================

  /// Začátky obsazených 15min úseků od dneška dál.
  static Stream<Set<int>> watchLockedUnits(String coachUid) {
    final now = DateTime.now();
    final today = dayKey(now);
    return _watch(
      _slots(coachUid).where('day', isGreaterThanOrEqualTo: today),
      (q) => {
        for (final d in q.docs)
          if (d.data()['t'] is num) (d.data()['t'] as num).toInt(),
      },
    );
  }

  // =================================================================
  // Klient
  // =================================================================

  /// Rezervuje termín. Vrací chybu k zobrazení, nebo `null` při úspěchu.
  static Future<String?> book({
    required ClientLinkInfo link,
    required String clientName,
    required BookingOffer offer,
    required DateTime start,
  }) async {
    final uid = _uid;
    if (uid == null) return 'Nejsi přihlášený/á.';
    final units = lockUnitsFor(start, offer.minutes);
    final ref = _requests(link.coachUid).doc();
    final booking = Booking(
      id: ref.id,
      coachUid: link.coachUid,
      linkId: link.linkId,
      clientId: link.clientId,
      clientUid: uid,
      clientName: clientName,
      offerName: offer.name,
      type: offer.type,
      start: start,
      minutes: offer.minutes,
      status: BookingStatus.booked,
      units: units,
    );
    final batch = _db.batch();
    batch.set(ref, {
      ...booking.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    for (final u in units) {
      batch.set(_slots(link.coachUid).doc('$u'), {
        't': u,
        'day': dayKey(DateTime.fromMillisecondsSinceEpoch(u)),
        'requestId': ref.id,
        'clientUid': uid,
        'linkId': link.linkId,
      });
    }
    try {
      await batch.commit();
      return null;
    } on FirebaseException catch (e) {
      debugPrint('BOOKING book -> ${e.code} ${e.message}');
      if (e.code == 'permission-denied') {
        return 'Tenhle termín si mezitím zarezervoval někdo jiný. '
            'Vyber prosím jiný čas.';
      }
      return 'Rezervace se nepodařila. Zkontroluj připojení k internetu.';
    } catch (e) {
      return 'Rezervace se nepodařila: $e';
    }
  }

  /// Klient: moje rezervace u trenéra.
  static Stream<List<Booking>> watchMine(String coachUid) {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return _watch(
      _requests(coachUid).where('clientUid', isEqualTo: uid),
      (q) => [
        for (final d in q.docs) Booking.fromJson(d.data()),
      ]..sort((a, b) => a.start.compareTo(b.start)),
    );
  }

  /// Klient zruší svou rezervaci.
  static Future<String?> cancelByClient(Booking b) async {
    final batch = _db.batch();
    batch.update(_requests(b.coachUid).doc(b.id), {
      'status': BookingStatus.cancelled.name,
      'cancelledAt': FieldValue.serverTimestamp(),
    });
    for (final u in b.units) {
      batch.delete(_slots(b.coachUid).doc('$u'));
    }
    try {
      await batch.commit();
      return null;
    } catch (e) {
      debugPrint('BOOKING cancelByClient -> $e');
      return 'Zrušení se nepodařilo. Zkus to prosím znovu.';
    }
  }

  // =================================================================
  // Trenér
  // =================================================================

  /// Trenér: rezervace od včerejška dál (živě).
  static Stream<List<Booking>> watchRequests() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    final from = DateTime.now()
        .subtract(const Duration(days: 1))
        .millisecondsSinceEpoch;
    return _watch(
      _requests(uid).where('start', isGreaterThanOrEqualTo: from),
      (q) => [
        for (final d in q.docs) Booking.fromJson(d.data()),
      ],
    );
  }

  /// Trenér zrušil (nebo smazal) termín z rezervace.
  static Future<void> cancelByCoach(String requestId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final ref = _requests(uid).doc(requestId);
      final snap = await ref.get();
      final d = snap.data();
      if (d == null) return;
      final b = Booking.fromJson(d);
      if (b.status != BookingStatus.booked) return;
      final batch = _db.batch();
      batch.update(ref, {
        'status': BookingStatus.cancelledByCoach.name,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      for (final u in b.units) {
        batch.delete(_slots(uid).doc('$u'));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('BOOKING cancelByCoach -> $e');
    }
  }

  /// Trenér přesunul termín z rezervace na jiný čas.
  static Future<void> rescheduleByCoach(
    String requestId,
    DateTime start,
    int minutes,
  ) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final ref = _requests(uid).doc(requestId);
      final d = (await ref.get()).data();
      if (d == null) return;
      final b = Booking.fromJson(d);
      if (b.status != BookingStatus.booked) return;
      final units = lockUnitsFor(start, minutes);
      final batch = _db.batch();
      for (final u in b.units) {
        if (!units.contains(u)) batch.delete(_slots(uid).doc('$u'));
      }
      for (final u in units) {
        batch.set(_slots(uid).doc('$u'), {
          't': u,
          'day': dayKey(DateTime.fromMillisecondsSinceEpoch(u)),
          'requestId': requestId,
          'clientUid': b.clientUid,
          'linkId': b.linkId,
        });
      }
      batch.update(ref, {
        'start': start.millisecondsSinceEpoch,
        'minutes': minutes,
        'units': units,
        'movedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } catch (e) {
      debugPrint('BOOKING rescheduleByCoach -> $e');
    }
  }

  /// Úklid starých zámků (starší než včera).
  static Future<void> cleanupOldSlots() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final limit = dayKey(DateTime.now().subtract(const Duration(days: 1)));
      final q = await _slots(uid)
          .where('day', isLessThan: limit)
          .limit(300)
          .get();
      if (q.docs.isEmpty) return;
      final batch = _db.batch();
      for (final d in q.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('BOOKING cleanup -> $e');
    }
  }
}
