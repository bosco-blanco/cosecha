import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/empleado.dart';
import '../services/supabase_service.dart';

/// Estado de autenticación.
enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final Empleado? empleado;
  final String? error;

  const AuthState({
    this.status = AuthStatus.loading,
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
  AuthNotifier() : super(const AuthState(status: AuthStatus.unauthenticated));

  /// Login por PIN (4 dígitos).
  /// Usa la función RPC `validate_pin` que bypasa RLS.
  Future<void> signInWithPin(String pin) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final result = await SupabaseService.client.rpc(
        'validate_pin',
        params: {'pin_code': pin},
      );

      if (result == null) {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          error: 'PIN incorrecto.',
        );
        return;
      }

      final empleadoData = result as Map<String, dynamic>;
      final empleado = Empleado.fromJson(empleadoData);

      state = AuthState(
        status: AuthStatus.authenticated,
        empleado: empleado,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Error de conexión. Inténtalo de nuevo.',
      );
    }
  }

  /// Login por email + contraseña (Supabase Auth).
  Future<void> signInWithEmail(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      // Buscar empleado por email usando RPC con PIN = password
      final result = await SupabaseService.client.rpc(
        'validate_pin',
        params: {'pin_code': password},
      );

      if (result == null) {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          error: 'Credenciales incorrectas.',
        );
        return;
      }

      final empleadoData = result as Map<String, dynamic>;
      if (empleadoData['email'] != email) {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          error: 'Email o contraseña incorrectos.',
        );
        return;
      }

      final empleado = Empleado.fromJson(empleadoData);
      state = AuthState(
        status: AuthStatus.authenticated,
        empleado: empleado,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Error de conexión. Inténtalo de nuevo.',
      );
    }
  }

  /// Cerrar sesión.
  Future<void> signOut() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Limpiar error.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider global de autenticación.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Atajo: empleado actual.
final currentEmpleadoProvider = Provider<Empleado?>((ref) {
  return ref.watch(authProvider).empleado;
});

/// Atajo: está autenticado.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});
