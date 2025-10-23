// features/pets/screens/pet_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
// Importações de módulos
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/pet.dart'; // Assume Pet e PetSpecies estão aqui
import '../../pet_tasks/models/pet_task.dart'; // Importa PetTask e PetTaskType
import '../providers/pets_provider.dart'; // petFutureProvider, petTasksStreamProvider
// Importação para usar a extensão de checagem de data (Assumida para clareza)


class PetDetailsScreen extends ConsumerWidget {
  final String petId;

  const PetDetailsScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watchers para obter os dados
    final petAsync = ref.watch(petFutureProvider(petId));
    final tasksAsync = ref.watch(petTasksStreamProvider(petId)); // CORRETO!

    return Scaffold(
      backgroundColor: AppColors.background,
      body: petAsync.when(
        data: (pet) {
          if (pet == null) {
            return const Center(child: Text('Pet não encontrado'));
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, pet),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildPetStats(context, pet),
                    const SizedBox(height: 16),
                    _buildQuickActions(context, pet),
                    const SizedBox(height: 24),
                    _buildRecentTasks(context, pet, tasksAsync),
                    const SizedBox(height: 80), // Espaço para o FAB
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Erro ao carregar pet: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/add-task/$petId'),
        backgroundColor: AppColors.primary,
        label: const Text(
          'Adicionar Tarefa',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --- 1. SLIVER APP BAR (Cabeçalho de Rolagem) ---

  SliverAppBar _buildSliverAppBar(BuildContext context, Pet pet) {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: true, // Flutua quando rola para cima
      pinned: true,
      snap: true, // Retorna ao topo rapidamente
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        pet.name,
        style: AppTextStyles.h4.copyWith(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.go('/edit-pet/$petId'),
          tooltip: 'Editar Pet',
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined),
          onPressed: () {
            // TODO: Implementar compartilhamento/notificação
          },
          tooltip: 'Notificar Família',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
        // O título flutuante é o nome do pet (definido acima)
        background: _buildPetHeader(context, pet),
      ),
    );
  }

  // --- 2. HEADER (Informações do Pet) ---

  Widget _buildPetHeader(BuildContext context, Pet pet) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Informações centradas no meio (abaixo da app bar contraída)
          Positioned(
            bottom: 20,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto do pet grande
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white, width: 3),
                    color: Colors.white, // Fundo branco caso a imagem não carregue
                  ),
                  child: pet.photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.network(
                            pet.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPetIcon(pet.species, isWhite: false);
                            },
                          ),
                        )
                      : _buildPetIcon(pet.species, isWhite: false),
                ),
                const SizedBox(height: 12),
                // Nome e Espécie
                Text(
                  pet.name,
                  style: AppTextStyles.h2.copyWith(color: Colors.white),
                ),
                Text(
                  '${pet.species.displayName} - ${pet.formattedAge}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. ESTATÍSTICAS (Informações Detalhadas - Usando ListTiles para Limpeza) ---

  Widget _buildPetStats(BuildContext context, Pet pet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero, // Já temos padding no SliverPadding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Informações Essenciais',
              style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
            ),
          ),
          Divider(color: AppColors.textHint.withOpacity(0.1), height: 1),
          _buildStatListTile(
            icon: Icons.monitor_weight_outlined,
            label: 'Peso Atual',
            value: '${pet.weightKg.toStringAsFixed(1)} kg',
          ),
          _buildStatListTile(
            icon: Icons.cake_outlined,
            label: 'Data de Nascimento',
            value: DateFormat('dd/MM/yyyy').format(pet.birthDate),
          ),
          _buildStatListTile(
            icon: Icons.calendar_month_outlined,
            label: 'Idade',
            value: pet.formattedAge,
          ),
        ],
      ),
    );
  }

  Widget _buildStatListTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.primary),
      title: Text(
        label,
        style:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Text(
        value,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  // --- 4. AÇÕES RÁPIDAS (Ícones Limpos) ---

  Widget _buildQuickActions(BuildContext context, Pet pet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ações Rápidas', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionChip(
              context,
              icon: _getIconForTaskType(PetTaskType.food),
              label: PetTaskType.food.displayName,
              onTap: () =>
                  context.go('/add-task/$petId?type=${PetTaskType.food.name}'),
            ),
            _buildActionChip(
              context,
              icon: _getIconForTaskType(PetTaskType.medicine),
              label: PetTaskType.medicine.displayName,
              onTap: () => context.go(
                '/add-task/$petId?type=${PetTaskType.medicine.name}',
              ),
            ),
            _buildActionChip(
              context,
              icon: _getIconForTaskType(PetTaskType.vet),
              label: PetTaskType.vet.displayName,
              onTap: () =>
                  context.go('/add-task/$petId?type=${PetTaskType.vet.name}'),
            ),
            _buildActionChip(
              context,
              icon: Icons.schedule_outlined,
              label: 'Ver Tarefas',
              onTap: () => context.go('/pet-tasks/$petId'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: MediaQuery.of(context).size.width / 4 - 20,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.textHint.withOpacity(0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppColors.secondary),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. TAREFAS RECENTES (Lista Limpa) ---

  Widget _buildRecentTasks(
    BuildContext context,
    Pet pet,
    AsyncValue<List<PetTask>> tasksAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Próximas Tarefas', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        tasksAsync.when(
          data: (tasks) {
            // Filtra tarefas pendentes, ordena por data e pega as 3 primeiras
            final upcomingTasks = tasks.where((t) => !t.done).toList()
              ..sort(
                (a, b) => (a.dueDate ?? DateTime(9999)).compareTo(
                  b.dueDate ?? DateTime(9999),
                ),
              );

            if (upcomingTasks.isEmpty) {
              return _buildEmptyTasks(context, pet);
            }
            // Chama a lista corrigida passando as tarefas filtradas e limitadas
            return _buildTasksList(context, upcomingTasks.take(3).toList());
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stackTrace) => Text(
            'Erro ao carregar tarefas: ${error.toString().split(':').last.trim()}',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTasks(BuildContext context, Pet pet) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textHint.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.task_alt_outlined, size: 40, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text('Nenhuma tarefa pendente', style: AppTextStyles.bodyLarge),
          ],
        ),
      ),
    );
  }

  // MUDANÇA AQUI: Recebe a lista já filtrada e limitada.
  Widget _buildTasksList(BuildContext context, List<PetTask> tasks) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Column(
        // ITERA SOBRE A LISTA PASSANDO O ÍNDICE PARA CALCULAR O isLast
        children: List.generate(tasks.length, (index) {
          final task = tasks[index];
          final isLast = index == tasks.length - 1;
          return _buildTaskCard(context, task, isLast: isLast); // Passa isLast
        }),
      ),
    );
  }

  // MUDANÇA AQUI: Recebe isLast como parâmetro
  Widget _buildTaskCard(BuildContext context, PetTask task,
      {required bool isLast}) {
    Color getLeadingColor() {
      // Usando a extensão PetTaskDueDateExtension assumida
      if (task.isOverdue) return AppColors.error;
      if (task.isDueSoon) return AppColors.warning;
      return AppColors.primary;
    }

    String getSubtitleText() {
      if (task.dueDate == null) return task.type.displayName;
      if (task.isOverdue)
        return 'VENCIDA ${DateFormat('dd/MM').format(task.dueDate!)}';
      if (task.isDueSoon)
        return 'VENCE ${DateFormat('dd/MM').format(task.dueDate!)} (Breve)';
      return 'Em ${DateFormat('dd/MM').format(task.dueDate!)}';
    }

    // A lógica de isLast foi movida para o _buildTasksList, simplificando o uso aqui.
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Icon(
            _getIconForTaskType(task.type),
            color: getLeadingColor(),
            size: 28,
          ),
          title: Text(
            task.title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            getSubtitleText(),
            style: AppTextStyles.bodySmall.copyWith(
              color: task.isOverdue ? AppColors.error : AppColors.textSecondary,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_outlined,
            size: 20,
            color: AppColors.textHint,
          ),
          onTap: () => context.go('/edit-task/${task.id}'),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: AppColors.textHint.withOpacity(0.1),
          ),
      ],
    );
  }

  // --- 6. AUXILIARES ---

  Widget _buildPetIcon(PetSpecies species, {bool isWhite = false}) {
    IconData iconData;
    Color iconColor = isWhite ? Colors.white : AppColors.primary;

    switch (species) {
      case PetSpecies.dog:
        iconData = Icons.pets;
        break;
      case PetSpecies.cat:
        iconData = Icons.pets;
        break;
      default:
        iconData = Icons.pets;
    }

    return Icon(iconData, size: 48, color: iconColor);
  }

  IconData _getIconForTaskType(PetTaskType type) {
    switch (type) {
      case PetTaskType.food:
        return Icons.restaurant_menu_outlined;
      case PetTaskType.medicine:
        return Icons.medical_services_outlined;
      case PetTaskType.walk:
        return Icons.directions_walk_outlined;
      case PetTaskType.grooming:
        return Icons.wash_outlined;
      case PetTaskType.vet:
        return Icons.healing_outlined;
      case PetTaskType.other:
        return Icons.assignment_outlined;
    }
  }
}
// OBS: Certifique-se de que a extensão PetTaskDueDateExtension esteja disponível, 
// e que AppColors e AppTextStyles estejam configurados no seu projeto.