import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'coach_clients_controller.dart';

class CoachClientLite {
  final String clientId;
  final String displayName;
  final String email;
  final double compliance7d; // 0..1
  final DateTime? lastSessionAt;
  final bool isEatingDisorderSupport;

  const CoachClientLite({
    required this.clientId,
    required this.displayName,
    required this.email,
    required this.compliance7d,
    this.lastSessionAt,
    this.isEatingDisorderSupport = false,
  });
}

/// Reálné klienty z controlleru (storage), ne mock
final coachClientsProvider = Provider<AsyncValue<List<CoachClientLite>>>((ref) {
  final async = ref.watch(coachClientsControllerProvider);

  return async.whenData((items) {
    return items
        .map(
          (x) => CoachClientLite(
            clientId: x.client.clientId,
            displayName: x.client.displayName,
            email: x.client.email,
            compliance7d: x.compliance7d,
            lastSessionAt: x.lastSessionAt,
            isEatingDisorderSupport: x.client.isEatingDisorderSupport,
          ),
        )
        .toList();
  });
});