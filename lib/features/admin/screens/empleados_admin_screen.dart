import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/ecdb_app_bar.dart';
import '../../../shared/widgets/ecdb_card.dart';
import '../../../shared/widgets/ecdb_toast.dart';

/// Provider de lista de empleados (admin).
final empleadosAdminProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await SupabaseService.client
      .from('empleados')
      .select('*, ubicaciones(nombre)')
      .order('nombre');
  return (data as List).cast<Map<String, dynamic>>();
});

/// Gestión de empleados — crear, ver PIN, activar/desactivar.
class EmpleadosAdminScreen extends ConsumerWidget {
  const EmpleadosAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empleadosAsync = ref.watch(empleadosAdminProvider);

    return Scaffold(
      appBar: ECDBAppBar(
        title: 'Empleados',
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showCrearEmpleado(context, ref),
          ),
        ],
      ),
      body: empleadosAsync.when(
        data: (empleados) => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: empleados.length,
          itemBuilder: (_, i) {
            final e = empleados[i];
            final nombre = e['nombre'] as String;
            final email = e['email'] as String;
            final pin = e['pin'] as String;
            final rol = (e['rol'] as String).toUpperCase();
            final activo = e['activo'] as bool;
            final ubicacion = e['ubicaciones'] != null
                ? (e['ubicaciones'] as Map)['nombre'] as String?
                : null;

            final rolColor = switch (e['rol'] as String) {
              'admin' => ECDBColors.error,
              'manager' => ECDBColors.warning,
              'comercial' => ECDBColors.info,
              _ => ECDBColors.textSecondary,
            };

            return ECDBCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: activo
                            ? ECDBColors.wine.withOpacity(0.1)
                            : ECDBColors.textMuted.withOpacity(0.1),
                        child: Text(
                          nombre[0],
                          style: TextStyle(
                            color: activo ? ECDBColors.wine : ECDBColors.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(nombre,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: activo ? null : ECDBColors.textMuted,
                                        )),
                                if (!activo) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: ECDBColors.textMuted.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('INACTIVO',
                                        style: TextStyle(fontSize: 9, color: ECDBColors.textMuted, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ],
                            ),
                            Text(email, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: rolColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(rol,
                            style: TextStyle(fontSize: 10, color: rolColor, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // PIN
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: pin));
                          ECDBToast.show(context, message: 'PIN copiado: $pin', type: ToastType.success);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: ECDBColors.bgAlt,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ECDBColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.pin, size: 14, color: ECDBColors.textSecondary),
                              const SizedBox(width: 6),
                              Text('PIN: $pin',
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter', letterSpacing: 2)),
                              const SizedBox(width: 6),
                              const Icon(Icons.copy, size: 12, color: ECDBColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (ubicacion != null)
                        Text(ubicacion,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ECDBColors.textMuted)),
                    ],
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

  void _showCrearEmpleado(BuildContext context, WidgetRef ref) {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    String rol = 'empleado';
    String? ubicacionId;
    final pinGenerado = _generatePin();
    List<Map<String, dynamic>> ubicaciones = [];

    // Cargar ubicaciones
    SupabaseService.client.from('ubicaciones').select().order('nombre').then((data) {
      ubicaciones = (data as List).cast<Map<String, dynamic>>();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nuevo Empleado', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),

                // PIN generado automáticamente
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ECDBColors.wine.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ECDBColors.wine.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Text('PIN generado',
                          style: TextStyle(fontSize: 12, color: ECDBColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(pinGenerado,
                          style: const TextStyle(
                              fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: 8, fontFamily: 'Inter')),
                      const SizedBox(height: 4),
                      const Text('Comparte este PIN con el empleado',
                          style: TextStyle(fontSize: 11, color: ECDBColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre completo *')),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email *'),
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono'),
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),

                // Rol
                DropdownButtonFormField<String>(
                  value: rol,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'empleado', child: Text('Empleado')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'comercial', child: Text('Comercial')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setSheetState(() => rol = v!),
                ),
                const SizedBox(height: 12),

                // Ubicación
                DropdownButtonFormField<String>(
                  value: ubicacionId,
                  decoration: const InputDecoration(labelText: 'Ubicación base'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Sin asignar')),
                    ...ubicaciones.map((u) => DropdownMenuItem(
                        value: u['id'] as String, child: Text(u['nombre'] as String))),
                  ],
                  onChanged: (v) => setSheetState(() => ubicacionId = v),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nombreCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                        ECDBToast.show(context, message: 'Nombre y email son obligatorios', type: ToastType.warning);
                        return;
                      }

                      try {
                        await SupabaseService.client.from('empleados').insert({
                          'nombre': nombreCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'telefono': telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
                          'pin': pinGenerado,
                          'rol': rol,
                          'ubicacion_base_id': ubicacionId,
                          'activo': true,
                        });

                        ref.invalidate(empleadosAdminProvider);

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ECDBToast.show(context,
                              message: '${nombreCtrl.text.trim()} creado con PIN $pinGenerado',
                              type: ToastType.success);
                        }
                      } catch (e) {
                        ECDBToast.show(context, message: 'Error: $e', type: ToastType.error);
                      }
                    },
                    child: const Text('Crear Empleado'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Genera PIN aleatorio de 4 dígitos (evita 0000, 1234, etc.).
  static String _generatePin() {
    final random = Random();
    String pin;
    do {
      pin = (1000 + random.nextInt(9000)).toString();
    } while (['0000', '1111', '1234', '4321', '9999'].contains(pin));
    return pin;
  }
}
