import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fichaje.dart';
import '../models/empleado.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';
import '../utils/geo_utils.dart';
import '../providers/auth_provider.dart';

/// Estado del fichaje actual del empleado.
enum EstadoFichaje { sinFichar, trabajando, enPausa }

class FichajeState {
  final EstadoFichaje estado;
  final Fichaje? ultimoFichaje;
  final DateTime? horaEntrada;
  final Duration tiempoTrabajado;
  final Duration tiempoPausa;
  final List<Fichaje> fichajesHoy;
  final List<Fichaje> fichajesHistorial;
  final bool isLoading;
  final String? error;

  const FichajeState({
    this.estado = EstadoFichaje.sinFichar,
    this.ultimoFichaje,
    this.horaEntrada,
    this.tiempoTrabajado = Duration.zero,
    this.tiempoPausa = Duration.zero,
    this.fichajesHoy = const [],
    this.fichajesHistorial = const [],
    this.isLoading = false,
    this.error,
  });

  FichajeState copyWith({
    EstadoFichaje? estado,
    Fichaje? ultimoFichaje,
    DateTime? horaEntrada,
    Duration? tiempoTrabajado,
    Duration? tiempoPausa,
    List<Fichaje>? fichajesHoy,
    List<Fichaje>? fichajesHistorial,
    bool? isLoading,
    String? error,
  }) {
    return FichajeState(
      estado: estado ?? this.estado,
      ultimoFichaje: ultimoFichaje ?? this.ultimoFichaje,
      horaEntrada: horaEntrada ?? this.horaEntrada,
      tiempoTrabajado: tiempoTrabajado ?? this.tiempoTrabajado,
      tiempoPausa: tiempoPausa ?? this.tiempoPausa,
      fichajesHoy: fichajesHoy ?? this.fichajesHoy,
      fichajesHistorial: fichajesHistorial ?? this.fichajesHistorial,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FichajeNotifier extends StateNotifier<FichajeState> {
  final Ref _ref;
  Timer? _timer;

  FichajeNotifier(this._ref) : super(const FichajeState()) {
    _loadFichajesHoy();
  }

  Empleado? get _empleado => _ref.read(currentEmpleadoProvider);

  /// Cargar fichajes del día actual.
  Future<void> _loadFichajesHoy() async {
    final empleado = _empleado;
    if (empleado == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final hoy = DateTime.now();
      final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
      final finHoy = inicioHoy.add(const Duration(days: 1));

      final data = await SupabaseService.client
          .from('fichajes')
          .select()
          .eq('empleado_id', empleado.id)
          .gte('timestamp', inicioHoy.toIso8601String())
          .lt('timestamp', finHoy.toIso8601String())
          .order('timestamp', ascending: true);

      final fichajes =
          (data as List).map((j) => Fichaje.fromJson(j)).toList();

      // Determinar estado actual
      EstadoFichaje estadoActual = EstadoFichaje.sinFichar;
      DateTime? horaEntrada;
      Duration tiempoTrabajado = Duration.zero;

      if (fichajes.isNotEmpty) {
        final ultimo = fichajes.last;
        if (ultimo.isEntrada) {
          estadoActual = EstadoFichaje.trabajando;
          horaEntrada = ultimo.timestamp;
        }

        // Calcular tiempo trabajado hoy
        for (int i = 0; i < fichajes.length - 1; i += 2) {
          if (i + 1 < fichajes.length &&
              fichajes[i].isEntrada &&
              fichajes[i + 1].isSalida) {
            tiempoTrabajado +=
                fichajes[i + 1].timestamp.difference(fichajes[i].timestamp);
          }
        }

        // Si está trabajando, sumar el tiempo desde la última entrada
        if (estadoActual == EstadoFichaje.trabajando && horaEntrada != null) {
          tiempoTrabajado += DateTime.now().difference(horaEntrada);
        }
      }

      state = state.copyWith(
        fichajesHoy: fichajes,
        estado: estadoActual,
        horaEntrada: horaEntrada,
        tiempoTrabajado: tiempoTrabajado,
        ultimoFichaje: fichajes.isNotEmpty ? fichajes.last : null,
        isLoading: false,
      );

      // Iniciar timer si está trabajando
      if (estadoActual == EstadoFichaje.trabajando) {
        _startTimer();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar fichajes: $e',
      );
    }
  }

  /// Fichar entrada.
  Future<FichajeResult> ficharEntrada({
    String metodo = 'app',
    String? ubicacionId,
  }) async {
    final empleado = _empleado;
    if (empleado == null) {
      return FichajeResult.error('No hay empleado autenticado.');
    }

    state = state.copyWith(isLoading: true);

    try {
      // Obtener geolocalización
      double? lat, lon;
      double? distancia;
      bool valido = true;

      try {
        final position = await LocationService.getCurrentPosition();
        lat = position.latitude;
        lon = position.longitude;

        // Si tiene ubicación base, calcular distancia
        if (empleado.ubicacionBaseId != null) {
          final ubData = await SupabaseService.client
              .from('ubicaciones')
              .select()
              .eq('id', empleado.ubicacionBaseId!)
              .single();

          final ubLat = (ubData['latitud'] as num).toDouble();
          final ubLon = (ubData['longitud'] as num).toDouble();
          final radio = ubData['radio_permitido'] as int? ?? 100;

          distancia = GeoUtils.haversineDistance(
            lat1: lat,
            lon1: lon,
            lat2: ubLat,
            lon2: ubLon,
          );

          valido = distancia <= radio;
        }
      } catch (e) {
        // Geolocalización falló — permitir fichar sin GPS
      }

      final ahora = DateTime.now();

      final result = await SupabaseService.client
          .from('fichajes')
          .insert({
            'empleado_id': empleado.id,
            'empleado_nombre': empleado.nombre,
            'tipo': 'entrada',
            'timestamp': ahora.toIso8601String(),
            'latitud': lat,
            'longitud': lon,
            'ubicacion_id': ubicacionId ?? empleado.ubicacionBaseId,
            'distancia_al_centro': distancia,
            'valido': valido,
            'metodo': metodo,
          })
          .select()
          .single();

      final fichaje = Fichaje.fromJson(result);

      state = state.copyWith(
        estado: EstadoFichaje.trabajando,
        horaEntrada: ahora,
        ultimoFichaje: fichaje,
        fichajesHoy: [...state.fichajesHoy, fichaje],
        isLoading: false,
      );

      _startTimer();

      return FichajeResult.success(
        fichaje: fichaje,
        distancia: distancia,
        dentroDeRango: valido,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error al fichar: $e');
      return FichajeResult.error('Error al fichar entrada: $e');
    }
  }

  /// Fichar salida.
  Future<FichajeResult> ficharSalida() async {
    final empleado = _empleado;
    if (empleado == null) {
      return FichajeResult.error('No hay empleado autenticado.');
    }

    state = state.copyWith(isLoading: true);
    _stopTimer();

    try {
      double? lat, lon;
      double? distancia;
      bool valido = true;

      try {
        final position = await LocationService.getCurrentPosition();
        lat = position.latitude;
        lon = position.longitude;

        if (empleado.ubicacionBaseId != null) {
          final ubData = await SupabaseService.client
              .from('ubicaciones')
              .select()
              .eq('id', empleado.ubicacionBaseId!)
              .single();

          final ubLat = (ubData['latitud'] as num).toDouble();
          final ubLon = (ubData['longitud'] as num).toDouble();
          final radio = ubData['radio_permitido'] as int? ?? 100;

          distancia = GeoUtils.haversineDistance(
            lat1: lat,
            lon1: lon,
            lat2: ubLat,
            lon2: ubLon,
          );
          valido = distancia <= radio;
        }
      } catch (_) {}

      final ahora = DateTime.now();
      final result = await SupabaseService.client
          .from('fichajes')
          .insert({
            'empleado_id': empleado.id,
            'empleado_nombre': empleado.nombre,
            'tipo': 'salida',
            'timestamp': ahora.toIso8601String(),
            'latitud': lat,
            'longitud': lon,
            'ubicacion_id': empleado.ubicacionBaseId,
            'distancia_al_centro': distancia,
            'valido': valido,
            'metodo': 'app',
          })
          .select()
          .single();

      final fichaje = Fichaje.fromJson(result);

      // Recalcular tiempo trabajado
      final entradas = state.fichajesHoy.where((f) => f.isEntrada).toList();
      final salidas = [...state.fichajesHoy.where((f) => f.isSalida), fichaje];
      Duration total = Duration.zero;
      for (int i = 0; i < entradas.length && i < salidas.length; i++) {
        total += salidas[i].timestamp.difference(entradas[i].timestamp);
      }

      state = state.copyWith(
        estado: EstadoFichaje.sinFichar,
        ultimoFichaje: fichaje,
        fichajesHoy: [...state.fichajesHoy, fichaje],
        tiempoTrabajado: total,
        horaEntrada: null,
        isLoading: false,
      );

      return FichajeResult.success(
        fichaje: fichaje,
        distancia: distancia,
        dentroDeRango: valido,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error al fichar: $e');
      return FichajeResult.error('Error al fichar salida: $e');
    }
  }

  /// Cargar historial de fichajes por rango de fechas.
  Future<void> loadHistorial({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final empleado = _empleado;
    if (empleado == null) return;

    try {
      final data = await SupabaseService.client
          .from('fichajes')
          .select()
          .eq('empleado_id', empleado.id)
          .gte('timestamp', desde.toIso8601String())
          .lte('timestamp', hasta.toIso8601String())
          .order('timestamp', ascending: false);

      final fichajes =
          (data as List).map((j) => Fichaje.fromJson(j)).toList();

      state = state.copyWith(fichajesHistorial: fichajes);
    } catch (e) {
      state = state.copyWith(error: 'Error al cargar historial: $e');
    }
  }

  /// Recargar datos.
  Future<void> refresh() => _loadFichajesHoy();

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.horaEntrada != null) {
        // Recalcular tiempo: tiempo de periodos cerrados + periodo actual
        Duration base = Duration.zero;
        final fichajes = state.fichajesHoy;
        for (int i = 0; i < fichajes.length - 1; i += 2) {
          if (fichajes[i].isEntrada && fichajes[i + 1].isSalida) {
            base += fichajes[i + 1].timestamp.difference(fichajes[i].timestamp);
          }
        }
        final current = DateTime.now().difference(state.horaEntrada!);
        state = state.copyWith(tiempoTrabajado: base + current);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

/// Resultado de una operación de fichaje.
class FichajeResult {
  final bool ok;
  final Fichaje? fichaje;
  final double? distancia;
  final bool? dentroDeRango;
  final String? errorMessage;

  const FichajeResult._({
    required this.ok,
    this.fichaje,
    this.distancia,
    this.dentroDeRango,
    this.errorMessage,
  });

  factory FichajeResult.success({
    required Fichaje fichaje,
    double? distancia,
    bool? dentroDeRango,
  }) =>
      FichajeResult._(
        ok: true,
        fichaje: fichaje,
        distancia: distancia,
        dentroDeRango: dentroDeRango,
      );

  factory FichajeResult.error(String message) =>
      FichajeResult._(ok: false, errorMessage: message);
}

/// Provider de fichaje.
final fichajeProvider =
    StateNotifierProvider<FichajeNotifier, FichajeState>((ref) {
  return FichajeNotifier(ref);
});

/// Provider: fichajes de todos los empleados para managers.
final fichajesEquipoProvider =
    FutureProvider.family<List<Fichaje>, ({DateTime desde, DateTime hasta})>(
        (ref, params) async {
  final data = await SupabaseService.client
      .from('fichajes')
      .select()
      .gte('timestamp', params.desde.toIso8601String())
      .lte('timestamp', params.hasta.toIso8601String())
      .order('timestamp', ascending: false);

  return (data as List).map((j) => Fichaje.fromJson(j)).toList();
});

/// Provider: empleados fichados ahora mismo.
final empleadosActivosProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return SupabaseService.client
      .from('fichajes')
      .stream(primaryKey: ['id'])
      .order('timestamp', ascending: false)
      .map((data) {
        // Filtrar solo fichajes de hoy
        final hoy = DateTime.now();
        final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
        return data
            .where((f) =>
                DateTime.parse(f['timestamp'] as String).isAfter(inicioHoy))
            .toList();
      });
});
