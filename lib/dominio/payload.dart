
/// Pantallas a las que puede dirigir
/// una notificación.
enum Destino {
  inicio,
  alimentar,
  alimentarYa,
  jugar,
}

/// Información que viaja dentro
/// de una notificación.
class PayloadNotif {
  const PayloadNotif(this.destino);

  final Destino destino;

  // Convierte el destino a texto.
  String codificar() {
    return 'v1:${destino.name}';
  }

  // Recupera el destino de una notificación.
  static PayloadNotif decodificar(String? crudo) {
    const defecto = PayloadNotif(Destino.inicio);

    // Si no contiene información,
    // regresa a la pantalla principal.
    if (crudo == null) {
      return defecto;
    }

    final partes = crudo.split(':');

    // Verificar el formato y su versión.
    if (partes.length != 2 || partes[0] != 'v1') {
      return defecto;
    }

    // Buscar el destino correspondiente.
    for (final destino in Destino.values) {
      if (destino.name == partes[1]) {
        return PayloadNotif(destino);
      }
    }

    // Si no existe el destino,
    // abrir la pantalla de inicio.
    return defecto;
  }
}
