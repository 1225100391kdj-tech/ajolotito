
import 'package:ajolotito/dominio/categoria.dart';
import 'package:ajolotito/dominio/mascota.dart';
import 'package:ajolotito/dominio/planificador.dart';
import 'package:ajolotito/dominio/politica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime d(int dia, int hora, [int minuto = 0]) {
    return DateTime(2026, 11, dia, hora, minuto);
  }

  const plani = Planificador();

  test('día normal: hambre, crítico y sorpresas', () {
    final ahora = d(12, 10);

    final plan = plani.planear(
      Mascota.nueva('Xólotl', ahora),
      ahora,
    );

    expect(
      plan.map((p) => (p.id, p.cuando)).toList(),
      [
        (Ids.hambre, d(12, 16)),
        (Ids.sorpresa(0), d(12, 18)),
        (Ids.critico, d(12, 18, 30)),
        (Ids.sorpresa(1), d(13, 18)),
        (Ids.sorpresa(2), d(14, 18)),
      ],
    );
  });

  test('cada notificación lleva payload y mensajes', () {
    final ahora = d(12, 10);

    final plan = plani.planear(
      Mascota.nueva('Xólotl', ahora),
      ahora,
    );

    final hambre = plan.firstWhere(
      (p) => p.id == Ids.hambre,
    );

    final juego = plan.firstWhere(
      (p) => p.id == Ids.sorpresa(0),
    );

    expect(hambre.payload, 'v1:alimentar');
    expect(juego.payload, 'v1:jugar');

    expect(
      hambre.titulo.isNotEmpty &&
          hambre.cuerpo.isNotEmpty,
      isTrue,
    );
  });

  group('horas de silencio', () {
    test('el aviso crítico nocturno pasa a las 08:00', () {
      final ahora = d(12, 15);

      final plan = plani.planear(
        Mascota.nueva('X', ahora),
        ahora,
      );

      expect(
        plan.firstWhere(
          (p) => p.id == Ids.hambre,
        ).cuando,
        d(12, 21),
      );

      expect(
        plan.firstWhere(
          (p) => p.id == Ids.critico,
        ).cuando,
        d(13, 8),
      );
    });

    test('si hambre y crítico coinciden, queda el crítico', () {
      final ahora = d(12, 17);

      final plan = plani.planear(
        Mascota.nueva('X', ahora),
        ahora,
      );

      expect(
        plan.any((p) => p.id == Ids.hambre),
        isFalse,
      );

      expect(
        plan.firstWhere(
          (p) => p.id == Ids.critico,
        ).cuando,
        d(13, 8),
      );
    });

    test('nunca se programa durante las horas de silencio', () {
      for (var hora = 0; hora < 24; hora++) {
        final ahora = d(12, hora, 17);

        final plan = plani.planear(
          Mascota.nueva('X', ahora),
          ahora,
        );

        for (final aviso in plan) {
          expect(
            plani.politica.enSilencio(aviso.cuando),
            isFalse,
            reason: 'Hora $hora, aviso ${aviso.id}',
          );
        }
      }
    });
  });

  group('no avisar de lo que ya pasó', () {
    test('si ya tiene hambre, solo programa el crítico', () {
      final ahora = d(12, 10);

      final mascota = Mascota(
        nombre: 'X',
        saciedadBase: 30,
        desde: ahora,
      );

      final plan = plani.planear(mascota, ahora);

      expect(
        plan.where((p) => p.esDeHambre).map((p) => p.id),
        [Ids.critico],
      );

      expect(
        plan.firstWhere(
          (p) => p.id == Ids.critico,
        ).cuando,
        d(12, 11, 30),
      );
    });

    test('si ya está famélico, no programa avisos de hambre', () {
      final ahora = d(12, 10);

      final mascota = Mascota(
        nombre: 'X',
        saciedadBase: 10,
        desde: ahora,
      );

      expect(
        plani.planear(mascota, ahora).where(
          (p) => p.esDeHambre,
        ),
        isEmpty,
      );
    });

    test('después de las 18:00, la sorpresa inicia mañana', () {
      final ahora = d(12, 19);

      final mascota = Mascota.nueva('X', ahora);

      final sorpresas = plani
          .planear(mascota, ahora)
          .where((p) => p.categoria == Categoria.sorpresa)
          .toList();

      expect(
        sorpresas.map((p) => p.cuando),
        [
          d(13, 18),
          d(14, 18),
          d(15, 18),
        ],
      );
    });
  });

  group('categorías apagadas', () {
    test('sin hambre, solo hay sorpresas', () {
      const sinHambre = Planificador(
        politica: PoliticaNotificaciones(
          activas: {Categoria.sorpresa},
        ),
      );

      final ahora = d(12, 10);

      final plan = sinHambre.planear(
        Mascota.nueva('X', ahora),
        ahora,
      );

      expect(
        plan.every(
          (p) => p.categoria == Categoria.sorpresa,
        ),
        isTrue,
      );

      expect(plan, hasLength(3));
    });

    test('sin sorpresas, solo hay hambre', () {
      const sinSorpresas = Planificador(
        politica: PoliticaNotificaciones(
          activas: {Categoria.hambre},
        ),
      );

      final ahora = d(12, 10);

      final plan = sinSorpresas.planear(
        Mascota.nueva('X', ahora),
        ahora,
      );

      expect(
        plan.map((p) => p.id),
        [Ids.hambre, Ids.critico],
      );
    });

    test('con todo apagado, la lista está vacía', () {
      const nada = Planificador(
        politica: PoliticaNotificaciones(
          activas: {},
        ),
      );

      final ahora = d(12, 10);

      expect(
        nada.planear(
          Mascota.nueva('X', ahora),
          ahora,
        ),
        isEmpty,
      );
    });
  });

  test('tope diario: máximo dos avisos', () {
    const tope2 = Planificador(
      politica: PoliticaNotificaciones(
        maxPorDia: 2,
      ),
    );

    final ahora = d(12, 10);

    final plan = tope2.planear(
      Mascota.nueva('X', ahora),
      ahora,
    );

    final hoy = plan
        .where((p) => p.cuando.day == 12)
        .map((p) => p.id)
        .toList();

    expect(
      hoy,
      [Ids.hambre, Ids.critico],
    );

    expect(plan, hasLength(4));
  });

  test('los identificadores de avisos son únicos', () {
    final ahora = d(12, 10);

    final ids = plani
        .planear(Mascota.nueva('X', ahora), ahora)
        .map((p) => p.id)
        .toList();

    expect(
      ids.toSet().length,
      ids.length,
    );

    expect(
      ids.every(Ids.todos.contains),
      isTrue,
    );
  });
}
