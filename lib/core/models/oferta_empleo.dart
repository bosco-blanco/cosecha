import 'package:equatable/equatable.dart';

enum TipoContrato { indefinido, temporal, practicas }
enum EstadoOferta { abierta, cerrada, completada }

/// Modelo de oferta de empleo — Portal del Empleado.
class OfertaEmpleo extends Equatable {
  final String id;
  final String titulo;
  final String? ubicacionId;
  final String? departamento;
  final String descripcion;
  final List<String> requisitos;
  final String? salario;
  final TipoContrato tipoContrato;
  final EstadoOferta estado;
  final DateTime creado;
  final DateTime? cierre;

  const OfertaEmpleo({
    required this.id,
    required this.titulo,
    this.ubicacionId,
    this.departamento,
    required this.descripcion,
    this.requisitos = const [],
    this.salario,
    this.tipoContrato = TipoContrato.indefinido,
    this.estado = EstadoOferta.abierta,
    required this.creado,
    this.cierre,
  });

  factory OfertaEmpleo.fromJson(Map<String, dynamic> json) {
    return OfertaEmpleo(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      ubicacionId: json['ubicacion_id'] as String?,
      departamento: json['departamento'] as String?,
      descripcion: json['descripcion'] as String,
      requisitos: (json['requisitos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      salario: json['salario'] as String?,
      tipoContrato: TipoContrato.values.firstWhere(
        (t) => t.name == json['tipo_contrato'],
        orElse: () => TipoContrato.indefinido,
      ),
      estado: EstadoOferta.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoOferta.abierta,
      ),
      creado: DateTime.parse(json['created_at'] as String),
      cierre: json['cierre'] != null
          ? DateTime.parse(json['cierre'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'ubicacion_id': ubicacionId,
      'departamento': departamento,
      'descripcion': descripcion,
      'requisitos': requisitos,
      'salario': salario,
      'tipo_contrato': tipoContrato.name,
      'estado': estado.name,
      'cierre': cierre?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id];
}
