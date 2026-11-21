
import 'package:ajolotito/dominio/almacen.dart';
import 'package:ajolotito/dominio/gestor_permiso.dart';
import 'package:flutter_test/flutter_test.dart';

import 'falsos.dart';

void main() {
  late PuertoFalso puerto;
  late GestorPermiso gestor;

  setUp(() {
    puerto = PuertoFalso()..activas = false;

    gestor = GestorPermiso(
      puerto: puerto,
      almacen: AlmacenMemoria(),
    );
  });

  test('al inicio nunca hemos preguntado', () async {
    expect(
      await gestor.estado(),
      EstadoPermiso.sinPreguntar,
    );

    expect(
      puerto.vecesPidioPermiso,
      0,
      reason: 'Consultar el estado no debe pedir permiso',
    );
  });

  test('si el usuario acepta, queda concedido', () async {
    expect(
      await gestor.solicitar(),
      ResultadoPermiso.concedido,
    );

    expect(
      await gestor.estado(),
      EstadoPermiso.concedido,
    );
  });

  test('si ya tiene permiso, no vuelve a preguntar', () async {
    puerto.activas = true;

    expect(
      await gestor.solicitar(),
      ResultadoPermiso.yaConcedido,
    );

    expect(puerto.vecesPidioPermiso, 0);
  });

  test('si rechaza, no volvemos a insistir', () async {
    puerto.usuarioAcepta = false;

    expect(
      await gestor.solicitar(),
      ResultadoPermiso.denegado,
    );

    expect(
      await gestor.estado(),
      EstadoPermiso.denegado,
    );

    expect(
      await gestor.solicitar(),
      ResultadoPermiso.hayQueIrAAjustes,
    );

    expect(
      puerto.vecesPidioPermiso,
      1,
      reason: 'El diálogo debe aparecer una sola vez',
    );
  });

  test('si activa el permiso desde Ajustes, queda concedido', () async {
    puerto.usuarioAcepta = false;

    await gestor.solicitar();

    puerto.activas = true;

    expect(
      await gestor.estado(),
      EstadoPermiso.concedido,
    );
  });

  test('abrir Ajustes utiliza el puerto', () async {
    await gestor.abrirAjustes();

    expect(puerto.ajustesAbiertos, 1);
  });
}
