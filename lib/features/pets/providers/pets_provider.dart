// features/pets/providers/pets_provider.dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importa o essencial do Riverpod
import 'package:flutter_riverpod/legacy.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart'; // NOVO: Adicionado para usar o StorageService no PetsNotifier
import '../../pets/models/pet.dart';
import '../../pet_tasks/models/pet_task.dart'; // Para allTasksProvider

// --- Providers de Serviço ---
// Fornece uma instância de FirestoreService.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Fornece uma instância de StorageService.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// --- StreamProviders para Dados em Tempo Real (Leitura) ---

// Stream de pets da família do usuário atual.
// Ideal para exibir uma lista de pets que atualiza em tempo real.
final petsStreamProvider = StreamProvider<List<Pet>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getPetsStream();
});

// FutureProvider para buscar um pet específico por ID.
// Usamos FutureProvider porque seu FirestoreService.getPetById retorna um Future, não um Stream.
final petFutureProvider = FutureProvider.family<Pet?, String>((ref, petId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getPetById(petId);
});

// Stream de tarefas de um pet específico.
// Ideal para exibir a lista de tarefas de um pet que atualiza em tempo real.
final petTasksStreamProvider = StreamProvider.family<List<PetTask>, String>((ref, petId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getPetTasksStream(petId);
});

// Stream de todas as tarefas da família do usuário atual.
// Útil para visões gerais ou dashboards de tarefas.
final allTasksStreamProvider = StreamProvider<List<PetTask>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllTasksStream();
});

// FutureProvider para buscar uma tarefa específica por ID.
// Usamos FutureProvider porque seu FirestoreService.getTaskById retorna um Future, não um Stream.
final taskFutureProvider = FutureProvider.family<PetTask?, String>((ref, taskId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getTaskById(taskId);
});

// --- FutureProviders para Dados da Família (Leitura Única) ---

// FutureProvider para obter os dados da família do usuário atual.
final familyDataProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getFamilyData();
});

// FutureProvider para obter a lista de membros da família do usuário atual.
final familyMembersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getFamilyMembers();
});

// --- StateNotifiers para Gerenciamento de Ações (CRUD) ---

// Notifier para gerenciar operações de pets (Adicionar, Atualizar, Deletar).
// O estado é um AsyncValue<void> para indicar o status da última operação.
class PetsNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final StorageService _storageService; // Injectar StorageService

  PetsNotifier(this._firestoreService, this._storageService) : super(const AsyncValue.data(null));

  Future<String> addPet({
    required String name,
    required PetSpecies species,
    required DateTime birthDate,
    required double weightKg,
    // Removido String? photoUrl daqui, pois o upload é uma etapa separada
  }) async {
    state = const AsyncValue.loading();
    try {
      final petId = await _firestoreService.addPet(
        name: name,
        species: species,
        birthDate: birthDate,
        weightKg: weightKg,
        // photoUrl será adicionado em um update posterior após upload
      );
      state = const AsyncValue.data(null);
      return petId; // Retorna o petId para que a UI possa usá-lo para upload de foto
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
  void setError(Object error, StackTrace stackTrace) {
    state = AsyncValue.error(error, stackTrace);
  }
  Future<void> updatePet({
    required String petId,
    String? name,
    PetSpecies? species,
    DateTime? birthDate,
    double? weightKg,
    String? photoUrl, // photoUrl pode ser atualizado aqui
  }) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.updatePet(
        petId: petId,
        name: name,
        species: species,
        birthDate: birthDate,
        weightKg: weightKg,
        photoUrl: photoUrl,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deletePet(String petId) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.deletePet(petId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // Método para lidar com o upload da foto do pet
  // Este método poderia ser um StateNotifierProvider separado se a lógica de upload for complexa
  Future<String> uploadPetPhoto({required String petId, required File imageFile}) async {
    state = const AsyncValue.loading(); // Reutiliza o estado para o upload
    try {
      final downloadUrl = await _storageService.uploadPetPhotoWithValidation(
        petId: petId,
        imageFile: imageFile,
      );
      // Após o upload, atualiza a URL da foto no documento do pet no Firestore
      await _firestoreService.updatePet(petId: petId, photoUrl: downloadUrl);
      state = const AsyncValue.data(null);
      return downloadUrl;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// StateNotifierProvider para PetsNotifier.
final petsNotifierProvider = StateNotifierProvider<PetsNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return PetsNotifier(firestoreService, storageService);
});

// Notifier para gerenciar operações de tarefas (Adicionar, Atualizar, Deletar, Toggle Done).
// O estado é um AsyncValue<void> para indicar o status da última operação.
class TasksNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;

  TasksNotifier(this._firestoreService) : super(const AsyncValue.data(null));

  Future<String> addTask({
    required String petId,
    required PetTaskType type,
    required String title,
    DateTime? dueDate,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final taskId = await _firestoreService.addTask(
        petId: petId,
        type: type,
        title: title,
        dueDate: dueDate,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      return taskId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateTask({
    required String taskId,
    PetTaskType? type,
    String? title,
    DateTime? dueDate,
    String? notes,
    bool? done,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.updateTask(
        taskId: taskId,
        type: type,
        title: title,
        dueDate: dueDate,
        notes: notes,
        done: done,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.deleteTask(taskId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> toggleTaskDone(String taskId) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.toggleTaskDone(taskId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// StateNotifierProvider para TasksNotifier.
final tasksNotifierProvider = StateNotifierProvider<TasksNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return TasksNotifier(firestoreService);
});

// --- Providers de Dados Derivados (Filtros e Estatísticas) ---

// Tasks com o status 'isOverdue' e 'isDueSoon' são dependentes de getters nos seus modelos,
// então vou assumir que esses getters estão implementados corretamente nos modelos PetTask.
extension PetTaskDueDateExtension on PetTask {
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && !done;
  bool get isDueSoon => dueDate != null && !done && dueDate!.isAfter(DateTime.now()) && dueDate!.difference(DateTime.now()).inDays <= 7;
}


// Lista de tarefas pendentes (não concluídas).
final pendingTasksProvider = Provider<AsyncValue<List<PetTask>>>((ref) {
  return ref.watch(allTasksStreamProvider).when(
        data: (list) => AsyncValue.data(list.where((task) => !task.done).toList()),
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
});

// Lista de tarefas atrasadas.
final overdueTasksProvider = Provider<AsyncValue<List<PetTask>>>((ref) {
  return ref.watch(allTasksStreamProvider).when(
        data: (list) => AsyncValue.data(list.where((task) => task.isOverdue).toList()),
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
});

// Lista de tarefas próximas do vencimento.
final dueSoonTasksProvider = Provider<AsyncValue<List<PetTask>>>((ref) {
  return ref.watch(allTasksStreamProvider).when(
        data: (list) => AsyncValue.data(list.where((task) => task.isDueSoon).toList()),
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
});

// Estatísticas de pets por espécie.
final petsStatsProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  return ref.watch(petsStreamProvider).when(
        data: (list) {
          final stats = <String, int>{};
          for (final pet in list) {
            final species = pet.species.displayName;
            stats[species] = (stats[species] ?? 0) + 1;
          }
          return AsyncValue.data(stats);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
});

// Estatísticas de tarefas (total, concluídas, pendentes, atrasadas, próximas do vencimento).
final tasksStatsProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  return ref.watch(allTasksStreamProvider).when(
        data: (list) {
          return AsyncValue.data({
            'total': list.length,
            'completed': list.where((t) => t.done).length,
            'pending': list.where((t) => !t.done).length,
            'overdue': list.where((t) => t.isOverdue).length,
            'dueSoon': list.where((t) => t.isDueSoon).length,
          });
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
});
