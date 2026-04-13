import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tarea.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

class TareasState {
  final List<Tarea> todas;
  final bool isLoading;
  final String? error;

  const TareasState({this.todas = const [], this.isLoading = false, this.error});

  List<Tarea> get backlog => todas.where((t) => t.columna == ColumnaTarea.backlog).toList();
  List<Tarea> get enProgreso => todas.where((t) => t.columna == ColumnaTarea.enProgreso).toList();
  List<Tarea> get revision => todas.where((t) => t.columna == ColumnaTarea.revision).toList();
  List<Tarea> get completado => todas.where((t) => t.columna == ColumnaTarea.completado).toList();

  TareasState copyWith({List<Tarea>? todas, bool? isLoading, String? error}) {
    return TareasState(
      todas: todas ?? this.todas,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TareasNotifier extends StateNotifier<TareasState> {
  final Ref _ref;

  TareasNotifier(this._ref) : super(const TareasState()) {
    loadTareas();
  }

  Future<void> loadTareas() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await SupabaseService.client
          .from('tareas')
          .select()
          .order('created_at', ascending: false);

      final tareas = (data as List).map((j) => Tarea.fromJson(j)).toList();
      state = state.copyWith(todas: tareas, isLoading: false);
    } catch (e) {
      debugPrint('[Tareas] Error: $e');
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  Future<void> crearTarea({
    required String titulo,
    String? descripcion,
    PrioridadTarea prioridad = PrioridadTarea.normal,
    DateTime? fechaLimite,
    List<String> etiquetas = const [],
  }) async {
    final empleado = _ref.read(currentEmpleadoProvider);
    if (empleado == null) return;

    try {
      await SupabaseService.client.from('tareas').insert({
        'titulo': titulo,
        'descripcion': descripcion,
        'columna': 'backlog',
        'prioridad': prioridad.name,
        'etiquetas': etiquetas,
        'fecha_limite': fechaLimite?.toIso8601String(),
        'creado_por': empleado.id,
        'asignados': [empleado.id],
      });
      await loadTareas();
    } catch (e) {
      debugPrint('[Tareas] Error creando: $e');
    }
  }

  Future<void> moverTarea(String tareaId, ColumnaTarea nuevaColumna) async {
    // Optimistic update
    final updated = state.todas.map((t) {
      if (t.id == tareaId) {
        return Tarea(
          id: t.id, titulo: t.titulo, descripcion: t.descripcion,
          columna: nuevaColumna, prioridad: t.prioridad, etiquetas: t.etiquetas,
          fechaLimite: t.fechaLimite, asignados: t.asignados,
          proyectoId: t.proyectoId, creadoPor: t.creadoPor, creado: t.creado,
          completadoEn: nuevaColumna == ColumnaTarea.completado ? DateTime.now() : null,
        );
      }
      return t;
    }).toList();
    state = state.copyWith(todas: updated);

    try {
      final updateData = <String, dynamic>{
        'columna': nuevaColumna.name,
      };
      if (nuevaColumna == ColumnaTarea.completado) {
        updateData['completado_en'] = DateTime.now().toIso8601String();
        updateData['completado_por'] = _ref.read(currentEmpleadoProvider)?.id;
      }
      await SupabaseService.client.from('tareas').update(updateData).eq('id', tareaId);
    } catch (e) {
      debugPrint('[Tareas] Error moviendo: $e');
      await loadTareas();
    }
  }

  Future<void> eliminarTarea(String tareaId) async {
    try {
      await SupabaseService.client.from('tareas').delete().eq('id', tareaId);
      state = state.copyWith(
        todas: state.todas.where((t) => t.id != tareaId).toList(),
      );
    } catch (e) {
      debugPrint('[Tareas] Error eliminando: $e');
    }
  }
}

final tareasProvider = StateNotifierProvider<TareasNotifier, TareasState>((ref) {
  return TareasNotifier(ref);
});

/// Tareas asignadas al usuario actual.
final misTareasProvider = Provider<List<Tarea>>((ref) {
  final tareas = ref.watch(tareasProvider).todas;
  final empleado = ref.watch(currentEmpleadoProvider);
  if (empleado == null) return [];
  return tareas.where((t) =>
      t.asignados.contains(empleado.id) || t.creadoPor == empleado.id).toList();
});
