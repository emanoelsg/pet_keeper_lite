import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Notificar família sobre uma tarefa
  Future<void> notifyFamily({
    required String petId,
    required String taskTitle,
    String? message,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      // Chamar a Cloud Function
      final callable = _functions.httpsCallable('notifyFamily');
      
      final result = await callable.call({
        'petId': petId,
        'taskTitle': taskTitle,
        'message': message ?? 'Nova tarefa adicionada para o pet',
        'createdBy': currentUser.uid,
      });

      if (result.data['success'] == false) {
        throw Exception(result.data['error'] ?? 'Erro ao enviar notificação');
      }
    } catch (e) {
      throw Exception('Erro ao notificar família: $e');
    }
  }

  // Notificar sobre tarefa vencida
  Future<void> notifyOverdueTask({
    required String petId,
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final callable = _functions.httpsCallable('notifyOverdueTask');
      
      final result = await callable.call({
        'petId': petId,
        'taskTitle': taskTitle,
        'dueDate': dueDate.toIso8601String(),
        'createdBy': currentUser.uid,
      });

      if (result.data['success'] == false) {
        throw Exception(result.data['error'] ?? 'Erro ao enviar notificação');
      }
    } catch (e) {
      throw Exception('Erro ao notificar sobre tarefa vencida: $e');
    }
  }

  // Notificar sobre tarefa próxima do vencimento
  Future<void> notifyTaskDueSoon({
    required String petId,
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final callable = _functions.httpsCallable('notifyTaskDueSoon');
      
      final result = await callable.call({
        'petId': petId,
        'taskTitle': taskTitle,
        'dueDate': dueDate.toIso8601String(),
        'createdBy': currentUser.uid,
      });

      if (result.data['success'] == false) {
        throw Exception(result.data['error'] ?? 'Erro ao enviar notificação');
      }
    } catch (e) {
      throw Exception('Erro ao notificar sobre tarefa próxima do vencimento: $e');
    }
  }

  // Notificar sobre nova vacina
  Future<void> notifyNewVaccine({
    required String petId,
    required String vaccineName,
    required DateTime dueDate,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final callable = _functions.httpsCallable('notifyNewVaccine');
      
      final result = await callable.call({
        'petId': petId,
        'vaccineName': vaccineName,
        'dueDate': dueDate.toIso8601String(),
        'createdBy': currentUser.uid,
      });

      if (result.data['success'] == false) {
        throw Exception(result.data['error'] ?? 'Erro ao enviar notificação');
      }
    } catch (e) {
      throw Exception('Erro ao notificar sobre nova vacina: $e');
    }
  }

  // Notificar sobre novo pet adicionado
  Future<void> notifyNewPet({
    required String petName,
    required String petSpecies,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final callable = _functions.httpsCallable('notifyNewPet');
      
      final result = await callable.call({
        'petName': petName,
        'petSpecies': petSpecies,
        'createdBy': currentUser.uid,
      });

      if (result.data['success'] == false) {
        throw Exception(result.data['error'] ?? 'Erro ao enviar notificação');
      }
    } catch (e) {
      throw Exception('Erro ao notificar sobre novo pet: $e');
    }
  }

  // Notificar sobre tarefa concluída
  Future<void> notifyTaskCompleted({
    required String petId,
    required String taskTitle,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final callable = _functions.httpsCallable('notifyTaskCompleted');
      
      final result = await callable.call({
        'petId': petId,
        'taskTitle': taskTitle,
        'completedBy': currentUser.uid,
      });

      if (result.data['success'] == false) {
        throw Exception(result.data['error'] ?? 'Erro ao enviar notificação');
      }
    } catch (e) {
      throw Exception('Erro ao notificar sobre tarefa concluída: $e');
    }
  }

  // Enviar mensagem personalizada para a família
  Future<void> sendCustomMessage({
    required String message,
    String? title,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final callable = _functions.httpsCallable('sendCustomMessage');
      
      final result = await callable.call({
        'message': message,
        'title': title ?? 'Mensagem da família',
        'sentBy': currentUser.uid,
      });

      if (result.data['success'] == false) {
        throw Exception(result.data['error'] ?? 'Erro ao enviar mensagem');
      }
    } catch (e) {
      throw Exception('Erro ao enviar mensagem personalizada: $e');
    }
  }

  // Obter estatísticas da família
  Future<Map<String, dynamic>> getFamilyStats() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final callable = _functions.httpsCallable('getFamilyStats');
      
      final result = await callable.call({
        'userId': currentUser.uid,
      });

      if (result.data['success'] == false) {
        throw Exception(result.data['error'] ?? 'Erro ao obter estatísticas');
      }

      return result.data['stats'] ?? {};
    } catch (e) {
      throw Exception('Erro ao obter estatísticas da família: $e');
    }
  }

  // Limpar tokens FCM antigos
  Future<void> cleanupOldFcmTokens() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final callable = _functions.httpsCallable('cleanupOldFcmTokens');
      
      final result = await callable.call({
        'userId': currentUser.uid,
      });

      if (result.data['success'] == false) {
        throw Exception(result.data['error'] ?? 'Erro ao limpar tokens');
      }
    } catch (e) {
      throw Exception('Erro ao limpar tokens FCM antigos: $e');
    }
  }
}
