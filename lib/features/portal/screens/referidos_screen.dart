import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/models/referido.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_card.dart';
import '../../../shared/widgets/ecdb_empty_state.dart';
import '../../../shared/widgets/ecdb_toast.dart';

final referidosProvider = FutureProvider<List<Referido>>((ref) async {
  final data = await SupabaseService.client.from('referidos').select().order('created_at', ascending: false);
  return (data as List).map((j) => Referido.fromJson(j)).toList();
});

class ReferidosScreen extends ConsumerWidget {
  const ReferidosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referidosAsync = ref.watch(referidosProvider);

    return Scaffold(
      appBar: ECDBAppBar(
        title: 'Mis Referidos',
        actions: [IconButton(icon: const Icon(Icons.person_add), onPressed: () => _showCrear(context, ref))],
      ),
      body: referidosAsync.when(
        data: (refs) => refs.isEmpty
            ? ECDBEmptyState(
                icon: Icons.group_add, title: 'Sin referidos',
                description: 'Refiere a un amigo y gana 200€ si cumple 6 meses.',
                ctaLabel: 'Referir candidato', onCtaPressed: () => _showCrear(context, ref))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: refs.length,
                itemBuilder: (_, i) {
                  final r = refs[i];
                  final statusColor = switch (r.estado) {
                    EstadoReferido.enviado => ECDBColors.info,
                    EstadoReferido.enProceso => ECDBColors.warning,
                    EstadoReferido.contratado => ECDBColors.success,
                    EstadoReferido.descartado => ECDBColors.error,
                  };

                  return ECDBCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(r.candidatoNombre, style: Theme.of(context).textTheme.titleSmall)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(r.estado.name, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        if (r.puestoTitulo != null)
                          Text('Para: ${r.puestoTitulo}', style: Theme.of(context).textTheme.bodySmall),
                        Text('Enviado ${CosechaDateUtils.timeAgo(r.fechaEnvio)}', style: Theme.of(context).textTheme.labelSmall),
                        if (r.elegibleParaBonificacion) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: ECDBColors.successLight, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.celebration, color: ECDBColors.success, size: 18),
                                const SizedBox(width: 8),
                                Text('Bonificación: €${r.montoBonificacion.toStringAsFixed(0)} disponible',
                                    style: const TextStyle(color: ECDBColors.success, fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showCrear(BuildContext context, WidgetRef ref) {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Referir Candidato', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Si es contratado y cumple 6 meses, recibes 200€.', style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: ECDBColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre del candidato *')),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: telCtrl, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nombreCtrl.text.trim().isEmpty) return;
                  final emp = ref.read(currentEmpleadoProvider);
                  if (emp == null) return;
                  await SupabaseService.client.from('referidos').insert({
                    'referido_por_id': emp.id, 'referido_por_nombre': emp.nombre,
                    'candidato_nombre': nombreCtrl.text.trim(),
                    'candidato_email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    'candidato_telefono': telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
                    'estado': 'enviado', 'fecha_envio': DateTime.now().toIso8601String(),
                  });
                  ref.invalidate(referidosProvider);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ECDBToast.show(context, message: 'Referido enviado', type: ToastType.success);
                  }
                },
                child: const Text('Enviar Referido'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
