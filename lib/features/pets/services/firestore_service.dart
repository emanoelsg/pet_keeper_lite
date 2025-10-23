// features/pets/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_keeper_lite/features/pet_tasks/models/pet_task.dart';
import 'package:pet_keeper_lite/features/pets/models/pet.dart';
import 'package:uuid/uuid.dart';

import 'package:pet_keeper_lite/features/pets/services/storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();
  final StorageService _storageService = StorageService();

  Stream<List<Pet>> getPetsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .asyncExpand((userDoc) {
          if (!userDoc.exists || userDoc.data() == null)
            return Stream.value(<Pet>[]);

          final familyCode = userDoc.data()!['familyCode'] as String;

          return _firestore
              .collection('pets')
              .where('familyCode', isEqualTo: familyCode)
              .orderBy('createdAt', descending: true)
              .snapshots()
              .map(
                (snapshot) => snapshot.docs
                    .map((doc) => Pet.fromMap(doc.data()))
                    .toList(),
              );
        });
  }

  Future<Pet?> getPetById(String petId) async {
    try {
      final doc = await _firestore.collection('pets').doc(petId).get();
      if (doc.exists) {
        return Pet.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao obter pet: $e');
    }
  }

  Future<String> addPet({
    required String name,
    required PetSpecies species,
    required DateTime birthDate,
    required double weightKg,
    String? photoUrl,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Usuário não autenticado');

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        throw Exception('Usuário não encontrado');
      }

      final familyCode = userDoc.data()!['familyCode'] as String;
      final petId = _uuid.v4();

      final pet = Pet(
        id: petId,
        familyCode: familyCode,
        name: name,
        species: species,
        birthDate: birthDate,
        weightKg: weightKg,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('pets').doc(petId).set(pet.toMap());
      return petId;
    } catch (e) {
      throw Exception('Erro ao adicionar pet: $e');
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
      final updateData = <String, dynamic>{'updatedAt': Timestamp.now()};

      if (name != null) updateData['name'] = name;
      if (species != null) updateData['species'] = species.name;
      if (birthDate != null)
        updateData['birthDate'] = Timestamp.fromDate(birthDate);
      if (weightKg != null) updateData['weightKg'] = weightKg;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;

      await _firestore.collection('pets').doc(petId).update(updateData);
    } catch (e) {
      throw Exception('Erro ao atualizar pet: $e');
    }
  }

  Future<void> deletePet(String petId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Usuário não autenticado');

      final petDoc = await _firestore.collection('pets').doc(petId).get();
      if (!petDoc.exists || petDoc.data() == null) {
        throw Exception('Pet não encontrado.');
      }
      final petData = petDoc.data()!;
      final petFamilyCode = petData['familyCode'] as String;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!userDoc.exists ||
          userDoc.data() == null ||
          userDoc.data()!['familyCode'] != petFamilyCode) {
        throw Exception(
          'Acesso negado: Você não pertence à família deste pet.',
        );
      }

      final batch = _firestore.batch();

      final tasksSnapshot = await _firestore
          .collection('pet_tasks')
          .where('petId', isEqualTo: petId)
          .get();

      for (final doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(_firestore.collection('pets').doc(petId));

      await batch.commit();

      final photoUrl = petData['photoUrl'] as String?;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        await _storageService.deletePetPhoto(petId);
      }
    } catch (e) {
      throw Exception('Erro ao deletar pet e suas tarefas/foto: $e');
    }
  }

  Stream<List<PetTask>> getPetTasksStream(String petId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .asyncExpand((userDoc) {
          if (!userDoc.exists || userDoc.data() == null) {
            return Stream.value(<PetTask>[]);
          }

          final familyCode = userDoc.data()!['familyCode'] as String?;
          if (familyCode == null || familyCode.isEmpty) {
            return Stream.value(<PetTask>[]);
          }

          return _firestore
              .collection('pet_tasks')
              .where('petId', isEqualTo: petId)
              .where('familyCode', isEqualTo: familyCode)
              .orderBy('dueDate', descending: false)
              .snapshots()
              .map(
                (snapshot) => snapshot.docs
                    .map((doc) => PetTask.fromMap(doc.data()))
                    .toList(),
              );
        });
  }

  Stream<List<PetTask>> getAllTasksStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .asyncExpand((userDoc) {
          if (!userDoc.exists || userDoc.data() == null) {
            return Stream.value(<PetTask>[]);
          }

          final familyCode = userDoc.data()!['familyCode'] as String;

          return _firestore
              .collection('pet_tasks')
              .where('familyCode', isEqualTo: familyCode)
              .orderBy('dueDate', descending: false)
              .snapshots()
              .map(
                (snapshot) => snapshot.docs
                    .map((doc) => PetTask.fromMap(doc.data()))
                    .toList(),
              );
        });
  }

  Future<PetTask?> getTaskById(String taskId) async {
    try {
      final doc = await _firestore.collection('pet_tasks').doc(taskId).get();
      if (doc.exists) {
        return PetTask.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao obter tarefa: $e');
    }
  }

  Future<String> addTask({
    required String petId,
    required PetTaskType type,
    required String title,
    DateTime? dueDate,
    String? notes,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Usuário não autenticado');

      final petDoc = await _firestore.collection('pets').doc(petId).get();
      if (!petDoc.exists || petDoc.data() == null) {
        throw Exception('Pet não encontrado para adicionar a tarefa');
      }
      final petFamilyCode = petDoc.data()!['familyCode'] as String;

      final taskId = _uuid.v4();

      final task = PetTask(
        id: taskId,
        petId: petId,
        familyCode: petFamilyCode,
        type: type,
        title: title,
        dueDate: dueDate,
        notes: notes,
        createdBy: currentUser.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('pet_tasks').doc(taskId).set(task.toMap());
      return taskId;
    } catch (e) {
      throw Exception('Erro ao adicionar tarefa: $e');
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
      final updateData = <String, dynamic>{'updatedAt': Timestamp.now()};

      if (type != null) updateData['type'] = type.name;
      if (title != null) updateData['title'] = title;
      if (dueDate != null) updateData['dueDate'] = Timestamp.fromDate(dueDate);
      if (notes != null) updateData['notes'] = notes;
      if (done != null) updateData['done'] = done;

      await _firestore.collection('pet_tasks').doc(taskId).update(updateData);
    } catch (e) {
      throw Exception('Erro ao atualizar tarefa: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('pet_tasks').doc(taskId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar tarefa: $e');
    }
  }

  Future<void> toggleTaskDone(String taskId) async {
    try {
      final taskDoc = await _firestore
          .collection('pet_tasks')
          .doc(taskId)
          .get();
      if (taskDoc.exists) {
        final currentDone = taskDoc.data()!['done'] as bool;
        await _firestore.collection('pet_tasks').doc(taskId).update({
          'done': !currentDone,
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      throw Exception('Erro ao alterar status da tarefa: $e');
    }
  }

  Future<Map<String, dynamic>?> getFamilyData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) return null;

      final familyCode = userDoc.data()!['familyCode'] as String;
      final familyDoc = await _firestore
          .collection('families')
          .doc(familyCode)
          .get();

      if (familyDoc.exists) {
        return familyDoc.data();
      }

      return null;
    } catch (e) {
      throw Exception('Erro ao obter dados da família: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFamilyMembers() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) return [];

      final familyCode = userDoc.data()!['familyCode'] as String;
      final membersSnapshot = await _firestore
          .collection('users')
          .where('familyCode', isEqualTo: familyCode)
          .get();

      return membersSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Erro ao obter membros da família: $e');
    }
  }
}
