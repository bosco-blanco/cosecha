import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/anuncio.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

class AnunciosNotifier extends StateNotifier<List<Anuncio>> {
  AnunciosNotifier() : super([]) {
    load();
  }

  Future<void> load() async {
    try {
      final data = await SupabaseService.client
          .from('anuncios')
          .select()
          .order('created_at', ascending: false)
          .limit(20);

      state = (data as List).map((j) => Anuncio.fromJson(j)).toList();
    } catch (e) {
      debugPrint('[Anuncios] Error: $e');
    }
  }

  Future<void> crear({
    required String titulo,
    required String cuerpo,
    required String autorId,
    PrioridadAnuncio prioridad = PrioridadAnuncio.normal,
    bool destacado = false,
  }) async {
    try {
      await SupabaseService.client.from('anuncios').insert({
        'titulo': titulo,
        'cuerpo': cuerpo,
        'autor_id': autorId,
        'prioridad': prioridad.name,
        'destinatarios': 'todos',
        'destacado': destacado,
      });
      await load();
    } catch (e) {
      debugPrint('[Anuncios] Error creando: $e');
    }
  }
}

final anunciosProvider =
    StateNotifierProvider<AnunciosNotifier, List<Anuncio>>((ref) {
  return AnunciosNotifier();
});
