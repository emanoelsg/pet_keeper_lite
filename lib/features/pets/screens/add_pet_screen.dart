// features/pets/screens/add_pet_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  String? _selectedImagePath;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () async {
                Navigator.pop(context);
                final imagePath = await ref
                    .read(photoUploadNotifierProvider.notifier)
                    .pickImageFromCamera();
                if (imagePath != null) {
                  setState(() => _selectedImagePath = imagePath);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () async {
                Navigator.pop(context);
                final imagePath = await ref
                    .read(photoUploadNotifierProvider.notifier)
                    .pickImageFromGallery();
                if (imagePath != null) {
                  setState(() => _selectedImagePath = imagePath);
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
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() => _selectedBirthDate = date);
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a data de nascimento'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? photoUrl;
      
      // Upload da foto se selecionada
      if (_selectedImagePath != null) {
        photoUrl = await ref
            .read(photoUploadNotifierProvider.notifier)
            .uploadPetPhoto(
              petId: '', // Será gerado pelo Firestore
              imagePath: _selectedImagePath!,
            );
      }

      // Adicionar pet
      await ref.read(petsNotifierProvider.notifier).addPet(
        name: _nameController.text.trim(),
        species: _selectedSpecies,
        birthDate: _selectedBirthDate!,
        weightKg: double.parse(_weightController.text.replaceAll(',', '.')),
        photoUrl: photoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet adicionado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/pets');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar pet: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Pet'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePet,
            child: Text(
              'Salvar',
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.white,
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
              // Foto do pet
              Center(
                child: GestureDetector(
                  onTap: _selectImage,
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
                    ),
                    child: _selectedImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_selectedImagePath!),
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

              // Nome do pet
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do pet',
                  prefixIcon: Icon(Icons.pets),
                ),
                validator: Validators.petName,
              ),
              const SizedBox(height: 16),

              // Espécie
              DropdownButtonFormField<PetSpecies>(
                value: _selectedSpecies,
                decoration: const InputDecoration(
                  labelText: 'Espécie',
                  prefixIcon: Icon(Icons.category),
                ),
                items: PetSpecies.values.map((species) {
                  return DropdownMenuItem(
                    value: species,
                    child: Text(species.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSpecies = value);
                  }
                },
                validator: (value) => value == null ? Validators.species(value.toString()) : null,
              ),
              const SizedBox(height: 16),

              // Data de nascimento
              InkWell(
                onTap: _selectBirthDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data de nascimento',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedBirthDate != null
                        ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                        : 'Selecione a data',
                    style: _selectedBirthDate != null
                        ? AppTextStyles.bodyMedium
                        : AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textHint,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Peso
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Peso (kg)',
                  prefixIcon: Icon(Icons.monitor_weight),
                  suffixText: 'kg',
                ),
                validator: Validators.weight,
              ),
              const SizedBox(height: 32),

              // Botão salvar
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Adicionar Pet',
                          style: AppTextStyles.buttonLarge,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
