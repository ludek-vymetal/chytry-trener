import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/coach/coach_setup_data.dart';

class CoachSetupNotifier extends AsyncNotifier<CoachSetupData?> {
  static const _firstNameKey = 'coach_first_name';
  static const _securityPinKey = 'coach_security_pin';
  static const _completedKey = 'has_completed_coach_setup';

  @override
  FutureOr<CoachSetupData?> build() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();

    final isCompleted = prefs.getBool(_scoped(uid, _completedKey)) ?? false;
    final firstName = prefs.getString(_scoped(uid, _firstNameKey))?.trim() ?? '';
    final securityPin =
        prefs.getString(_scoped(uid, _securityPinKey))?.trim() ?? '';

    if (!isCompleted || firstName.isEmpty || securityPin.length != 4) {
      return null;
    }

    return CoachSetupData(
      firstName: firstName,
      securityPin: securityPin,
    );
  }

  Future<void> saveSetup({
    required String firstName,
    required String securityPin,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      throw StateError('Coach není přihlášený.');
    }

    final normalizedFirstName = _normalizeFirstName(firstName);
    final normalizedPin = securityPin.trim();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_scoped(uid, _firstNameKey), normalizedFirstName);
    await prefs.setString(_scoped(uid, _securityPinKey), normalizedPin);
    await prefs.setBool(_scoped(uid, _completedKey), true);

    state = AsyncData(
      CoachSetupData(
        firstName: normalizedFirstName,
        securityPin: normalizedPin,
      ),
    );
  }

  Future<void> clearSetup() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      state = const AsyncData(null);
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_scoped(uid, _firstNameKey));
    await prefs.remove(_scoped(uid, _securityPinKey));
    await prefs.remove(_scoped(uid, _completedKey));

    state = const AsyncData(null);
  }

  String _scoped(String uid, String key) => 'coach_setup_${uid}_$key';

  String _normalizeFirstName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    final lower = trimmed.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}

final coachSetupProvider =
    AsyncNotifierProvider<CoachSetupNotifier, CoachSetupData?>(
  CoachSetupNotifier.new,
);