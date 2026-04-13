import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';

/// Servicio de geolocalización para fichaje y visitas comerciales.
class LocationService {
  LocationService._();

  /// Obtener posición actual con alta precisión.
  static Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException('Los servicios de ubicación están desactivados.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException('Permiso de ubicación denegado.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'Permiso de ubicación denegado permanentemente. '
        'Actívalo en los ajustes del dispositivo.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  /// Calcular distancia entre dos puntos (Haversine) en metros.
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Verificar si una posición está dentro del radio permitido de una ubicación.
  static bool isWithinRadius({
    required double posLat,
    required double posLon,
    required double targetLat,
    required double targetLon,
    required int radioMetros,
  }) {
    final distance = calculateDistance(
      lat1: posLat,
      lon1: posLon,
      lat2: targetLat,
      lon2: targetLon,
    );
    return distance <= radioMetros;
  }
}

class LocationServiceException implements Exception {
  final String message;
  const LocationServiceException(this.message);

  @override
  String toString() => message;
}
