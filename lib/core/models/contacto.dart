import 'package:equatable/equatable.dart';

enum TipoContacto { cliente, prospecto, partner, distribuidor, eventos }

/// Modelo de contacto — CRM Comercial.
class Contacto extends Equatable {
  final String id;
  final String nombre;
  final String? email;
  final String? telefono;
  final String? empresa;
  final TipoContacto tipo;
  final List<String> etiquetas;
  final String? notas;
  final DateTime? ultimoContacto;
  final DateTime creado;
  final DateTime? actualizadoEn;

  const Contacto({
    required this.id,
    required this.nombre,
    this.email,
    this.telefono,
    this.empresa,
    this.tipo = TipoContacto.prospecto,
    this.etiquetas = const [],
    this.notas,
    this.ultimoContacto,
    required this.creado,
    this.actualizadoEn,
  });

  factory Contacto.fromJson(Map<String, dynamic> json) {
    return Contacto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String?,
      telefono: json['telefono'] as String?,
      empresa: json['empresa'] as String?,
      tipo: TipoContacto.values.firstWhere(
        (t) => t.name == json['tipo'],
        orElse: () => TipoContacto.prospecto,
      ),
      etiquetas: (json['etiquetas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      notas: json['notas'] as String?,
      ultimoContacto: json['ultimo_contacto'] != null
          ? DateTime.parse(json['ultimo_contacto'] as String)
          : null,
      creado: DateTime.parse(json['created_at'] as String),
      actualizadoEn: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'empresa': empresa,
      'tipo': tipo.name,
      'etiquetas': etiquetas,
      'notas': notas,
    };
  }

  @override
  List<Object?> get props => [id];
}
