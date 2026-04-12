import 'package:equatable/equatable.dart';

/// Roles disponibles en el sistema.
enum Rol { admin, manager, empleado, comercial }

/// Departamentos de ECDB.
enum Departamento { operaciones, comercial, cocina, servicio, admin, rrhh }

/// Modelo de empleado — entidad central del sistema.
/// Todos los módulos referencian Empleado como fuente de verdad.
class Empleado extends Equatable {
  final String id;
  final String nombre;
  final String email;
  final String? telefono;
  final String pin;
  final Rol rol;
  final String? ubicacionBaseId;
  final Departamento? departamento;
  final String? fotoPerfil;
  final bool activo;
  final DateTime? ultimaActividadEn;
  final bool notificacionesActivadas;
  final DateTime creado;
  final DateTime? actualizadoEn;

  const Empleado({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    required this.pin,
    required this.rol,
    this.ubicacionBaseId,
    this.departamento,
    this.fotoPerfil,
    this.activo = true,
    this.ultimaActividadEn,
    this.notificacionesActivadas = true,
    required this.creado,
    this.actualizadoEn,
  });

  bool get isAdmin => rol == Rol.admin;
  bool get isManager => rol == Rol.manager;
  bool get isComercial => rol == Rol.comercial;
  bool get canManage => isAdmin || isManager;

  factory Empleado.fromJson(Map<String, dynamic> json) {
    return Empleado(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      telefono: json['telefono'] as String?,
      pin: json['pin'] as String,
      rol: Rol.values.firstWhere(
        (r) => r.name == json['rol'],
        orElse: () => Rol.empleado,
      ),
      ubicacionBaseId: json['ubicacion_base_id'] as String?,
      departamento: json['departamento'] != null
          ? Departamento.values.firstWhere(
              (d) => d.name == json['departamento'],
              orElse: () => Departamento.operaciones,
            )
          : null,
      fotoPerfil: json['foto_perfil'] as String?,
      activo: json['activo'] as bool? ?? true,
      ultimaActividadEn: json['ultima_actividad_en'] != null
          ? DateTime.parse(json['ultima_actividad_en'] as String)
          : null,
      notificacionesActivadas:
          json['notificaciones_activadas'] as bool? ?? true,
      creado: DateTime.parse(json['created_at'] as String),
      actualizadoEn: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'pin': pin,
      'rol': rol.name,
      'ubicacion_base_id': ubicacionBaseId,
      'departamento': departamento?.name,
      'foto_perfil': fotoPerfil,
      'activo': activo,
      'notificaciones_activadas': notificacionesActivadas,
    };
  }

  Empleado copyWith({
    String? nombre,
    String? email,
    String? telefono,
    String? pin,
    Rol? rol,
    String? ubicacionBaseId,
    Departamento? departamento,
    String? fotoPerfil,
    bool? activo,
    DateTime? ultimaActividadEn,
    bool? notificacionesActivadas,
  }) {
    return Empleado(
      id: id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      pin: pin ?? this.pin,
      rol: rol ?? this.rol,
      ubicacionBaseId: ubicacionBaseId ?? this.ubicacionBaseId,
      departamento: departamento ?? this.departamento,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      activo: activo ?? this.activo,
      ultimaActividadEn: ultimaActividadEn ?? this.ultimaActividadEn,
      notificacionesActivadas:
          notificacionesActivadas ?? this.notificacionesActivadas,
      creado: creado,
      actualizadoEn: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, email];

  @override
  String toString() => 'Empleado($nombre, $rol)';
}
