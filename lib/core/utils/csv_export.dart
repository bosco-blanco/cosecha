import 'package:csv/csv.dart';
import '../models/fichaje.dart';
import 'date_utils.dart';

/// Exportar fichajes a CSV para inspecciones laborales (RD-ley 8/2019).
class CsvExport {
  CsvExport._();

  /// Genera CSV de fichajes en formato requerido por inspección laboral.
  static String fichajesACsv(List<Fichaje> fichajes) {
    final headers = [
      'ID Empleado',
      'Nombre Empleado',
      'Tipo',
      'Fecha',
      'Hora',
      'Latitud',
      'Longitud',
      'Ubicación ID',
      'Distancia al Centro (m)',
      'Válido',
      'Método',
      'Dispositivo',
    ];

    final rows = fichajes.map((f) => [
      f.empleadoId,
      f.empleadoNombre,
      f.tipo == TipoFichaje.entrada ? 'Entrada' : 'Salida',
      CosechaDateUtils.formatDate(f.timestamp),
      CosechaDateUtils.formatTime(f.timestamp),
      f.latitud?.toStringAsFixed(6) ?? '',
      f.longitud?.toStringAsFixed(6) ?? '',
      f.ubicacionId ?? '',
      f.distanciaAlCentro?.round().toString() ?? '',
      f.valido ? 'Sí' : 'No',
      f.metodo.name.toUpperCase(),
      f.dispositivo ?? '',
    ]);

    return const ListToCsvConverter().convert([headers, ...rows]);
  }
}
