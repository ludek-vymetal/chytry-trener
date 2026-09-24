import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/coach/coach_storage_service.dart';
import '../daily_history_provider.dart';
import '../daily_intake_provider.dart';
import '../training_session_provider.dart';
import 'coach_circumference_controller.dart';
import 'coach_clients_controller.dart';
import 'coach_diagnostic_controller.dart';
import 'coach_goal_controller.dart';
import 'coach_inbody_controller.dart';
import 'coach_notes_controller.dart';
import 'coach_setup_provider.dart';

final coachAuthStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

class CoachAuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      debugPrint('AUTH SIGN IN OK -> uid=${cred.user?.uid}');

      // Synchronizaci s cloudem spouští CoachSessionBootstrap (app.dart),
      // jakmile authStateChanges ohlásí přihlášeného uživatele.

      _invalidateCoachProviders();

      state = const AsyncData(null);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(_mapFirebaseAuthError(e), st);
      rethrow;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      debugPrint('AUTH REGISTER OK -> uid=${cred.user?.uid}');

      // Synchronizaci s cloudem spouští CoachSessionBootstrap (app.dart),
      // jakmile authStateChanges ohlásí přihlášeného uživatele.

      _invalidateCoachProviders();

      state = const AsyncData(null);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(_mapFirebaseAuthError(e), st);
      rethrow;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Pošle e-mail s odkazem pro obnovení hesla.
  Future<void> sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    }
  }

  /// Trvale smaže účet trenéra: ověří heslo, smaže data v cloudu,
  /// lokální trenérská data a nakonec samotný účet ve Firebase Auth.
  Future<void> deleteAccount({required String password}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw 'Nikdo není přihlášený.';
    }

    state = const AsyncLoading();

    try {
      // Firebase vyžaduje čerstvé přihlášení před smazáním účtu.
      final email = user.email;
      if (email != null && email.isNotEmpty) {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: password),
        );
      }

      final uid = user.uid;

      await CoachStorageService.deleteCloudDataForCoach(uid);
      await CoachStorageService.clearLocalDataForCoach(uid);
      await user.delete();

      debugPrint('AUTH DELETE ACCOUNT OK -> uid=$uid');

      _invalidateCoachProviders();

      state = const AsyncData(null);
    } on FirebaseAuthException catch (e, st) {
      final message = _mapFirebaseAuthError(e);
      state = AsyncError(message, st);
      throw message;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();

    try {
      await FirebaseAuth.instance.signOut();
      debugPrint('AUTH SIGN OUT OK');

      _invalidateCoachProviders();

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  void _invalidateCoachProviders() {
    ref.invalidate(coachClientsControllerProvider);
    ref.invalidate(coachNotesControllerProvider);
    ref.invalidate(coachInbodyControllerProvider);
    ref.invalidate(coachCircumferenceControllerProvider);
    ref.invalidate(coachDiagnosticControllerProvider);
    ref.invalidate(coachGoalControllerProvider);
    ref.invalidate(trainingSessionProvider);
    ref.invalidate(dailyHistoryProvider);
    ref.invalidate(dailyIntakeProvider);
    ref.invalidate(coachSetupProvider);
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'E-mail nemá platný formát.';
      case 'user-disabled':
        return 'Tento účet byl zablokovaný.';
      case 'user-not-found':
        return 'Účet s tímto e-mailem neexistuje.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Neplatný e-mail nebo heslo.';
      case 'email-already-in-use':
        return 'Tento e-mail už je registrovaný.';
      case 'weak-password':
        return 'Heslo je příliš slabé.';
      case 'network-request-failed':
        return 'Síťová chyba. Zkontroluj internetové připojení.';
      case 'requires-recent-login':
        return 'Pro tuto akci se musíš znovu přihlásit.';
      case 'too-many-requests':
        return 'Příliš mnoho pokusů. Zkus to znovu později.';
      default:
        return e.message ?? 'Nepodařilo se dokončit přihlášení.';
    }
  }
}

final coachAuthControllerProvider =
    AsyncNotifierProvider<CoachAuthController, void>(
  CoachAuthController.new,
);