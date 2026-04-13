import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/providers/fichaje_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/ecdb_toast.dart';

/// Widget principal de fichaje — prominente en el Dashboard.
/// 3 estados: sin fichar (botón verde), trabajando (timer + rojo), pausa.
class ClockWidget extends ConsumerWidget {
  const ClockWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fichaje = ref.watch(fichajeProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ECDBColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ECDBColors.border, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Estado actual
          _StatusIndicator(estado: fichaje.estado, horaEntrada: fichaje.horaEntrada),
          const SizedBox(height: 20),

          // Timer (solo si trabajando)
          if (fichaje.estado == EstadoFichaje.trabajando) ...[
            _TimerDisplay(duration: fichaje.tiempoTrabajado),
            const SizedBox(height: 20),
          ],

          // Botón principal
          _ClockButton(
            estado: fichaje.estado,
            isLoading: fichaje.isLoading,
            onPressed: () => _handleClockAction(context, ref),
          ),

          // Info de último fichaje
          if (fichaje.ultimoFichaje != null) ...[
            const SizedBox(height: 16),
            _LastClockInfo(fichaje: fichaje),
          ],
        ],
      ),
    );
  }

  Future<void> _handleClockAction(BuildContext context, WidgetRef ref) async {
    final estado = ref.read(fichajeProvider).estado;
    HapticFeedback.heavyImpact();

    if (estado == EstadoFichaje.sinFichar) {
      // Fichar entrada
      final result = await ref.read(fichajeProvider.notifier).ficharEntrada();
      if (context.mounted) {
        if (result.ok) {
          final distMsg = result.distancia != null
              ? ' (${result.distancia!.round()}m del centro)'
              : '';
          final validMsg = result.dentroDeRango == false
              ? ' - Fuera del rango permitido'
              : '';
          ECDBToast.show(
            context,
            message: 'Entrada registrada$distMsg$validMsg',
            type: result.dentroDeRango != false
                ? ToastType.success
                : ToastType.warning,
          );
        } else {
          ECDBToast.show(
            context,
            message: result.errorMessage ?? 'Error al fichar',
            type: ToastType.error,
          );
        }
      }
    } else if (estado == EstadoFichaje.trabajando) {
      // Confirmar salida
      final confirmar = await _showConfirmDialog(context);
      if (confirmar == true) {
        final result = await ref.read(fichajeProvider.notifier).ficharSalida();
        if (context.mounted) {
          if (result.ok) {
            ECDBToast.show(
              context,
              message: 'Salida registrada. Buen trabajo!',
              type: ToastType.success,
            );
          } else {
            ECDBToast.show(
              context,
              message: result.errorMessage ?? 'Error al fichar',
              type: ToastType.error,
            );
          }
        }
      }
    }
  }

  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.exit_to_app, size: 48, color: ECDBColors.error),
              const SizedBox(height: 16),
              Text(
                'Fichar salida',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Se registrará tu salida con la hora y ubicación actual.',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: ECDBColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ECDBColors.error,
                      ),
                      child: const Text('Fichar Salida'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicador de estado (icono + texto).
class _StatusIndicator extends StatelessWidget {
  final EstadoFichaje estado;
  final DateTime? horaEntrada;

  const _StatusIndicator({required this.estado, this.horaEntrada});

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = switch (estado) {
      EstadoFichaje.sinFichar => (
          Icons.circle_outlined,
          ECDBColors.textMuted,
          'No has fichado hoy',
        ),
      EstadoFichaje.trabajando => (
          Icons.circle,
          ECDBColors.success,
          'Trabajando desde las ${horaEntrada != null ? CosechaDateUtils.formatTime(horaEntrada!) : "--:--"}',
        ),
      EstadoFichaje.enPausa => (
          Icons.pause_circle,
          ECDBColors.warning,
          'En pausa',
        ),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ECDBColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

/// Display del timer con formato HH:MM:SS.
class _TimerDisplay extends StatelessWidget {
  final Duration duration;

  const _TimerDisplay({required this.duration});

  @override
  Widget build(BuildContext context) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return Text(
      '$hours:$minutes:$seconds',
      style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
            fontFamily: 'Inter',
            color: ECDBColors.textPrimary,
          ),
    );
  }
}

/// Botón grande de fichaje — verde (entrada), rojo (salida).
class _ClockButton extends StatelessWidget {
  final EstadoFichaje estado;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ClockButton({
    required this.estado,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (estado) {
      EstadoFichaje.sinFichar => (
          ECDBColors.success,
          'FICHAR ENTRADA',
          Icons.login,
        ),
      EstadoFichaje.trabajando => (
          ECDBColors.error,
          'FICHAR SALIDA',
          Icons.logout,
        ),
      EstadoFichaje.enPausa => (
          ECDBColors.warning,
          'REANUDAR',
          Icons.play_arrow,
        ),
    };

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Info del último fichaje.
class _LastClockInfo extends StatelessWidget {
  final FichajeState fichaje;

  const _LastClockInfo({required this.fichaje});

  @override
  Widget build(BuildContext context) {
    final f = fichaje.ultimoFichaje!;
    final tipoStr = f.isEntrada ? 'Entrada' : 'Salida';
    final horaStr = CosechaDateUtils.formatTime(f.timestamp);
    final metodoStr = f.metodo.name.toUpperCase();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          f.valido ? Icons.check_circle : Icons.warning_amber,
          size: 14,
          color: f.valido ? ECDBColors.success : ECDBColors.warning,
        ),
        const SizedBox(width: 6),
        Text(
          'Último: $tipoStr a las $horaStr ($metodoStr)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ECDBColors.textMuted,
              ),
        ),
      ],
    );
  }
}
