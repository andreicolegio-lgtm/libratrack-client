import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../model/resena.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth_service.dart';

class ResenaCard extends StatefulWidget {
  final Resena resena;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ResenaCard({
    required this.resena,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  @override
  State<ResenaCard> createState() => _ResenaCardState();
}

class _ResenaCardState extends State<ResenaCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final String fechaFormateada =
        DateFormat('dd/MM/yyyy').format(widget.resena.fechaCreacion);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Obtener usuario actual para permisos
    final currentUser = context.read<AuthService>().currentUser;
    // Asumimos que podemos comparar por username si no tenemos ID de usuario a mano,
    // o mejor aún, si tu modelo Resena tiene usuarioId. Ajusta según tu modelo.
    // Aquí uso username como fallback visual.
    final bool isMyReview = currentUser != null &&
        (widget.resena.usernameAutor == currentUser.username);
    final bool isAdminOrMod = currentUser != null &&
        (currentUser.esAdministrador || currentUser.esModerador);

    final bool showActions = isMyReview || isAdminOrMod;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: theme.colorScheme.surfaceContainerLowest,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Cabecera (Avatar, Nombre, Estrellas)
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: (widget.resena.autorFotoPerfilUrl != null &&
                          widget.resena.autorFotoPerfilUrl!.isNotEmpty)
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: widget.resena.autorFotoPerfilUrl!,
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
                        l10n.reviewCardBy(widget.resena.usernameAutor),
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
                _buildStarRating(widget.resena.valoracion),
              ],
            ),
            const SizedBox(height: 12),

            // Texto Colapsable
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.resena.textoResena != null &&
                      widget.resena.textoResena!.isNotEmpty)
                    Text(
                      widget.resena.textoResena!,
                      style: theme.textTheme.bodyMedium,
                      maxLines: _isExpanded ? null : 2,
                      overflow: _isExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
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

            // Botones de Acción (Editar/Borrar)
            if (showActions) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isMyReview)
                    TextButton.icon(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  if (isAdminOrMod || isMyReview)
                    TextButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Borrar'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
            ],
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
