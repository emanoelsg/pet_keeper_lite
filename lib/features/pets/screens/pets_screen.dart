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
    final petsAsync = ref.watch(petsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pets'),
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
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => _buildErrorState(context, ref, error.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add-pet'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 100,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhum pet cadastrado',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione seu primeiro pet para começar',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/add-pet'),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Pet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 100,
            color: AppColors.error,
          ),
          const SizedBox(height: 24),
          Text(
            'Erro ao carregar pets',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.error,
            ),
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
              // Recarregar a lista
              ref.invalidate(petsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar Novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsList(BuildContext context, WidgetRef ref, List<Pet> pets) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(petsProvider);
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.go('/pet-details/${pet.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Foto do pet
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
                child: pet.photoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          pet.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPetIcon(pet.species);
                          },
                        ),
                      )
                    : _buildPetIcon(pet.species),
              ),
              const SizedBox(width: 16),
              
              // Informações do pet
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: AppTextStyles.petName,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pet.species.displayName,
                      style: AppTextStyles.petSpecies,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pet.formattedAge,
                      style: AppTextStyles.petAge,
                    ),
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
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Botão de ações
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
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Excluir', style: TextStyle(color: AppColors.error)),
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
        iconData = Icons.pets;
        iconColor = AppColors.birdColor;
        break;
      case PetSpecies.fish:
        iconData = Icons.pets;
        iconColor = AppColors.fishColor;
        break;
      default:
        iconData = Icons.pets;
        iconColor = AppColors.otherColor;
    }

    return Icon(
      iconData,
      size: 40,
      color: iconColor,
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Pet'),
        content: Text('Tem certeza que deseja excluir ${pet.name}? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(petsNotifierProvider.notifier).deletePet(pet.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${pet.name} foi excluído com sucesso'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir pet: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
