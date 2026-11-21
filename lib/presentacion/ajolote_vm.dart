
import 'dart:async';

import 'package:flutter/widgets.dart';

import '../dominio/categoria.dart';
import '../dominio/gestor_permiso.dart';
import '../dominio/mascota.dart';
import '../dominio/payload.dart';
import '../dominio/planificador.dart';
import '../dominio/reloj.dart';
import '../dominio/servicio.dart';

/// Conecta la lógica del ajolote con las pantallas.
class AjoloteViewModel extends ChangeNotifier {
  AjoloteViewModel({
    required this.servicio,
    required this.gestor,
    required this.reloj,
  });

  final ServicioAjolote servicio;
  final GestorPermiso gestor;
  final Reloj reloj;

  Mascota? _m;
  Timer? _timer;

  EstadoPermiso permiso = EstadoPermiso.sinPreguntar;

  Map<Categoria, bool> categorias = {
    for (final c in Categoria.values) c: true,
  };

  String? aviso;
  bool resaltarAlimentar = false;

  // Indica si la mascota ya está cargada.
  bool get listo => _m != null;

  // Nombre del ajolote.
  String get nombre => _m?.nombre ?? '';

  // Saciedad actual de la mascota.
  double get saciedad {
    return _m?.saciedadEn(reloj.ahora()) ?? 0;
  }

  // Estado de ánimo actual.
  Humor get humor {
    return _m?.humorEn(reloj.ahora()) ?? Humor.feliz;
  }

  // Indica si está activado el modo clase.
  bool get modoClase {
    return (_m?.puntosPorHora ??
            ServicioAjolote.ritmoNormal) >
        ServicioAjolote.ritmoNormal;
  }

  // Notificaciones programadas.
  List<PlanNotificacion> get programadas {
    return servicio.programadas;
  }

  /// Iniciar la aplicación.
  Future<void> iniciar({
    Destino destino = Destino.inicio,
    bool conReloj = true,
  }) async {
    _m = await servicio.cargar();

    permiso = await gestor.estado();

    categorias = await servicio.categorias();

    await servicio.sincronizar(_m!);

    await _aplicarDestino(destino);

    // Actualizar la interfaz cada segundo.
    if (conReloj) {
      _timer?.cancel();

      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          notifyListeners();
        },
      );
    }

    notifyListeners();
  }

  /// Determinar qué hacer al abrir una notificación.
  Future<void> _aplicarDestino(Destino destino) async {
    switch (destino) {
      case Destino.inicio:
        break;

      case Destino.alimentar:
        resaltarAlimentar = true;
        aviso =
            '$nombre te estaba esperando. '
            '¡Dale de comer!';
        break;

      case Destino.alimentarYa:
        await alimentar();
        break;

      case Destino.jugar:
        aviso =
            '$nombre quiere jugar, '
            'pero primero mírale esa carita 🥹';
        break;
    }
  }

  /// Detectar cuando el usuario toca una notificación.
  Future<void> alTocarNotificacion(
    String? payload,
  ) async {
    final destino = PayloadNotif.decodificar(
      payload,
    ).destino;

    await _aplicarDestino(destino);

    notifyListeners();
  }

  /// Alimentar al ajolote.
  Future<void> alimentar() async {
    try {
      _m = await servicio.alimentar();

      aviso = '¡Ñam! $nombre quedó feliz 🍤';

      resaltarAlimentar = false;
    } on YaEstaLlena catch (e) {
      aviso =
          '${e.nombre} está llenísimo; '
          'ni un acocil más.';
    }

    notifyListeners();
  }

  /// Solicitar permiso cuando el usuario lo decide.
  Future<ResultadoPermiso> activarAvisos() async {
    final resultado = await gestor.solicitar();

    permiso = await gestor.estado();

    if (_m != null) {
      await servicio.sincronizar(_m!);
    }

    notifyListeners();

    return resultado;
  }

  /// Abrir ajustes de notificaciones.
  Future<void> abrirAjustes() {
    return gestor.abrirAjustes();
  }

  /// Activar o desactivar el modo clase.
  Future<void> cambiarModoClase(bool activo) async {
    _m = await servicio.cambiarRitmo(
      activo
          ? ServicioAjolote.ritmoClase
          : ServicioAjolote.ritmoNormal,
    );

    notifyListeners();
  }

  /// Cambiar una categoría de notificaciones.
  Future<void> cambiarCategoria(
    Categoria categoria,
    bool activa,
  ) async {
    await servicio.cambiarCategoria(
      categoria,
      activa,
    );

    categorias = await servicio.categorias();

    notifyListeners();
  }

  /// Mostrar una notificación de prueba.
  Future<void> probarAhora() {
    return servicio.probarAhora();
  }

  /// Detectar si la aplicación está abierta o en segundo plano.
  Future<void> alCambiarCicloDeVida(
    AppLifecycleState estado,
  ) async {
    if (estado == AppLifecycleState.paused) {
      await servicio.alPasarAFondo();
    } else if (estado == AppLifecycleState.resumed) {
      await servicio.alVolverAlFrente();

      _m = await servicio.cargar();

      // El usuario pudo cambiar permisos en Ajustes.
      permiso = await gestor.estado();

      notifyListeners();
    }
  }

  /// Liberar recursos al cerrar la pantalla.
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
