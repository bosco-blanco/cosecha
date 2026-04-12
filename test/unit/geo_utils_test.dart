import 'package:flutter_test/flutter_test.dart';
import 'package:cosecha/core/utils/geo_utils.dart';

void main() {
  group('GeoUtils', () {
    test('haversineDistance entre dos puntos conocidos en Madrid', () {
      // Zoco de Pozuelo → CODEBA Nave Leganés (~13km)
      final distance = GeoUtils.haversineDistance(
        lat1: 40.4357,
        lon1: -3.8123,
        lat2: 40.3270,
        lon2: -3.7640,
      );
      // Debería ser ~12-13km
      expect(distance, greaterThan(11000));
      expect(distance, lessThan(14000));
    });

    test('haversineDistance devuelve 0 para el mismo punto', () {
      final distance = GeoUtils.haversineDistance(
        lat1: 40.4168,
        lon1: -3.7038,
        lat2: 40.4168,
        lon2: -3.7038,
      );
      expect(distance, closeTo(0, 0.01));
    });

    test('distancia entre dos tiendas cercanas', () {
      // Calle Núñez de Balboa → La Casita (Claudio Coello) (~350m)
      final distance = GeoUtils.haversineDistance(
        lat1: 40.4280,
        lon1: -3.6830,
        lat2: 40.4295,
        lon2: -3.6795,
      );
      expect(distance, greaterThan(200));
      expect(distance, lessThan(600));
    });

    test('formatDistance muestra metros bajo 1km', () {
      expect(GeoUtils.formatDistance(150), '150 m');
      expect(GeoUtils.formatDistance(50), '50 m');
    });

    test('formatDistance muestra km sobre 1km', () {
      expect(GeoUtils.formatDistance(1500), '1.5 km');
      expect(GeoUtils.formatDistance(12500), '12.5 km');
    });
  });
}
