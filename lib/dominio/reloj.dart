
/// El reloj permite controlar el tiempo
/// dentro de nuestra aplicación.
abstract class Reloj {
  DateTime ahora();
}

/// Reloj que utiliza la fecha y hora real.
class RelojSistema implements Reloj {
  const RelojSistema();

  @override
  DateTime ahora() {
    return DateTime.now();
  }
}

/// Reloj falso utilizado para las pruebas TDD.
class RelojFalso implements Reloj {
  RelojFalso(this._t);

  DateTime _t;

  @override
  DateTime ahora() {
    return _t;
  }

  /// Avanza el tiempo indicado.
  void avanzar(Duration duracion) {
    _t = _t.add(duracion);
  }

  /// Establece una fecha y hora específica.
  void fijar(DateTime tiempo) {
    _t = tiempo;
  }
}
