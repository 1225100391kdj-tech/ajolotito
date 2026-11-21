
import 'categoria.dart';
import 'mascota.dart';
import 'mensajes.dart';
import 'payload.dart';
import 'politica.dart';

/// Identificadores fijos de las notificaciones.
/// Evitan programar avisos duplicados.
class Ids {
  static const int hambre = 1;
  static const int critico = 2;
  static const int sorpresaBase = 100;

  static int sorpresa(int n) {
    return sorpresaBase + n;
  }

  static const List<int> todos = [
    1,
    2,
    100,
    101,
    102,
  ];
}

/// Representa una notificación programada.
class PlanNotificacion {
  const PlanNotificacion({
    required this.id,
    required this.categoria,
    required this.cuando,
    required this.titulo,
    required this.cuerpo,
    required this.payload,
    required this.prioridad,
  });

  final int id;
  final Categoria categoria;
  final DateTime cuando;
  final String titulo;
  final String cuerpo;
  final String payload;
  final int prioridad;

  bool get esDeHambre {
    return id == Ids.hambre || id == Ids.critico;
  }
}

/// Calcula las notificaciones que debe recibir
/// nuestro ajolotito según su estado y la hora.
class Planificador {
  const Planificador({
    this.politica = const PoliticaNotificaciones(),
  });

  final PoliticaNotificaciones politica;

  static const int sorpresasAdelantadas = 3;
  static const int horaSorpresa = 18;

  /// Genera la lista de notificaciones.
  List<PlanNotificacion> planear(
    Mascota mascota,
    DateTime ahora,
  ) {
    final plan = <PlanNotificacion>[];

    // Notificaciones relacionadas con el hambre.
    if (politica.habilitada(Categoria.hambre)) {
      final horaHambre = politica.ajustar(
        mascota.momentoEnQueBajaA(
          Mascota.umbralHambre,
        ),
      );

      final horaCritica = politica.ajustar(
        mascota.momentoEnQueBajaA(
          Mascota.umbralCritico,
        ),
      );

      var hayHambre = horaHambre.isAfter(ahora);
      final hayCritico = horaCritica.isAfter(ahora);

      // Evitar avisos demasiado cercanos.
      // Si coinciden, tiene prioridad el crítico.
      if (hayHambre &&
          hayCritico &&
          horaCritica.difference(horaHambre) <
              politica.margenEntreAvisos) {
        hayHambre = false;
      }

      // Programar aviso de hambre.
      if (hayHambre) {
        final mensaje = Mensajes.hambre(
          mascota.nombre,
          horaHambre.day + horaHambre.month * 31,
        );

        plan.add(
          PlanNotificacion(
            id: Ids.hambre,
            categoria: Categoria.hambre,
            cuando: horaHambre,
            titulo: mensaje.titulo,
            cuerpo: mensaje.cuerpo,
            payload: const PayloadNotif(
              Destino.alimentar,
            ).codificar(),
            prioridad: 2,
          ),
        );
      }

      // Programar aviso de hambre crítica.
      if (hayCritico) {
        final mensaje = Mensajes.critico(
          mascota.nombre,
          horaCritica.day + horaCritica.month * 31,
        );

        plan.add(
          PlanNotificacion(
            id: Ids.critico,
            categoria: Categoria.hambre,
            cuando: horaCritica,
            titulo: mensaje.titulo,
            cuerpo: mensaje.cuerpo,
            payload: const PayloadNotif(
              Destino.alimentar,
            ).codificar(),
            prioridad: 3,
          ),
        );
      }
    }

    // Programar las sorpresas de los próximos tres días.
    if (politica.habilitada(Categoria.sorpresa)) {
      var numero = 0;

      for (
        var dia = 0;
        numero < sorpresasAdelantadas && dia < 30;
        dia++
      ) {
        final fechaBase = DateTime(
          ahora.year,
          ahora.month,
          ahora.day + dia,
          horaSorpresa,
        );

        final cuando = politica.ajustar(
          fechaBase,
        );

        // No programar notificaciones del pasado.
        if (!cuando.isAfter(ahora)) {
          continue;
        }

        final mensaje = Mensajes.sorpresa(
          mascota.nombre,
          cuando.day + cuando.month * 31,
        );

        plan.add(
          PlanNotificacion(
            id: Ids.sorpresa(numero),
            categoria: Categoria.sorpresa,
            cuando: cuando,
            titulo: mensaje.titulo,
            cuerpo: mensaje.cuerpo,
            payload: const PayloadNotif(
              Destino.jugar,
            ).codificar(),
            prioridad: 1,
          ),
        );

        numero++;
      }
    }

    // Aplicar el límite diario y ordenar avisos.
    return _limitarPorDia(plan);
  }

  /// Identifica el día de una notificación.
  String _clave(DateTime tiempo) {
    return '${tiempo.year}-${tiempo.month}-${tiempo.day}';
  }

  /// Limita las notificaciones diarias.
  /// Conserva las de mayor prioridad.
  List<PlanNotificacion> _limitarPorDia(
    List<PlanNotificacion> plan,
  ) {
    final porDia = <String, List<PlanNotificacion>>{};

    // Agrupar los avisos por fecha.
    for (final aviso in plan) {
      porDia.putIfAbsent(
        _clave(aviso.cuando),
        () => [],
      ).add(aviso);
    }

    final conservadas = <PlanNotificacion>[];

    // Seleccionar los avisos más importantes.
    for (final lista in porDia.values) {
      lista.sort(
        (a, b) => b.prioridad.compareTo(a.prioridad),
      );

      conservadas.addAll(
        lista.take(politica.maxPorDia),
      );
    }

    // Ordenar cronológicamente.
    conservadas.sort(
      (a, b) => a.cuando.compareTo(b.cuando),
    );

    return conservadas;
  }
}
