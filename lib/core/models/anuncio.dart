import 'package:equatable/equatable.dart';

enum PrioridadAnuncio { baja, normal, urgente }
enum DestinatarioAnuncio { todos, ubicacion, equipo, rol }

/// Modelo de anuncio — comunicación interna.
class Anuncio extends Equatable {
  final String id;
  final String titulo;
  final String cuerpo;
  final String autorId;
  final PrioridadAnuncio prioridad;
  final DestinatarioAnuncio destinatarios;
  final String? ubicacionId;
  final List<String> leidoPor;
  final bool destacado;
  final DateTime creado;
  final DateTime? expira;

  const Anuncio({
    required this.id,
    required this.titulo,
    required this.cuerpo,
    required this.autorId,
    this.prioridad = PrioridadAnuncio.normal,
    this.destinatarios = DestinatarioAnuncio.todos,
    this.ubicacionId,
    this.leidoPor = const [],
    this.destacado = false,
    required this.creado,
    this.expira,
  });

  bool isLeidoPor(String empleadoId) => leidoPor.contains(empleadoId);
  bool get isExpirado => expira != null && DateTime.now().isAfter(expira!);

  factory Anuncio.fromJson(Map<String, dynamic> json) {
    return Anuncio(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      cuerpo: json['cuerpo'] as String,
      autorId: json['autor_id'] as String,
      prioridad: PrioridadAnuncio.values.firstWhere(
        (p) => p.name == json['prioridad'],
        orElse: () => PrioridadAnuncio.normal,
      ),
      destinatarios: DestinatarioAnuncio.values.firstWhere(
        (d) => d.name == json['destinatarios'],
        orElse: () => DestinatarioAnuncio.todos,
      ),
      ubicacionId: json['ubicacion_id'] as String?,
      leidoPor: (json['leido_por'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      destacado: json['destacado'] as bool? ?? false,
      creado: DateTime.parse(json['created_at'] as String),
      expira: json['expira'] != null
          ? DateTime.parse(json['expira'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'cuerpo': cuerpo,
      'autor_id': autorId,
      'prioridad': prioridad.name,
      'destinatarios': destinatarios.name,
      'ubicacion_id': ubicacionId,
      'destacado': destacado,
      'expira': expira?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id];
}
