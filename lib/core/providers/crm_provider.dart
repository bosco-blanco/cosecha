import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contacto.dart';
import '../models/deal.dart';
import '../models/visita_comercial.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

// ── Contactos ──
class ContactosNotifier extends StateNotifier<List<Contacto>> {
  ContactosNotifier() : super([]) { load(); }

  Future<void> load() async {
    try {
      final data = await SupabaseService.client
          .from('contactos').select().order('created_at', ascending: false);
      state = (data as List).map((j) => Contacto.fromJson(j)).toList();
    } catch (e) { debugPrint('[CRM] Error contactos: $e'); }
  }

  Future<void> crear({
    required String nombre, String? email, String? telefono,
    String? empresa, TipoContacto tipo = TipoContacto.prospecto,
  }) async {
    try {
      await SupabaseService.client.from('contactos').insert({
        'nombre': nombre, 'email': email, 'telefono': telefono,
        'empresa': empresa, 'tipo': tipo.name,
      });
      await load();
    } catch (e) { debugPrint('[CRM] Error creando contacto: $e'); }
  }
}

final contactosProvider =
    StateNotifierProvider<ContactosNotifier, List<Contacto>>((ref) => ContactosNotifier());

// ── Deals ──
class DealsNotifier extends StateNotifier<List<Deal>> {
  final Ref _ref;
  DealsNotifier(this._ref) : super([]) { load(); }

  Future<void> load() async {
    try {
      final data = await SupabaseService.client
          .from('deals').select().order('created_at', ascending: false);
      state = (data as List).map((j) => Deal.fromJson(j)).toList();
    } catch (e) { debugPrint('[CRM] Error deals: $e'); }
  }

  List<Deal> porEtapa(String etapa) => state.where((d) => d.etapa == etapa).toList();

  Future<void> crear({
    required String titulo, required TipoDeal tipo, required String etapa,
    String? contactoId, String? contactoNombre, double valor = 0,
  }) async {
    final emp = _ref.read(currentEmpleadoProvider);
    if (emp == null) return;
    try {
      await SupabaseService.client.from('deals').insert({
        'titulo': titulo, 'tipo': tipo.name, 'etapa': etapa,
        'contacto_id': contactoId, 'contacto_nombre': contactoNombre,
        'valor': valor, 'creado_por': emp.id, 'asignado_id': emp.id,
      });
      await load();
    } catch (e) { debugPrint('[CRM] Error creando deal: $e'); }
  }

  Future<void> moverEtapa(String dealId, String nuevaEtapa) async {
    state = state.map((d) {
      if (d.id == dealId) {
        return Deal(id: d.id, titulo: d.titulo, tipo: d.tipo, contactoId: d.contactoId,
          contactoNombre: d.contactoNombre, valor: d.valor, etapa: nuevaEtapa,
          probabilidad: d.probabilidad, creadoPor: d.creadoPor, creado: d.creado);
      }
      return d;
    }).toList();

    try {
      await SupabaseService.client.from('deals')
          .update({'etapa': nuevaEtapa}).eq('id', dealId);
    } catch (e) { debugPrint('[CRM] Error moviendo deal: $e'); await load(); }
  }
}

final dealsProvider = StateNotifierProvider<DealsNotifier, List<Deal>>((ref) => DealsNotifier(ref));

// ── Visitas ──
final visitasProvider = FutureProvider<List<VisitaComercial>>((ref) async {
  try {
    final data = await SupabaseService.client
        .from('visitas_comerciales').select().order('fecha', ascending: false).limit(50);
    return (data as List).map((j) => VisitaComercial.fromJson(j)).toList();
  } catch (e) { debugPrint('[CRM] Error visitas: $e'); return []; }
});
