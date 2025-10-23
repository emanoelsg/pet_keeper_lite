// features/auth/providers/auth_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        await _loadUserData();
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getCurrentUserData();
      state = AsyncValue.data(userData);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String familyCode,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        familyCode: familyCode,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithGoogle();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> joinFamily(String familyCode) async {
    try {
      await _authService.joinFamily(familyCode);
      await _loadUserData();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateUserData({String? displayName, String? familyCode}) async {
    try {
      await _authService.updateUserData(
        displayName: displayName,
        familyCode: familyCode,
      );
      await _loadUserData();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
