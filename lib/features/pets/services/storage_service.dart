// features/pets/services/storage_service.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  Future<String> uploadPetPhoto({
    required String petId,
    required File imageFile,
  }) async {
    try {
      final fileName = '$petId.jpg';
      final ref = _storage.ref().child('pet_photos/$fileName');

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'petId': petId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;

      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Erro ao fazer upload da foto: $e');
    }
  }

  Future<void> deletePetPhoto(String petId) async {
    try {
      final fileName = '$petId.jpg';
      final ref = _storage.ref().child('pet_photos/$fileName');

      await ref.delete();
    } catch (e) {
      debugPrint('Erro ao deletar foto: $e');
    }
  }

  Future<String?> getPetPhotoUrl(String petId) async {
    try {
      final fileName = '$petId.jpg';
      final ref = _storage.ref().child('pet_photos/$fileName');

      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }

      return null;
    } catch (e) {
      throw Exception('Erro ao selecionar imagem: $e');
    }
  }

  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }

      return null;
    } catch (e) {
      throw Exception('Erro ao capturar imagem: $e');
    }
  }

  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }

      return null;
    } catch (e) {
      throw Exception('Erro ao selecionar imagem: $e');
    }
  }

  bool validateImageSize(File imageFile, {int maxSizeInMB = 5}) {
    final fileSizeInBytes = imageFile.lengthSync();
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

    return fileSizeInMB <= maxSizeInMB;
  }

  bool validateImageType(File imageFile) {
    final extension = path.extension(imageFile.path).toLowerCase();
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

    return allowedExtensions.contains(extension);
  }

  Map<String, dynamic> getImageInfo(File imageFile) {
    final fileSizeInBytes = imageFile.lengthSync();
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
    final extension = path.extension(imageFile.path).toLowerCase();
    final fileName = path.basename(imageFile.path);

    return {
      'fileName': fileName,
      'fileSize': fileSizeInBytes,
      'fileSizeInMB': fileSizeInMB,
      'extension': extension,
      'isValidSize': validateImageSize(imageFile),
      'isValidType': validateImageType(imageFile),
    };
  }

  Future<String> uploadPetPhotoWithValidation({
    required String petId,
    required File imageFile,
  }) async {
    if (!validateImageSize(imageFile)) {
      throw Exception('Arquivo muito grande. Máximo permitido: 5MB');
    }

    if (!validateImageType(imageFile)) {
      throw Exception('Tipo de arquivo não suportado. Use JPG, PNG ou GIF');
    }

    return await uploadPetPhoto(petId: petId, imageFile: imageFile);
  }

  Stream<double> getUploadProgress({
    required String petId,
    required File imageFile,
  }) async* {
    try {
      final fileName = '$petId.jpg';
      final ref = _storage.ref().child('pet_photos/$fileName');

      final uploadTask = ref.putFile(imageFile);

      await for (final snapshot in uploadTask.snapshotEvents) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        yield progress;
      }
    } catch (e) {
      throw Exception('Erro ao obter progresso do upload: $e');
    }
  }
}
