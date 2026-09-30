import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'online_coaching_service.dart';

/// Týdenní check-in klienta (váha + jak se cítí), `coaching/{linkId}/checkins`.
class CheckIn {
  final String id;
  final DateTime date;
  final double? weight;

  /// Hodnocení 1–5 (5 = nejlepší). U hladu a stresu 5 = nejmenší.
  final int sleep;
  final int energy;
  final int hunger;
  final int stress;
  final int diet;
  final String note;

  const CheckIn({
    required this.id,
    required this.date,
    required this.weight,
    required this.sleep,
    required this.energy,
    required this.hunger,
    required this.stress,
    required this.diet,
    required this.note,
  });

  /// Průměrná pohoda 1–5.
  double get score => (sleep + energy + hunger + stress + diet) / 5;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'weight': weight,
        'sleep': sleep,
        'energy': energy,
        'hunger': hunger,
        'stress': stress,
        'diet': diet,
        'note': note,
      };

  factory CheckIn.fromJson(Map<String, dynamic> j) {
    int v(Object? x) => ((x as num?)?.toInt() ?? 3).clamp(1, 5);
    return CheckIn(
      id: (j['id'] ?? '').toString(),
      date: DateTime.tryParse((j['date'] ?? '').toString()) ?? DateTime.now(),
      weight: (j['weight'] as num?)?.toDouble(),
      sleep: v(j['sleep']),
      energy: v(j['energy']),
      hunger: v(j['hunger']),
      stress: v(j['stress']),
      diet: v(j['diet']),
      note: (j['note'] ?? '').toString(),
    );
  }
}

class CheckInService {
  CheckInService._();

  /// Jak často má klient check-in posílat.
  static const intervalDays = 7;

  static CollectionReference<Map<String, dynamic>> _ref(String linkId) =>
      FirebaseFirestore.instance
          .collection('coaching')
          .doc(linkId)
          .collection('checkins');

  static List<CheckIn> _parse(QuerySnapshot<Map<String, dynamic>> q) => [
        for (final d in q.docs) CheckIn.fromJson(d.data()),
      ]..sort((a, b) => b.date.compareTo(a.date));

  /// Trenér: check-iny klienta (nejnovější první).
  static Future<List<CheckIn>> listForLink(String linkId) async {
    final q = await _ref(linkId).get();
    return _parse(q);
  }

  /// Trenér: živý seznam check-inů.
  static Stream<List<CheckIn>> watchForLink(String linkId) =>
      _ref(linkId).snapshots().map(_parse);

  /// Klient: moje check-iny.
  static Future<List<CheckIn>> listMine() async {
    final link = await OnlineCoachingService.localClientLink();
    if (link == null) return const [];
    try {
      return _parse(await _ref(link.linkId).get());
    } catch (_) {
      return const [];
    }
  }

  static Future<void> submit(CheckIn c) async {
    final link = await OnlineCoachingService.localClientLink();
    if (link == null) throw StateError('Nejsi propojený s trenérem.');
    await _ref(link.linkId).doc(c.id).set({
      ...c.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'uid': FirebaseAuth.instance.currentUser?.uid,
    });
  }

  /// Je čas na nový check-in?
  static bool isDue(List<CheckIn> list) {
    if (list.isEmpty) return true;
    return DateTime.now().difference(list.first.date).inDays >= intervalDays;
  }
}
