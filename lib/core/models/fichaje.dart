import 'package:equatable/equatable.dart';

enum TipoFichaje { entrada, salida }
enum MetodoFichaje { app, qr, manual }

/// Modelo de fichaje — registro inmutable de entrada/salida.
/// Cumplimiento legal: RD-ley 8/2019.
class Fichaje extends Equatable {
  final String id;
  final String empleadoId;
  final String empleadoNombre;
  final TipoFichaje tipo;
  final DateTime timestamp;
  final double? latitud;
  final double? longitud;
  final String? ubicacionId;
  final double? distanciaAlCentro;
  final bool valido;
  final MetodoFichaje metodo;
  final String? dispositivo;
  final String? ipAddress;
  final DateTime creado;

  const Fichaje({
    required this.id,
    required this.empleadoId,
    required this.empleadoNombre,
    required this.tipo,
    required this.timestamp,
    this.latitud,
    this.longitud,
    this.ubicacionId,
    this.distanciaAlCentro,
    this.valido = true,
    this.metodo = MetodoFichaje.app,
    this.dispositivo,
    this.ipAddress,
    required this.creado,
  });

  bool get isEntrada => tipo == TipoFichaje.entrada;
  bool get isSalida => tipo == TipoFichaje.salida;
  bool get isDentroDeRango => valido;

  factory Fichaje.fromJson(Map<String, dynamic> json) {
    return Fichaje(
      id: json['id'] as String,
      empleadoId: json['empleado_id'] as String,
      empleadoNombre: json['empleado_nombre'] as String,
      tipo: json['tipo'] == 'entrada' ? TipoFichaje.entrada : TipoFichaje.salida,
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      ubicacionId: json['ubicacion_id'] as String?,
      distanciaAlCentro: (json['distancia_al_centro'] as num?)?.toDouble(),
      valido: json['valido'] as bool? ?? true,
      metodo: MetodoFichaje.values.firstWhere(
        (m) => m.name == json['metodo'],
        orElse: () => MetodoFichaje.app,
      ),
      dispositivo: json['dispositivo'] as String?,
      ipAddress: json['ip_address'] as String?,
      creado: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'empleado_id': empleadoId,
      'empleado_nombre': empleadoNombre,
      'tipo': tipo.name,
      'timestamp': timestamp.toIso8601String(),
      'latitud': latitud,
      'longitud': longitud,
      'ubicacion_id': ubicacionId,
      'distancia_al_centro': distanciaAlCentro,
      'valido': valido,
      'metodo': metodo.name,
      'dispositivo': dispositivo,
      'ip_address': ipAddress,
    };
  }

  @override
  List<Object?> get props => [id];
}
