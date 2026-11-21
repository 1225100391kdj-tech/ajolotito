
import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../dominio/categoria.dart';
import '../dominio/payload.dart';
import '../dominio/planificador.dart';
import '../dominio/puerto.dart';

/// Conecta las notificaciones del ajolote
/// con el dispositivo Android o iOS.
class PuertoReal implements PuertoNotificaciones {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  void Function(String? payload)? _alTocar;

  static const _accionAlimentar = 'alimentar';

  /// Inicializar las notificaciones.
  @override
  Future<void> inicializar() async {
    // Configurar la zona horaria de México.
    tzdata.initializeTimeZones();

    tz.setLocalLocation(
      tz.getLocation('America/Mexico_City'),
    );

    // No pedir permisos automáticamente al iniciar.
    const ajustes = InitializationSettings(
      android: AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      ),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      settings: ajustes,
      onDidReceiveNotificationResponse: (
        NotificationResponse respuesta,
      ) {
        // Detectar el botón "Dar de comer".
        final payload =
            respuesta.actionId == _accionAlimentar
                ? const PayloadNotif(
                    Destino.alimentarYa,
                  ).codificar()
                : respuesta.payload;

        _alTocar?.call(payload);
      },
    );

    // Crear los canales de Android.
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    for (final categoria in Categoria.values) {
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          categoria.canal.id,
          categoria.canal.nombre,
          description: categoria.canal.descripcion,
          importance: _importancia(
            categoria.canal.importancia,
          ),
        ),
      );
    }
  }

  /// Convertir importancia a la del plugin.
  Importance _importancia(Importancia importancia) {
    switch (importancia) {
      case Importancia.baja:
        return Importance.low;

      case Importancia.normal:
        return Importance.defaultImportance;

      case Importancia.alta:
        return Importance.high;
    }
  }

  /// Convertir prioridad a la del plugin.
  Priority _prioridad(Importancia importancia) {
    switch (importancia) {
      case Importancia.baja:
        return Priority.low;

      case Importancia.normal:
        return Priority.defaultPriority;

      case Importancia.alta:
        return Priority.high;
    }
  }

  /// Configurar los detalles de las notificaciones.
  NotificationDetails _detalles(Categoria categoria) {
    final canal = categoria.canal;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        canal.id,
        canal.nombre,
        channelDescription: canal.descripcion,
        importance: _importancia(
          canal.importancia,
        ),
        priority: _prioridad(
          canal.importancia,
        ),
        actions: categoria == Categoria.hambre
            ? const [
                AndroidNotificationAction(
                  _accionAlimentar,
                  'Dar de comer 🍤',
                  showsUserInterface: true,
                ),
              ]
            : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: categoria == Categoria.hambre,
      ),
    );
  }

  /// Verificar si las notificaciones están habilitadas.
  @override
  Future<bool> notificacionesActivas() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      return await android.areNotificationsEnabled() ??
          false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (ios != null) {
      return (await ios.checkPermissions())?.isEnabled ??
          false;
    }

    return true;
  }

  /// Solicitar permiso para mostrar notificaciones.
  @override
  Future<bool> pedirPermiso() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      return await android.requestNotificationsPermission() ??
          false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  /// Programar una notificación futura.
  @override
  Future<void> programar(PlanNotificacion plan) {
    return _plugin.zonedSchedule(
      id: plan.id,
      title: plan.titulo,
      body: plan.cuerpo,
      scheduledDate: tz.TZDateTime.from(
        plan.cuando,
        tz.local,
      ),
      notificationDetails: _detalles(
        plan.categoria,
      ),
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
      payload: plan.payload,
    );
  }

  /// Mostrar una notificación inmediatamente.
  @override
  Future<void> mostrarAhora({
    required int id,
    required String titulo,
    required String cuerpo,
    required Categoria categoria,
    required String payload,
  }) {
    return _plugin.show(
      id: id,
      title: titulo,
      body: cuerpo,
      notificationDetails: _detalles(categoria),
      payload: payload,
    );
  }

  /// Cancelar una notificación por su identificador.
  @override
  Future<void> cancelar(int id) {
    return _plugin.cancel(id: id);
  }

  /// Obtener la notificación que abrió la aplicación.
  @override
  Future<String?> payloadDeLanzamiento() async {
    final detalles =
        await _plugin.getNotificationAppLaunchDetails();

    if (detalles?.didNotificationLaunchApp ?? false) {
      final respuesta = detalles!.notificationResponse;

      if (respuesta?.actionId == _accionAlimentar) {
        return const PayloadNotif(
          Destino.alimentarYa,
        ).codificar();
      }

      return respuesta?.payload;
    }

    return null;
  }

  /// Escuchar cuando el usuario toca una notificación.
  @override
  void escucharToques(
    void Function(String? payload) alTocar,
  ) {
    _alTocar = alTocar;
  }

  /// Abrir los ajustes de notificaciones.
  @override
  Future<void> abrirAjustes() {
    return AppSettings.openAppSettings(
      type: AppSettingsType.notification,
    );
  }
}
