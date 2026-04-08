import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/coach/active_client_service.dart';

final activeClientIdProvider =
    AsyncNotifierProvider<ActiveClientIdController, String?>(ActiveClientIdController.new);

class ActiveClientIdController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return ActiveClientService.load();
  }

  Future<void> setActive(String clientId) async {
    state = const AsyncLoading();
    await ActiveClientService.save(clientId);
    state = AsyncData(clientId);
  }

  Future<void> clear() async {
    state = const AsyncLoading();
    await ActiveClientService.clear();
    state = const AsyncData(null);
  }
}