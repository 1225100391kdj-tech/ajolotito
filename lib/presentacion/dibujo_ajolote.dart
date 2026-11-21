
import 'package:flutter/material.dart';

import '../dominio/mascota.dart';

/// Dibuja un ajolote rosita con branquias
/// y una carita según su estado de ánimo.
class DibujoAjolote extends StatelessWidget {
  const DibujoAjolote({
    super.key,
    required this.humor,
  });

  final Humor humor;

  // Cambiar la expresión del ajolote.
  String get _cara {
    switch (humor) {
      case Humor.feliz:
        return '😊';

      case Humor.hambriento:
        return '😋';

      case Humor.famelico:
        return '😭';
    }
  }

  @override
  Widget build(BuildContext context) {
    const rosa = Color(0xFFF8B6C8);
    const rosaOscuro = Color(0xFFE56B8F);

    // Crear una branquia del ajolote.
    Widget branquia(double angulo) {
      return Transform.rotate(
        angle: angulo,
        child: Container(
          width: 46,
          height: 14,
          decoration: BoxDecoration(
            color: rosaOscuro,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    return SizedBox(
      width: 220,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Branquias del lado izquierdo.
          Positioned(
            left: 6,
            top: 40,
            child: branquia(-0.5),
          ),
          Positioned(
            left: 0,
            top: 70,
            child: branquia(0),
          ),
          Positioned(
            left: 6,
            top: 100,
            child: branquia(0.5),
          ),

          // Branquias del lado derecho.
          Positioned(
            right: 6,
            top: 40,
            child: branquia(0.5),
          ),
          Positioned(
            right: 0,
            top: 70,
            child: branquia(0),
          ),
          Positioned(
            right: 6,
            top: 100,
            child: branquia(-0.5),
          ),

          // Cabeza del ajolote.
          Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: rosa,
              shape: BoxShape.circle,
            ),
            child: Text(
              _cara,
              style: const TextStyle(
                fontSize: 64,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
