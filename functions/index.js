const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Função para notificar família sobre uma tarefa
exports.notifyFamily = functions.https.onCall(async (data, context) => {
  try {
    // Verificar autenticação
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
    }

    const { petId, taskTitle, message, createdBy } = data;

    if (!petId || !taskTitle) {
      throw new functions.https.HttpsError('invalid-argument', 'Dados obrigatórios não fornecidos');
    }

    // Obter dados do usuário
    const userDoc = await admin.firestore().collection('users').doc(createdBy).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Usuário não encontrado');
    }

    const userData = userDoc.data();
    const familyCode = userData.familyCode;

    // Obter todos os membros da família
    const familyMembersSnapshot = await admin.firestore()
      .collection('users')
      .where('familyCode', '==', familyCode)
      .get();

    const notifications = [];

    for (const memberDoc of familyMembersSnapshot.docs) {
      const memberData = memberDoc.data();
      const fcmTokens = memberData.fcmTokens || [];

      for (const token of fcmTokens) {
        const notification = {
          token: token,
          notification: {
            title: 'Nova tarefa para o pet',
            body: `${taskTitle} - ${message || 'Nova tarefa adicionada'}`,
          },
          data: {
            type: 'new_task',
            petId: petId,
            taskTitle: taskTitle,
            createdBy: createdBy,
          },
        };

        notifications.push(notification);
      }
    }

    // Enviar notificações
    if (notifications.length > 0) {
      const response = await admin.messaging().sendAll(notifications);
      console.log(`Notificações enviadas: ${response.successCount}/${notifications.length}`);
    }

    return { success: true, notificationsSent: notifications.length };
  } catch (error) {
    console.error('Erro ao notificar família:', error);
    throw new functions.https.HttpsError('internal', 'Erro interno do servidor');
  }
});

// Função para notificar sobre tarefa vencida
exports.notifyOverdueTask = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
    }

    const { petId, taskTitle, dueDate, createdBy } = data;

    // Obter dados do usuário e família
    const userDoc = await admin.firestore().collection('users').doc(createdBy).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Usuário não encontrado');
    }

    const userData = userDoc.data();
    const familyCode = userData.familyCode;

    // Obter membros da família
    const familyMembersSnapshot = await admin.firestore()
      .collection('users')
      .where('familyCode', '==', familyCode)
      .get();

    const notifications = [];

    for (const memberDoc of familyMembersSnapshot.docs) {
      const memberData = memberDoc.data();
      const fcmTokens = memberData.fcmTokens || [];

      for (const token of fcmTokens) {
        const notification = {
          token: token,
          notification: {
            title: 'Tarefa vencida!',
            body: `${taskTitle} estava prevista para ${new Date(dueDate).toLocaleDateString('pt-BR')}`,
          },
          data: {
            type: 'overdue_task',
            petId: petId,
            taskTitle: taskTitle,
            dueDate: dueDate,
          },
        };

        notifications.push(notification);
      }
    }

    if (notifications.length > 0) {
      await admin.messaging().sendAll(notifications);
    }

    return { success: true };
  } catch (error) {
    console.error('Erro ao notificar tarefa vencida:', error);
    throw new functions.https.HttpsError('internal', 'Erro interno do servidor');
  }
});

// Função para notificar sobre nova vacina
exports.notifyNewVaccine = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
    }

    const { petId, vaccineName, dueDate, createdBy } = data;

    // Obter dados do usuário e família
    const userDoc = await admin.firestore().collection('users').doc(createdBy).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Usuário não encontrado');
    }

    const userData = userDoc.data();
    const familyCode = userData.familyCode;

    // Obter membros da família
    const familyMembersSnapshot = await admin.firestore()
      .collection('users')
      .where('familyCode', '==', familyCode)
      .get();

    const notifications = [];

    for (const memberDoc of familyMembersSnapshot.docs) {
      const memberData = memberDoc.data();
      const fcmTokens = memberData.fcmTokens || [];

      for (const token of fcmTokens) {
        const notification = {
          token: token,
          notification: {
            title: 'Nova vacina agendada',
            body: `${vaccineName} - ${new Date(dueDate).toLocaleDateString('pt-BR')}`,
          },
          data: {
            type: 'new_vaccine',
            petId: petId,
            vaccineName: vaccineName,
            dueDate: dueDate,
          },
        };

        notifications.push(notification);
      }
    }

    if (notifications.length > 0) {
      await admin.messaging().sendAll(notifications);
    }

    return { success: true };
  } catch (error) {
    console.error('Erro ao notificar nova vacina:', error);
    throw new functions.https.HttpsError('internal', 'Erro interno do servidor');
  }
});

// Função para notificar sobre novo pet
exports.notifyNewPet = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
    }

    const { petName, petSpecies, createdBy } = data;

    // Obter dados do usuário e família
    const userDoc = await admin.firestore().collection('users').doc(createdBy).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Usuário não encontrado');
    }

    const userData = userDoc.data();
    const familyCode = userData.familyCode;

    // Obter membros da família
    const familyMembersSnapshot = await admin.firestore()
      .collection('users')
      .where('familyCode', '==', familyCode)
      .get();

    const notifications = [];

    for (const memberDoc of familyMembersSnapshot.docs) {
      const memberData = memberDoc.data();
      const fcmTokens = memberData.fcmTokens || [];

      for (const token of fcmTokens) {
        const notification = {
          token: token,
          notification: {
            title: 'Novo pet adicionado!',
            body: `${petName} (${petSpecies}) foi adicionado à família`,
          },
          data: {
            type: 'new_pet',
            petName: petName,
            petSpecies: petSpecies,
          },
        };

        notifications.push(notification);
      }
    }

    if (notifications.length > 0) {
      await admin.messaging().sendAll(notifications);
    }

    return { success: true };
  } catch (error) {
    console.error('Erro ao notificar novo pet:', error);
    throw new functions.https.HttpsError('internal', 'Erro interno do servidor');
  }
});

// Função para notificar sobre tarefa concluída
exports.notifyTaskCompleted = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
    }

    const { petId, taskTitle, completedBy } = data;

    // Obter dados do usuário e família
    const userDoc = await admin.firestore().collection('users').doc(completedBy).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Usuário não encontrado');
    }

    const userData = userDoc.data();
    const familyCode = userData.familyCode;

    // Obter membros da família
    const familyMembersSnapshot = await admin.firestore()
      .collection('users')
      .where('familyCode', '==', familyCode)
      .get();

    const notifications = [];

    for (const memberDoc of familyMembersSnapshot.docs) {
      const memberData = memberDoc.data();
      const fcmTokens = memberData.fcmTokens || [];

      for (const token of fcmTokens) {
        const notification = {
          token: token,
          notification: {
            title: 'Tarefa concluída!',
            body: `${taskTitle} foi marcada como concluída`,
          },
          data: {
            type: 'task_completed',
            petId: petId,
            taskTitle: taskTitle,
            completedBy: completedBy,
          },
        };

        notifications.push(notification);
      }
    }

    if (notifications.length > 0) {
      await admin.messaging().sendAll(notifications);
    }

    return { success: true };
  } catch (error) {
    console.error('Erro ao notificar tarefa concluída:', error);
    throw new functions.https.HttpsError('internal', 'Erro interno do servidor');
  }
});

// Função para enviar mensagem personalizada
exports.sendCustomMessage = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
    }

    const { message, title, sentBy } = data;

    // Obter dados do usuário e família
    const userDoc = await admin.firestore().collection('users').doc(sentBy).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Usuário não encontrado');
    }

    const userData = userDoc.data();
    const familyCode = userData.familyCode;

    // Obter membros da família
    const familyMembersSnapshot = await admin.firestore()
      .collection('users')
      .where('familyCode', '==', familyCode)
      .get();

    const notifications = [];

    for (const memberDoc of familyMembersSnapshot.docs) {
      const memberData = memberDoc.data();
      const fcmTokens = memberData.fcmTokens || [];

      for (const token of fcmTokens) {
        const notification = {
          token: token,
          notification: {
            title: title || 'Mensagem da família',
            body: message,
          },
          data: {
            type: 'custom_message',
            message: message,
            sentBy: sentBy,
          },
        };

        notifications.push(notification);
      }
    }

    if (notifications.length > 0) {
      await admin.messaging().sendAll(notifications);
    }

    return { success: true };
  } catch (error) {
    console.error('Erro ao enviar mensagem personalizada:', error);
    throw new functions.https.HttpsError('internal', 'Erro interno do servidor');
  }
});

// Função para obter estatísticas da família
exports.getFamilyStats = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
    }

    const { userId } = data;

    // Obter dados do usuário
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Usuário não encontrado');
    }

    const userData = userDoc.data();
    const familyCode = userData.familyCode;

    // Obter estatísticas dos pets
    const petsSnapshot = await admin.firestore()
      .collection('pets')
      .where('familyCode', '==', familyCode)
      .get();

    // Obter estatísticas das tarefas
    const tasksSnapshot = await admin.firestore()
      .collection('pet_tasks')
      .get();

    const familyPetIds = petsSnapshot.docs.map(doc => doc.id);
    const familyTasks = tasksSnapshot.docs
      .map(doc => doc.data())
      .filter(task => familyPetIds.includes(task.petId));

    const stats = {
      totalPets: petsSnapshot.size,
      totalTasks: familyTasks.length,
      completedTasks: familyTasks.filter(task => task.done).length,
      pendingTasks: familyTasks.filter(task => !task.done).length,
      overdueTasks: familyTasks.filter(task => {
        if (!task.dueDate) return false;
        return new Date(task.dueDate.toDate()) < new Date() && !task.done;
      }).length,
    };

    return { success: true, stats };
  } catch (error) {
    console.error('Erro ao obter estatísticas:', error);
    throw new functions.https.HttpsError('internal', 'Erro interno do servidor');
  }
});

// Função para limpar tokens FCM antigos
exports.cleanupOldFcmTokens = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
    }

    const { userId } = data;

    // Obter dados do usuário
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Usuário não encontrado');
    }

    const userData = userDoc.data();
    const fcmTokens = userData.fcmTokens || [];

    // Verificar quais tokens ainda são válidos
    const validTokens = [];
    for (const token of fcmTokens) {
      try {
        await admin.messaging().send({
          token: token,
          data: { test: 'true' },
        }, true);
        validTokens.push(token);
      } catch (error) {
        console.log(`Token inválido removido: ${token}`);
      }
    }

    // Atualizar tokens válidos
    await admin.firestore().collection('users').doc(userId).update({
      fcmTokens: validTokens,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { 
      success: true, 
      removedTokens: fcmTokens.length - validTokens.length,
      validTokens: validTokens.length,
    };
  } catch (error) {
    console.error('Erro ao limpar tokens:', error);
    throw new functions.https.HttpsError('internal', 'Erro interno do servidor');
  }
});
