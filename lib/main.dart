import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'features/spal/spal_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // V ostré verzi nevypisovat ladicí logy (obsahují jména klientů, cíle apod.).
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  try {
    // Při návratu z platební brány může Android spustit aplikaci podruhé –
    // Firebase už pak běží, znovu se nezakládá (jinak černá obrazovka).
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    debugPrint('MAIN -> Firebase initialized');

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );

    debugPrint(
      'MAIN -> Firestore settings applied: persistence=false',
    );
  } catch (e, st) {
    debugPrint('MAIN -> Firebase init error: $e');
    debugPrint('$st');
    rethrow;
  }

  // SPAL Strength Gym (Supabase) – chyba nesmí zastavit aplikaci
  await SpalService.init();

  // Nečekané chyby → sešit chyb ve fitku (jen když je přihlášený člen SPAL)
  // Webová verze: chyby vypsat do konzole prohlížeče (F12) – debugPrint je v ostré verzi vypnutý
  // a místo šedé obrazovky ukázat, co se stalo (ať to jde vyfotit a poslat).
  if (kIsWeb) {
    ErrorWidget.builder = (d) => Material(
          color: Colors.white,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                  'Něco se pokazilo – pošli prosím tuto obrazovku správci:\n\n'
                  '${d.exceptionAsString()}\n\n${d.stack.toString().split('\n').take(12).join('\n')}',
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          ),
        );
  }
  final puvodni = FlutterError.onError;
  FlutterError.onError = (d) {
    // ignore: avoid_print
    if (kIsWeb) print('FLUTTER CHYBA: ${d.exceptionAsString()}\n${d.stack}');
    if (puvodni != null) {
      puvodni(d);
    } else {
      FlutterError.presentError(d);
    }
    SpalService.zapsatChybu(d.exceptionAsString(),
        detail: '${d.context?.toDescription() ?? ''}\n${d.stack ?? ''}', kde: d.library);
  };
  PlatformDispatcher.instance.onError = (e, st) {
    // ignore: avoid_print
    if (kIsWeb) print('NEZACHYCENÁ CHYBA: $e\n$st');
    SpalService.zapsatChybu(e.toString(), detail: st.toString(), kde: 'nezachycená chyba');
    return false;
  };

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
