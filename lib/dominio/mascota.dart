
import 'dart:convert';
import 'dart:math' as math;

// Estados de ánimo del ajolote.
enum Humor {
  feliz,
  hambriento,
  famelico,
}

// Excepción cuando el ajolote ya está lleno.
class YaEstaLlena implements Exception {
  const YaEstaLlena(this.nombre);

  final String nombre;

  @override
  String toString() {
    return '$nombre ya no puede comer más';
  }
}

// Mascota virtual cuya saciedad disminuye con el tiempo.
class Mascota {
  const Mascota({
    required this.nombre,
    required this.saciedadBase,
    required this.desde,
    this.puntosPorHora = 10,
  }) : assert(puntosPorHora > 0);

  // Crear una mascota nueva con saciedad completa.
  factory Mascota.nueva(
    String nombre,
    DateTime ahora, {
    double puntosPorHora = 10,
  }) {
    return Mascota(
      nombre: nombre,
      saciedadBase: maxSaciedad,
      desde: ahora,
      puntosPorHora: puntosPorHora,
    );
  }

  static const double maxSaciedad = 100;
  static const double umbralHambre = 40;
  static const double umbralCritico = 15;
  static const double limiteParaComer = 90;
  static const double porcion = 35;

  final String nombre;
  final double saciedadBase;
  final DateTime desde;
  final double puntosPorHora;

  // Calcular la saciedad según el tiempo transcurrido.
  double saciedadEn(DateTime tiempo) {
    if (!tiempo.isAfter(desde)) {
      return saciedadBase;
    }

    final horas = tiempo.difference(desde).inMicroseconds /
        Duration.microsecondsPerHour;

    return math.max(
      0.0,
      saciedadBase - horas * puntosPorHora,
    );
  }

  // Determinar el estado de ánimo de la mascota.
  Humor humorEn(DateTime tiempo) {
    final saciedad = saciedadEn(tiempo);

    if (saciedad <= umbralCritico) {
      return Humor.famelico;
    }

    if (saciedad <= umbralHambre) {
      return Humor.hambriento;
    }

    return Humor.feliz;
  }

  // Predecir cuándo llegará a un nivel de saciedad.
  DateTime momentoEnQueBajaA(double umbral) {
    if (saciedadBase <= umbral) {
      return desde;
    }

    final horas = (saciedadBase - umbral) / puntosPorHora;

    return desde.add(
      Duration(
        microseconds: (
          horas * Duration.microsecondsPerHour
        ).round(),
      ),
    );
  }

  // Alimentar al ajolote.
  Mascota alimentar(DateTime tiempo) {
    final actual = saciedadEn(tiempo);

    if (actual >= limiteParaComer) {
      throw YaEstaLlena(nombre);
    }

    return Mascota(
      nombre: nombre,
      saciedadBase: math.min(
        maxSaciedad,
        actual + porcion,
      ),
      desde: tiempo,
      puntosPorHora: puntosPorHora,
    );
  }

  // Modificar el ritmo de hambre sin alterar la
  // saciedad que tiene en ese momento.
  Mascota conRitmo(
    DateTime tiempo,
    double nuevoRitmo,
  ) {
    return Mascota(
      nombre: nombre,
      saciedadBase: saciedadEn(tiempo),
      desde: tiempo,
      puntosPorHora: nuevoRitmo,
    );
  }

  // Convertir los datos de la mascota a JSON.
  Map<String, Object> toJson() {
    return {
      'nombre': nombre,
      'saciedadBase': saciedadBase,
      'desde': desde.toIso8601String(),
      'puntosPorHora': puntosPorHora,
    };
  }

  // Convertir los datos a texto.
  String aTexto() {
    return jsonEncode(toJson());
  }

  // Recuperar una mascota desde texto JSON.
  static Mascota? desdeTexto(String? texto) {
    if (texto == null) {
      return null;
    }

    try {
      final json = jsonDecode(texto);

      if (json is! Map<String, dynamic>) {
        return null;
      }

      final nombre = json['nombre'];
      final saciedad = json['saciedadBase'];
      final fechaTexto = json['desde'];
      final ritmo = json['puntosPorHora'];

      if (nombre is! String ||
          nombre.isEmpty ||
          saciedad is! num ||
          fechaTexto is! String ||
          ritmo is! num) {
        return null;
      }

      final fecha = DateTime.tryParse(fechaTexto);

      if (fecha == null ||
          saciedad < 0 ||
          saciedad > maxSaciedad ||
          ritmo <= 0) {
        return null;
      }

      return Mascota(
        nombre: nombre,
        saciedadBase: saciedad.toDouble(),
        desde: fecha,
        puntosPorHora: ritmo.toDouble(),
      );
    } on FormatException {
      return null;
    }
  }
}
