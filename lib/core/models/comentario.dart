import 'package:equatable/equatable.dart';

enum TipoEntidad { tarea, contacto, deal, reunion }

/// Modelo de comentario — polimórfico (tareas, contactos, deals, reuniones).
class Comentario extends Equatable {
  final String id;
  final TipoEntidad entidadTipo;
  final String entidadId;
  final String autorId;
  final String autorNombre;
  final String texto;
  final List<String> menciones;
  final DateTime creado;
  final DateTime? actualizadoEn;

  const Comentario({
    required this.id,
    required this.entidadTipo,
    required this.entidadId,
    required this.autorId,
    required this.autorNombre,
    required this.texto,
    this.menciones = const [],
    required this.creado,
    this.actualizadoEn,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'] as String,
      entidadTipo: TipoEntidad.values.firstWhere(
        (t) => t.name == json['entidad_tipo'],
        orElse: () => TipoEntidad.tarea,
      ),
      entidadId: json['entidad_id'] as String,
      autorId: json['autor_id'] as String,
      autorNombre: json['autor_nombre'] as String,
      texto: json['texto'] as String,
      menciones: (json['menciones'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      creado: DateTime.parse(json['created_at'] as String),
      actualizadoEn: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entidad_tipo': entidadTipo.name,
      'entidad_id': entidadId,
      'autor_id': autorId,
      'autor_nombre': autorNombre,
      'texto': texto,
      'menciones': menciones,
    };
  }

  @override
  List<Object?> get props => [id];
}
