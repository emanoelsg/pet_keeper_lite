// features/pets/screens/pet_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/pet.dart';
import '../providers/pets_provider.dart';
import '../providers/pets_provider.dart' as tasks_provider;

class PetDetailsScreen extends ConsumerWidget {
  final String petId;

  const PetDetailsScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(petProvider(petId));
    final tasksAsync = ref.watch(tasks_provider.petTasksProvider(petId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Pet'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/edit-pet/$petId'),
            tooltip: 'Editar Pet',
          ),
        ],
      ),
      body: petAsync.when(
        data: (pet) {
          if (pet == null) {
            return const Center(
              child: Text('Pet não encontrado'),
            );
          }
          return _buildPetDetails(context, pet, tasksAsync);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Erro ao carregar pet: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add-task/$petId'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPetDetails(BuildContext context, Pet pet, AsyncValue<List<dynamic>> tasksAsync) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto e informações básicas
          _buildPetHeader(context, pet),
          
          // Estatísticas
          _buildPetStats(context, pet),
          
          // Tarefas recentes
          _buildRecentTasks(context, pet, tasksAsync),
          
          // Ações rápidas
          _buildQuickActions(context, pet),
        ],
      ),
    );
  }

  Widget _buildPetHeader(BuildContext context, Pet pet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Foto do pet
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: pet.photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.network(
                      pet.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPetIcon(pet.species, isWhite: true);
                      },
                    ),
                  )
                : _buildPetIcon(pet.species, isWhite: true),
          ),
          const SizedBox(height: 16),
          
          // Nome e espécie
          Text(
            pet.name,
            style: AppTextStyles.h2.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pet.species.displayName,
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pet.formattedAge,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetStats(BuildContext context, Pet pet) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: 16),
          
          _buildStatRow(
            icon: Icons.monitor_weight,
            label: 'Peso',
            value: '${pet.weightKg.toStringAsFixed(1)} kg',
          ),
          const SizedBox(height: 12),
          
          _buildStatRow(
            icon: Icons.calendar_today,
            label: 'Data de nascimento',
            value: '${pet.birthDate.day}/${pet.birthDate.month}/${pet.birthDate.year}',
          ),
          const SizedBox(height: 12),
          
          _buildStatRow(
            icon: Icons.access_time,
            label: 'Idade',
            value: pet.formattedAge,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTasks(BuildContext context, Pet pet, AsyncValue<List<dynamic>> tasksAsync) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tarefas Recentes',
                style: AppTextStyles.h4,
              ),
              TextButton(
                onPressed: () => context.go('/pet-tasks/$petId'),
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          tasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return _buildEmptyTasks(context, pet);
              }
              return _buildTasksList(context, tasks.take(3).toList());
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Text(
              'Erro ao carregar tarefas: $error',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTasks(BuildContext context, Pet pet) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textHint.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.task_alt,
            size: 48,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma tarefa cadastrada',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione vacinas, medicamentos e outros cuidados para ${pet.name}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/add-task/$petId'),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Tarefa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(BuildContext context, List<dynamic> tasks) {
    return Column(
      children: tasks.map((task) => _buildTaskCard(context, task)).toList(),
    );
  }

  Widget _buildTaskCard(BuildContext context, dynamic task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: task.done ? AppColors.success : AppColors.primary,
          child: Icon(
            task.done ? Icons.check : Icons.schedule,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          task.title,
          style: AppTextStyles.bodyMedium.copyWith(
            decoration: task.done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          task.type.displayName,
          style: AppTextStyles.bodySmall,
        ),
        trailing: task.dueDate != null
            ? Text(
                '${task.dueDate.day}/${task.dueDate.month}',
                style: AppTextStyles.bodySmall,
              )
            : null,
        onTap: () => context.go('/edit-task/${task.id}'),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Pet pet) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações Rápidas',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.add,
                  label: 'Nova Tarefa',
                  onTap: () => context.go('/add-task/$petId'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.edit,
                  label: 'Editar Pet',
                  onTap: () => context.go('/edit-pet/$petId'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textHint.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetIcon(PetSpecies species, {bool isWhite = false}) {
    IconData iconData;
    Color iconColor;

    switch (species) {
      case PetSpecies.dog:
        iconData = Icons.pets;
        iconColor = isWhite ? Colors.white : AppColors.dogColor;
        break;
      case PetSpecies.cat:
        iconData = Icons.pets;
        iconColor = isWhite ? Colors.white : AppColors.catColor;
        break;
      case PetSpecies.bird:
        iconData = Icons.pets;
        iconColor = isWhite ? Colors.white : AppColors.birdColor;
        break;
      case PetSpecies.fish:
        iconData = Icons.pets;
        iconColor = isWhite ? Colors.white : AppColors.fishColor;
        break;
      default:
        iconData = Icons.pets;
        iconColor = isWhite ? Colors.white : AppColors.otherColor;
    }

    return Icon(
      iconData,
      size: 60,
      color: iconColor,
    );
  }
}
