import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/models/solicitud.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_card.dart';
import '../../../shared/widgets/ecdb_empty_state.dart';
import '../../../shared/widgets/ecdb_toast.dart';

final solicitudesProvider = FutureProvider<List<Solicitud>>((ref) async {
  final data = await SupabaseService.client.from('solicitudes').select().order('created_at', ascending: false);
  return (data as List).map((j) => Solicitud.fromJson(j)).toList();
});

class SolicitudesScreen extends ConsumerWidget {
  const SolicitudesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solicitudesAsync = ref.watch(solicitudesProvider);

    return Scaffold(
      appBar: ECDBAppBar(
        title: 'Solicitudes',
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showCrear(context, ref))],
      ),
      body: solicitudesAsync.when(
        data: (sols) => sols.isEmpty
            ? ECDBEmptyState(
                icon: Icons.help_outline, title: 'Sin solicitudes',
                description: 'Crea una solicitud para IT, RRHH, Mantenimiento...',
                ctaLabel: 'Nueva Solicitud', onCtaPressed: () => _showCrear(context, ref))
            : RefreshIndicator(
                onRefresh: () => ref.refresh(solicitudesProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: sols.length,
                  itemBuilder: (_, i) {
                    final s = sols[i];
                    final statusColor = switch (s.estado) {
                      EstadoSolicitud.nueva => ECDBColors.info,
                      EstadoSolicitud.enProceso => ECDBColors.warning,
                      EstadoSolicitud.resuelta => ECDBColors.success,
                      EstadoSolicitud.cerrada => ECDBColors.textMuted,
                    };
                    final catIcon = switch (s.categoria) {
                      CategoriaSolicitud.it => Icons.computer,
                      CategoriaSolicitud.rrhh => Icons.people,
                      CategoriaSolicitud.mantenimiento => Icons.build,
                      CategoriaSolicitud.admin => Icons.business,
                      CategoriaSolicitud.otro => Icons.help,
                    };

                    return ECDBCard(
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Icon(catIcon, color: statusColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.titulo, style: Theme.of(context).textTheme.titleSmall),
                                Text('${s.categoria.name.toUpperCase()} · ${s.estado.name}',
                                    style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Text(CosechaDateUtils.timeAgo(s.creado), style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showCrear(BuildContext context, WidgetRef ref) {
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    CategoriaSolicitud cat = CategoriaSolicitud.it;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nueva Solicitud', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<CategoriaSolicitud>(
                value: cat,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: CategoriaSolicitud.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()))).toList(),
                onChanged: (v) => setSheetState(() => cat = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: tituloCtrl, decoration: const InputDecoration(labelText: 'Título *')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 3),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (tituloCtrl.text.trim().isEmpty) return;
                    final emp = ref.read(currentEmpleadoProvider);
                    if (emp == null) return;
                    await SupabaseService.client.from('solicitudes').insert({
                      'empleado_id': emp.id, 'categoria': cat.name,
                      'titulo': tituloCtrl.text.trim(), 'descripcion': descCtrl.text.trim(),
                      'prioridad': 'normal', 'estado': 'nueva',
                    });
                    ref.invalidate(solicitudesProvider);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ECDBToast.show(context, message: 'Solicitud enviada', type: ToastType.success);
                    }
                  },
                  child: const Text('Enviar Solicitud'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
