import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'coach_clients_controller.dart';

class CoachClientLite {
  final String clientId;
  final String displayName;
  final String email;
  final double compliance7d; // 0..1
  final DateTime? lastSessionAt;
  final bool isEatingDisorderSupport;
  final int completedDaysInLast7;
  final bool isInactive7d;

  const CoachClientLite({
    required this.clientId,
    required this.displayName,
    required this.email,
    required this.compliance7d,
    required this.lastSessionAt,
    required this.isEatingDisorderSupport,
    required this.completedDaysInLast7,
    required this.isInactive7d,
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
            completedDaysInLast7: x.completedDaysInLast7,
            isInactive7d: x.isInactive7d,
          ),
        )
        .toList();
  });
});