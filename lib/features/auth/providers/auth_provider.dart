// features/auth/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'auth_notifier.dart'; // separei a classe AuthNotifier

// Provider do AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider do AuthNotifier, que já contém toda a lógica de estado
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
  (ref) {
    final authService = ref.watch(authServiceProvider);
    return AuthNotifier(authService);
  },
);

// Providers auxiliares baseados no estado do AuthNotifier

// Estado de autenticação
final authStateProvider = Provider<AuthState>((ref) {
  final state = ref.watch(authNotifierProvider);
  return state.hasValue
      ? AuthState.authenticated
      : state.hasError
          ? AuthState.error
          : AuthState.unauthenticated;
});

// Verifica se o usuário tem família
final hasFamilyProvider = Provider<bool>((ref) {
  final user = ref.watch(authNotifierProvider).value;
  return user?.familyCode.isNotEmpty == true;
});

// Código da família
final familyCodeProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).value?.familyCode;
});

// Verifica se é o dono da família
final isFamilyOwnerProvider = Provider<bool>((ref) {
  final user = ref.watch(authNotifierProvider).value;
  final familyCode = ref.watch(familyCodeProvider);
  if (user == null || familyCode == null) return false;

  // Exemplo: primeiro usuário da família é dono
  return true;
});

// Enum de estados de autenticação
enum AuthState {
  loading,
  authenticated,
  unauthenticated,
  error,
}
