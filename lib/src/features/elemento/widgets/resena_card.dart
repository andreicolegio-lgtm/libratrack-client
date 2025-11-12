// lib/src/features/elemento/widgets/resena_card.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/model/resena.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <-- ¡NUEVA IMPORTACIÓN!

/// Un widget 'Card' para mostrar una única Reseña (RF12).
/// --- ¡ACTUALIZADO (Sprint 3)! ---
class ResenaCard extends StatelessWidget {
  final Resena resena;

  const ResenaCard({super.key, required this.resena});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // --- ¡AVATAR REEMPLAZADO! ---
                _buildAvatar(context, resena.autorFotoPerfilUrl),
                const SizedBox(width: 12),
                
                // Autor
                Text(
                  resena.usernameAutor,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                // Estrellas
                _buildStaticStars(resena.valoracion),
              ],
            ),
            const SizedBox(height: 12),
            // Texto de la reseña (si existe)
            if (resena.textoResena != null && resena.textoResena!.isNotEmpty)
              Text(
                resena.textoResena!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
  
  /// --- ¡NUEVO WIDGET HELPER! ---
  /// Construye el avatar del usuario, mostrando la imagen
  /// o un placeholder si no tiene.
  Widget _buildAvatar(BuildContext context, String? imageUrl) {
    // Si tenemos una URL, usamos CachedNetworkImage
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Theme.of(context).colorScheme.surface,
        backgroundImage: CachedNetworkImageProvider(imageUrl),
      );
    }
    
    // Si no, mostramos el placeholder
    return CircleAvatar(
      radius: 16,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: const Icon(Icons.person_outline, size: 16),
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