
import 'almacen.dart';
import 'categoria.dart';
import 'mascota.dart';
import 'payload.dart';
import 'planificador.dart';
import 'politica.dart';
import 'puerto.dart';
import 'reloj.dart';

/// Conecta la mascota, el reloj y las notificaciones.
/// Mantiene los avisos sincronizados con el estado del ajolote.
class ServicioAjolote {
  ServicioAjolote({
    required this.puerto,
    required this.almacen,
    required this.reloj,
    this.nombre = 'Xólotl',
  });

  final PuertoNotificaciones puerto;
  final Almacen almacen;
  final Reloj reloj;
  final String nombre;

  static const _kMascota = 'mascota';

  static const double ritmoNormal = 10;
  static const double ritmoClase = 600;

  bool _enPrimerPlano = true;

  List<PlanNotificacion> _programadas = const [];

  List<PlanNotificacion> get programadas {
    return _programadas;
  }

  // Cargar una mascota guardada o crear una nueva.
  Future<Mascota> cargar() async {
    final guardada = Mascota.desdeTexto(
      await almacen.leerTexto(_kMascota),
    );

    if (guardada != null) {
      return guardada;
    }

    final nueva = Mascota.nueva(
      nombre,
      reloj.ahora(),
    );

    await _guardar(nueva);

    return nueva;
  }

  // Guardar los datos de la mascota.
  Future<void> _guardar(Mascota mascota) {
    return almacen.guardarTexto(
      _kMascota,
      mascota.aTexto(),
    );
  }

  // Consultar las categorías activadas por el usuario.
  Future<Map<Categoria, bool>> categorias() async {
    final resultado = <Categoria, bool>{};

    for (final categoria in Categoria.values) {
      resultado[categoria] =
          await almacen.leerBool(
            'cat_${categoria.name}',
          ) ??
          true;
    }

    return resultado;
  }

  // Crear la política de notificaciones actual.
  Future<PoliticaNotificaciones> _politica(
    Mascota mascota,
  ) async {
    final categoriasActuales = await categorias();

    // Ajustar el margen cuando utilizamos
    // el modo de tiempo acelerado.
    final escala =
        ritmoNormal / mascota.puntosPorHora;

    return PoliticaNotificaciones(
      activas: {
        for (final entrada in categoriasActuales.entries)
          if (entrada.value) entrada.key,
      },
      margenEntreAvisos: Duration(
        microseconds: (
          const Duration(minutes: 30).inMicroseconds *
          escala
        ).round(),
      ),
    );
  }

  // Alimentar al ajolote.
  Future<Mascota> alimentar() async {
    final mascota = await cargar();

    final nueva = mascota.alimentar(
      reloj.ahora(),
    );

    await _guardar(nueva);

    // Actualizar los avisos después de comer.
    await sincronizar(nueva);

    return nueva;
  }

  // Cambiar la velocidad con la que le da hambre.
  Future<Mascota> cambiarRitmo(
    double puntosPorHora,
  ) async {
    final mascota = await cargar();

    final nueva = mascota.conRitmo(
      reloj.ahora(),
      puntosPorHora,
    );

    await _guardar(nueva);

    await sincronizar(nueva);

    return nueva;
  }

  // Activar o desactivar una categoría.
  Future<void> cambiarCategoria(
    Categoria categoria,
    bool activa,
  ) async {
    await almacen.guardarBool(
      'cat_${categoria.name}',
      activa,
    );

    await sincronizar(await cargar());
  }

  // Actualizar todas las notificaciones programadas.
  Future<void> sincronizar(Mascota mascota) async {
    // Primero cancelar los avisos anteriores.
    for (final id in Ids.todos) {
      await puerto.cancelar(id);
    }

    _programadas = const [];

    // No programar avisos si no existe permiso.
    if (!await puerto.notificacionesActivas()) {
      return;
    }

    // Calcular el nuevo plan de notificaciones.
    final politicaActual = await _politica(mascota);

    final plan = Planificador(
      politica: politicaActual,
    ).planear(
      mascota,
      reloj.ahora(),
    );

    // Si la app está abierta, no enviar
    // avisos de hambre mientras se está viendo.
    final aProgramar = plan.where((aviso) {
      return !(_enPrimerPlano && aviso.esDeHambre);
    }).toList();

    // Programar los avisos actualizados.
    for (final aviso in aProgramar) {
      await puerto.programar(aviso);
    }

    _programadas = aProgramar;
  }

  // La aplicación pasa a segundo plano.
  Future<void> alPasarAFondo() async {
    _enPrimerPlano = false;

    await sincronizar(await cargar());
  }

  // El usuario vuelve a abrir la aplicación.
  Future<void> alVolverAlFrente() async {
    _enPrimerPlano = true;

    await sincronizar(await cargar());
  }

  // Identificar qué pantalla abrir desde una notificación.
  Future<Destino> destinoDeLanzamiento() async {
    final payload = await puerto.payloadDeLanzamiento();

    return PayloadNotif.decodificar(
      payload,
    ).destino;
  }

  // Mostrar una notificación inmediata de prueba.
  Future<void> probarAhora() async {
    final mascota = await cargar();

    await puerto.mostrarAhora(
      id: 999,
      titulo: '${mascota.nombre} te saluda 👋',
      cuerpo:
          'Esta es una notificación de prueba: '
          'apareció al instante.',
      categoria: Categoria.sorpresa,
      payload: const PayloadNotif(
        Destino.jugar,
      ).codificar(),
    );
  }
}
