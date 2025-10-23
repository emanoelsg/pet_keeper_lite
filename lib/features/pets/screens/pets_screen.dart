// features/pets/screens/pets_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/pet.dart';
import '../providers/pets_provider.dart';

class PetsScreen extends ConsumerWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petsStreamProvider);

    ref.listen<AsyncValue<void>>(petsNotifierProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro na operação com pets: ${error.toString()}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Meus Pets',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/add-pet'),
            tooltip: 'Adicionar Pet',
          ),
        ],
      ),
      body: petsAsync.when(
        data: (pets) {
          if (pets.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildPetsList(context, ref, pets);
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stackTrace) =>
            _buildErrorState(context, ref, error.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add-pet'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Adicionar novo pet',
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 100, color: AppColors.textHint),
            const SizedBox(height: 24),
            Text(
              'Nenhum pet cadastrado',
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione seu primeiro pet para começar a organizar sua família PetKeeper!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/add-pet'),
              icon: const Icon(Icons.add),
              label: Text('Adicionar Pet', style: AppTextStyles.buttonMedium),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 100, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              'Erro ao carregar pets',
              style: AppTextStyles.h3.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(petsStreamProvider);
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                'Tentar Novamente',
                style: AppTextStyles.buttonMedium,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetsList(BuildContext context, WidgetRef ref, List<Pet> pets) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(petsStreamProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pets.length,
        itemBuilder: (context, index) {
          final pet = pets[index];
          return _buildPetCard(context, ref, pet);
        },
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, WidgetRef ref, Pet pet) {
    final petNameStyle = AppTextStyles.h3.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.bold,
    );
    final petSpeciesStyle = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textSecondary,
      fontStyle: FontStyle.italic,
    );
    final petAgeStyle = AppTextStyles.bodySmall.copyWith(
      color: AppColors.textHint,
    );
    final petWeightStyle = AppTextStyles.bodySmall.copyWith(
      color: AppColors.textSecondary,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.go('/pet-details/${pet.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.surface,
                  border: Border.all(
                    color: AppColors.textHint.withOpacity(0.3),
                  ),
                ),
                child: pet.photoUrl != null && pet.photoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          pet.photoUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryLight,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPetIcon(pet.species);
                          },
                        ),
                      )
                    : _buildPetIcon(pet.species),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.name, style: petNameStyle),
                    const SizedBox(height: 4),
                    Text(pet.species.displayName, style: petSpeciesStyle),
                    const SizedBox(height: 4),
                    Text(pet.formattedAge, style: petAgeStyle),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.monitor_weight,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${pet.weightKg.toStringAsFixed(1)} kg',
                          style: petWeightStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      context.go('/edit-pet/${pet.id}');
                      break;
                    case 'delete':
                      _showDeleteDialog(context, ref, pet);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: AppColors.textPrimary),
                        const SizedBox(width: 8),
                        Text(
                          'Editar',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(
                          'Excluir',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: const Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetIcon(PetSpecies species) {
    IconData iconData;
    Color iconColor;

    switch (species) {
      case PetSpecies.dog:
        iconData = Icons.pets;
        iconColor = AppColors.dogColor;
        break;
      case PetSpecies.cat:
        iconData = Icons.pets;
        iconColor = AppColors.catColor;
        break;
      case PetSpecies.bird:
        iconData = Icons.flutter_dash;
        iconColor = AppColors.birdColor;
        break;
      case PetSpecies.fish:
        iconData = Icons.waves;
        iconColor = AppColors.fishColor;
        break;
      case PetSpecies.rabbit:
        iconData = Icons.pets;
        iconColor = AppColors.otherColor;
        break;
      case PetSpecies.hamster:
        iconData = Icons.pets;
        iconColor = AppColors.otherColor;
        break;
      case PetSpecies.turtle:
        iconData = Icons.pets;
        iconColor = AppColors.otherColor;
        break;
      default:
        iconData = Icons.pets;
        iconColor = AppColors.otherColor;
    }

    return Center(child: Icon(iconData, size: 40, color: iconColor));
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Excluir Pet',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Tem certeza que deseja excluir ${pet.name}? Esta ação não pode ser desfeita e removerá todas as tarefas associadas.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(petsNotifierProvider.notifier).deletePet(pet.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${pet.name} foi excluído com sucesso!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.surface,
                        ),
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erro ao excluir pet: ${e.toString()}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.surface,
                        ),
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Excluir',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
