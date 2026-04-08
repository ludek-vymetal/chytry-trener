import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/coach/active_client_service.dart';

final activeClientIdProvider = AsyncNotifierProvider<ActiveClientIdController, String?>(
  ActiveClientIdController.new,
);

class ActiveClientIdController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return ActiveClientService.load();
  }

  Future<void> setActive(String clientId) async {
    state = const AsyncValue.loading();
    await ActiveClientService.save(clientId);
    state = AsyncValue.data(clientId);
  }

  Future<void> clear() async {
    state = const AsyncValue.loading();
    await ActiveClientService.clear();
    state = const AsyncValue.data(null);
  }
}