import 'package:uuid/uuid.dart';
import 'supabase_service.dart';

/// Servicio QR — generar códigos QR por ubicación y validar escaneos.
class QrService {
  QrService._();

  /// Genera un token QR único para una ubicación.
  /// Solo admin puede generar QR.
  static Future<String> generateQrForUbicacion(String ubicacionId) async {
    final qrCode = const Uuid().v4();

    await SupabaseService.client
        .from('ubicaciones')
        .update({'qr_code': qrCode})
        .eq('id', ubicacionId);

    return qrCode;
  }

  /// Valida un QR escaneado y devuelve la ubicación asociada.
  static Future<Map<String, dynamic>?> validateQr(String qrCode) async {
    final result = await SupabaseService.client
        .from('ubicaciones')
        .select()
        .eq('qr_code', qrCode)
        .eq('activo', true)
        .maybeSingle();

    return result;
  }

  /// Genera el contenido del QR: URL con token.
  static String buildQrContent({
    required String ubicacionId,
    required String qrCode,
  }) {
    return 'cosecha://fichaje?ubicacion=$ubicacionId&qr=$qrCode';
  }

  /// Parsea el contenido de un QR escaneado.
  static ({String? ubicacionId, String? qrCode}) parseQrContent(String content) {
    final uri = Uri.tryParse(content);
    if (uri == null) return (ubicacionId: null, qrCode: null);

    return (
      ubicacionId: uri.queryParameters['ubicacion'],
      qrCode: uri.queryParameters['qr'],
    );
  }
}
