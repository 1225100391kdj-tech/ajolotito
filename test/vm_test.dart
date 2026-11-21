
import 'package:ajolotito/dominio/almacen.dart';
import 'package:ajolotito/dominio/categoria.dart';
import 'package:ajolotito/dominio/gestor_permiso.dart';
import 'package:ajolotito/dominio/mascota.dart';
import 'package:ajolotito/dominio/payload.dart';
import 'package:ajolotito/dominio/planificador.dart';
import 'package:ajolotito/dominio/reloj.dart';
import 'package:ajolotito/dominio/servicio.dart';
import 'package:ajolotito/presentacion/ajolote_vm.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'falsos.dart';

void main() {
  late PuertoFalso puerto;
  late RelojFalso reloj;
  late AjoloteViewModel vm;

  setUp(() {
    puerto = PuertoFalso()..activas = false;

    reloj = RelojFalso(
      DateTime(2026, 11, 12, 10),
    );

    final almacen = AlmacenMemoria();

    vm = AjoloteViewModel(
      servicio: ServicioAjolote(
        puerto: puerto,
        almacen: almacen,
        reloj: reloj,
      ),
      gestor: GestorPermiso(
        puerto: puerto,
        almacen: almacen,
      ),
      reloj: reloj,
    );

    puerto.escucharToques(
      vm.alTocarNotificacion,
    );
  });

  tearDown(() {
    vm.dispose();
  });

  test('al iniciar NO pide permiso', () async {
    await vm.iniciar(conReloj: false);

    expect(puerto.vecesPidioPermiso, 0);

    expect(
      vm.permiso,
      EstadoPermiso.sinPreguntar,
    );

    expect(vm.saciedad, 100);
  });

  test('activar avisos solicita permiso', () async {
    await vm.iniciar(conReloj: false);

    final resultado = await vm.activarAvisos();

    expect(
      resultado,
      ResultadoPermiso.concedido,
    );

    expect(
      vm.permiso,
      EstadoPermiso.concedido,
    );

    expect(vm.programadas, isNotEmpty);
  });

  test('si rechaza el permiso no se insiste', () async {
    puerto.usuarioAcepta = false;

    await vm.iniciar(conReloj: false);

    expect(
      await vm.activarAvisos(),
      ResultadoPermiso.denegado,
    );

    expect(puerto.programadas, isEmpty);

    expect(
      await vm.activarAvisos(),
      ResultadoPermiso.hayQueIrAAjustes,
    );
  });

  test('si está lleno no puede comer', () async {
    await vm.iniciar(conReloj: false);

    await vm.alimentar();

    expect(
      vm.aviso,
      contains('llenísimo'),
    );
  });

  test('alimentar aumenta la saciedad', () async {
    await vm.iniciar(conReloj: false);

    reloj.avanzar(
      const Duration(hours: 6),
    );

    expect(vm.humor, Humor.hambriento);

    await vm.alimentar();

    expect(vm.saciedad, 75);
    expect(vm.humor, Humor.feliz);
  });

  group('toques de notificaciones', () {
    test('tocar aviso de hambre resalta el botón', () async {
      await vm.iniciar(conReloj: false);

      puerto.simularToque('v1:alimentar');

      await Future<void>.delayed(
        Duration.zero,
      );

      expect(vm.resaltarAlimentar, isTrue);
    });

    test('dar de comer desde la notificación', () async {
      await vm.iniciar(conReloj: false);

      reloj.avanzar(
        const Duration(hours: 6),
      );

      puerto.simularToque('v1:alimentarYa');

      await Future<void>.delayed(
        Duration.zero,
      );

      expect(vm.saciedad, 75);
    });

    test('abrir desde la notificación alimenta', () async {
      await vm.servicio.cargar();

      reloj.avanzar(
        const Duration(hours: 6),
      );

      await vm.iniciar(
        destino: Destino.alimentarYa,
        conReloj: false,
      );

      expect(vm.saciedad, 75);
    });
  });

  test('el ciclo de vida programa y cancela hambre', () async {
    puerto.activas = true;

    await vm.iniciar(conReloj: false);

    expect(
      puerto.programadas.containsKey(Ids.hambre),
      isFalse,
    );

    await vm.alCambiarCicloDeVida(
      AppLifecycleState.paused,
    );

    expect(
      puerto.programadas.containsKey(Ids.hambre),
      isTrue,
    );

    await vm.alCambiarCicloDeVida(
      AppLifecycleState.resumed,
    );

    expect(
      puerto.programadas.containsKey(Ids.hambre),
      isFalse,
    );
  });

  test('desactivar hambre elimina sus avisos', () async {
    puerto.activas = true;

    await vm.iniciar(conReloj: false);

    await vm.alCambiarCicloDeVida(
      AppLifecycleState.paused,
    );

    await vm.cambiarCategoria(
      Categoria.hambre,
      false,
    );

    expect(
      puerto.programadas.containsKey(Ids.hambre),
      isFalse,
    );

    expect(
      vm.categorias[Categoria.hambre],
      isFalse,
    );
  });
}
