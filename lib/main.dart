import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('MAIN -> Firebase initialized');

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    debugPrint('MAIN -> Firestore settings applied: persistence=false');
  } catch (e, st) {
    debugPrint('MAIN -> Firebase init error: $e');
    debugPrint('$st');
    rethrow;
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}