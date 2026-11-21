
import 'package:ajolotito/dominio/almacen.dart';
import 'package:ajolotito/dominio/categoria.dart';
import 'package:ajolotito/dominio/payload.dart';
import 'package:ajolotito/dominio/planificador.dart';
import 'package:ajolotito/dominio/reloj.dart';
import 'package:ajolotito/dominio/servicio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'falsos.dart';

void main() {
  DateTime d(int dia, int hora, [int minuto = 0]) {
    return DateTime(2026, 11, dia, hora, minuto);
  }

  late PuertoFalso puerto;
  late RelojFalso reloj;
  late AlmacenMemoria almacen;
  late ServicioAjolote servicio;

  setUp(() {
    puerto = PuertoFalso();

    reloj = RelojFalso(d(12, 10));

    almacen = AlmacenMemoria();

    servicio = ServicioAjolote(
      puerto: puerto,
      almacen: almacen,
      reloj: reloj,
    );
  });

  test('crea al ajolote y después recupera sus datos', () async {
    final primera = await servicio.cargar();

    reloj.avanzar(const Duration(hours: 3));

    final segunda = await servicio.cargar();

    expect(segunda.nombre, primera.nombre);

    expect(
      segunda.desde,
      primera.desde,
      reason: 'La mascota no debe reiniciarse',
    );
  });

  group('sincronizar', () {
    test('en segundo plano programa cinco avisos', () async {
      await servicio.alPasarAFondo();

      expect(
        puerto.programadas.keys.toSet(),
        {
          Ids.hambre,
          Ids.critico,
          100,
          101,
          102,
        },
      );

      expect(
        puerto.programadas[Ids.hambre]!.cuando,
        d(12, 16),
      );
    });

    test('sin permiso cancela todos los avisos', () async {
      await servicio.alPasarAFondo();

      expect(puerto.programadas, isNotEmpty);

      puerto.activas = false;

      await servicio.alPasarAFondo();

      expect(puerto.programadas, isEmpty);
      expect(servicio.programadas, isEmpty);
    });

    test('sincronizar dos veces no duplica avisos', () async {
      await servicio.alPasarAFondo();

      final antes = Map.of(puerto.programadas);

      await servicio.alPasarAFondo();

      expect(
        puerto.programadas.keys,
        antes.keys,
      );
    });
  });

  group('alimentar y actualizar notificaciones', () {
    test('después de comer se reemplazan los avisos', () async {
      await servicio.alPasarAFondo();

      // Avanzamos hasta las 15:00.
      reloj.fijar(d(12, 15));

      await servicio.alVolverAlFrente();

      // La mascota tenía 50 puntos y ahora tendrá 85.
      await servicio.alimentar();

      await servicio.alPasarAFondo();

      expect(
        puerto.programadas[Ids.hambre]!.cuando,
        d(12, 19, 30),
      );

      expect(
        puerto.programadas[Ids.critico]!.cuando,
        d(13, 8),
      );
    });
  });

  group('primer plano y segundo plano', () {
    test('en primer plano solo programa sorpresas', () async {
      await servicio.alVolverAlFrente();

      expect(
        puerto.programadas.containsKey(Ids.hambre),
        isFalse,
      );

      expect(
        puerto.programadas.containsKey(Ids.critico),
        isFalse,
      );

      expect(
        puerto.programadas.keys.toSet(),
        {100, 101, 102},
      );
    });

    test('al salir vuelve a programar el hambre', () async {
      await servicio.alVolverAlFrente();

      await servicio.alPasarAFondo();

      expect(
        puerto.programadas.containsKey(Ids.hambre),
        isTrue,
      );
    });
  });

  group('preferencias del usuario', () {
    test('desactivar hambre elimina sus avisos', () async {
      await servicio.alPasarAFondo();

      await servicio.cambiarCategoria(
        Categoria.hambre,
        false,
      );

      expect(
        puerto.programadas.keys.toSet(),
        {100, 101, 102},
      );

      expect(
        (await servicio.categorias())[Categoria.hambre],
        isFalse,
      );
    });

    test('desactivar sorpresas deja solo hambre', () async {
      await servicio.alPasarAFondo();

      await servicio.cambiarCategoria(
        Categoria.sorpresa,
        false,
      );

      expect(
        puerto.programadas.keys.toSet(),
        {
          Ids.hambre,
          Ids.critico,
        },
      );
    });
  });

  group('modo clase', () {
    test('el ritmo acelerado programa avisos en minutos', () async {
      await servicio.cambiarRitmo(
        ServicioAjolote.ritmoClase,
      );

      await servicio.alPasarAFondo();

      expect(
        puerto.programadas[Ids.hambre]!.cuando,
        d(12, 10, 6),
      );

      expect(
        puerto.programadas[Ids.critico]!.cuando,
        DateTime(2026, 11, 12, 10, 8, 30),
      );
    });
  });

  group('toques de notificaciones', () {
    test('el payload determina la pantalla inicial', () async {
      puerto.lanzamiento = 'v1:alimentarYa';

      expect(
        await servicio.destinoDeLanzamiento(),
        Destino.alimentarYa,
      );
    });

    test('sin notificación abre en inicio', () async {
      expect(
        await servicio.destinoDeLanzamiento(),
        Destino.inicio,
      );
    });

    test('un payload incorrecto abre en inicio', () async {
      puerto.lanzamiento = '¿¿??';

      expect(
        await servicio.destinoDeLanzamiento(),
        Destino.inicio,
      );
    });
  });

  test('probarAhora muestra una notificación inmediata', () async {
    await servicio.probarAhora();

    expect(
      puerto.mostradas,
      hasLength(1),
    );
  });
}
