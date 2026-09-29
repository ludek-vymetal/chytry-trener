import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'coach_cloud_sync_service.dart';
import 'coach_storage_service.dart';
import 'extra_backup_service.dart';

/// Propojení trenér ↔ klient v cloudu.
class CoachingLink {
  final String linkId;
  final String coachUid;
  final String clientId;
  final String clientName;
  final String? coachName;
  final String? clientUid;
  final String? inviteCode;
  final DateTime? joinedAt;

  const CoachingLink({
    required this.linkId,
    required this.coachUid,
    required this.clientId,
    required this.clientName,
    this.coachName,
    this.clientUid,
    this.inviteCode,
    this.joinedAt,
  });

  bool get isConnected => clientUid != null;

  factory CoachingLink.fromDoc(String id, Map<String, dynamic> d) {
    DateTime? ts(Object? v) => v is Timestamp ? v.toDate() : null;
    return CoachingLink(
      linkId: id,
      coachUid: (d['coachUid'] ?? '') as String,
      clientId: (d['clientId'] ?? '') as String,
      clientName: (d['clientName'] ?? '') as String,
      coachName: d['coachName'] as String?,
      clientUid: d['clientUid'] as String?,
      inviteCode: d['inviteCode'] as String?,
      joinedAt: ts(d['joinedAt']),
    );
  }
}

/// Propojení uložené v telefonu KLIENTA.
class ClientLinkInfo {
  final String linkId;
  final String clientId;
  final String coachUid;
  final String? coachName;

  const ClientLinkInfo({
    required this.linkId,
    required this.clientId,
    required this.coachUid,
    this.coachName,
  });

  Map<String, dynamic> toJson() => {
        'linkId': linkId,
        'clientId': clientId,
        'coachUid': coachUid,
        'coachName': coachName,
      };

  factory ClientLinkInfo.fromJson(Map<String, dynamic> j) => ClientLinkInfo(
        linkId: j['linkId'] as String,
        clientId: j['clientId'] as String,
        coachUid: j['coachUid'] as String,
        coachName: j['coachName'] as String?,
      );
}

/// Online coaching: každý klient má v cloudu vlastní „složku“
/// `coaching/{linkId}`, do které má přístup jen trenér a ten klient.
///
/// Sdílí se: karta klienta, profil (cíl, makra, jídelníček), tréninkové
/// plány, InBody, obvody, cíle, odcvičené tréninky, jídlo a výkony.
/// Poznámky trenéra se NESDÍLEJÍ.
class OnlineCoachingService {
  OnlineCoachingService._();

  static const _links = 'coaching';
  static const _invites = 'invites';
  static const _data = 'data';
  static const _clientLinkKey = 'coaching_client_link_v1';
  static const _chunkChars = 300000;

  /// Seznamy, ze kterých se sdílí záznamy daného klienta.
  static const _listKeys = <String>[
    CoachStorageService.clientsKey,
    CoachStorageService.clientDetailsKey,
    CoachStorageService.circumferencesKey,
    CoachStorageService.inbodyKey,
    CoachStorageService.goalsKey,
    CoachStorageService.diagnosticsKey,
    CoachStorageService.overridesKey,
    CoachStorageService.trainingSessionsKey,
    CoachStorageService.dailyHistoryKey,
    // Tréninkové plány se záměrně NESDÍLEJÍ – klient dostává jen
    // jednotlivé tréninky, které mu trenér pošle (WorkoutAssignmentService).
  ];

  static const _performanceKey = 'exercise_performance_storage';

  /// Zvýší se, když synchronizace změnila data v zařízení → aplikace
  /// si je načte znovu.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  /// Poslední chyba synchronizace (pro zobrazení), `null` = v pořádku.
  static final ValueNotifier<String?> lastError = ValueNotifier(null);

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static String linkIdFor(String coachUid, String clientId) =>
      '${coachUid}_$clientId';

  // =================================================================
  // TRENÉR
  // =================================================================

  static String? _coachUid() {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null || u.isAnonymous) return null;
    return u.uid;
  }

  static Future<CoachingLink?> loadLink(String clientId) async {
    final uid = _coachUid();
    if (uid == null) return null;
    final id = linkIdFor(uid, clientId);
    final snap = await _db.collection(_links).doc(id).get();
    if (!snap.exists) return null;
    return CoachingLink.fromDoc(id, snap.data()!);
  }

  static Future<List<CoachingLink>> coachLinks() async {
    final uid = _coachUid();
    if (uid == null) return const [];
    final q =
        await _db.collection(_links).where('coachUid', isEqualTo: uid).get();
    return [for (final d in q.docs) CoachingLink.fromDoc(d.id, d.data())];
  }

  static const _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static String normalizeCode(String input) {
    final n = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return n.startsWith('KL') ? n : 'KL$n';
  }

  static String formatCode(String code) {
    final n = code.startsWith('KL') ? code.substring(2) : code;
    if (n.length != 8) return code;
    return 'KL-${n.substring(0, 4)}-${n.substring(4)}';
  }

  /// Vytvoří (nebo obnoví) pozvánku pro klienta. Vrací kód ve tvaru
  /// KL-XXXX-XXXX. Starý nevyužitý kód přestane platit.
  static Future<String> createInvite({
    required String clientId,
    required String clientName,
    String? coachName,
  }) async {
    final uid = _coachUid();
    if (uid == null) {
      throw StateError('Pro pozvání klienta musíš být přihlášená jako trenér.');
    }
    final rnd = Random.secure();
    final b = StringBuffer('KL');
    for (var i = 0; i < 8; i++) {
      b.write(_alphabet[rnd.nextInt(_alphabet.length)]);
    }
    final code = b.toString();
    final linkId = linkIdFor(uid, clientId);
    final linkRef = _db.collection(_links).doc(linkId);
    final existing = await linkRef.get();

    final batch = _db.batch();
    final oldCode = existing.data()?['inviteCode'] as String?;
    if (oldCode != null && existing.data()?['clientUid'] == null) {
      batch.delete(_db.collection(_invites).doc(oldCode));
    }
    if (existing.exists) {
      batch.update(linkRef, {
        'inviteCode': code,
        'clientName': clientName,
        'coachName': coachName,
      });
    } else {
      batch.set(linkRef, {
        'coachUid': uid,
        'clientId': clientId,
        'clientName': clientName,
        'coachName': coachName,
        'clientUid': null,
        'inviteCode': code,
        'joinCode': null,
        'createdAt': FieldValue.serverTimestamp(),
        'joinedAt': null,
      });
    }
    batch.set(_db.collection(_invites).doc(code), {
      'coachUid': uid,
      'linkId': linkId,
      'clientId': clientId,
      'coachName': coachName,
      'createdAt': FieldValue.serverTimestamp(),
      'usedBy': null,
      'usedAt': null,
    });
    await batch.commit();

    // Klient hned po připojení uvidí aktuální data.
    unawaited(_syncLinkSafe(linkId, clientId));
    return formatCode(code);
  }

  /// Ukončí online coaching s klientem – klient ztratí přístup.
  static Future<void> unlink(String clientId) async {
    final uid = _coachUid();
    if (uid == null) return;
    final linkId = linkIdFor(uid, clientId);
    final linkRef = _db.collection(_links).doc(linkId);
    final data = await linkRef.collection(_data).get();
    final batch = _db.batch();
    for (final d in data.docs) {
      batch.delete(d.reference);
    }
    final code = (await linkRef.get()).data()?['inviteCode'] as String?;
    if (code != null) batch.delete(_db.collection(_invites).doc(code));
    batch.delete(linkRef);
    await batch.commit();
  }

  // =================================================================
  // KLIENT
  // =================================================================

  static Future<ClientLinkInfo?> localClientLink() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_clientLinkKey);
    if (raw == null) return null;
    try {
      return ClientLinkInfo.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  /// Připojení klienta kódem od trenéra. Vrací `null` při úspěchu,
  /// jinak srozumitelnou chybu.
  static Future<(ClientLinkInfo?, String?)> joinWithCode(String input) async {
    final code = normalizeCode(input);
    if (code.length != 10) {
      return (null, 'Kód má tvar KL-XXXX-XXXX – zkontroluj ho.');
    }
    try {
      final auth = FirebaseAuth.instance;
      // Telefon klienta: případný trenérský účet (omyl při výběru režimu)
      // se odhlásí – klient se připojuje vlastním anonymním účtem.
      final current = auth.currentUser;
      if (current != null && !current.isAnonymous) {
        await auth.signOut();
      }
      final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;

      final inviteRef = _db.collection(_invites).doc(code);
      final invite = await inviteRef.get();
      if (!invite.exists) {
        return (null, 'Tento kód neexistuje nebo už neplatí.');
      }
      final inv = invite.data()!;
      final usedBy = inv['usedBy'] as String?;
      if (usedBy != null && usedBy != user.uid) {
        return (null, 'Tento kód už někdo použil. Požádej trenéra o nový.');
      }
      final linkId = inv['linkId'] as String;
      final linkRef = _db.collection(_links).doc(linkId);

      if (usedBy == null) {
        final batch = _db.batch();
        batch.update(inviteRef, {
          'usedBy': user.uid,
          'usedAt': FieldValue.serverTimestamp(),
        });
        batch.update(linkRef, {
          'clientUid': user.uid,
          'joinedAt': FieldValue.serverTimestamp(),
          'joinCode': code,
        });
        await batch.commit();
      }

      final info = ClientLinkInfo(
        linkId: linkId,
        clientId: inv['clientId'] as String,
        coachUid: inv['coachUid'] as String,
        coachName: inv['coachName'] as String?,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_clientLinkKey, jsonEncode(info.toJson()));

      await syncLink(info.linkId, info.clientId);
      return (info, null);
    } on FirebaseException catch (e) {
      debugPrint('JOIN ERROR -> ${e.code} ${e.message}');
      if (e.code == 'permission-denied') {
        return (null, 'Připojení se nepodařilo (oprávnění). Kód možná už neplatí.');
      }
      if (e.code == 'operation-not-allowed' || e.code == 'admin-restricted-operation') {
        return (null, 'Přihlášení klientů není zapnuté – dej vědět trenérovi.');
      }
      return (null, 'Nepodařilo se připojit. Zkontroluj internet.');
    } catch (e) {
      debugPrint('JOIN ERROR -> $e');
      return (null, 'Nepodařilo se připojit. Zkontroluj internet.');
    }
  }

  /// Klient se odpojí (data v telefonu zůstanou).
  static Future<void> leave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clientLinkKey);
  }

  // =================================================================
  // SYNCHRONIZACE
  // =================================================================

  static Timer? _timer;
  static bool _running = false;

  /// Synchronizace chvíli po poslední změně (víc změn = jedna).
  static void scheduleSync({Duration delay = const Duration(seconds: 6)}) {
    _timer?.cancel();
    _timer = Timer(delay, () => syncNow());
  }

  /// Synchronizuje vše, co se týká tohoto zařízení:
  /// klient → jeho propojení, trenér → všichni připojení klienti.
  static Future<void> syncNow() async {
    if (_running) return;
    if (FirebaseAuth.instance.currentUser == null) return;
    _running = true;
    try {
      final client = await localClientLink();
      if (client != null) {
        await syncLink(client.linkId, client.clientId);
      } else if (_coachUid() != null) {
        for (final link in await coachLinks()) {
          await syncLink(link.linkId, link.clientId);
        }
      }
      lastError.value = null;
    } on FirebaseException catch (e) {
      lastError.value = e.code == 'permission-denied'
          ? 'Propojení s trenérem už neplatí.'
          : 'Synchronizace se nepovedla (${e.code}).';
      debugPrint('COACHING SYNC ERROR -> ${e.code}');
    } catch (e) {
      lastError.value = 'Synchronizace se nepovedla.';
      debugPrint('COACHING SYNC ERROR -> $e');
    } finally {
      _running = false;
    }
  }

  static Future<void> _syncLinkSafe(String linkId, String clientId) async {
    try {
      await syncLink(linkId, clientId);
    } catch (e) {
      debugPrint('COACHING SYNC ERROR -> $e');
    }
  }

  /// Sloučí data jednoho klienta mezi zařízením a cloudem (obousměrně).
  static Future<void> syncLink(String linkId, String clientId) async {
    final dataRef = _db.collection(_links).doc(linkId).collection(_data);
    final me = FirebaseAuth.instance.currentUser?.uid ?? '';
    var changed = false;

    // ---- seznamy (novější verze záznamu vyhrává) ----
    for (final key in _listKeys) {
      final all = await CoachStorageService.loadRawItemsForKey(key);
      final mine = [for (final i in all) if (i['clientId'] == clientId) i];
      final others = [for (final i in all) if (i['clientId'] != clientId) i];

      final cloudRaw = await _read(dataRef, key);
      final cloud = cloudRaw == null
          ? const <Map<String, dynamic>>[]
          : [
              for (final e in (jsonDecode(cloudRaw) as List))
                Map<String, dynamic>.from(e as Map),
            ];

      final merged = cloud.isEmpty
          ? mine
          : CoachCloudSyncService.mergeLists(
              key: key,
              localItems: mine,
              cloudItems: cloud,
            );

      final mergedJson = jsonEncode(merged);
      if (mergedJson != jsonEncode(mine)) {
        await CoachStorageService.saveRawItemsForKeyLocalOnly(
          key: key,
          items: [...others, ...merged],
        );
        changed = true;
      }
      if (cloudRaw == null || mergedJson != cloudRaw) {
        await _write(dataRef, key, mergedJson, me);
      }
    }

    // ---- celý tréninkový plán klient nevidí ----
    final plansDoc = dataRef.doc(CoachStorageService.customTrainingPlansKey);
    if ((await plansDoc.get()).exists) await plansDoc.delete();
    if (await localClientLink() != null) {
      const key = CoachStorageService.customTrainingPlansKey;
      final all = await CoachStorageService.loadRawItemsForKey(key);
      final kept = [for (final i in all) if (i['clientId'] != clientId) i];
      if (kept.length != all.length) {
        await CoachStorageService.saveRawItemsForKeyLocalOnly(
          key: key,
          items: kept,
        );
        changed = true;
      }
    }

    final prefs = await SharedPreferences.getInstance();

    // ---- výkony u cviků (sjednocení) ----
    {
      List<dynamic> parse(String? s) {
        if (s == null || s.isEmpty) return const [];
        try {
          final d = jsonDecode(s);
          return d is List ? d : const [];
        } catch (_) {
          return const [];
        }
      }

      final all = parse(prefs.getString(_performanceKey));
      final mine = [for (final e in all) if (e is Map && e['clientId'] == clientId) e];
      final others = [for (final e in all) if (!(e is Map && e['clientId'] == clientId)) e];
      final cloudRaw = await _read(dataRef, 'performances');
      final merged = ExtraBackupService.mergePerformances(
        jsonEncode(mine),
        cloudRaw,
      );
      if (merged != jsonEncode(mine)) {
        await prefs.setString(
          _performanceKey,
          jsonEncode([...others, ...parse(merged)]),
        );
        changed = true;
      }
      if (merged != cloudRaw) {
        await _write(dataRef, 'performances', merged, me);
      }
    }

    // ---- profil klienta (novější vyhrává) ----
    {
      final profileKey = 'user_profile_storage_$clientId';
      final tsKey = 'profile_updated_at_$clientId';
      final local = prefs.getString(profileKey);
      final localTs =
          DateTime.tryParse(prefs.getString(tsKey) ?? '') ?? DateTime(2000);

      final doc = await dataRef.doc('profile').get();
      final cloudPayload = doc.data()?['payloadJson'] as String?;
      final cloudTs = DateTime.tryParse(
            (doc.data()?['changedAt'] as String?) ?? '',
          ) ??
          DateTime(2000);

      if (cloudPayload != null &&
          cloudTs.isAfter(localTs) &&
          cloudPayload != local) {
        await prefs.setString(profileKey, cloudPayload);
        await prefs.setString(tsKey, cloudTs.toUtc().toIso8601String());
        changed = true;
      } else if (local != null &&
          (cloudPayload == null || localTs.isAfter(cloudTs)) &&
          local != cloudPayload) {
        await dataRef.doc('profile').set({
          'payloadJson': local,
          'changedAt': localTs.toUtc().toIso8601String(),
          'updatedBy': me,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await _db.collection(_links).doc(linkId).collection(_data).doc('_meta').set({
      'lastSyncBy': me,
      'lastSyncAt': FieldValue.serverTimestamp(),
    });

    if (changed) revision.value++;
    debugPrint('COACHING SYNC OK -> link=$linkId changed=$changed');
  }

  // ---- čtení / zápis s dělením na části (limit dokumentu 1 MiB) ----

  static Future<String?> _read(
    CollectionReference<Map<String, dynamic>> ref,
    String key,
  ) async {
    final doc = await ref.doc(key).get();
    if (!doc.exists) return null;
    final d = doc.data()!;
    final single = d['payloadJson'];
    if (single is String) return single;
    final count = (d['chunkCount'] as num?)?.toInt() ?? 0;
    if (count <= 0) return null;
    final parts = await Future.wait(
      List.generate(count, (i) => ref.doc('${key}__part_$i').get()),
    );
    return parts.map((p) => (p.data()?['payloadPart'] ?? '') as String).join();
  }

  static Future<void> _write(
    CollectionReference<Map<String, dynamic>> ref,
    String key,
    String payload,
    String uid,
  ) async {
    final meta = {
      'updatedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (payload.length <= _chunkChars) {
      await ref.doc(key).set({...meta, 'payloadJson': payload});
      return;
    }
    final batch = _db.batch();
    var count = 0;
    for (var i = 0; i < payload.length; i += _chunkChars) {
      final end = min(i + _chunkChars, payload.length);
      batch.set(ref.doc('${key}__part_$count'), {
        'payloadPart': payload.substring(i, end),
      });
      count++;
    }
    batch.set(ref.doc(key), {...meta, 'chunkCount': count});
    await batch.commit();
  }
}
