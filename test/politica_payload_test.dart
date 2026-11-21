
import 'package:ajolotito/dominio/payload.dart';
import 'package:ajolotito/dominio/politica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const p = PoliticaNotificaciones();

  DateTime a(int hora, [int minuto = 0, int dia = 12]) {
    return DateTime(2026, 11, dia, hora, minuto);
  }

  group('horas de silencio', () {
    test('de 22:00 a 07:59 hay silencio', () {
      for (final hora in [22, 23, 0, 3, 7]) {
        expect(
          p.enSilencio(a(hora)),
          isTrue,
          reason: 'hora $hora',
        );
      }
    });

    test('de 08:00 a 21:59 no hay silencio', () {
      for (final hora in [8, 12, 18, 21]) {
        expect(
          p.enSilencio(a(hora)),
          isFalse,
          reason: 'hora $hora',
        );
      }
    });

    test('verificar los límites del silencio', () {
      expect(p.enSilencio(a(22)), isTrue);
      expect(p.enSilencio(a(7, 59)), isTrue);
      expect(p.enSilencio(a(8)), isFalse);
    });

    test('si las horas son iguales no hay silencio', () {
      const sinSilencio = PoliticaNotificaciones(
        silencioDesde: 8,
        silencioHasta: 8,
      );

      expect(
        sinSilencio.enSilencio(a(3)),
        isFalse,
      );
    });

    test('silencio durante el mismo día', () {
      const siesta = PoliticaNotificaciones(
        silencioDesde: 13,
        silencioHasta: 15,
      );

      expect(siesta.enSilencio(a(14)), isTrue);
      expect(siesta.enSilencio(a(15)), isFalse);
    });
  });

  group('ajustar notificaciones', () {
    test('durante el día no cambia la hora', () {
      expect(p.ajustar(a(12)), a(12));
    });

    test('a las 23:00 pasa a las 08:00 del día siguiente', () {
      expect(
        p.ajustar(a(23)),
        DateTime(2026, 11, 13, 8),
      );
    });

    test('a las 03:00 pasa a las 08:00 del mismo día', () {
      expect(
        p.ajustar(a(3)),
        a(8),
      );
    });

    test('ajustar al cambiar de mes', () {
      expect(
        p.ajustar(DateTime(2026, 11, 30, 23)),
        DateTime(2026, 12, 1, 8),
      );
    });
  });

  group('payload de notificaciones', () {
    test('codificar y decodificar destinos', () {
      for (final destino in Destino.values) {
        final original = PayloadNotif(destino);

        final recuperado = PayloadNotif.decodificar(
          original.codificar(),
        );

        expect(recuperado.destino, destino);
      }
    });

    test('utiliza el formato versionado', () {
      expect(
        const PayloadNotif(
          Destino.alimentar,
        ).codificar(),
        'v1:alimentar',
      );
    });

    test('datos incorrectos abren el inicio', () {
      for (final texto in [
        null,
        '',
        'hola',
        'v2:alimentar',
        'v1:',
        'v1:borrarTodo',
        'v1:alimentar:extra',
      ]) {
        expect(
          PayloadNotif.decodificar(texto).destino,
          Destino.inicio,
          reason: '$texto',
        );
      }
    });
  });
}
