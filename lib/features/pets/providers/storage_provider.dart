// features/pets/providers/storage_provider.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class PhotoUploadNotifier extends StateNotifier<AsyncValue<String?>> {
  final StorageService _storageService;

  PhotoUploadNotifier(this._storageService)
    : super(const AsyncValue.data(null));

  Future<String> uploadPetPhoto({
    required String petId,
    required String imagePath,
  }) async {
    state = const AsyncValue.loading();
    try {
      final imageFile = File(imagePath);
      final photoUrl = await _storageService.uploadPetPhotoWithValidation(
        petId: petId,
        imageFile: imageFile,
      );
      state = AsyncValue.data(photoUrl);
      return photoUrl;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<File?> pickImageFromGallery() async {
    try {
      final imageFile = await _storageService.pickImageFromGallery();
      return imageFile;
    } catch (e) {
      rethrow;
    }
  }

  Future<File?> pickImageFromCamera() async {
    try {
      final imageFile = await _storageService.pickImageFromCamera();
      return imageFile;
    } catch (e) {
      rethrow;
    }
  }

  void clearState() {
    state = const AsyncValue.data(null);
  }
}

final photoUploadNotifierProvider =
    StateNotifierProvider<PhotoUploadNotifier, AsyncValue<String?>>((ref) {
      final storageService = ref.watch(storageServiceProvider);
      return PhotoUploadNotifier(storageService);
    });
