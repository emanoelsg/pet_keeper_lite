// features/pets/services/cloud_functions_service.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> notifyFamily({
    required String petId,
    required String taskTitle,
    String? message,
  }) async {
    try {
      final callable = _functions.httpsCallable('notifyFamily');

      final result = await callable.call({
        'petId': petId,
        'taskTitle': taskTitle,
        'message': message ?? 'Nova tarefa adicionada para o pet',
      });

      if (result.data['success'] == false) {
        throw Exception(result.data['error'] ?? 'Erro ao enviar notificação');
      }
      debugPrint('Notificação de família enviada com sucesso: ${result.data}');
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'Erro na Cloud Function notifyFamily: ${e.code} - ${e.message}',
      );
      throw Exception('Erro ao notificar família: ${e.message}');
    } catch (e) {
      debugPrint('Erro inesperado ao chamar notifyFamily: $e');
      throw Exception('Erro inesperado ao notificar família.');
    }
  }
}
