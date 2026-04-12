import 'package:equatable/equatable.dart';

enum TipoVisita { presencial, llamada, email, videollamada }
enum ResultadoVisita { exitosa, sinInteres, pospuesto }

/// Modelo de visita comercial — CRM Comercial.
class VisitaComercial extends Equatable {
  final String id;
  final String comercialId;
  final String contactoId;
  final TipoVisita tipo;
  final DateTime fecha;
  final int? duracion;
  final String? ubicacion;
  final double? latitud;
  final double? longitud;
  final double? distancia;
  final String? notas;
  final String? siguientePaso;
  final String? dealId;
  final ResultadoVisita? resultado;
  final DateTime creado;

  const VisitaComercial({
    required this.id,
    required this.comercialId,
    required this.contactoId,
    required this.tipo,
    required this.fecha,
    this.duracion,
    this.ubicacion,
    this.latitud,
    this.longitud,
    this.distancia,
    this.notas,
    this.siguientePaso,
    this.dealId,
    this.resultado,
    required this.creado,
  });

  factory VisitaComercial.fromJson(Map<String, dynamic> json) {
    return VisitaComercial(
      id: json['id'] as String,
      comercialId: json['comercial_id'] as String,
      contactoId: json['contacto_id'] as String,
      tipo: TipoVisita.values.firstWhere(
        (t) => t.name == json['tipo'],
        orElse: () => TipoVisita.presencial,
      ),
      fecha: DateTime.parse(json['fecha'] as String),
      duracion: json['duracion'] as int?,
      ubicacion: json['ubicacion'] as String?,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      distancia: (json['distancia'] as num?)?.toDouble(),
      notas: json['notas'] as String?,
      siguientePaso: json['siguiente_paso'] as String?,
      dealId: json['deal_id'] as String?,
      resultado: json['resultado'] != null
          ? ResultadoVisita.values.firstWhere(
              (r) => r.name == json['resultado'],
              orElse: () => ResultadoVisita.exitosa,
            )
          : null,
      creado: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comercial_id': comercialId,
      'contacto_id': contactoId,
      'tipo': tipo.name,
      'fecha': fecha.toIso8601String(),
      'duracion': duracion,
      'ubicacion': ubicacion,
      'latitud': latitud,
      'longitud': longitud,
      'distancia': distancia,
      'notas': notas,
      'siguiente_paso': siguientePaso,
      'deal_id': dealId,
      'resultado': resultado?.name,
    };
  }

  @override
  List<Object?> get props => [id];
}
