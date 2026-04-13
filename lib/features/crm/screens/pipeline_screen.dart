import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/models/deal.dart';
import '../../../core/providers/crm_provider.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_empty_state.dart';
import '../../../shared/widgets/ecdb_toast.dart';

class PipelineScreen extends ConsumerStatefulWidget {
  const PipelineScreen({super.key});

  @override
  ConsumerState<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends ConsumerState<PipelineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deals = ref.watch(dealsProvider);

    return Scaffold(
      appBar: ECDBAppBar(
        title: 'CRM Comercial',
        actions: [
          IconButton(icon: const Icon(Icons.people), onPressed: () => context.push('/crm/contactos')),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showCrearDeal(context, ref)),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: ECDBColors.wine,
          indicatorColor: ECDBColors.wine,
          tabs: const [Tab(text: 'CODEBA'), Tab(text: 'Eventos')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _PipelineView(
            deals: deals.where((d) => d.tipo == TipoDeal.codeba).toList(),
            etapas: Deal.etapasCodeba,
            onMover: (id, etapa) => ref.read(dealsProvider.notifier).moverEtapa(id, etapa),
          ),
          _PipelineView(
            deals: deals.where((d) => d.tipo == TipoDeal.evento).toList(),
            etapas: Deal.etapasEventos,
            onMover: (id, etapa) => ref.read(dealsProvider.notifier).moverEtapa(id, etapa),
          ),
        ],
      ),
    );
  }

  void _showCrearDeal(BuildContext context, WidgetRef ref) {
    final tituloCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    TipoDeal tipo = TipoDeal.codeba;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nuevo Deal', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: tituloCtrl, decoration: const InputDecoration(labelText: 'Título *')),
              const SizedBox(height: 12),
              TextField(controller: valorCtrl, decoration: const InputDecoration(labelText: 'Valor (EUR)', prefixText: '€ '), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              SegmentedButton<TipoDeal>(
                segments: const [
                  ButtonSegment(value: TipoDeal.codeba, label: Text('CODEBA')),
                  ButtonSegment(value: TipoDeal.evento, label: Text('Evento')),
                ],
                selected: {tipo},
                onSelectionChanged: (s) => setSheetState(() => tipo = s.first),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (tituloCtrl.text.trim().isEmpty) return;
                    final etapa = tipo == TipoDeal.codeba ? Deal.etapasCodeba.first : Deal.etapasEventos.first;
                    await ref.read(dealsProvider.notifier).crear(
                      titulo: tituloCtrl.text.trim(), tipo: tipo, etapa: etapa,
                      valor: double.tryParse(valorCtrl.text) ?? 0,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ECDBToast.show(context, message: 'Deal creado', type: ToastType.success);
                    }
                  },
                  child: const Text('Crear Deal'),
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

class _PipelineView extends StatelessWidget {
  final List<Deal> deals;
  final List<String> etapas;
  final void Function(String id, String etapa) onMover;

  const _PipelineView({required this.deals, required this.etapas, required this.onMover});

  @override
  Widget build(BuildContext context) {
    if (deals.isEmpty) {
      return const ECDBEmptyState(
        icon: Icons.trending_up,
        title: 'Pipeline vacío',
        description: 'Crea tu primer deal para empezar.',
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: etapas.map((etapa) {
          final etapaDeals = deals.where((d) => d.etapa == etapa).toList();
          final totalValor = etapaDeals.fold<double>(0, (s, d) => s + d.valor);

          return Container(
            width: 240,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: ECDBColors.bgAlt.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DragTarget<String>(
              onAcceptWithDetails: (details) => onMover(details.data, etapa),
              builder: (ctx, candidate, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          etapa.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ECDBColors.textSecondary, letterSpacing: 0.5),
                        ),
                        if (totalValor > 0)
                          Text('€${totalValor.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: ECDBColors.wine, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  ...etapaDeals.map((d) => LongPressDraggable<String>(
                    data: d.id,
                    feedback: Material(
                      elevation: 6, borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 220, padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: ECDBColors.surface, borderRadius: BorderRadius.circular(10)),
                        child: Text(d.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ECDBColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ECDBColors.border, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.titulo, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          if (d.contactoNombre != null)
                            Text(d.contactoNombre!, style: Theme.of(ctx).textTheme.bodySmall),
                          if (d.valor > 0)
                            Text('€${d.valor.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, color: ECDBColors.wine, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  )),
                  if (etapaDeals.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('—', style: TextStyle(color: ECDBColors.textMuted)),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
