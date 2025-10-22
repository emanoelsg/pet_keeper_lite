// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Função auxiliar para obter o familyCode e displayName do usuário que fez a chamada
async function getUserFamilyAndDisplayName(contextAuthUid) {
  const userDoc = await admin.firestore().collection('users').doc(contextAuthUid).get();
  if (!userDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Usuário que fez a chamada não encontrado.');
  }
  const userData = userDoc.data();
  if (!userData.familyCode) {
    throw new functions.https.HttpsError('failed-precondition', 'Usuário não tem um código de família.');
  }
  return { familyCode: userData.familyCode, displayName: userData.displayName || 'Alguém da família' };
}

// Função auxiliar para obter o nome do pet
async function getPetName(petId) {
  const petDoc = await admin.firestore().collection('pets').doc(petId).get();
  if (!petDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Pet não encontrado.');
  }
  return petDoc.data().name || 'Um pet';
}


// Função para notificar família sobre uma tarefa (ou evento genérico)
exports.notifyFamily = functions.https.onCall(async (data, context) => {
  // 1. Verificar autenticação
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  }
  const callerUid = context.auth.uid;

  const { petId, taskTitle, message } = data; // createdBy não é mais necessário aqui, usamos o displayName do caller

  // Validação de entrada
  if (!petId || !taskTitle) { // message pode ser opcional
    throw new functions.https.HttpsError('invalid-argument', 'Dados obrigatórios (petId, taskTitle) não fornecidos.');
  }

  functions.logger.log("notifyFamily chamada por:", callerUid, "com dados:", data);

  try {
    const { familyCode, displayName } = await getUserFamilyAndDisplayName(callerUid);
    const petName = await getPetName(petId);

    // Obter todos os membros da família (exceto o próprio remetente)
    const familyMembersSnapshot = await admin.firestore()
      .collection('users')
      .where('familyCode', '==', familyCode)
      .get();

    const registrationTokens = [];
    familyMembersSnapshot.forEach(doc => {
      // Não enviar notificação para o próprio usuário que acionou a função
      if (doc.id !== callerUid) {
        const memberData = doc.data();
        if (memberData.fcmTokens && Array.isArray(memberData.fcmTokens)) {
          registrationTokens.push(...memberData.fcmTokens);
        }
      }
    });

    if (registrationTokens.length === 0) {
      functions.logger.log("Nenhum token de registro encontrado na família (excluindo o remetente).");
      return { success: true, message: "Nenhum token para notificar." };
    }

    // Remover tokens duplicados
    const uniqueTokens = [...new Set(registrationTokens)];

    // Montar a mensagem de notificação
    const payload = {
      notification: {
        title: `PetKeeper Lite: ${petName}`,
        body: `${taskTitle} - ${displayName}`, // Usando o displayName do remetente
      },
      data: {
        type: 'new_task',
        petId: petId,
        taskTitle: taskTitle,
        // createdBy aqui pode ser o displayName, se você quiser exibi-lo no app
        createdByDisplayName: displayName,
        // message, se você quiser que o app exiba algo diferente do taskTitle
        message: message || `Uma nova tarefa foi adicionada para ${petName}.`,
      },
    };

    // Enviar notificações usando sendEachForMulticast para melhor performance e feedback
    const response = await admin.messaging().sendEachForMulticast({
      tokens: uniqueTokens,
      ...payload
    });

    // Opcional: Log de resultados e limpeza de tokens inválidos (melhoria futura)
    functions.logger.log(`Notificações enviadas para ${response.successCount} de ${uniqueTokens.length} tokens.`);
    response.responses.forEach((res, idx) => {
      if (!res.success) {
        functions.logger.error(`Falha ao enviar para token ${uniqueTokens[idx]}:`, res.error);
        // Aqui você pode adicionar lógica para remover tokens inválidos do Firestore.
        // O desafio não exige, mas é uma boa prática.
      }
    });


    return { success: true, notificationsSent: response.successCount };
  } catch (error) {
    functions.logger.error('Erro ao notificar família:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Erro interno do servidor', error.message);
  }
});


// FUNÇÕES SIMPLIFICADAS PARA OUTROS TIPOS DE NOTIFICAÇÃO (usando a mesma estrutura)
// Você pode consolidar algumas delas se a lógica for muito similar.

// Função para notificar sobre tarefa vencida
exports.notifyOverdueTask = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  const callerUid = context.auth.uid;
  const { petId, taskTitle, dueDate } = data; // createdBy não é mais necessário

  if (!petId || !taskTitle || !dueDate) {
    throw new functions.https.HttpsError('invalid-argument', 'Dados obrigatórios não fornecidos');
  }

  try {
    const { familyCode, displayName } = await getUserFamilyAndDisplayName(callerUid);
    const petName = await getPetName(petId);

    const familyMembersSnapshot = await admin.firestore()
      .collection('users')
      .where('familyCode', '==', familyCode)
      .get();

    const registrationTokens = [];
    familyMembersSnapshot.forEach(doc => {
      if (doc.id !== callerUid && doc.data().fcmTokens && Array.isArray(doc.data().fcmTokens)) {
        registrationTokens.push(...doc.data().fcmTokens);
      }
    });

    if (registrationTokens.length === 0) return { success: true, message: "Nenhum token para notificar." };
    const uniqueTokens = [...new Set(registrationTokens)];

    const payload = {
      notification: {
        title: `PetKeeper Lite: ${petName}`,
        body: `Tarefa vencida: ${taskTitle} estava prevista para ${new Date(dueDate).toLocaleDateString('pt-BR')}`,
      },
      data: {
        type: 'overdue_task',
        petId: petId,
        taskTitle: taskTitle,
        dueDate: new Date(dueDate).toISOString(), // Mantenha o formato ISO para fácil parse no app
        createdByDisplayName: displayName,
      },
    };

    const response = await admin.messaging().sendEachForMulticast({ tokens: uniqueTokens, ...payload });
    return { success: true, notificationsSent: response.successCount };
  } catch (error) {
    functions.logger.error('Erro ao notificar tarefa vencida:', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Erro interno do servidor', error.message);
  }
});

// Função para notificar sobre nova vacina
exports.notifyNewVaccine = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  const callerUid = context.auth.uid;
  const { petId, vaccineName, dueDate } = data; // createdBy não é mais necessário

  if (!petId || !vaccineName || !dueDate) {
    throw new functions.https.HttpsError('invalid-argument', 'Dados obrigatórios não fornecidos');
  }

  try {
    const { familyCode, displayName } = await getUserFamilyAndDisplayName(callerUid);
    const petName = await getPetName(petId);

    const familyMembersSnapshot = await admin.firestore()
      .collection('users')
      .where('familyCode', '==', familyCode)
      .get();

    const registrationTokens = [];
    familyMembersSnapshot.forEach(doc => {
      if (doc.id !== callerUid && doc.data().fcmTokens && Array.isArray(doc.data().fcmTokens)) {
        registrationTokens.push(...doc.data().fcmTokens);
      }
    });

    if (registrationTokens.length === 0) return { success: true, message: "Nenhum token para notificar." };
    const uniqueTokens = [...new Set(registrationTokens)];

    const payload = {
      notification: {
        title: `PetKeeper Lite: ${petName}`,
        body: `Nova vacina: ${vaccineName} agendada para ${new Date(dueDate).toLocaleDateString('pt-BR')}`,
      },
      data: {
        type: 'new_vaccine',
        petId: petId,
        vaccineName: vaccineName,
        dueDate: new Date(dueDate).toISOString(),
        createdByDisplayName: displayName,
      },
    };

    const response = await admin.messaging().sendEachForMulticast({ tokens: uniqueTokens, ...payload });
    return { success: true, notificationsSent: response.successCount };
  } catch (error) {
    functions.logger.error('Erro ao notificar nova vacina:', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Erro interno do servidor', error.message);
  }
});

// Função para notificar sobre novo pet
exports.notifyNewPet = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  const callerUid = context.auth.uid;
  const { petName, petSpecies } = data; // createdBy não é mais necessário

  if (!petName || !petSpecies) {
    throw new functions.https.HttpsError('invalid-argument', 'Dados obrigatórios não fornecidos');
  }

  try {
    const { familyCode, displayName } = await getUserFamilyAndDisplayName(callerUid);

    const familyMembersSnapshot = await admin.firestore()
      .collection('users')
      .where('familyCode', '==', familyCode)
      .get();

    const registrationTokens = [];
    familyMembersSnapshot.forEach(doc => {
      if (doc.id !== callerUid && doc.data().fcmTokens && Array.isArray(doc.data().fcmTokens)) {
        registrationTokens.push(...doc.data().fcmTokens);
      }
    });

    if (registrationTokens.length === 0) return { success: true, message: "Nenhum token para notificar." };
    const uniqueTokens = [...new Set(registrationTokens)];

    const payload = {
      notification: {
        title: `PetKeeper Lite: ${petName}`,
        body: `${petName} (${petSpecies}) foi adicionado por ${displayName}!`,
      },
      data: {
        type: 'new_pet',
        petName: petName,
        petSpecies: petSpecies,
        createdByDisplayName: displayName,
      },
    };

    const response = await admin.messaging().sendEachForMulticast({ tokens: uniqueTokens, ...payload });
    return { success: true, notificationsSent: response.successCount };
  } catch (error) {
    functions.logger.error('Erro ao notificar novo pet:', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Erro interno do servidor', error.message);
  }
});

// Função para notificar sobre tarefa concluída
exports.notifyTaskCompleted = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  const callerUid = context.auth.uid;
  const { petId, taskTitle } = data; // completedBy não é mais necessário

  if (!petId || !taskTitle) {
    throw new functions.https.HttpsError('invalid-argument', 'Dados obrigatórios não fornecidos');
  }

  try {
    const { familyCode, displayName } = await getUserFamilyAndDisplayName(callerUid);
    const petName = await getPetName(petId);

    const familyMembersSnapshot = await admin.firestore()
      .collection('users')
      .where('familyCode', '==', familyCode)
      .get();

    const registrationTokens = [];
    familyMembersSnapshot.forEach(doc => {
      if (doc.id !== callerUid && doc.data().fcmTokens && Array.isArray(doc.data().fcmTokens)) {
        registrationTokens.push(...doc.data().fcmTokens);
      }
    });

    if (registrationTokens.length === 0) return { success: true, message: "Nenhum token para notificar." };
    const uniqueTokens = [...new Set(registrationTokens)];

    const payload = {
      notification: {
        title: `PetKeeper Lite: ${petName}`,
        body: `Tarefa concluída: ${taskTitle} por ${displayName}`,
      },
      data: {
        type: 'task_completed',
        petId: petId,
        taskTitle: taskTitle,
        completedByDisplayName: displayName,
      },
    };

    const response = await admin.messaging().sendEachForMulticast({ tokens: uniqueTokens, ...payload });
    return { success: true, notificationsSent: response.successCount };
  } catch (error) {
    functions.logger.error('Erro ao notificar tarefa concluída:', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Erro interno do servidor', error.message);
  }
});

// Função para enviar mensagem personalizada
exports.sendCustomMessage = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  const callerUid = context.auth.uid;
  const { message, title } = data; // sentBy não é mais necessário

  if (!message) {
    throw new functions.https.HttpsError('invalid-argument', 'Mensagem não fornecida');
  }

  try {
    const { familyCode, displayName } = await getUserFamilyAndDisplayName(callerUid);

    const familyMembersSnapshot = await admin.firestore()
      .collection('users')
      .where('familyCode', '==', familyCode)
      .get();

    const registrationTokens = [];
    familyMembersSnapshot.forEach(doc => {
      if (doc.id !== callerUid && doc.data().fcmTokens && Array.isArray(doc.data().fcmTokens)) {
        registrationTokens.push(...doc.data().fcmTokens);
      }
    });

    if (registrationTokens.length === 0) return { success: true, message: "Nenhum token para notificar." };
    const uniqueTokens = [...new Set(registrationTokens)];

    const payload = {
      notification: {
        title: title || `PetKeeper Lite: Mensagem de ${displayName}`,
        body: message,
      },
      data: {
        type: 'custom_message',
        message: message,
        sentByDisplayName: displayName,
      },
    };

    const response = await admin.messaging().sendEachForMulticast({ tokens: uniqueTokens, ...payload });
    return { success: true, notificationsSent: response.successCount };
  } catch (error) {
    functions.logger.error('Erro ao enviar mensagem personalizada:', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Erro interno do servidor', error.message);
  }
});

// Função para obter estatísticas da família (CORRIGIDA)
exports.getFamilyStats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  }
  const callerUid = context.auth.uid; // Usamos context.auth.uid diretamente

  functions.logger.log("getFamilyStats chamada por:", callerUid);

  try {
    const { familyCode } = await getUserFamilyAndDisplayName(callerUid); // Obtém familyCode do caller

    // Obter estatísticas dos pets (já filtrado por familyCode)
    const petsSnapshot = await admin.firestore()
      .collection('pets')
      .where('familyCode', '==', familyCode)
      .get();

    // Obter estatísticas das tarefas (CORRIGIDO: agora filtra por familyCode no Firestore)
    const tasksSnapshot = await admin.firestore()
      .collection('pet_tasks')
      .where('familyCode', '==', familyCode) // FILTRA DIRETAMENTE AQUI
      .get();

    const familyTasks = tasksSnapshot.docs.map(doc => doc.data());

    const stats = {
      totalPets: petsSnapshot.size,
      totalTasks: familyTasks.length,
      completedTasks: familyTasks.filter(task => task.done).length,
      pendingTasks: familyTasks.filter(task => !task.done).length,
      overdueTasks: familyTasks.filter(task => {
        // Assume que dueDate é um Timestamp do Firestore, ou Date object se convertido
        if (!task.dueDate) return false;
        const taskDueDate = task.dueDate.toDate ? task.dueDate.toDate() : new Date(task.dueDate);
        return taskDueDate < new Date() && !task.done;
      }).length,
    };

    return { success: true, stats };
  } catch (error) {
    functions.logger.error('Erro ao obter estatísticas:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Erro interno do servidor', error.message);
  }
});

// Função para limpar tokens FCM antigos (CORRIGIDA)
exports.cleanupOldFcmTokens = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  }
  const callerUid = context.auth.uid; // Usamos context.auth.uid diretamente

  functions.logger.log("cleanupOldFcmTokens chamada por:", callerUid);

  try {
    const userDocRef = admin.firestore().collection('users').doc(callerUid);
    const userDoc = await userDocRef.get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Usuário não encontrado');
    }

    const userData = userDoc.data();
    const fcmTokens = userData.fcmTokens || [];

    const messaging = admin.messaging();
    const validTokens = [];
    const tokensToRemove = [];

    // Verificamos a validade de cada token
    // Nota: sendAll para dryRun é mais eficiente que send em loop para muitos tokens
    const dryRunMessages = fcmTokens.map(token => ({ token: token, data: { test: 'true' } }));
    if (dryRunMessages.length > 0) {
      const response = await messaging.sendEachForMulticast({tokens: fcmTokens, data: { test: 'true' }}, true); // Dry run
      
      response.responses.forEach((res, index) => {
        const token = fcmTokens[index];
        if (res.success) {
          validTokens.push(token);
        } else {
          // Se o erro indica que o token não é registrado ou é inválido, marcamos para remoção
          if (res.error && (res.error.code === 'messaging/invalid-argument' || res.error.code === 'messaging/registration-token-not-registered' || res.error.code === 'messaging/unregistered')) {
            functions.logger.log(`Token FCM inválido/não registrado para ${callerUid}: ${token}`);
            tokensToRemove.push(token);
          } else {
            // Outros erros, talvez seja temporário, mantém o token por enquanto
            validTokens.push(token);
            functions.logger.warn(`Erro ao verificar token ${token} para ${callerUid}:`, res.error);
          }
        }
      });
    }

    // Atualizar apenas se houver mudança nos tokens (para economizar escrita)
    if (fcmTokens.length !== validTokens.length) {
      await userDocRef.update({
        fcmTokens: validTokens,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      functions.logger.log(`Tokens FCM limpos para ${callerUid}. Removidos: ${tokensToRemove.length}, Válidos: ${validTokens.length}`);
    } else {
      functions.logger.log(`Nenhum token FCM inválido encontrado para ${callerUid}.`);
    }

    return {
      success: true,
      removedTokens: tokensToRemove.length,
      validTokens: validTokens.length,
    };
  } catch (error) {
    functions.logger.error('Erro ao limpar tokens:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Erro interno do servidor', error.message);
  }
});

