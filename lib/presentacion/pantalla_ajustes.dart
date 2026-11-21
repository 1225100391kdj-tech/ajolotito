
import 'package:flutter/material.dart';

import '../dominio/categoria.dart';
import '../dominio/gestor_permiso.dart';
import 'ajolote_vm.dart';

/// Pantalla donde el usuario puede configurar
/// las notificaciones de Ajolotito Hambriento.
class PantallaAjustes extends StatelessWidget {
  const PantallaAjustes({
    super.key,
    required this.vm,
  });

  final AjoloteViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ajustes de avisos'),
          ),
          body: ListView(
            children: [
              // Estado actual de los permisos.
              ListTile(
                leading: Icon(
                  vm.permiso == EstadoPermiso.concedido
                      ? Icons.check_circle
                      : Icons.block,
                ),
                title: Text(
                  switch (vm.permiso) {
                    EstadoPermiso.concedido =>
                      'El sistema permite notificaciones',
                    EstadoPermiso.denegado =>
                      'El sistema las tiene bloqueadas',
                    EstadoPermiso.sinPreguntar =>
                      'Aún no has decidido',
                  },
                ),
                trailing: TextButton(
                  onPressed: vm.abrirAjustes,
                  child: const Text(
                    'Ajustes del sistema',
                  ),
                ),
              ),

              const Divider(),

              // Activar o desactivar cada categoría.
              for (final categoria in Categoria.values)
                SwitchListTile(
                  title: Text(
                    categoria.canal.nombre,
                  ),
                  subtitle: Text(
                    categoria.canal.descripcion,
                  ),
                  value:
                      vm.categorias[categoria] ?? true,
                  onChanged: (valor) {
                    vm.cambiarCategoria(
                      categoria,
                      valor,
                    );
                  },
                ),

              // Información sobre las notificaciones.
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Silencio automático de 10 pm a 8 am. '
                  'Máximo 3 avisos al día.',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
