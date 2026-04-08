import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/coach/coach_client_details.dart';
import '../../services/coach/coach_storage_service.dart';

final coachClientDetailsControllerProvider =
    AsyncNotifierProvider<CoachClientDetailsController, List<CoachClientDetails>>(
  CoachClientDetailsController.new,
);

final coachClientDetailsForClientProvider =
    Provider.family<AsyncValue<CoachClientDetails>, String>((ref, clientId) {
  final all = ref.watch(coachClientDetailsControllerProvider);

  return all.whenData((items) {
    final found = items.where((x) => x.clientId == clientId).toList();
    if (found.isEmpty) return CoachClientDetails(clientId: clientId);
    return found.first;
  });
});

class CoachClientDetailsController extends AsyncNotifier<List<CoachClientDetails>> {
  @override
  Future<List<CoachClientDetails>> build() async {
    return CoachStorageService.loadClientDetailsAll();
  }

  Future<void> upsert(CoachClientDetails details) async {
    final existing = state.value ?? await CoachStorageService.loadClientDetailsAll();

    final updated = <CoachClientDetails>[
      for (final d in existing)
        if (d.clientId != details.clientId) d,
      details,
    ];

    await CoachStorageService.saveClientDetailsAll(updated);
    state = AsyncData(updated);
  }
}
