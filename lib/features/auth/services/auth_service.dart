// features/auth/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  final Uuid _uuid = const Uuid();

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  firebase_auth.User? get currentUser => _auth.currentUser;
  Future<void> init() async {
    await GoogleSignIn.instance.initialize();
  }

  Future<firebase_auth.User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _updateFcmToken();
      }

      return credential.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<firebase_auth.User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String familyCode,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(displayName);

        await _createUserDocument(
          uid: credential.user!.uid,
          displayName: displayName,
          email: email,
          familyCode: familyCode,
        );

        await _createFamilyDocument(familyCode, credential.user!.uid);

        await _updateFcmToken();
      }

      return credential.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<firebase_auth.User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.idToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          final familyCode = _generateFamilyCode();

          await _createUserDocument(
            uid: userCredential.user!.uid,
            displayName: userCredential.user!.displayName ?? 'Usuário',
            email: userCredential.user!.email ?? '',
            familyCode: familyCode,
          );

          await _createFamilyDocument(familyCode, userCredential.user!.uid);
        }

        await _updateFcmToken();
      }

      return userCredential.user;
    } catch (e) {
      throw Exception('Erro ao fazer login com Google: $e');
    }
  }

  Future<void> joinFamily(String familyCode) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Usuário não autenticado');

      final familyDoc = await _firestore
          .collection('families')
          .doc(familyCode)
          .get();

      if (!familyDoc.exists) {
        throw Exception('Código da família inválido');
      }

      await _firestore.collection('users').doc(currentUser.uid).update({
        'familyCode': familyCode,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erro ao entrar na família: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Usuário não autenticado');

      await _firestore.collection('users').doc(currentUser.uid).delete();

      await currentUser.delete();
    } catch (e) {
      throw Exception('Erro ao deletar conta: $e');
    }
  }

  Future<User?> getCurrentUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        return User.fromMap(userDoc.data()!);
      }

      return null;
    } catch (e) {
      throw Exception('Erro ao obter dados do usuário: $e');
    }
  }

  Future<void> updateUserData({String? displayName, String? familyCode}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Usuário não autenticado');

      final updateData = <String, dynamic>{'updatedAt': Timestamp.now()};

      if (displayName != null) {
        updateData['displayName'] = displayName;
        await currentUser.updateDisplayName(displayName);
      }

      if (familyCode != null) {
        updateData['familyCode'] = familyCode;
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update(updateData);
    } catch (e) {
      throw Exception('Erro ao atualizar dados do usuário: $e');
    }
  }

  Future<void> _createUserDocument({
    required String uid,
    required String displayName,
    required String email,
    required String familyCode,
  }) async {
    final user = User(
      uid: uid,
      displayName: displayName,
      email: email,
      familyCode: familyCode,
      fcmTokens: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(user.toMap());
  }

  Future<void> _createFamilyDocument(String familyCode, String ownerUid) async {
    final family = {
      'familyCode': familyCode,
      'ownerUid': ownerUid,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    await _firestore.collection('families').doc(familyCode).set(family);
  }

  Future<void> _updateFcmToken() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final token = await _messaging.getToken();
      if (token == null) return;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final fcmTokens = List<String>.from(userData['fcmTokens'] ?? []);

        if (!fcmTokens.contains(token)) {
          fcmTokens.add(token);
          await _firestore.collection('users').doc(currentUser.uid).update({
            'fcmTokens': fcmTokens,
            'updatedAt': Timestamp.now(),
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao atualizar FCM token: $e');
    }
  }

  String _generateFamilyCode() {
    return _uuid.v4().substring(0, 8).toUpperCase();
  }

  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'email-already-in-use':
        return 'Email já está em uso';
      case 'weak-password':
        return 'Senha muito fraca';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Usuário desabilitado';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }
}
