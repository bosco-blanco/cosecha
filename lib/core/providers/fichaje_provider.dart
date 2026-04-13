import 'dart:async';
import 'package:flutter/foundation.dart';
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
  final List<Fichaje> fichajesHoy;
  final List<Fichaje> fichajesHistorial;
  final bool isLoading;
  final String? error;

  const FichajeState({
    this.estado = EstadoFichaje.sinFichar,
    this.ultimoFichaje,
    this.horaEntrada,
    this.tiempoTrabajado = Duration.zero,
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

      final fichajes = (data as List).map((j) => Fichaje.fromJson(j)).toList();

      EstadoFichaje estadoActual = EstadoFichaje.sinFichar;
      DateTime? horaEntrada;
      Duration tiempoTrabajado = Duration.zero;

      if (fichajes.isNotEmpty) {
        final ultimo = fichajes.last;
        if (ultimo.isEntrada) {
          estadoActual = EstadoFichaje.trabajando;
          horaEntrada = ultimo.timestamp;
        }

        for (int i = 0; i < fichajes.length - 1; i += 2) {
          if (i + 1 < fichajes.length &&
              fichajes[i].isEntrada &&
              fichajes[i + 1].isSalida) {
            tiempoTrabajado +=
                fichajes[i + 1].timestamp.difference(fichajes[i].timestamp);
          }
        }

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

      if (estadoActual == EstadoFichaje.trabajando) {
        _startTimer();
      }
    } catch (e) {
      debugPrint('[Fichaje] Error cargando fichajes: $e');
      state = state.copyWith(isLoading: false, error: 'Error: $e');
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
            lat1: lat, lon1: lon, lat2: ubLat, lon2: ubLon,
          );
          valido = distancia <= radio;
        }
      } catch (e) {
        debugPrint('[Fichaje] GPS no disponible: $e');
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
        fichaje: fichaje, distancia: distancia, dentroDeRango: valido,
      );
    } catch (e) {
      debugPrint('[Fichaje] Error al fichar entrada: $e');
      state = state.copyWith(isLoading: false, error: '$e');
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
            lat1: lat, lon1: lon, lat2: ubLat, lon2: ubLon,
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
        fichaje: fichaje, distancia: distancia, dentroDeRango: valido,
      );
    } catch (e) {
      debugPrint('[Fichaje] Error al fichar salida: $e');
      state = state.copyWith(isLoading: false, error: '$e');
      return FichajeResult.error('Error al fichar salida: $e');
    }
  }

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

      state = state.copyWith(
        fichajesHistorial: (data as List).map((j) => Fichaje.fromJson(j)).toList(),
      );
    } catch (e) {
      debugPrint('[Fichaje] Error historial: $e');
    }
  }

  Future<void> refresh() => _loadFichajesHoy();

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.horaEntrada != null) {
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

class FichajeResult {
  final bool ok;
  final Fichaje? fichaje;
  final double? distancia;
  final bool? dentroDeRango;
  final String? errorMessage;

  const FichajeResult._({
    required this.ok, this.fichaje, this.distancia, this.dentroDeRango, this.errorMessage,
  });

  factory FichajeResult.success({
    required Fichaje fichaje, double? distancia, bool? dentroDeRango,
  }) => FichajeResult._(ok: true, fichaje: fichaje, distancia: distancia, dentroDeRango: dentroDeRango);

  factory FichajeResult.error(String message) =>
      FichajeResult._(ok: false, errorMessage: message);
}

final fichajeProvider =
    StateNotifierProvider<FichajeNotifier, FichajeState>((ref) {
  return FichajeNotifier(ref);
});

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

final empleadosActivosProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final hoy = DateTime.now();
  final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);

  final data = await SupabaseService.client
      .from('fichajes')
      .select()
      .gte('timestamp', inicioHoy.toIso8601String())
      .order('timestamp', ascending: false);

  return (data as List).cast<Map<String, dynamic>>();
});
