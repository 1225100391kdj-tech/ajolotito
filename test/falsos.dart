
import 'package:ajolotito/dominio/categoria.dart';
import 'package:ajolotito/dominio/planificador.dart';
import 'package:ajolotito/dominio/puerto.dart';

/// Simula el funcionamiento de las notificaciones
/// para poder realizar pruebas automatizadas.
class PuertoFalso implements PuertoNotificaciones {
  // Indica si las notificaciones están habilitadas.
  bool activas = true;

  // Simula la respuesta del usuario al pedir permiso.
  bool usuarioAcepta = true;

  // Contadores para las pruebas.
  int vecesPidioPermiso = 0;
  int ajustesAbiertos = 0;

  // Notificación que abrió la aplicación.
  String? lanzamiento;

  // Función que se ejecuta al tocar una notificación.
  void Function(String?)? _alTocar;

  // Notificaciones programadas.
  final Map<int, PlanNotificacion> programadas = {};

  // Notificaciones mostradas inmediatamente.
  final List<String> mostradas = [];

  @override
  Future<void> inicializar() async {}

  @override
  Future<bool> notificacionesActivas() async {
    return activas;
  }

  @override
  Future<bool> pedirPermiso() async {
    vecesPidioPermiso++;
    activas = usuarioAcepta;
    return usuarioAcepta;
  }

  @override
  Future<void> programar(PlanNotificacion plan) async {
    // Si el ID ya existe, reemplaza el aviso anterior.
    programadas[plan.id] = plan;
  }

  @override
  Future<void> mostrarAhora({
    required int id,
    required String titulo,
    required String cuerpo,
    required Categoria categoria,
    required String payload,
  }) async {
    mostradas.add(titulo);
  }

  @override
  Future<void> cancelar(int id) async {
    programadas.remove(id);
  }

  @override
  Future<String?> payloadDeLanzamiento() async {
    return lanzamiento;
  }

  @override
  void escucharToques(
    void Function(String? payload) alTocar,
  ) {
    _alTocar = alTocar;
  }

  /// Simula que el usuario toca una notificación.
  void simularToque(String? payload) {
    _alTocar?.call(payload);
  }

  @override
  Future<void> abrirAjustes() async {
    ajustesAbiertos++;
  }
}
