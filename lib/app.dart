
import 'package:flutter/material.dart';

import 'dominio/payload.dart';
import 'presentacion/ajolote_vm.dart';
import 'presentacion/pantalla_ajolote.dart';

/// Aplicación principal de Ajolotito Hambriento.
class AppAjolote extends StatefulWidget {
  const AppAjolote({
    super.key,
    required this.vm,
    this.destinoInicial = Destino.inicio,
  });

  final AjoloteViewModel vm;
  final Destino destinoInicial;

  @override
  State<AppAjolote> createState() => _AppAjoloteState();
}

class _AppAjoloteState extends State<AppAjolote>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();

    // Detectar cuando la aplicación cambia de estado.
    WidgetsBinding.instance.addObserver(this);

    // Iniciar el ajolote y cargar sus datos.
    widget.vm.iniciar(
      destino: widget.destinoInicial,
    );
  }

  /// Detectar cuando la aplicación pasa a segundo plano
  /// o cuando el usuario vuelve a abrirla.
  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    widget.vm.alCambiarCicloDeVida(state);
  }

  /// Liberar los recursos al cerrar la aplicación.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    widget.vm.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ajolotito',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFE56B8F),
        useMaterial3: true,
      ),
      home: PantallaAjolote(
        vm: widget.vm,
      ),
    );
  }
}
