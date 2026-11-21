
import 'package:ajolotito/dominio/almacen.dart';
import 'package:ajolotito/dominio/gestor_permiso.dart';
import 'package:ajolotito/dominio/reloj.dart';
import 'package:ajolotito/dominio/servicio.dart';
import 'package:ajolotito/presentacion/ajolote_vm.dart';
import 'package:ajolotito/presentacion/pantalla_ajolote.dart';
import 'package:flutter/material.dart';
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
  });

  tearDown(() {
    vm.dispose();
  });

  Future<void> abrir(WidgetTester tester) async {
    await tester.runAsync(
      () => vm.iniciar(conReloj: false),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PantallaAjolote(vm: vm),
      ),
    );
  }

  testWidgets(
    'muestra al ajolote feliz y el botón para activar avisos',
    (tester) async {
      await abrir(tester);

      expect(
        find.text('Feliz y con la pancita llena'),
        findsOneWidget,
      );

      expect(
        find.text('Avísame cuando tenga hambre'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'con hambre, dar de comer sube la saciedad',
    (tester) async {
      await abrir(tester);

      reloj.avanzar(
        const Duration(hours: 6),
      );

      await tester.runAsync(vm.alimentar);

      await tester.pump();

      expect(
        find.text('Saciedad: 75 / 100'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'el permiso se pide después de explicar y aceptar',
    (tester) async {
      await abrir(tester);

      // Abrir el diálogo de explicación.
      await tester.tap(
        find.text('Avísame cuando tenga hambre'),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('¿Te avisamos cuando tenga hambre?'),
        findsOneWidget,
      );

      // Todavía no debe pedir permiso.
      expect(
        puerto.vecesPidioPermiso,
        0,
      );

      // El usuario selecciona "Ahora no".
      await tester.tap(
        find.text('Ahora no'),
      );

      await tester.pumpAndSettle();

      expect(
        puerto.vecesPidioPermiso,
        0,
      );

      // Abrir nuevamente el diálogo.
      await tester.tap(
        find.text('Avísame cuando tenga hambre'),
      );

      await tester.pumpAndSettle();

      // Ahora acepta.
      await tester.tap(
        find.text('Sí, avísame'),
      );

      await tester.pumpAndSettle();

      expect(
        puerto.vecesPidioPermiso,
        1,
      );
    },
  );
}
