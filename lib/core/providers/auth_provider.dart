import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
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
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  void _init() {
    // Escuchar cambios de auth de Supabase.
    SupabaseService.authStateChanges.listen((data) async {
      final session = data.session;
      if (session != null) {
        await _loadEmpleado(session.user.id);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });

    // Comprobar sesión existente.
    final currentUser = SupabaseService.currentUser;
    if (currentUser != null) {
      _loadEmpleado(currentUser.id);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _loadEmpleado(String userId) async {
    try {
      final data = await SupabaseService.client
          .from('empleados')
          .select()
          .eq('id', userId)
          .single();
      final empleado = Empleado.fromJson(data);
      state = AuthState(
        status: AuthStatus.authenticated,
        empleado: empleado,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: 'No se encontró el perfil de empleado.',
      );
    }
  }

  /// Login por email + contraseña.
  Future<void> signInWithEmail(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await SupabaseService.signInWithEmail(email: email, password: password);
      // El listener de authStateChanges se encargará del resto.
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _translateAuthError(e.message),
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Error de conexión. Inténtalo de nuevo.',
      );
    }
  }

  /// Login por PIN (4 dígitos).
  /// Busca el empleado por PIN, luego hace signIn con su email.
  Future<void> signInWithPin(String pin) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final empleadoData = await SupabaseService.findEmpleadoByPin(pin);
      if (empleadoData == null) {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          error: 'PIN incorrecto.',
        );
        return;
      }

      final email = empleadoData['email'] as String;
      // Para PIN login, usamos una contraseña derivada del PIN
      // configurada al crear el empleado en Supabase Auth.
      await SupabaseService.signInWithEmail(email: email, password: pin);
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _translateAuthError(e.message),
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
    await SupabaseService.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Limpiar error.
  void clearError() {
    state = state.copyWith(error: null);
  }

  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email o contraseña incorrectos.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Confirma tu email antes de iniciar sesión.';
    }
    return 'Error de autenticación: $message';
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
