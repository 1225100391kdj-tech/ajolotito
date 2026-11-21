
import 'package:shared_preferences/shared_preferences.dart';

import '../dominio/almacen.dart';

/// Guarda los datos de la aplicación
/// utilizando SharedPreferences.
class AlmacenPrefs implements Almacen {
  AlmacenPrefs(this._p);

  final SharedPreferences _p;

  /// Leer un texto guardado.
  @override
  Future<String?> leerTexto(String clave) async {
    return _p.getString(clave);
  }

  /// Guardar un texto.
  @override
  Future<void> guardarTexto(
    String clave,
    String valor,
  ) async {
    await _p.setString(clave, valor);
  }

  /// Leer un valor verdadero o falso.
  @override
  Future<bool?> leerBool(String clave) async {
    return _p.getBool(clave);
  }

  /// Guardar un valor verdadero o falso.
  @override
  Future<void> guardarBool(
    String clave,
    bool valor,
  ) async {
    await _p.setBool(clave, valor);
  }
}
