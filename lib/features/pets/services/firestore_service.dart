// features/pets/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_keeper_lite/features/pet_tasks/models/pet_task.dart';
import 'package:pet_keeper_lite/features/pets/models/pet.dart';
import 'package:uuid/uuid.dart';


class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // PETS

  // Stream de pets da família atual
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
      if (!userDoc.exists || userDoc.data() == null) return Stream.value(<Pet>[]);

      final familyCode = userDoc.data()!['familyCode'] as String;

      return _firestore
          .collection('pets')
          .where('familyCode', isEqualTo: familyCode)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Pet.fromMap(doc.data())).toList());
    });
  }


  // Obter pet por ID
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

  // Adicionar pet
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

      // Obter familyCode do usuário
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

  // Atualizar pet
  Future<void> updatePet({
    required String petId,
    String? name,
    PetSpecies? species,
    DateTime? birthDate,
    double? weightKg,
    String? photoUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (name != null) updateData['name'] = name;
      if (species != null) updateData['species'] = species.name;
      if (birthDate != null) updateData['birthDate'] = Timestamp.fromDate(birthDate);
      if (weightKg != null) updateData['weightKg'] = weightKg;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;

      await _firestore.collection('pets').doc(petId).update(updateData);
    } catch (e) {
      throw Exception('Erro ao atualizar pet: $e');
    }
  }

  // Deletar pet
  Future<void> deletePet(String petId) async {
    try {
      // Deletar todas as tarefas do pet primeiro
      // IMPORTANTE: Para isso funcionar com as novas regras,
      // a tarefa precisa ter o familyCode e o usuário precisa ser da família.
      // E, para um batch delete, as regras são avaliadas para cada documento.
      final tasksSnapshot = await _firestore
          .collection('pet_tasks')
          .where('petId', isEqualTo: petId)
          .get();

      final batch = _firestore.batch();

      for (final doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Deletar o pet
      batch.delete(_firestore.collection('pets').doc(petId));

      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao deletar pet: $e');
    }
  }

  // PET TASKS

  // Stream de tarefas de um pet
  // Esta query ainda funciona porque você está filtrando por petId,
  // e as regras de segurança ainda exigirão que o familyCode da tarefa
  // corresponda ao do usuário autenticado.
  Stream<List<PetTask>> getPetTasksStream(String petId) {
    // Você pode adicionar a verificação de familyCode aqui para ser mais seguro no cliente
    // se precisar filtrar antes da regra de segurança atuar.
    // Exemplo:
    // final currentUser = _auth.currentUser;
    // if (currentUser == null) return Stream.value([]);
    // final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    // if (!userDoc.exists || userDoc.data() == null) return Stream.value([]);
    // final familyCode = userDoc.data()!['familyCode'] as String;
    // return _firestore.collection('pet_tasks').where('petId', isEqualTo: petId).where('familyCode', isEqualTo: familyCode) ...
    // No entanto, as regras de segurança já fazem isso, então a query atual é "segura".
    return _firestore
        .collection('pet_tasks')
        .where('petId', isEqualTo: petId)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PetTask.fromMap(doc.data()))
            .toList());
  }

  // Stream de todas as tarefas da família (REFATORADO)
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

      // Consulta diretamente as tarefas pelo familyCode
      return _firestore
          .collection('pet_tasks')
          .where('familyCode', isEqualTo: familyCode)
          .orderBy('dueDate', descending: false)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => PetTask.fromMap(doc.data())).toList());
    });
  }


  // Obter tarefa por ID
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

  // Adicionar tarefa (MODIFICADO)
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

      // 1. Obter o Pet para buscar o familyCode
      final petDoc = await _firestore.collection('pets').doc(petId).get();
      if (!petDoc.exists || petDoc.data() == null) {
        throw Exception('Pet não encontrado para adicionar a tarefa');
      }
      final petFamilyCode = petDoc.data()!['familyCode'] as String;

      final taskId = _uuid.v4();

      final task = PetTask(
        id: taskId,
        petId: petId,
        familyCode: petFamilyCode, // AGORA PASSAMOS O familyCode
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

  // Atualizar tarefa
  Future<void> updateTask({
    required String taskId,
    PetTaskType? type,
    String? title,
    DateTime? dueDate,
    String? notes,
    bool? done,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

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

  // Deletar tarefa
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('pet_tasks').doc(taskId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar tarefa: $e');
    }
  }

  // Marcar tarefa como concluída/não concluída
  Future<void> toggleTaskDone(String taskId) async {
    try {
      final taskDoc = await _firestore.collection('pet_tasks').doc(taskId).get();
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

  // FAMILY

  // Obter dados da família
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

  // Obter membros da família
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
