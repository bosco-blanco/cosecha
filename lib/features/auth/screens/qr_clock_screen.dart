import 'package:flutter/material.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';

/// Pantalla de fichaje por QR — el empleado escanea el QR del local.
/// Placeholder para Sprint 2.
class QrClockScreen extends StatelessWidget {
  const QrClockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ECDBAppBar(title: 'Fichar con QR'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: ECDBColors.bgAlt,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  size: 64,
                  color: ECDBColors.wine,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Escanea el QR de tu local',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Apunta la cámara al código QR ubicado en la entrada de tu local para fichar automáticamente.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ECDBColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: null, // Habilitado en Sprint 2
                icon: const Icon(Icons.camera_alt),
                label: const Text('Abrir cámara'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
