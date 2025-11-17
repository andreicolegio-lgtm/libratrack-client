import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../model/resena.dart';
import 'package:intl/intl.dart';
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: (resena.autorFotoPerfilUrl != null &&
                          resena.autorFotoPerfilUrl!.isNotEmpty)
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: resena.autorFotoPerfilUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            placeholder: (BuildContext context, String url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (BuildContext context, String url,
                                    Object error) =>
                                const Icon(Icons.person, size: 20),
                          ),
                        )
                      : const Icon(Icons.person, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.reviewCardBy(resena.usernameAutor),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        fechaFormateada,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _buildStarRating(resena.valoracion),
              ],
            ),
            if (resena.textoResena != null && resena.textoResena!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  resena.textoResena!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  l10n.reviewCardNoText,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
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
