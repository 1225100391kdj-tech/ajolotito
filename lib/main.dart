
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'dominio/gestor_permiso.dart';
import 'dominio/reloj.dart';
import 'dominio/servicio.dart';
import 'infra/almacen_prefs.dart';
import 'infra/puerto_real.dart';
import 'presentacion/ajolote_vm.dart';

Future<void> main() async {
  // Inicializar Flutter.
  WidgetsFlutterBinding.ensureInitialized();

  // Preparar las notificaciones reales.
  final puerto = PuertoReal();
  await puerto.inicializar();

  // Preparar el almacenamiento del dispositivo.
  final almacen = AlmacenPrefs(
    await SharedPreferences.getInstance(),
  );

  // Utilizar el reloj del dispositivo.
  const reloj = RelojSistema();

  // Crear el servicio de la mascota.
  final servicio = ServicioAjolote(
    puerto: puerto,
    almacen: almacen,
    reloj: reloj,
  );

  // Crear el gestor de permisos.
  final gestor = GestorPermiso(
    puerto: puerto,
    almacen: almacen,
  );

  // Crear el ViewModel.
  final vm = AjoloteViewModel(
    servicio: servicio,
    gestor: gestor,
    reloj: reloj,
  );

  // Detectar cuando el usuario toca una notificación.
  puerto.escucharToques(
    vm.alTocarNotificacion,
  );

  // Saber si la aplicación se abrió
  // desde una notificación.
  final destino = await servicio.destinoDeLanzamiento();

  // Iniciar Ajolotito Hambriento.
  runApp(
    AppAjolote(
      vm: vm,
      destinoInicial: destino,
    ),
  );
}
