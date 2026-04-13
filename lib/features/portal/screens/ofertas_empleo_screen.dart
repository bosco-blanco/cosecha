import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/models/oferta_empleo.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_card.dart';
import '../../../shared/widgets/ecdb_empty_state.dart';

final ofertasProvider = FutureProvider<List<OfertaEmpleo>>((ref) async {
  final data = await SupabaseService.client.from('ofertas_empleo').select().eq('estado', 'abierta').order('created_at', ascending: false);
  return (data as List).map((j) => OfertaEmpleo.fromJson(j)).toList();
});

class OfertasEmpleoScreen extends ConsumerWidget {
  const OfertasEmpleoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ofertasAsync = ref.watch(ofertasProvider);

    return Scaffold(
      appBar: const ECDBAppBar(title: 'Bolsa de Empleo'),
      body: ofertasAsync.when(
        data: (ofertas) => ofertas.isEmpty
            ? const ECDBEmptyState(icon: Icons.work_outline, title: 'Sin ofertas abiertas', description: 'No hay ofertas de empleo activas.')
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: ofertas.length,
                itemBuilder: (_, i) {
                  final o = ofertas[i];
                  return ECDBCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(o.titulo, style: Theme.of(context).textTheme.titleSmall)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: ECDBColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Text('Abierta', style: TextStyle(fontSize: 10, color: ECDBColors.success, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        if (o.salario != null) ...[
                          const SizedBox(height: 4),
                          Text(o.salario!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ECDBColors.wine, fontWeight: FontWeight.w600)),
                        ],
                        const SizedBox(height: 4),
                        Text('${o.tipoContrato.name} · ${o.departamento ?? "General"}', style: Theme.of(context).textTheme.bodySmall),
                        if (o.requisitos.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: o.requisitos.take(3).map((r) => Chip(label: Text(r), padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)).toList(),
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(onPressed: () {}, child: const Text('Referir a un amigo')),
                        ),
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
}
