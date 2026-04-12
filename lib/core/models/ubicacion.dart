import 'package:equatable/equatable.dart';

/// Tipos de local ECDB.
enum TipoUbicacion { tienda, restaurante, hibrido, gastronomico, noche, distribucion }

/// Modelo de ubicación / local de ECDB.
class Ubicacion extends Equatable {
  final String id;
  final String nombre;
  final String? direccion;
  final double latitud;
  final double longitud;
  final int radioPermitido;
  final TipoUbicacion tipo;
  final String? qrCode;
  final bool activo;
  final DateTime creado;

  const Ubicacion({
    required this.id,
    required this.nombre,
    this.direccion,
    required this.latitud,
    required this.longitud,
    this.radioPermitido = 100,
    required this.tipo,
    this.qrCode,
    this.activo = true,
    required this.creado,
  });

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String?,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      radioPermitido: json['radio_permitido'] as int? ?? 100,
      tipo: _parseTipo(json['tipo'] as String?),
      qrCode: json['qr_code'] as String?,
      activo: json['activo'] as bool? ?? true,
      creado: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'radio_permitido': radioPermitido,
      'tipo': _tipoToString(tipo),
      'qr_code': qrCode,
      'activo': activo,
    };
  }

  static TipoUbicacion _parseTipo(String? value) {
    switch (value) {
      case 'tienda':
        return TipoUbicacion.tienda;
      case 'restaurante':
        return TipoUbicacion.restaurante;
      case 'híbrido':
      case 'hibrido':
        return TipoUbicacion.hibrido;
      case 'gastronómico':
      case 'gastronomico':
        return TipoUbicacion.gastronomico;
      case 'noche':
        return TipoUbicacion.noche;
      case 'distribución':
      case 'distribucion':
        return TipoUbicacion.distribucion;
      default:
        return TipoUbicacion.tienda;
    }
  }

  static String _tipoToString(TipoUbicacion tipo) {
    switch (tipo) {
      case TipoUbicacion.tienda:
        return 'tienda';
      case TipoUbicacion.restaurante:
        return 'restaurante';
      case TipoUbicacion.hibrido:
        return 'híbrido';
      case TipoUbicacion.gastronomico:
        return 'gastronómico';
      case TipoUbicacion.noche:
        return 'noche';
      case TipoUbicacion.distribucion:
        return 'distribución';
    }
  }

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'Ubicacion($nombre)';
}
