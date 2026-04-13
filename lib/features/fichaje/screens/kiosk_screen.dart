import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/ecdb_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/geo_utils.dart';

/// Modo Kiosco — pantalla que se abre al escanear QR del local.
/// No requiere tener la app instalada. Solo PIN → fichar.
/// URL: /kiosk/{ubicacionId}
class KioskScreen extends StatefulWidget {
  final String ubicacionId;
  const KioskScreen({super.key, required this.ubicacionId});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  String _pin = '';
  String _ubicacionNombre = 'Cargando...';
  bool _loading = true;
  bool _processing = false;
  String? _mensaje;
  bool? _exito;
  Map<String, dynamic>? _ubicacionData;

  @override
  void initState() {
    super.initState();
    _loadUbicacion();
  }

  Future<void> _loadUbicacion() async {
    try {
      final data = await SupabaseService.client
          .from('ubicaciones')
          .select()
          .eq('id', widget.ubicacionId)
          .single();

      setState(() {
        _ubicacionData = data;
        _ubicacionNombre = data['nombre'] as String;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _ubicacionNombre = 'Ubicación no encontrada';
        _loading = false;
      });
    }
  }

  void _onDigit(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _mensaje = null;
        _exito = null;
      });
      HapticFeedback.lightImpact();

      if (_pin.length == 4) {
        _fichar();
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _fichar() async {
    setState(() => _processing = true);

    try {
      // Validar PIN
      final empResult = await SupabaseService.client.rpc(
        'validate_pin',
        params: {'pin_code': _pin},
      );

      if (empResult == null) {
        setState(() {
          _processing = false;
          _mensaje = 'PIN incorrecto';
          _exito = false;
          _pin = '';
        });
        return;
      }

      final empData = empResult as Map<String, dynamic>;
      final empId = empData['id'] as String;
      final empNombre = empData['nombre'] as String;

      // Determinar si es entrada o salida
      final hoy = DateTime.now();
      final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);

      final fichajes = await SupabaseService.client
          .from('fichajes')
          .select()
          .eq('empleado_id', empId)
          .gte('timestamp', inicioHoy.toIso8601String())
          .order('timestamp', ascending: false)
          .limit(1);

      final lista = fichajes as List;
      final tipo = lista.isEmpty || lista.first['tipo'] == 'salida'
          ? 'entrada'
          : 'salida';

      // Registrar fichaje
      await SupabaseService.client.from('fichajes').insert({
        'empleado_id': empId,
        'empleado_nombre': empNombre,
        'tipo': tipo,
        'timestamp': DateTime.now().toIso8601String(),
        'ubicacion_id': widget.ubicacionId,
        'valido': true,
        'metodo': 'qr',
      });

      final hora = CosechaDateUtils.formatTime(DateTime.now());

      setState(() {
        _processing = false;
        _exito = true;
        _mensaje = tipo == 'entrada'
            ? '$empNombre — Entrada registrada a las $hora'
            : '$empNombre — Salida registrada a las $hora';
        _pin = '';
      });

      // Limpiar después de 5 segundos
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _mensaje = null;
            _exito = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _processing = false;
        _mensaje = 'Error de conexión. Inténtalo de nuevo.';
        _exito = false;
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ECDBColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ECDBColors.wine,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('C',
                        style: TextStyle(
                            color: ECDBColors.gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 32,
                            fontFamily: 'serif')),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Cosecha',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),

                // Ubicación
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: ECDBColors.wine.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: ECDBColors.wine),
                      const SizedBox(width: 6),
                      Text(_ubicacionNombre,
                          style: const TextStyle(
                              color: ECDBColors.wine,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Mensaje de resultado
                if (_mensaje != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: _exito == true
                          ? ECDBColors.successLight
                          : ECDBColors.errorLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _exito == true
                              ? Icons.check_circle
                              : Icons.error,
                          color: _exito == true
                              ? ECDBColors.success
                              : ECDBColors.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_mensaje!,
                              style: TextStyle(
                                  color: _exito == true
                                      ? ECDBColors.success
                                      : ECDBColors.error,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),

                // Instrucción
                Text('Introduce tu PIN para fichar',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),

                // PIN dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < _pin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? ECDBColors.wine : Colors.transparent,
                        border: Border.all(
                            color:
                                filled ? ECDBColors.wine : ECDBColors.textMuted,
                            width: 2),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),

                // Teclado numérico
                if (_processing)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child:
                        CircularProgressIndicator(color: ECDBColors.wine),
                  )
                else
                  _buildKeypad(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 76),
            const SizedBox(width: 12),
            _key('0'),
            const SizedBox(width: 12),
            SizedBox(
              width: 76,
              height: 76,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onDelete,
                  borderRadius: BorderRadius.circular(38),
                  child: const Center(
                      child: Icon(Icons.backspace_outlined,
                          color: ECDBColors.textSecondary, size: 24)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits
          .map((d) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _key(d),
              ))
          .toList(),
    );
  }

  Widget _key(String label) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Material(
        color: ECDBColors.surface,
        borderRadius: BorderRadius.circular(38),
        elevation: 1,
        child: InkWell(
          onTap: () => _onDigit(label),
          borderRadius: BorderRadius.circular(38),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: ECDBColors.textPrimary)),
          ),
        ),
      ),
    );
  }
}
