import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/services/qr_service.dart';
import '../../../core/providers/fichaje_provider.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_toast.dart';

/// Pantalla de fichaje por QR — escanea el QR del local para fichar.
class QrClockScreen extends ConsumerStatefulWidget {
  const QrClockScreen({super.key});

  @override
  ConsumerState<QrClockScreen> createState() => _QrClockScreenState();
}

class _QrClockScreenState extends ConsumerState<QrClockScreen> {
  bool _processing = false;
  String? _lastScanned;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ECDBAppBar(title: 'Fichar con QR'),
      body: Column(
        children: [
          // Instrucciones
          Container(
            padding: const EdgeInsets.all(20),
            color: ECDBColors.wine.withOpacity(0.05),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: ECDBColors.wine),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Apunta la cámara al código QR de tu local para fichar automáticamente.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ECDBColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // Scanner
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  onDetect: (capture) => _onQrDetected(capture),
                ),
                // Overlay con marco
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: ECDBColors.gold, width: 3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                if (_processing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: ECDBColors.gold),
                    ),
                  ),
              ],
            ),
          ),

          // Estado
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _processing
                    ? 'Procesando fichaje...'
                    : 'Esperando código QR...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ECDBColors.textSecondary,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final content = barcode.rawValue!;
    if (content == _lastScanned) return; // Evitar escaneos duplicados

    setState(() {
      _processing = true;
      _lastScanned = content;
    });

    HapticFeedback.mediumImpact();

    try {
      // Parsear QR
      final parsed = QrService.parseQrContent(content);
      if (parsed.qrCode == null) {
        if (mounted) {
          ECDBToast.show(context,
              message: 'QR no válido', type: ToastType.error);
        }
        setState(() => _processing = false);
        return;
      }

      // Validar QR contra la base de datos
      final ubicacion = await QrService.validateQr(parsed.qrCode!);
      if (ubicacion == null) {
        if (mounted) {
          ECDBToast.show(context,
              message: 'QR no reconocido o ubicación inactiva',
              type: ToastType.error);
        }
        setState(() => _processing = false);
        return;
      }

      // Fichar con método QR
      final result = await ref.read(fichajeProvider.notifier).ficharEntrada(
            metodo: 'qr',
            ubicacionId: ubicacion['id'] as String,
          );

      if (mounted) {
        if (result.ok) {
          ECDBToast.show(
            context,
            message: 'Fichaje registrado en ${ubicacion['nombre']}',
            type: ToastType.success,
          );
          Navigator.pop(context);
        } else {
          ECDBToast.show(context,
              message: result.errorMessage ?? 'Error',
              type: ToastType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        ECDBToast.show(context,
            message: 'Error al procesar QR', type: ToastType.error);
      }
    }

    if (mounted) {
      setState(() => _processing = false);
    }
  }
}
