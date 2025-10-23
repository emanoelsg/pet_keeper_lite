// features/pets/providers/notifications_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../services/cloud_functions_service.dart';

final cloudFunctionsServiceProvider = Provider<CloudFunctionsService>((ref) {
  return CloudFunctionsService();
});

class NotificationsNotifier extends StateNotifier<AsyncValue<void>> {
  final CloudFunctionsService _cloudFunctionsService;

  NotificationsNotifier(this._cloudFunctionsService)
    : super(const AsyncValue.data(null));

  Future<void> notifyFamily({
    required String petId,
    required String taskTitle,
    String? message,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _cloudFunctionsService.notifyFamily(
        petId: petId,
        taskTitle: taskTitle,
        message: message,
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);

      rethrow;
    }
  }

  void clearState() {
    state = const AsyncValue.data(null);
  }
}

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, AsyncValue<void>>((ref) {
      final cloudFunctionsService = ref.watch(cloudFunctionsServiceProvider);
      return NotificationsNotifier(cloudFunctionsService);
    });
