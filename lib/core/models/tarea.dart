import 'package:equatable/equatable.dart';

enum ColumnaTarea { backlog, enProgreso, revision, completado }
enum PrioridadTarea { baja, normal, alta, critica }

/// Modelo de tarea — módulo CRM Interno.
class Tarea extends Equatable {
  final String id;
  final String titulo;
  final String? descripcion;
  final ColumnaTarea columna;
  final PrioridadTarea prioridad;
  final List<String> etiquetas;
  final DateTime? fechaLimite;
  final List<String> asignados;
  final String? proyectoId;
  final String creadoPor;
  final DateTime creado;
  final DateTime? completadoEn;
  final String? completadoPor;
  final DateTime? actualizadoEn;

  const Tarea({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.columna = ColumnaTarea.backlog,
    this.prioridad = PrioridadTarea.normal,
    this.etiquetas = const [],
    this.fechaLimite,
    this.asignados = const [],
    this.proyectoId,
    required this.creadoPor,
    required this.creado,
    this.completadoEn,
    this.completadoPor,
    this.actualizadoEn,
  });

  bool get isCompleted => columna == ColumnaTarea.completado;

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      columna: ColumnaTarea.values.firstWhere(
        (c) => c.name == json['columna'],
        orElse: () => ColumnaTarea.backlog,
      ),
      prioridad: PrioridadTarea.values.firstWhere(
        (p) => p.name == json['prioridad'],
        orElse: () => PrioridadTarea.normal,
      ),
      etiquetas: (json['etiquetas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      fechaLimite: json['fecha_limite'] != null
          ? DateTime.parse(json['fecha_limite'] as String)
          : null,
      asignados: (json['asignados'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      proyectoId: json['proyecto_id'] as String?,
      creadoPor: json['creado_por'] as String,
      creado: DateTime.parse(json['created_at'] as String),
      completadoEn: json['completado_en'] != null
          ? DateTime.parse(json['completado_en'] as String)
          : null,
      completadoPor: json['completado_por'] as String?,
      actualizadoEn: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'columna': columna.name,
      'prioridad': prioridad.name,
      'etiquetas': etiquetas,
      'fecha_limite': fechaLimite?.toIso8601String(),
      'asignados': asignados,
      'proyecto_id': proyectoId,
      'creado_por': creadoPor,
    };
  }

  @override
  List<Object?> get props => [id];
}
