import 'package:equatable/equatable.dart';

enum TipoDeal { codeba, evento }

/// Modelo de oportunidad / deal — CRM Comercial.
class Deal extends Equatable {
  final String id;
  final String titulo;
  final TipoDeal tipo;
  final String? contactoId;
  final String? contactoNombre;
  final double valor;
  final String etapa;
  final int probabilidad;
  final DateTime? cierreEsperado;
  final String? asignadoId;
  final String? notas;
  final String creadoPor;
  final DateTime creado;
  final DateTime? actualizadoEn;

  const Deal({
    required this.id,
    required this.titulo,
    required this.tipo,
    this.contactoId,
    this.contactoNombre,
    this.valor = 0,
    required this.etapa,
    this.probabilidad = 0,
    this.cierreEsperado,
    this.asignadoId,
    this.notas,
    required this.creadoPor,
    required this.creado,
    this.actualizadoEn,
  });

  double get valorEsperado => valor * probabilidad / 100;

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      tipo: json['tipo'] == 'codeba' ? TipoDeal.codeba : TipoDeal.evento,
      contactoId: json['contacto_id'] as String?,
      contactoNombre: json['contacto_nombre'] as String?,
      valor: (json['valor'] as num?)?.toDouble() ?? 0,
      etapa: json['etapa'] as String,
      probabilidad: json['probabilidad'] as int? ?? 0,
      cierreEsperado: json['cierre_esperado'] != null
          ? DateTime.parse(json['cierre_esperado'] as String)
          : null,
      asignadoId: json['asignado_id'] as String?,
      notas: json['notas'] as String?,
      creadoPor: json['creado_por'] as String,
      creado: DateTime.parse(json['created_at'] as String),
      actualizadoEn: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'tipo': tipo.name,
      'contacto_id': contactoId,
      'contacto_nombre': contactoNombre,
      'valor': valor,
      'etapa': etapa,
      'probabilidad': probabilidad,
      'cierre_esperado': cierreEsperado?.toIso8601String(),
      'asignado_id': asignadoId,
      'notas': notas,
      'creado_por': creadoPor,
    };
  }

  /// Etapas del pipeline CODEBA.
  static const List<String> etapasCodeba = [
    'prospeccion',
    'primera_visita',
    'degustacion',
    'presupuesto',
    'pedido',
    'servicio_activo',
  ];

  /// Etapas del pipeline Eventos.
  static const List<String> etapasEventos = [
    'lead',
    'briefing',
    'propuesta_enviada',
    'negociacion',
    'confirmado',
    'ejecutado',
    'facturado',
  ];

  @override
  List<Object?> get props => [id];
}
