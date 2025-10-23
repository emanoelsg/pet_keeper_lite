// features/auth/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'auth_notifier.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
      final authService = ref.watch(authServiceProvider);
      return AuthNotifier(authService);
    });

final authStateProvider = Provider<AuthState>((ref) {
  final state = ref.watch(authNotifierProvider);
  return state.hasValue
      ? AuthState.authenticated
      : state.hasError
      ? AuthState.error
      : AuthState.unauthenticated;
});

final hasFamilyProvider = Provider<bool>((ref) {
  final user = ref.watch(authNotifierProvider).value;
  return user?.familyCode.isNotEmpty == true;
});

final familyCodeProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).value?.familyCode;
});

final isFamilyOwnerProvider = Provider<bool>((ref) {
  final user = ref.watch(authNotifierProvider).value;
  final familyCode = ref.watch(familyCodeProvider);
  if (user == null || familyCode == null) return false;

  return true;
});

enum AuthState { loading, authenticated, unauthenticated, error }
