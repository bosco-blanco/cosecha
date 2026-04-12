import 'package:flutter/material.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/models/fichaje.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_card.dart';

/// Detalle de un fichaje individual.
class FichajeDetalleScreen extends StatelessWidget {
  final Fichaje fichaje;

  const FichajeDetalleScreen({super.key, required this.fichaje});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ECDBAppBar(title: 'Detalle de Fichaje'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Estado
          ECDBCard(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: (fichaje.isEntrada
                            ? ECDBColors.success
                            : ECDBColors.error)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    fichaje.isEntrada ? Icons.login : Icons.logout,
                    size: 32,
                    color:
                        fichaje.isEntrada ? ECDBColors.success : ECDBColors.error,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  fichaje.isEntrada ? 'Entrada' : 'Salida',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  CosechaDateUtils.formatDateTime(fichaje.timestamp),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ECDBColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),

          // Detalles
          ECDBCard(
            child: Column(
              children: [
                _DetailRow(label: 'Empleado', value: fichaje.empleadoNombre),
                const Divider(),
                _DetailRow(
                  label: 'Método',
                  value: fichaje.metodo.name.toUpperCase(),
                ),
                const Divider(),
                _DetailRow(
                  label: 'Válido',
                  value: fichaje.valido ? 'Sí' : 'No — fuera de rango',
                  valueColor: fichaje.valido ? ECDBColors.success : ECDBColors.error,
                ),
                if (fichaje.distanciaAlCentro != null) ...[
                  const Divider(),
                  _DetailRow(
                    label: 'Distancia al centro',
                    value: GeoUtils.formatDistance(fichaje.distanciaAlCentro!),
                  ),
                ],
                if (fichaje.latitud != null && fichaje.longitud != null) ...[
                  const Divider(),
                  _DetailRow(
                    label: 'Coordenadas',
                    value:
                        '${fichaje.latitud!.toStringAsFixed(6)}, ${fichaje.longitud!.toStringAsFixed(6)}',
                  ),
                ],
                if (fichaje.dispositivo != null) ...[
                  const Divider(),
                  _DetailRow(label: 'Dispositivo', value: fichaje.dispositivo!),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Los fichajes son inmutables. Solo un administrador puede hacer correcciones manuales.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ECDBColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ECDBColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
