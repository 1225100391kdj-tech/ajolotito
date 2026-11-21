
import 'package:ajolotito/dominio/mascota.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 11, 12, 10, 0);

  group('saciedad', () {
    test('empieza en 100 y baja 10 puntos por hora', () {
      final m = Mascota.nueva('Xólotl', t0);

      expect(m.saciedadEn(t0), 100);
      expect(
        m.saciedadEn(t0.add(const Duration(hours: 3))),
        70,
      );
    });

    test('nunca baja de 0', () {
      final m = Mascota.nueva('Xólotl', t0);

      expect(
        m.saciedadEn(t0.add(const Duration(days: 5))),
        0,
      );
    });

    test('antes del punto de partida devuelve la base', () {
      final m = Mascota.nueva('Xólotl', t0);

      expect(
        m.saciedadEn(
          t0.subtract(const Duration(hours: 2)),
        ),
        100,
      );
    });
  });

  group('humor (pruebas de frontera)', () {
    final m = Mascota.nueva('Xólotl', t0);

    Humor aLas(double horas) {
      return m.humorEn(
        t0.add(
          Duration(minutes: (horas * 60).round()),
        ),
      );
    }

    test('feliz mientras la saciedad sea mayor a 40', () {
      expect(aLas(5.9), Humor.feliz);
    });

    test('hambriento justo en 40', () {
      expect(aLas(6), Humor.hambriento);
    });

    test('hambriento hasta pasar 15', () {
      expect(aLas(8), Humor.hambriento);
    });

    test('famélico justo en 15', () {
      expect(aLas(8.5), Humor.famelico);
    });
  });

  group('predicción: cuándo tendrá hambre', () {
    test('llega a 40 a las 6 horas y a 15 a las 8.5', () {
      final m = Mascota.nueva('Xólotl', t0);

      expect(
        m.momentoEnQueBajaA(40),
        t0.add(const Duration(hours: 6)),
      );

      expect(
        m.momentoEnQueBajaA(15),
        t0.add(
          const Duration(hours: 8, minutes: 30),
        ),
      );
    });

    test('si ya estaba por debajo, devuelve el inicio', () {
      final m = Mascota(
        nombre: 'X',
        saciedadBase: 30,
        desde: t0,
      );

      expect(m.momentoEnQueBajaA(40), t0);
    });

    test('predicción coincide con la saciedad', () {
      final m = Mascota(
        nombre: 'X',
        saciedadBase: 77,
        desde: t0,
        puntosPorHora: 7,
      );

      final cuando = m.momentoEnQueBajaA(40);

      expect(
        m.saciedadEn(cuando),
        closeTo(40, 0.001),
      );
    });
  });

  group('alimentar', () {
    test('suma una porción de 35 puntos', () {
      final m = Mascota.nueva('X', t0);

      final seis = t0.add(
        const Duration(hours: 6),
      );

      final nueva = m.alimentar(seis);

      expect(nueva.saciedadEn(seis), 75);
      expect(nueva.desde, seis);
    });

    test('no pasa de 100', () {
      final m = Mascota.nueva('X', t0);

      final tiempo = t0.add(
        const Duration(hours: 3),
      );

      final nueva = m.alimentar(tiempo);

      expect(nueva.saciedadEn(tiempo), 100);
    });

    test('con 90 o más ya no quiere comer', () {
      final m = Mascota.nueva('X', t0);

      expect(
        () => m.alimentar(t0),
        throwsA(isA<YaEstaLlena>()),
      );
    });
  });

  test('cambiar el ritmo no produce saltos', () {
    final m = Mascota.nueva('X', t0);

    final tiempo = t0.add(
      const Duration(hours: 2),
    );

    final nueva = m.conRitmo(tiempo, 600);

    expect(nueva.saciedadEn(tiempo), 80);

    expect(
      nueva.saciedadEn(
        tiempo.add(const Duration(minutes: 1)),
      ),
      closeTo(70, 0.001),
    );
  });

  group('guardar y leer JSON', () {
    test('ida y vuelta conserva todos los datos', () {
      final m = Mascota(
        nombre: 'Xólotl',
        saciedadBase: 63.5,
        desde: t0,
        puntosPorHora: 12,
      );

      final recuperada = Mascota.desdeTexto(
        m.aTexto(),
      )!;

      expect(recuperada.nombre, 'Xólotl');
      expect(recuperada.saciedadBase, 63.5);
      expect(recuperada.desde, t0);
      expect(recuperada.puntosPorHora, 12);
    });

    test('datos dañados devuelven null', () {
      expect(Mascota.desdeTexto(null), isNull);

      expect(
        Mascota.desdeTexto('esto no es json'),
        isNull,
      );

      expect(
        Mascota.desdeTexto('[1,2,3]'),
        isNull,
      );

      expect(
        Mascota.desdeTexto('{"nombre":"X"}'),
        isNull,
      );

      expect(
        Mascota.desdeTexto(
          '{"nombre":"X","saciedadBase":500,'
          '"desde":"2026-01-01T00:00:00",'
          '"puntosPorHora":10}',
        ),
        isNull,
      );

      expect(
        Mascota.desdeTexto(
          '{"nombre":"X","saciedadBase":50,'
          '"desde":"ayer","puntosPorHora":10}',
        ),
        isNull,
      );

      expect(
        Mascota.desdeTexto(
          '{"nombre":"X","saciedadBase":50,'
          '"desde":"2026-01-01T00:00:00",'
          '"puntosPorHora":0}',
        ),
        isNull,
      );
    });
  });
}
