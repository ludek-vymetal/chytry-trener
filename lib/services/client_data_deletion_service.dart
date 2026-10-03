import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'app_reset_service.dart';
import 'coach/online_coaching_service.dart';
import 'health/health_sync_service.dart';

/// Klient: smazání všech vlastních dat (požadavek App Store a GDPR).
///
/// Smaže data z hodinek (i ta sdílená s trenérem), zruší propojení
/// s trenérem, smaže anonymní účet klienta a vymaže zařízení.
/// Záznamy, které vede trenér (karta klienta, odcvičené tréninky),
/// zůstávají trenérovi – klienta může smazat on.
class ClientDataDeletionService {
  ClientDataDeletionService._();

  static Future<void> deleteAll() async {
    // 1) Data z hodinek – v telefonu i u trenéra.
    try {
      await HealthSyncService.disconnect();
    } catch (e) {
      debugPrint('CLIENT DELETE health -> $e');
    }

    // 2) Odpojení od trenéra.
    try {
      await OnlineCoachingService.leave();
    } catch (e) {
      debugPrint('CLIENT DELETE leave -> $e');
    }

    // 3) Anonymní účet klienta (trenérský účet se tu nikdy nemaže –
    //    na ten je „Smazat účet“ v nastavení trenéra).
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.isAnonymous) {
      try {
        await user.delete();
      } catch (e) {
        debugPrint('CLIENT DELETE auth -> $e');
      }
    }

    // 4) Vše v zařízení + odhlášení.
    await AppResetService.factoryReset();
  }
}
