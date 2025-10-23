// features/pets/screens/add_pet_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../models/pet.dart';
import '../providers/pets_provider.dart';
import '../providers/storage_provider.dart';

class AddPetScreen extends ConsumerStatefulWidget {
  const AddPetScreen({super.key});

  @override
  ConsumerState<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends ConsumerState<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();

  PetSpecies _selectedSpecies = PetSpecies.dog;
  DateTime? _selectedBirthDate;
  File? _selectedImageFile;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectImageSource() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('Câmera', style: AppTextStyles.bodyLarge),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final imageFile = await ref
                      .read(photoUploadNotifierProvider.notifier)
                      .pickImageFromCamera();
                  if (imageFile != null) {
                    setState(() => _selectedImageFile = imageFile);
                  }
                } catch (e) {
                  _showErrorSnackBar('Erro ao capturar imagem: $e');
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Galeria', style: AppTextStyles.bodyLarge),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final imageFile = await ref
                      .read(photoUploadNotifierProvider.notifier)
                      .pickImageFromGallery();
                  if (imageFile != null) {
                    setState(() => _selectedImageFile = imageFile);
                  }
                } catch (e) {
                  _showErrorSnackBar('Erro ao selecionar imagem: $e');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _selectedBirthDate = date);
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      _showErrorSnackBar('Selecione a data de nascimento do pet.');
      return;
    }

    final currentContext = context;

    try {
      final newPetId = await ref
          .read(petsNotifierProvider.notifier)
          .addPet(
            name: _nameController.text.trim(),
            species: _selectedSpecies,
            birthDate: _selectedBirthDate!,
            weightKg: double.parse(_weightController.text.replaceAll(',', '.')),
          );

      if (_selectedImageFile != null) {
        final photoUrl = await ref
            .read(photoUploadNotifierProvider.notifier)
            .uploadPetPhoto(
              petId: newPetId,
              imagePath: _selectedImageFile!.path,
            );

        await ref
            .read(petsNotifierProvider.notifier)
            .updatePet(petId: newPetId, photoUrl: photoUrl);
      }

      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(
              'Pet adicionado com sucesso!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.surface,
              ),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        currentContext.go('/pets');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao adicionar pet: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.surface),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final petsLoadingState = ref.watch(petsNotifierProvider);
    final photoUploadLoadingState = ref.watch(photoUploadNotifierProvider);

    final isLoading =
        petsLoadingState is AsyncLoading ||
        photoUploadLoadingState is AsyncLoading;

    ref.listen<AsyncValue<void>>(petsNotifierProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          _showErrorSnackBar('Erro ao adicionar pet: ${error.toString()}');
        },
      );
    });

    ref.listen<AsyncValue<String?>>(photoUploadNotifierProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        error: (error, stackTrace) {
          _showErrorSnackBar(
            'Erro ao fazer upload da foto: ${error.toString()}',
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Adicionar Pet',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: isLoading ? null : _savePet,
            child: Text(
              'Salvar',
              style: AppTextStyles.buttonMedium.copyWith(
                color: isLoading ? Colors.white.withOpacity(0.5) : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _selectImageSource,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.surface,
                      border: Border.all(
                        color: AppColors.textHint.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textHint.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _selectedImageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Adicionar foto',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome do pet',
                  prefixIcon: Icon(Icons.pets, color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  errorStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
                validator: Validators.petName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<PetSpecies>(
                value: _selectedSpecies,
                decoration: InputDecoration(
                  labelText: 'Espécie',
                  prefixIcon: Icon(
                    Icons.category,
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  errorStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
                items: PetSpecies.values.map((species) {
                  return DropdownMenuItem(
                    value: species,
                    child: Text(
                      species.displayName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSpecies = value);
                  }
                },
                validator: (value) =>
                    value == null ? Validators.species("null") : null,
                dropdownColor: AppColors.surface,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _selectBirthDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Data de nascimento',
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    labelStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                    errorStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  child: Text(
                    _selectedBirthDate != null
                        ? DateFormat('dd/MM/yyyy').format(_selectedBirthDate!)
                        : 'Selecione a data',
                    style: _selectedBirthDate != null
                        ? AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          )
                        : AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textHint,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Peso (kg)',
                  prefixIcon: Icon(
                    Icons.monitor_weight,
                    color: AppColors.textSecondary,
                  ),
                  suffixText: 'kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  errorStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
                validator: Validators.weight,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _savePet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: AppColors.surface,
                        )
                      : Text('Adicionar Pet', style: AppTextStyles.buttonLarge),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
