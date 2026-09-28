import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Výsledek uplatnění kódu.
class RedeemResult {
  final int months;
  final String? error;

  const RedeemResult.ok(this.months) : error = null;
  const RedeemResult.fail(this.error) : months = 0;
}

/// Aktivační kódy na předplatné (pro klienty, kteří platí přímo trenérce).
///
/// Kód je dokument `license_codes/{KÓD}` ve Firestore:
/// `{ months: 1|3|6|12, createdAt, createdBy, usedBy: null, usedAt: null }`.
/// Každý kód jde použít jen jednou.
class LicenseCodeService {
  LicenseCodeService._();

  static const _collection = 'license_codes';

  /// Bez zaměnitelných znaků (0/O, 1/I/L).
  static const _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static String normalize(String code) =>
      code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// Hezky čitelný tvar: CT-ABCD-EFGH.
  static String format(String normalized) {
    final n = normalized.startsWith('CT') ? normalized.substring(2) : normalized;
    if (n.length != 8) return normalized;
    return 'CT-${n.substring(0, 4)}-${n.substring(4)}';
  }

  static String _newCode(Random rnd) {
    final b = StringBuffer('CT');
    for (var i = 0; i < 8; i++) {
      b.write(_alphabet[rnd.nextInt(_alphabet.length)]);
    }
    return b.toString();
  }

  static Future<User> _ensureUser() async {
    final auth = FirebaseAuth.instance;
    final current = auth.currentUser;
    if (current != null) return current;
    // Klient bez účtu – anonymní přihlášení jen kvůli ověření kódu.
    final cred = await auth.signInAnonymously();
    return cred.user!;
  }

  static Future<RedeemResult> redeem(String input) async {
    final code = normalize(input);
    if (code.length < 8) {
      return const RedeemResult.fail('Kód je příliš krátký – zkontroluj ho.');
    }
    final docId = code.startsWith('CT') ? code : 'CT$code';

    try {
      final user = await _ensureUser();
      final ref =
          FirebaseFirestore.instance.collection(_collection).doc(docId);

      return await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) {
          return const RedeemResult.fail(
            'Tento kód neexistuje. Zkontroluj překlepy.',
          );
        }
        final data = snap.data() ?? const <String, dynamic>{};
        final usedBy = data['usedBy'] as String?;
        if (usedBy != null && usedBy != user.uid) {
          return const RedeemResult.fail('Tento kód už byl použitý.');
        }
        final months = (data['months'] as num?)?.toInt() ?? 0;
        if (months <= 0) {
          return const RedeemResult.fail('Kód není platný.');
        }
        if (usedBy == null) {
          tx.update(ref, {
            'usedBy': user.uid,
            'usedAt': FieldValue.serverTimestamp(),
          });
        }
        return RedeemResult.ok(months);
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const RedeemResult.fail(
          'Kód se nepodařilo ověřit (chybí oprávnění). Kontaktuj trenéra.',
        );
      }
      return const RedeemResult.fail(
        'Kód se nepodařilo ověřit. Zkontroluj připojení k internetu.',
      );
    } catch (_) {
      return const RedeemResult.fail(
        'Kód se nepodařilo ověřit. Zkontroluj připojení k internetu.',
      );
    }
  }

  /// Vygeneruje [count] nových kódů na [months] měsíců (jen pro správce).
  static Future<List<String>> generate({
    required int months,
    int count = 1,
    String? note,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Pro generování kódů je potřeba být přihlášen/a.');
    }
    final rnd = Random.secure();
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    final codes = <String>[];
    for (var i = 0; i < count; i++) {
      final code = _newCode(rnd);
      codes.add(format(code));
      batch.set(db.collection(_collection).doc(code), {
        'months': months,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'note': note,
        'usedBy': null,
        'usedAt': null,
      });
    }
    await batch.commit();
    return codes;
  }
}
