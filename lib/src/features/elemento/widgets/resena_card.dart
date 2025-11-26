import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../model/resena.dart';
import '../../../core/l10n/app_localizations.dart';

class ResenaCard extends StatelessWidget {
  final Resena resena;

  const ResenaCard({
    required this.resena,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final String fechaFormateada =
        DateFormat('dd/MM/yyyy').format(resena.fechaCreacion);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: theme.colorScheme.surfaceContainerLowest,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: (resena.autorFotoPerfilUrl != null &&
                          resena.autorFotoPerfilUrl!.isNotEmpty)
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: resena.autorFotoPerfilUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(strokeWidth: 2),
                            errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        )
                      : Icon(Icons.person,
                          size: 20, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.reviewCardBy(resena.usernameAutor),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        fechaFormateada,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _buildStarRating(resena.valoracion),
              ],
            ),
            const SizedBox(height: 12),
            if (resena.textoResena != null && resena.textoResena!.isNotEmpty)
              Text(
                resena.textoResena!,
                style: theme.textTheme.bodyMedium,
              )
            else
              Text(
                l10n.reviewCardNoText,
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(int valoracion) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (int index) {
        return Icon(
          index < valoracion ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }
}
