
import 'categoria.dart';

/// Reglas para enviar notificaciones
/// respetando los horarios de descanso.
class PoliticaNotificaciones {
  const PoliticaNotificaciones({
    this.silencioDesde = 22,
    this.silencioHasta = 8,
    this.maxPorDia = 3,
    this.margenEntreAvisos = const Duration(minutes: 30),
    this.activas = const {
      Categoria.hambre,
      Categoria.sorpresa,
    },
  });

  // Hora en que comienza el silencio.
  final int silencioDesde;

  // Hora en que termina el silencio.
  final int silencioHasta;

  // Número máximo de notificaciones diarias.
  final int maxPorDia;

  // Tiempo mínimo entre notificaciones.
  final Duration margenEntreAvisos;

  // Categorías que pueden enviar avisos.
  final Set<Categoria> activas;

  // Verifica si una categoría está habilitada.
  bool habilitada(Categoria categoria) {
    return activas.contains(categoria);
  }

  // Comprueba si estamos en horas de silencio.
  bool enSilencio(DateTime tiempo) {
    if (silencioDesde == silencioHasta) {
      return false;
    }

    final hora = tiempo.hour;

    if (silencioDesde > silencioHasta) {
      // Cuando el silencio cruza la medianoche.
      return hora >= silencioDesde ||
          hora < silencioHasta;
    }

    // Cuando comienza y termina el mismo día.
    return hora >= silencioDesde &&
        hora < silencioHasta;
  }

  // Ajusta los avisos para respetar
  // el horario de descanso.
  DateTime ajustar(DateTime tiempo) {
    if (!enSilencio(tiempo)) {
      return tiempo;
    }

    final finHoy = DateTime(
      tiempo.year,
      tiempo.month,
      tiempo.day,
      silencioHasta,
    );

    if (tiempo.isBefore(finHoy)) {
      return finHoy;
    }

    return DateTime(
      tiempo.year,
      tiempo.month,
      tiempo.day + 1,
      silencioHasta,
    );
  }
}
