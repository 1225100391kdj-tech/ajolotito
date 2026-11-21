
import 'categoria.dart';
import 'planificador.dart';

/// Interfaz para comunicarse con las
/// notificaciones del dispositivo.
///
/// Permite probar la lógica sin depender
/// directamente de los plugins de Android.
abstract class PuertoNotificaciones {

  // Inicializar las notificaciones.
  Future<void> inicializar();

  // Comprobar si están habilitadas.
  Future<bool> notificacionesActivas();

  // Solicitar permiso al usuario.
  Future<bool> pedirPermiso();

  // Programar una notificación.
  Future<void> programar(PlanNotificacion plan);

  // Mostrar una notificación inmediatamente.
  Future<void> mostrarAhora({
    required int id,
    required String titulo,
    required String cuerpo,
    required Categoria categoria,
    required String payload,
  });

  // Cancelar una notificación.
  Future<void> cancelar(int id);

  // Recuperar la notificación que abrió la app.
  Future<String?> payloadDeLanzamiento();

  // Detectar cuando el usuario toca un aviso.
  void escucharToques(
    void Function(String? payload) alTocar,
  );

  // Abrir los ajustes de notificaciones.
  Future<void> abrirAjustes();
}
