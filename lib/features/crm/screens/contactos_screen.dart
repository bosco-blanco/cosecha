import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/models/contacto.dart';
import '../../../core/providers/crm_provider.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_card.dart';
import '../../../shared/widgets/ecdb_empty_state.dart';
import '../../../shared/widgets/ecdb_toast.dart';

class ContactosScreen extends ConsumerWidget {
  const ContactosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactos = ref.watch(contactosProvider);

    return Scaffold(
      appBar: ECDBAppBar(
        title: 'Contactos',
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showCrear(context, ref)),
        ],
      ),
      body: contactos.isEmpty
          ? ECDBEmptyState(
              icon: Icons.people_outline,
              title: 'Sin contactos',
              description: 'Añade tu primer contacto comercial.',
              ctaLabel: 'Nuevo Contacto',
              onCtaPressed: () => _showCrear(context, ref),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(contactosProvider.notifier).load(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: contactos.length,
                itemBuilder: (_, i) {
                  final c = contactos[i];
                  return ECDBCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: ECDBColors.wine.withOpacity(0.1),
                          child: Text(c.nombre[0], style: const TextStyle(color: ECDBColors.wine, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.nombre, style: Theme.of(context).textTheme.titleSmall),
                              if (c.empresa != null)
                                Text(c.empresa!, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ECDBColors.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(c.tipo.name, style: const TextStyle(fontSize: 10, color: ECDBColors.gold, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _showCrear(BuildContext context, WidgetRef ref) {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final empresaCtrl = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nuevo Contacto', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre *')),
            const SizedBox(height: 12),
            TextField(controller: empresaCtrl, decoration: const InputDecoration(labelText: 'Empresa')),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nombreCtrl.text.trim().isEmpty) return;
                  await ref.read(contactosProvider.notifier).crear(
                    nombre: nombreCtrl.text.trim(),
                    email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    telefono: telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
                    empresa: empresaCtrl.text.trim().isEmpty ? null : empresaCtrl.text.trim(),
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ECDBToast.show(context, message: 'Contacto creado', type: ToastType.success);
                  }
                },
                child: const Text('Crear Contacto'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
