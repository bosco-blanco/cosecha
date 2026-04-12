import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente Supabase singleton.
/// Inicializar en main.dart antes de runApp.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  /// Usuario actualmente autenticado.
  static User? get currentUser => auth.currentUser;

  /// ID del usuario actual.
  static String? get currentUserId => currentUser?.id;

  /// Stream de cambios de autenticación.
  static Stream<AuthState> get authStateChanges => auth.onAuthStateChange;

  /// Login con email y contraseña.
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return auth.signInWithPassword(email: email, password: password);
  }

  /// Login con PIN: busca empleado por PIN, luego hace signIn con email.
  /// El PIN se valida contra la tabla empleados.
  static Future<Map<String, dynamic>?> findEmpleadoByPin(String pin) async {
    final response = await client
        .from('empleados')
        .select()
        .eq('pin', pin)
        .eq('activo', true)
        .maybeSingle();
    return response;
  }

  /// Cerrar sesión.
  static Future<void> signOut() async {
    await auth.signOut();
  }
}
