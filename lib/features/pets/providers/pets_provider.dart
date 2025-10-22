// features/pets/providers/pets_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';
import '../services/firestore_service.dart';
import '../../pets/models/pet.dart';
import '../../pet_tasks/models/pet_task.dart';

// Provider do FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Provider da lista de pets
final petsProvider = StreamProvider<List<Pet>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getPetsStream();
});

// Provider de um pet específico
final petProvider = StreamProvider.family<Pet?, String>((ref, petId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return Stream.fromFuture(firestoreService.getPetById(petId));
});

// Provider das tarefas de um pet
final petTasksProvider = StreamProvider.family<List<PetTask>, String>((ref, petId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getPetTasksStream(petId);
});

// Provider de todas as tarefas da família
final allTasksProvider = StreamProvider<List<PetTask>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllTasksStream();
});

// Provider de uma tarefa específica
final taskProvider = StreamProvider.family<PetTask?, String>((ref, taskId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return Stream.fromFuture(firestoreService.getTaskById(taskId));
});

// Provider dos dados da família
final familyDataProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getFamilyData();
});

// Provider dos membros da família
final familyMembersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getFamilyMembers();
});

// Notifier para gerenciar pets
class PetsNotifier extends StateNotifier<AsyncValue<List<Pet>>> {
  final FirestoreService _firestoreService;
  
  PetsNotifier(this._firestoreService) : super(const AsyncValue.loading()) {
    _loadPets();
  }
  
  void _loadPets() {
    _firestoreService.getPetsStream().listen(
      (pets) {
        state = AsyncValue.data(pets);
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );
  }
  
  Future<String> addPet({
    required String name,
    required PetSpecies species,
    required DateTime birthDate,
    required double weightKg,
    String? photoUrl,
  }) async {
    try {
      final petId = await _firestoreService.addPet(
        name: name,
        species: species,
        birthDate: birthDate,
        weightKg: weightKg,
        photoUrl: photoUrl,
      );
      return petId;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  Future<void> updatePet({
    required String petId,
    String? name,
    PetSpecies? species,
    DateTime? birthDate,
    double? weightKg,
    String? photoUrl,
  }) async {
    try {
      await _firestoreService.updatePet(
        petId: petId,
        name: name,
        species: species,
        birthDate: birthDate,
        weightKg: weightKg,
        photoUrl: photoUrl,
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  Future<void> deletePet(String petId) async {
    try {
      await _firestoreService.deletePet(petId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

// Provider do PetsNotifier
final petsNotifierProvider = StateNotifierProvider<PetsNotifier, AsyncValue<List<Pet>>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return PetsNotifier(firestoreService);
});

// Notifier para gerenciar tarefas
class TasksNotifier extends StateNotifier<AsyncValue<List<PetTask>>> {
  final FirestoreService _firestoreService;
  
  TasksNotifier(this._firestoreService) : super(const AsyncValue.loading()) {
    _loadTasks();
  }
  
  void _loadTasks() {
    _firestoreService.getAllTasksStream().listen(
      (tasks) {
        state = AsyncValue.data(tasks);
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );
  }
  
  Future<String> addTask({
    required String petId,
    required PetTaskType type,
    required String title,
    DateTime? dueDate,
    String? notes,
  }) async {
    try {
      final taskId = await _firestoreService.addTask(
        petId: petId,
        type: type,
        title: title,
        dueDate: dueDate,
        notes: notes,
      );
      return taskId;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
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
    try {
      await _firestoreService.updateTask(
        taskId: taskId,
        type: type,
        title: title,
        dueDate: dueDate,
        notes: notes,
        done: done,
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestoreService.deleteTask(taskId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  Future<void> toggleTaskDone(String taskId) async {
    try {
      await _firestoreService.toggleTaskDone(taskId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

// Provider do TasksNotifier
final tasksNotifierProvider = StateNotifierProvider<TasksNotifier, AsyncValue<List<PetTask>>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return TasksNotifier(firestoreService);
});

// Provider para tarefas pendentes
final pendingTasksProvider = Provider<List<PetTask>>((ref) {
  final tasks = ref.watch(allTasksProvider);
  
  return tasks.when(
    data: (tasks) => tasks.where((task) => !task.done).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

// Provider para tarefas vencidas
final overdueTasksProvider = Provider<List<PetTask>>((ref) {
  final tasks = ref.watch(allTasksProvider);
  
  return tasks.when(
    data: (tasks) => tasks.where((task) => task.isOverdue).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

// Provider para tarefas próximas do vencimento
final dueSoonTasksProvider = Provider<List<PetTask>>((ref) {
  final tasks = ref.watch(allTasksProvider);
  
  return tasks.when(
    data: (tasks) => tasks.where((task) => task.isDueSoon).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

// Provider para estatísticas dos pets
final petsStatsProvider = Provider<Map<String, int>>((ref) {
  final pets = ref.watch(petsProvider);
  
  return pets.when(
    data: (pets) {
      final stats = <String, int>{};
      
      for (final pet in pets) {
        final species = pet.species.displayName;
        stats[species] = (stats[species] ?? 0) + 1;
      }
      
      return stats;
    },
    loading: () => {},
    error: (_, _) => {},
  );
});

// Provider para estatísticas das tarefas
final tasksStatsProvider = Provider<Map<String, int>>((ref) {
  final tasks = ref.watch(allTasksProvider);
  
  return tasks.when(
    data: (tasks) {
      final stats = <String, int>{
        'total': tasks.length,
        'completed': tasks.where((task) => task.done).length,
        'pending': tasks.where((task) => !task.done).length,
        'overdue': tasks.where((task) => task.isOverdue).length,
        'dueSoon': tasks.where((task) => task.isDueSoon).length,
      };
      
      return stats;
    },
    loading: () => {},
    error: (_, _) => {},
  );
});
