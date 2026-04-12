import 'package:flutter_test/flutter_test.dart';
import 'package:cosecha/core/models/referido.dart';

void main() {
  group('Elegibilidad de bonificación de referido', () {
    test('elegible después de 6 meses de contratación', () {
      final referido = Referido(
        id: 'test-1',
        referidoPorId: 'emp-1',
        referidoPorNombre: 'Juan García',
        candidatoNombre: 'María López',
        estado: EstadoReferido.contratado,
        fechaEnvio: DateTime(2025, 1, 1),
        fechaContratacion: DateTime(2025, 3, 1), // hace > 6 meses
        creado: DateTime(2025, 1, 1),
      );
      expect(referido.elegibleParaBonificacion, true);
    });

    test('NO elegible antes de 6 meses', () {
      final referido = Referido(
        id: 'test-2',
        referidoPorId: 'emp-1',
        referidoPorNombre: 'Juan García',
        candidatoNombre: 'Pedro Sánchez',
        estado: EstadoReferido.contratado,
        fechaEnvio: DateTime.now().subtract(const Duration(days: 30)),
        fechaContratacion: DateTime.now().subtract(const Duration(days: 30)),
        creado: DateTime.now().subtract(const Duration(days: 30)),
      );
      expect(referido.elegibleParaBonificacion, false);
    });

    test('NO elegible si no contratado', () {
      final referido = Referido(
        id: 'test-3',
        referidoPorId: 'emp-1',
        referidoPorNombre: 'Juan García',
        candidatoNombre: 'Laura Martín',
        estado: EstadoReferido.enProceso,
        fechaEnvio: DateTime(2025, 1, 1),
        creado: DateTime(2025, 1, 1),
      );
      expect(referido.elegibleParaBonificacion, false);
    });

    test('NO elegible si ya tiene bonificación', () {
      final referido = Referido(
        id: 'test-4',
        referidoPorId: 'emp-1',
        referidoPorNombre: 'Juan García',
        candidatoNombre: 'Ana Torres',
        estado: EstadoReferido.contratado,
        fechaEnvio: DateTime(2024, 1, 1),
        fechaContratacion: DateTime(2024, 3, 1),
        fechaBonificacion: DateTime(2024, 9, 1), // ya pagada
        creado: DateTime(2024, 1, 1),
      );
      expect(referido.elegibleParaBonificacion, false);
    });

    test('monto bonificación por defecto es 200 EUR', () {
      final referido = Referido(
        id: 'test-5',
        referidoPorId: 'emp-1',
        referidoPorNombre: 'Juan García',
        candidatoNombre: 'Test',
        estado: EstadoReferido.enviado,
        fechaEnvio: DateTime.now(),
        creado: DateTime.now(),
      );
      expect(referido.montoBonificacion, 200.0);
    });

    test('estado descartado no es elegible', () {
      final referido = Referido(
        id: 'test-6',
        referidoPorId: 'emp-1',
        referidoPorNombre: 'Juan García',
        candidatoNombre: 'Descartado',
        estado: EstadoReferido.descartado,
        fechaEnvio: DateTime(2024, 1, 1),
        creado: DateTime(2024, 1, 1),
      );
      expect(referido.elegibleParaBonificacion, false);
    });
  });
}
