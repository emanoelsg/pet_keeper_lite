import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';
import '../services/cloud_functions_service.dart';

// Provider do CloudFunctionsService
final cloudFunctionsServiceProvider = Provider<CloudFunctionsService>((ref) {
  return CloudFunctionsService();
});

// Notifier para gerenciar notificações
class NotificationsNotifier extends StateNotifier<AsyncValue<void>> {
  final CloudFunctionsService _cloudFunctionsService;
  
  NotificationsNotifier(this._cloudFunctionsService) : super(const AsyncValue.data(null));
  
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
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  Future<void> notifyNewPet({
    required String petName,
    required String petSpecies,
  }) async {
    try {
      await _cloudFunctionsService.notifyNewPet(
        petName: petName,
        petSpecies: petSpecies,
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  Future<void> notifyTaskCompleted({
    required String petId,
    required String taskTitle,
  }) async {
    try {
      await _cloudFunctionsService.notifyTaskCompleted(
        petId: petId,
        taskTitle: taskTitle,
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  Future<void> sendCustomMessage({
    required String message,
    String? title,
  }) async {
    try {
      await _cloudFunctionsService.sendCustomMessage(
        message: message,
        title: title,
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  void clearState() {
    state = const AsyncValue.data(null);
  }
}

// Provider do NotificationsNotifier
final notificationsNotifierProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<void>>((ref) {
  final cloudFunctionsService = ref.watch(cloudFunctionsServiceProvider);
  return NotificationsNotifier(cloudFunctionsService);
});
