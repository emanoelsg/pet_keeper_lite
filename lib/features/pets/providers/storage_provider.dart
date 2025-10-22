// features/pets/providers/storage_provider.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';
import '../services/storage_service.dart';

// Provider do StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Notifier para gerenciar upload de fotos
class PhotoUploadNotifier extends StateNotifier<AsyncValue<String?>> {
  final StorageService _storageService;
  
  PhotoUploadNotifier(this._storageService) : super(const AsyncValue.data(null));
  
  Future<String> uploadPetPhoto({
    required String petId,
    required String imagePath,
  }) async {
    state = const AsyncValue.loading();
    try {
      final photoUrl = await _storageService.uploadPetPhotoWithValidation(
        petId: petId,
        imageFile: File(imagePath),
      );
      state = AsyncValue.data(photoUrl);
      return photoUrl;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  Future<String?> pickImageFromGallery() async {
    try {
      final imageFile = await _storageService.pickImageFromGallery();
      if (imageFile != null) {
        return imageFile.path;
      }
      return null;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }
  
  Future<String?> pickImageFromCamera() async {
    try {
      final imageFile = await _storageService.pickImageFromCamera();
      if (imageFile != null) {
        return imageFile.path;
      }
      return null;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }
  
  void clearState() {
    state = const AsyncValue.data(null);
  }
}

// Provider do PhotoUploadNotifier
final photoUploadNotifierProvider = StateNotifierProvider<PhotoUploadNotifier, AsyncValue<String?>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return PhotoUploadNotifier(storageService);
});
