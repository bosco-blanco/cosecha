import 'package:equatable/equatable.dart';

enum CategoriaSolicitud { it, rrhh, mantenimiento, admin, otro }
enum EstadoSolicitud { nueva, enProceso, resuelta, cerrada }
enum PrioridadSolicitud { baja, normal, alta }

/// Modelo de solicitud — Portal del Empleado (help desk).
class Solicitud extends Equatable {
  final String id;
  final String empleadoId;
  final CategoriaSolicitud categoria;
  final String titulo;
  final String descripcion;
  final PrioridadSolicitud prioridad;
  final EstadoSolicitud estado;
  final String? asignadoA;
  final String? respuesta;
  final DateTime creado;
  final DateTime? resueltoEn;
  final int? satisfaccion;

  const Solicitud({
    required this.id,
    required this.empleadoId,
    required this.categoria,
    required this.titulo,
    required this.descripcion,
    this.prioridad = PrioridadSolicitud.normal,
    this.estado = EstadoSolicitud.nueva,
    this.asignadoA,
    this.respuesta,
    required this.creado,
    this.resueltoEn,
    this.satisfaccion,
  });

  factory Solicitud.fromJson(Map<String, dynamic> json) {
    return Solicitud(
      id: json['id'] as String,
      empleadoId: json['empleado_id'] as String,
      categoria: CategoriaSolicitud.values.firstWhere(
        (c) => c.name == json['categoria'],
        orElse: () => CategoriaSolicitud.otro,
      ),
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      prioridad: PrioridadSolicitud.values.firstWhere(
        (p) => p.name == json['prioridad'],
        orElse: () => PrioridadSolicitud.normal,
      ),
      estado: EstadoSolicitud.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoSolicitud.nueva,
      ),
      asignadoA: json['asignado_a'] as String?,
      respuesta: json['respuesta'] as String?,
      creado: DateTime.parse(json['created_at'] as String),
      resueltoEn: json['resuelto_en'] != null
          ? DateTime.parse(json['resuelto_en'] as String)
          : null,
      satisfaccion: json['satisfaccion'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'empleado_id': empleadoId,
      'categoria': categoria.name,
      'titulo': titulo,
      'descripcion': descripcion,
      'prioridad': prioridad.name,
      'estado': estado.name,
      'asignado_a': asignadoA,
      'respuesta': respuesta,
    };
  }

  @override
  List<Object?> get props => [id];
}
