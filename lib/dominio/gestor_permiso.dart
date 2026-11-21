
import 'almacen.dart';
import 'puerto.dart';

/// Estados del permiso de notificaciones.
enum EstadoPermiso {
  sinPreguntar,
  concedido,
  denegado,
}

/// Resultados al solicitar el permiso.
enum ResultadoPermiso {
  yaConcedido,
  concedido,
  denegado,
  hayQueIrAAjustes,
}

/// Controla cuándo solicitar el permiso
/// de notificaciones al usuario.
class GestorPermiso {
  GestorPermiso({
    required this.puerto,
    required this.almacen,
  });

  final PuertoNotificaciones puerto;
  final Almacen almacen;

  static const _kPregunto = 'preguntamos_permiso';

  /// Consulta el estado actual del permiso.
  Future<EstadoPermiso> estado() async {
    // Si las notificaciones están activas,
    // el permiso ya está concedido.
    if (await puerto.notificacionesActivas()) {
      return EstadoPermiso.concedido;
    }

    // Revisar si anteriormente se solicitó.
    final pregunto =
        await almacen.leerBool(_kPregunto) ?? false;

    if (pregunto) {
      return EstadoPermiso.denegado;
    }

    return EstadoPermiso.sinPreguntar;
  }

  /// Solicita permiso solo cuando corresponde.
  Future<ResultadoPermiso> solicitar() async {
    final estadoActual = await estado();

    switch (estadoActual) {
      case EstadoPermiso.concedido:
        // Ya tiene permiso, no se vuelve a pedir.
        return ResultadoPermiso.yaConcedido;

      case EstadoPermiso.denegado:
        // Si ya rechazó, se le enviará a Ajustes.
        return ResultadoPermiso.hayQueIrAAjustes;

      case EstadoPermiso.sinPreguntar:
        // Solicitar permiso por primera vez.
        final acepto = await puerto.pedirPermiso();

        // Guardar que ya preguntamos.
        await almacen.guardarBool(
          _kPregunto,
          true,
        );

        if (acepto) {
          return ResultadoPermiso.concedido;
        }

        return ResultadoPermiso.denegado;
    }
  }

  /// Abre los ajustes del dispositivo.
  Future<void> abrirAjustes() {
    return puerto.abrirAjustes();
  }
}
