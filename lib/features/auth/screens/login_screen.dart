import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/ecdb_button.dart';
import '../../../shared/widgets/ecdb_toast.dart';
import '../widgets/pin_keyboard.dart';

/// Pantalla de login — PIN (principal) + email/password (alternativa).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _showEmailLogin = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _pin = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onPinDigit(String digit) {
    if (_pin.length < 4) {
      setState(() => _pin += digit);
      HapticFeedback.lightImpact();

      if (_pin.length == 4) {
        _loginWithPin();
      }
    }
  }

  void _onPinDelete() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _loginWithPin() async {
    await ref.read(authProvider.notifier).signInWithPin(_pin);
    final error = ref.read(authProvider).error;
    if (error != null && mounted) {
      ECDBToast.show(context, message: error, type: ToastType.error);
      setState(() => _pin = '');
    }
  }

  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ECDBToast.show(
        context,
        message: 'Introduce email y contraseña.',
        type: ToastType.warning,
      );
      return;
    }
    await ref.read(authProvider.notifier).signInWithEmail(email, password);
    final error = ref.read(authProvider).error;
    if (error != null && mounted) {
      ECDBToast.show(context, message: error, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: ECDBColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo ECDB
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ECDBColors.wine,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'C',
                    style: TextStyle(
                      color: ECDBColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 40,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Cosecha',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'En Copa de Balón',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ECDBColors.textSecondary,
                    ),
              ),

              const SizedBox(height: 48),

              if (!_showEmailLogin) ...[
                // ── Login por PIN ──
                Text(
                  'Introduce tu PIN',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),

                // Indicadores de PIN
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final filled = index < _pin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? ECDBColors.wine : Colors.transparent,
                        border: Border.all(
                          color: filled ? ECDBColors.wine : ECDBColors.textMuted,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                if (isLoading)
                  const CircularProgressIndicator(color: ECDBColors.wine)
                else
                  PinKeyboard(
                    onDigit: _onPinDigit,
                    onDelete: _onPinDelete,
                  ),

                const SizedBox(height: 32),

                TextButton(
                  onPressed: () => setState(() => _showEmailLogin = true),
                  child: Text(
                    'Usar email y contraseña',
                    style: TextStyle(color: ECDBColors.textSecondary),
                  ),
                ),
              ] else ...[
                // ── Login por email ──
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  onSubmitted: (_) => _loginWithEmail(),
                ),
                const SizedBox(height: 24),

                ECDBButton(
                  label: 'Iniciar Sesión',
                  isExpanded: true,
                  isLoading: isLoading,
                  onPressed: _loginWithEmail,
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => setState(() {
                    _showEmailLogin = false;
                    _pin = '';
                  }),
                  child: Text(
                    'Usar PIN',
                    style: TextStyle(color: ECDBColors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
