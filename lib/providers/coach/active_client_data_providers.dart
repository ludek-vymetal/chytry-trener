import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/coach/coach_client.dart';
import '../../models/coach/coach_client_details.dart';
import '../../models/coach/coach_inbody_entry.dart';
import '../../services/coach/coach_storage_service.dart';
import 'active_client_provider.dart';

/// Aktivní coach klient (full CoachClient) podle activeClientIdProvider
final activeCoachClientProvider = FutureProvider<CoachClient?>((ref) async {
  final activeId = ref.watch(activeClientIdProvider).valueOrNull;
  if (activeId == null) return null;

  final all = await CoachStorageService.loadClients();
  try {
    return all.firstWhere((c) => c.clientId == activeId);
  } catch (_) {
    return null;
  }
});

/// Aktivní klient – details (lifestyle)
final activeCoachClientDetailsProvider = FutureProvider<CoachClientDetails?>((ref) async {
  final activeId = ref.watch(activeClientIdProvider).valueOrNull;
  if (activeId == null) return null;

  final all = await CoachStorageService.loadClientDetailsAll();
  try {
    return all.firstWhere((x) => x.clientId == activeId);
  } catch (_) {
    return null;
  }
});

/// Aktivní klient – INBODY entries
final activeCoachClientInbodyProvider = FutureProvider<List<CoachInbodyEntry>>((ref) async {
  final activeId = ref.watch(activeClientIdProvider).valueOrNull;
  if (activeId == null) return const [];

  final all = await CoachStorageService.loadInbodyAll();
  return all.where((e) => e.clientId == activeId).toList();
});