import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/qr_service.dart';
import '../../../shared/widgets/ecdb_button.dart';
import '../../../shared/widgets/ecdb_toast.dart';

/// Bottom sheet para generar QR de fichaje por ubicación.
class QrGeneratorSheet extends StatefulWidget {
  const QrGeneratorSheet({super.key});

  @override
  State<QrGeneratorSheet> createState() => _QrGeneratorSheetState();
}

class _QrGeneratorSheetState extends State<QrGeneratorSheet> {
  List<Map<String, dynamic>> _ubicaciones = [];
  String? _selectedId;
  String? _qrContent;
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadUbicaciones();
  }

  Future<void> _loadUbicaciones() async {
    try {
      final data = await SupabaseService.client
          .from('ubicaciones')
          .select()
          .eq('activo', true)
          .order('nombre');
      setState(() {
        _ubicaciones = (data as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _generateQr() async {
    if (_selectedId == null) return;
    setState(() => _generating = true);

    try {
      // URL del modo kiosco — funciona en cualquier navegador móvil
      // En producción, cambiar por el dominio real (ej: cosecha.encopadebalon.com)
      final content = 'https://cosecha.encopadebalon.com/#/kiosk/$_selectedId';
      setState(() {
        _qrContent = content;
        _generating = false;
      });
    } catch (e) {
      if (mounted) {
        ECDBToast.show(context, message: 'Error al generar QR', type: ToastType.error);
      }
      setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Generar QR de Fichaje',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona una ubicación para generar su código QR único.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ECDBColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),

              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Selector de ubicación
                DropdownButtonFormField<String>(
                  value: _selectedId,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items: _ubicaciones.map((u) {
                    return DropdownMenuItem(
                      value: u['id'] as String,
                      child: Text(u['nombre'] as String),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() {
                    _selectedId = v;
                    _qrContent = null;
                  }),
                ),
                const SizedBox(height: 20),

                ECDBButton(
                  label: 'Generar QR',
                  icon: Icons.qr_code,
                  isExpanded: true,
                  isLoading: _generating,
                  onPressed: _selectedId == null ? null : _generateQr,
                ),
              ],

              // QR generado
              if (_qrContent != null) ...[
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ECDBColors.border),
                    ),
                    child: QrImageView(
                      data: _qrContent!,
                      version: QrVersions.auto,
                      size: 220,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: ECDBColors.wine,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: ECDBColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _ubicaciones
                            .firstWhere(
                              (u) => u['id'] == _selectedId,
                              orElse: () => {'nombre': ''},
                            )['nombre']
                            as String? ??
                        '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Imprime este QR y colócalo en la entrada del local.\nEl empleado lo escanea con su móvil, mete su PIN y ficha.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ECDBColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
