import 'package:equatable/equatable.dart';

enum EstadoReferido { enviado, enProceso, contratado, descartado }

/// Modelo de referido — programa de referidos del Portal del Empleado.
/// Bonificación: 200EUR si el referido cumple 6 meses.
class Referido extends Equatable {
  final String id;
  final String referidoPorId;
  final String referidoPorNombre;
  final String candidatoNombre;
  final String? candidatoTelefono;
  final String? candidatoEmail;
  final String? puestoId;
  final String? puestoTitulo;
  final EstadoReferido estado;
  final DateTime fechaEnvio;
  final DateTime? fechaContratacion;
  final DateTime? fechaBonificacion;
  final double montoBonificacion;
  final bool notificacionEnviada;
  final String? notas;
  final DateTime creado;

  const Referido({
    required this.id,
    required this.referidoPorId,
    required this.referidoPorNombre,
    required this.candidatoNombre,
    this.candidatoTelefono,
    this.candidatoEmail,
    this.puestoId,
    this.puestoTitulo,
    this.estado = EstadoReferido.enviado,
    required this.fechaEnvio,
    this.fechaContratacion,
    this.fechaBonificacion,
    this.montoBonificacion = 200.0,
    this.notificacionEnviada = false,
    this.notas,
    required this.creado,
  });

  /// Comprueba si han pasado 6 meses desde la contratación.
  bool get elegibleParaBonificacion {
    if (estado != EstadoReferido.contratado || fechaContratacion == null) {
      return false;
    }
    final seismeses = fechaContratacion!.add(const Duration(days: 180));
    return DateTime.now().isAfter(seismeses) && fechaBonificacion == null;
  }

  factory Referido.fromJson(Map<String, dynamic> json) {
    return Referido(
      id: json['id'] as String,
      referidoPorId: json['referido_por_id'] as String,
      referidoPorNombre: json['referido_por_nombre'] as String,
      candidatoNombre: json['candidato_nombre'] as String,
      candidatoTelefono: json['candidato_telefono'] as String?,
      candidatoEmail: json['candidato_email'] as String?,
      puestoId: json['puesto_id'] as String?,
      puestoTitulo: json['puesto_titulo'] as String?,
      estado: EstadoReferido.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoReferido.enviado,
      ),
      fechaEnvio: DateTime.parse(json['fecha_envio'] as String),
      fechaContratacion: json['fecha_contratacion'] != null
          ? DateTime.parse(json['fecha_contratacion'] as String)
          : null,
      fechaBonificacion: json['fecha_bonificacion'] != null
          ? DateTime.parse(json['fecha_bonificacion'] as String)
          : null,
      montoBonificacion:
          (json['monto_bonificacion'] as num?)?.toDouble() ?? 200.0,
      notificacionEnviada: json['notificacion_enviada'] as bool? ?? false,
      notas: json['notas'] as String?,
      creado: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'referido_por_id': referidoPorId,
      'referido_por_nombre': referidoPorNombre,
      'candidato_nombre': candidatoNombre,
      'candidato_telefono': candidatoTelefono,
      'candidato_email': candidatoEmail,
      'puesto_id': puestoId,
      'puesto_titulo': puestoTitulo,
      'estado': estado.name,
      'fecha_envio': fechaEnvio.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id];
}
