import 'package:flutter/material.dart';
import '../../../model/resena.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ResenaCard extends StatelessWidget {
  final Resena resena;

  const ResenaCard({required this.resena, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _buildAvatar(context, resena.autorFotoPerfilUrl),
                const SizedBox(width: 12),
                Text(
                  resena.usernameAutor,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                _buildStaticStars(resena.valoracion),
              ],
            ),
            const SizedBox(height: 12),
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

  Widget _buildAvatar(BuildContext context, String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Theme.of(context).colorScheme.surface,
        backgroundImage: CachedNetworkImageProvider(imageUrl),
      );
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: const Icon(Icons.person_outline, size: 16),
    );
  }

  Widget _buildStaticStars(int valoracion) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (int index) {
        return Icon(
          index < valoracion ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }
}
