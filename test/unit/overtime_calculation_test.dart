import 'package:flutter_test/flutter_test.dart';
import 'package:cosecha/core/utils/date_utils.dart';

void main() {
  group('Cálculo de horas extra (ley española: >40h/semana)', () {
    test('calcula 5h extra para semana de 45h', () {
      final horasDiarias = [
        const Duration(hours: 9),     // Lunes
        const Duration(hours: 8),     // Martes
        const Duration(hours: 8),     // Miércoles
        const Duration(hours: 8),     // Jueves
        const Duration(hours: 8),     // Viernes
        const Duration(hours: 4),     // Sábado
      ];
      final extra = CosechaDateUtils.calcularHorasExtra(horasDiarias);
      expect(extra.inHours, 5);
    });

    test('devuelve 0 horas extra para semana de 40h', () {
      final horasDiarias = [
        const Duration(hours: 8),
        const Duration(hours: 8),
        const Duration(hours: 8),
        const Duration(hours: 8),
        const Duration(hours: 8),
      ];
      final extra = CosechaDateUtils.calcularHorasExtra(horasDiarias);
      expect(extra, Duration.zero);
    });

    test('devuelve 0 horas extra para semana corta (32h)', () {
      final horasDiarias = [
        const Duration(hours: 8),
        const Duration(hours: 8),
        const Duration(hours: 8),
        const Duration(hours: 8),
      ];
      final extra = CosechaDateUtils.calcularHorasExtra(horasDiarias);
      expect(extra, Duration.zero);
    });

    test('maneja jornadas con minutos (40h 30min → 30min extra)', () {
      final horasDiarias = [
        const Duration(hours: 8, minutes: 6),  // 5 días × 8h06min = 40h30min
        const Duration(hours: 8, minutes: 6),
        const Duration(hours: 8, minutes: 6),
        const Duration(hours: 8, minutes: 6),
        const Duration(hours: 8, minutes: 6),
      ];
      final extra = CosechaDateUtils.calcularHorasExtra(horasDiarias);
      expect(extra.inMinutes, 30);
    });
  });

  group('Formateo de duración', () {
    test('formatea solo horas', () {
      expect(CosechaDateUtils.formatDuration(const Duration(hours: 8)), '8h');
    });

    test('formatea horas y minutos', () {
      expect(
        CosechaDateUtils.formatDuration(const Duration(hours: 8, minutes: 30)),
        '8h 30min',
      );
    });

    test('formatea solo minutos', () {
      expect(
        CosechaDateUtils.formatDuration(const Duration(minutes: 45)),
        '45min',
      );
    });
  });
}
