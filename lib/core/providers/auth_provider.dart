import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/empleado.dart';
import '../services/supabase_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final Empleado? empleado;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.empleado,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, Empleado? empleado, String? error}) {
    return AuthState(
      status: status ?? this.status,
      empleado: empleado ?? this.empleado,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// Login por PIN (4 dígitos).
  Future<void> signInWithPin(String pin) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      debugPrint('[Auth] Validando PIN...');
      final result = await SupabaseService.client.rpc(
        'validate_pin',
        params: {'pin_code': pin},
      );

      debugPrint('[Auth] Resultado RPC: $result');

      if (result == null) {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          error: 'PIN incorrecto.',
        );
        return;
      }

      final empleado = Empleado.fromJson(result as Map<String, dynamic>);
      debugPrint('[Auth] Login OK: ${empleado.nombre} (${empleado.rol})');

      state = AuthState(
        status: AuthStatus.authenticated,
        empleado: empleado,
      );
    } catch (e) {
      debugPrint('[Auth] Error: $e');
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Error de conexión: $e',
      );
    }
  }

  /// Login por email + PIN.
  Future<void> signInWithEmail(String email, String password) async {
    await signInWithPin(password);
    if (state.empleado != null && state.empleado!.email != email) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Email o contraseña incorrectos.',
      );
    }
  }

  Future<void> signOut() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentEmpleadoProvider = Provider<Empleado?>((ref) {
  return ref.watch(authProvider).empleado;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});
