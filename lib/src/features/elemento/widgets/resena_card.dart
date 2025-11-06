// lib/src/features/elemento/widgets/resena_card.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/model/resena.dart';

/// Un widget 'Card' para mostrar una única Reseña (RF12).
class ResenaCard extends StatelessWidget {
  final Resena resena;

  const ResenaCard({super.key, required this.resena});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar (placeholder)
                const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.person_outline, size: 16),
                ),
                const SizedBox(width: 12),
                // Autor
                Text(
                  resena.usernameAutor, //
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // Estrellas
                _buildStaticStars(resena.valoracion), //
              ],
            ),
            const SizedBox(height: 12),
            // Texto de la reseña (si existe)
            if (resena.textoResena != null && resena.textoResena!.isNotEmpty)
              Text(
                resena.textoResena!, //
                style: TextStyle(color: Colors.grey[300]),
              ),
          ],
        ),
      ),
    );
  }

  /// Helper para mostrar las N estrellas estáticas
  Widget _buildStaticStars(int valoracion) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < valoracion ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }
}