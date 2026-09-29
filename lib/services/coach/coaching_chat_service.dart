import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Jedna zpráva mezi trenérem a klientem.
class ChatMessage {
  final String id;
  final bool fromCoach;
  final String text;
  final DateTime at;

  /// Přečetl ji příjemce.
  final bool read;

  const ChatMessage({
    required this.id,
    required this.fromCoach,
    required this.text,
    required this.at,
    required this.read,
  });

  factory ChatMessage.fromDoc(String id, Map<String, dynamic> d) {
    return ChatMessage(
      id: id,
      fromCoach: d['from'] == 'coach',
      text: (d['text'] ?? '').toString(),
      at: DateTime.tryParse((d['clientAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      read: d['read'] == true,
    );
  }
}

/// Zprávy online koučinku: `coaching/{linkId}/messages/{id}`.
/// Přístup mají jen trenér a klient daného propojení (pravidla Firestore).
class CoachingChatService {
  CoachingChatService._();

  static const maxLength = 2000;

  static CollectionReference<Map<String, dynamic>> _ref(String linkId) =>
      FirebaseFirestore.instance
          .collection('coaching')
          .doc(linkId)
          .collection('messages');

  /// Posledních 300 zpráv, nejnovější první.
  static Stream<List<ChatMessage>> watch(String linkId) {
    return _ref(linkId)
        .orderBy('clientAt', descending: true)
        .limit(300)
        .snapshots()
        .map((q) => [
              for (final d in q.docs) ChatMessage.fromDoc(d.id, d.data()),
            ]);
  }

  static Future<void> send(
    String linkId,
    String text, {
    required bool fromCoach,
  }) async {
    final t = text.trim();
    if (t.isEmpty) return;
    await _ref(linkId).add({
      'from': fromCoach ? 'coach' : 'client',
      'text': t.length > maxLength ? t.substring(0, maxLength) : t,
      'clientAt': DateTime.now().toUtc().toIso8601String(),
      'at': FieldValue.serverTimestamp(),
      'read': false,
      'uid': FirebaseAuth.instance.currentUser?.uid,
    });
  }

  static Query<Map<String, dynamic>> _unreadQuery(
    String linkId, {
    required bool asCoach,
  }) =>
      _ref(linkId)
          .where('from', isEqualTo: asCoach ? 'client' : 'coach')
          .where('read', isEqualTo: false);

  /// Počet nepřečtených zpráv od druhé strany (živě).
  static Stream<int> watchUnread(String linkId, {required bool asCoach}) =>
      _unreadQuery(linkId, asCoach: asCoach)
          .snapshots()
          .map((q) => q.size);

  static Future<int> unread(String linkId, {required bool asCoach}) async {
    try {
      final q = await _unreadQuery(linkId, asCoach: asCoach).get();
      return q.size;
    } catch (_) {
      return 0;
    }
  }

  /// Označí zprávy od druhé strany jako přečtené.
  static Future<void> markRead(String linkId, {required bool asCoach}) async {
    try {
      final q = await _unreadQuery(linkId, asCoach: asCoach).get();
      if (q.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final d in q.docs) {
        batch.update(d.reference, {'read': true});
      }
      await batch.commit();
    } catch (_) {
      // Bez připojení se to zkusí příště.
    }
  }
}
