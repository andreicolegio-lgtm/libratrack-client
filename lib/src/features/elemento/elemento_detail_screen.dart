import 'dart:async'; // Necesario para Timer y Future
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/elemento_service.dart';
import '../../core/services/catalog_service.dart';
import '../../core/services/resena_service.dart';
import '../../core/services/auth_service.dart';
import '../../model/elemento.dart';
import '../../model/catalogo_entrada.dart';
import '../../model/elemento_relacion.dart';
import '../../model/resena.dart';
import 'widgets/resena_form_modal.dart';
import 'widgets/resena_card.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/error_translator.dart';
import '../../core/services/admin_service.dart';
import '../moderacion/elemento_form.dart';
import '../../core/utils/api_exceptions.dart';
import '../../core/widgets/maybe_marquee.dart';

class ElementoDetailScreen extends StatefulWidget {
  final int elementoId;

  const ElementoDetailScreen({
    required this.elementoId,
    super.key,
  });

  @override
  State<ElementoDetailScreen> createState() => _ElementoDetailScreenState();
}

class _ElementoDetailScreenState extends State<ElementoDetailScreen> {
  late final ElementoService _elementoService;
  late final CatalogService _catalogService;
  late final ResenaService _resenaService;
  late final AdminService _adminService;
  late final AuthService _authService;

  late Future<void> _screenDataFuture;

  Elemento? _elemento;
  List<Resena> _resenas = [];
  bool _isInCatalog = false;
  bool _isFavorito = false;
  bool _haResenado = false;

  // Estado UI
  bool _isAddingToCatalog = false;
  bool _isRemovingFromCatalog = false;
  bool _isTogglingFavorite = false;
  bool _isUpdatingAdminStatus = false;

  bool _sortReviewsAscending = false;

  @override
  void initState() {
    super.initState();
    _elementoService = context.read<ElementoService>();
    _catalogService = context.read<CatalogService>();
    _resenaService = context.read<ResenaService>();
    _adminService = context.read<AdminService>();
    _authService = context.read<AuthService>();

    _screenDataFuture = _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _elementoService.getElementoById(widget.elementoId),
        _resenaService.getResenas(widget.elementoId),
      ]);

      _elemento = results[0] as Elemento;
      _resenas = results[1] as List<Resena>;

      final CatalogoEntrada? entrada =
          _catalogService.getEntradaPorElementoId(widget.elementoId);

      _isInCatalog = entrada != null;
      _isFavorito = entrada?.esFavorito ?? false;

      final username = _authService.perfilUsuario?.username;
      if (username != null) {
        _haResenado = _resenas.any((r) => r.usernameAutor == username);
      }

      _sortResenasInternal(); // Llamamos a la lógica de ordenamiento al final
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
    }
  }

  void _sortResenasInternal() {
    final currentUserIdStr = _authService.currentUser?.id.toString();

    setState(() {
      // 1. Separamos la lista en "Mías" y "Otras"
      List<Resena> myReviews = [];
      List<Resena> otherReviews = [];

      for (var r in _resenas) {
        if (currentUserIdStr != null &&
            r.usuarioId.toString() == currentUserIdStr) {
          myReviews.add(r);
        } else {
          otherReviews.add(r);
        }
      }

      // 2. Ordenamos SOLO las "Otras" según el criterio de fecha
      otherReviews.sort((a, b) {
        if (_sortReviewsAscending) {
          return a.fechaCreacion
              .compareTo(b.fechaCreacion); // Más viejas primero
        } else {
          return b.fechaCreacion
              .compareTo(a.fechaCreacion); // Más nuevas primero
        }
      });

      // 3. Reconstruimos la lista: Primero la mía, luego las otras ordenadas
      _resenas = [...myReviews, ...otherReviews];
    });
  }

  // --- Acciones de Usuario ---

  Future<void> _handleAddCatalog() async {
    setState(() => _isAddingToCatalog = true);
    final l10n = AppLocalizations.of(context);

    try {
      await _catalogService.addElemento(widget.elementoId);
      if (!mounted) {
        return;
      }

      setState(() {
        _isInCatalog = true;
        _isFavorito = false;
      });
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarCatalogAdded,
          isError: false);
    } catch (e) {
      _handleError(e, l10n);
    } finally {
      if (mounted) {
        setState(() => _isAddingToCatalog = false);
      }
    }
  }

  Future<void> _handleRemoveCatalog() async {
    setState(() => _isRemovingFromCatalog = true);
    final l10n = AppLocalizations.of(context);

    try {
      await _catalogService.removeElemento(widget.elementoId);
      if (!mounted) {
        return;
      }

      setState(() {
        _isInCatalog = false;
        _isFavorito = false;
      });
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarCatalogRemoved,
          isError: false);
    } catch (e) {
      _handleError(e, l10n);
    } finally {
      if (mounted) {
        setState(() => _isRemovingFromCatalog = false);
      }
    }
  }

  Future<void> _handleToggleFavorite() async {
    if (_isTogglingFavorite) {
      return;
    }

    setState(() {
      _isTogglingFavorite = true;
      _isFavorito = !_isFavorito;
    });

    final l10n = AppLocalizations.of(context);

    try {
      await _catalogService.toggleFavorite(widget.elementoId);
      if (!mounted) {
        return;
      }

      final msg = _isFavorito
          ? l10n.snackbarFavoritoAdded
          : l10n.snackbarFavoritoRemoved;
      SnackBarHelper.showTopSnackBar(context, msg, isError: false);

      if (!_isInCatalog && _isFavorito) {
        setState(() => _isInCatalog = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFavorito = !_isFavorito);
        _handleError(e, l10n);
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingFavorite = false);
      }
    }
  }

  Future<void> _openReviewModal() async {
    final l10n = AppLocalizations.of(context);
    final Resena? nuevaResena = await showModalBottomSheet<Resena>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ResenaFormModal(elementoId: widget.elementoId),
    );

    if (nuevaResena != null && mounted) {
      setState(() {
        _resenas.insert(0, nuevaResena);
        _haResenado = true;
        _sortResenasInternal(); // Reordenar al añadir
      });
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarReviewPublished,
          isError: false);
    }
  }

  // --- Acciones Admin ---

  Future<void> _handleToggleOfficial() async {
    if (_elemento == null) {
      return;
    }

    setState(() => _isUpdatingAdminStatus = true);
    final l10n = AppLocalizations.of(context);
    final bool esOficialActual = _elemento!.estadoContenido == 'OFICIAL';

    try {
      final updatedElement = await _adminService.toggleElementoOficial(
        widget.elementoId,
        !esOficialActual,
      );
      if (!mounted) {
        return;
      }

      setState(() => _elemento = updatedElement);
      final msg = updatedElement.estadoContenido == 'OFICIAL'
          ? l10n.snackbarAdminStatusOfficial
          : l10n.snackbarAdminStatusCommunity;
      SnackBarHelper.showTopSnackBar(context, msg, isError: false);
    } catch (e) {
      _handleError(e, l10n);
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAdminStatus = false);
      }
    }
  }

  Future<void> _goToEditElement() async {
    if (_elemento == null) {
      return;
    }

    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ElementoFormScreen(elemento: _elemento)),
    );

    if (result == true) {
      _reloadData();
    }
  }

  Future<void> _handleDeleteReview(Resena resena) async {
    final l10n = AppLocalizations.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogDeleteReviewTitle),
        content: Text(l10n.dialogDeleteReviewContent),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l10n.actionDelete)),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    try {
      await _resenaService.eliminarResena(resena.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _resenas.removeWhere((r) => r.id == resena.id);
        if (resena.usernameAutor == _authService.perfilUsuario?.username) {
          _haResenado = false;
        }
      });
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarReviewDeleted,
          isError: false);
    } catch (e) {
      _handleError(e, l10n);
    }
  }

  Future<void> _handleEditReview(Resena resena) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Resena? resenaActualizada = await showModalBottomSheet<Resena>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ResenaFormModal(
        elementoId: widget.elementoId,
        resenaExistente: resena,
      ),
    );

    if (resenaActualizada != null && mounted) {
      setState(() {
        final index = _resenas.indexWhere((r) => r.id == resenaActualizada.id);
        if (index != -1) {
          _resenas[index] = resenaActualizada;
        }
        _sortResenasInternal(); // Reordenar por si cambió fecha (aunque al editar no suele cambiar)
      });
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarReviewUpdated,
          isError: false);
    }
  }

  void _handleError(Object e, AppLocalizations l10n) {
    if (!mounted) {
      return;
    }
    String msg = l10n.errorUnexpected(e.toString());
    if (e is ApiException) {
      msg = ErrorTranslator.translate(context, e.message);
    }
    SnackBarHelper.showTopSnackBar(context, msg, isError: true);
  }

  bool get _isProcessing => _isAddingToCatalog || _isRemovingFromCatalog;

  void _reloadData() {
    setState(() {
      _screenDataFuture = _loadData();
    });
  }

  // --- UI Builder ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: FutureBuilder<void>(
        future: _screenDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                  TextButton(
                      onPressed: _reloadData, child: const Text('Reintentar'))
                ],
              ),
            );
          }
          if (_elemento == null) {
            return Center(child: Text(l10n.elementDetailNoElement));
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              _buildSliverList(context, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320.0,
      pinned: true,
      stretch: true,
      // Sobrescribimos el botón 'leading' para cambiar su comportamiento
      leading: IconButton(
        icon: const Icon(Icons.arrow_back,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 2, color: Colors.black45)]),
        onPressed: () {
          // Cierra pantallas hasta encontrar una que NO sea 'ElementoDetailScreen'
          // o hasta llegar al principio de la app.
          Navigator.of(context).popUntil((route) {
            return route.isFirst ||
                route.settings.name != 'ElementoDetailScreen';
          });
        },
      ),
      // --- FIN DEL CAMBIO ---
      flexibleSpace: FlexibleSpaceBar(
        title: MaybeMarquee(
          text: _elemento!.titulo,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [Shadow(blurRadius: 4, offset: Offset(0, 1))],
          ),
          height: 20,
        ),
        centerTitle: true,
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_elemento!.urlImagen != null)
              CachedNetworkImage(
                imageUrl: _elemento!.urlImagen!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[900]),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image,
                    size: 64, color: Colors.white54),
              )
            else
              Container(
                  color: Colors.grey[800],
                  child:
                      const Icon(Icons.movie, size: 64, color: Colors.white54)),

            // Gradiente para legibilidad (Encima de la imagen)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black87
                  ],
                  stops: [0.0, 0.2, 0.6, 1.0],
                ),
              ),
            ),

            Positioned(
              top: kToolbarHeight + 30,
              right: 16,
              child: SafeArea(
                child: Chip(
                  label: Text(
                    _elemento!.estadoContenidoDisplay(context),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                  backgroundColor: _elemento!.estadoContenido == 'OFICIAL'
                      ? Colors.blueAccent
                      : _elemento!.estadoContenido == 'COMUNITARIO'
                          ? Colors.orange
                          : Colors.grey[700],
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  side: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverList(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    // Formateo de Disponibilidad (ej. "RELEASING" -> "Releasing")
    String availability = _elemento?.estadoPublicacion ?? l10n.labelUnknown;
    if (availability.isNotEmpty && availability.length > 1) {
      availability = availability[0] + availability.substring(1).toLowerCase();
    }

    return SliverSafeArea(
      top: false,
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderInfo(theme),
                const SizedBox(height: 16),
                _buildUserActions(context, l10n),
                const SizedBox(height: 16),
                _buildAdminActions(context, l10n),

                // Sinopsis
                if (_elemento?.descripcion != null &&
                    _elemento!.descripcion.isNotEmpty) ...[
                  Text(l10n.labelSynopsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_elemento!.descripcion,
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 24),
                ],

                // Disponibilidad
                Text(l10n.labelAvailability,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Builder(builder: (context) {
                      IconData icon;
                      Color color = theme.colorScheme.primary;
                      switch (_elemento?.estadoPublicacion) {
                        case 'RELEASING':
                          icon = Icons.schedule;
                          break;
                        case 'FINISHED':
                          icon = Icons.check_circle;
                          break;
                        case 'ANNOUNCED':
                          icon = Icons.campaign;
                          break;
                        case 'CANCELLED':
                          icon = Icons.cancel;
                          color = theme.colorScheme.error;
                          break;
                        case 'PAUSED':
                          icon = Icons.pause_circle;
                          break;
                        case 'AVAILABLE':
                          icon = Icons.play_circle;
                          break;
                        default:
                          icon = Icons.help_outline;
                      }
                      return Icon(icon, color: color);
                    }),
                    const SizedBox(width: 8),
                    Text(availability, style: theme.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 24),

                // Progreso
                _buildTechnicalDetails(theme),
                const SizedBox(height: 24),

                // Cronología (Secuelas/Precuelas)
                _buildChronology(theme),

                const Divider(height: 48),

                // Reseñas
                _buildReviewsSection(context, l10n),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeaderInfo(ThemeData theme) {
    final sortedGeneros = List<String>.from(_elemento?.generos ?? [])..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tipo más grande
        Text(
          _elemento?.tipo ?? '',
          style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: sortedGeneros
              .map((g) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    // Géneros más grandes
                    child: Text(g, style: theme.textTheme.bodyMedium),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildUserActions(BuildContext context, AppLocalizations l10n) {
    if (_isProcessing) {
      return SizedBox(
        height: 50,
        child: Center(
            child: Text(_isAddingToCatalog
                ? l10n.elementDetailAddingButton
                : l10n.elementDetailRemovingButton)),
      );
    }
    return Row(
      children: [
        Expanded(
          child: _isInCatalog
              ? OutlinedButton.icon(
                  icon: const Icon(Icons.remove_circle_outline),
                  label: Text(l10n.elementDetailRemoveButton),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: _handleRemoveCatalog,
                )
              : FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(l10n.elementDetailAddButton),
                  onPressed: _handleAddCatalog,
                ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          icon: Icon(_isFavorito ? Icons.star : Icons.star_border),
          color: _isFavorito ? Colors.amber : null,
          onPressed: _handleToggleFavorite,
          tooltip: l10n.tooltipFavorite,
        ),
      ],
    );
  }

  Widget _buildAdminActions(BuildContext context, AppLocalizations l10n) {
    final perfil = _authService.perfilUsuario;
    if (perfil == null || !perfil.esModerador) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.security, size: 20), // Icono más grande
              const SizedBox(width: 8),
              // Texto más grande
              Text(l10n.labelModActions,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: _goToEditElement,
                  tooltip: l10n.elementDetailAdminEdit),
              if (perfil.esAdministrador)
                IconButton(
                  icon: _isUpdatingAdminStatus
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(
                          _elemento?.estadoContenido == 'OFICIAL'
                              ? Icons.verified
                              : Icons.public,
                          size: 20),
                  onPressed:
                      _isUpdatingAdminStatus ? null : _handleToggleOfficial,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Progreso y Detalles ---
  Widget _buildTechnicalDetails(ThemeData theme) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (_elemento?.tipo == 'Video Game') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.labelProgressDetails,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_elemento?.tipo == 'Series' &&
            _elemento?.episodiosPorTemporada != null) ...[
          // Parsea "12, 13, 24"
          Builder(builder: (context) {
            final parts = _elemento!.episodiosPorTemporada!.split(',');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(parts.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                      l10n.formatSeasonEpisodes(
                          (i + 1).toString(), parts[i].trim()),
                      style: theme.textTheme.bodyMedium),
                );
              }),
            );
          }),
        ],
        if (_elemento?.tipo == 'Book') ...[
          _detailRow(Icons.menu_book, l10n.labelTotalChapters,
              '${_elemento?.totalCapitulosLibro ?? "?"}'),
          _detailRow(Icons.description, l10n.labelTotalPages,
              '${_elemento?.totalPaginasLibro ?? "?"}'),
        ],
        if (_elemento?.tipo == 'Movie' && _elemento?.duracion != null) ...[
          // Asume duración "120" minutos
          Builder(builder: (context) {
            final mins = int.tryParse(
                    _elemento!.duracion!.replaceAll(RegExp(r'[^0-9]'), '')) ??
                0;
            final h = mins ~/ 60;
            final m = mins % 60;
            return _detailRow(
                Icons.timer, l10n.labelDuration, l10n.formatDuration(h, m));
          }),
        ],
        if (_elemento?.tipo == 'Anime') ...[
          _detailRow(Icons.tv, l10n.labelTotalEpisodes,
              '${_elemento?.totalUnidades ?? "?"}'),
        ],
        if (['Manga', 'Manhwa'].contains(_elemento?.tipo)) ...[
          _detailRow(Icons.library_books, l10n.labelTotalChapters,
              '${_elemento?.totalCapitulosLibro ?? "?"}'),
        ],
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  // --- Cronología ---
  Widget _buildChronology(ThemeData theme) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final precuela = _elemento?.precuelas.isNotEmpty == true
        ? _elemento!.precuelas.first
        : null;
    final secuela = _elemento?.secuelas.isNotEmpty == true
        ? _elemento!.secuelas.first
        : null;
    if (precuela == null && secuela == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.labelChronology,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // COLUMNA 1: PRECUELA (Mitad Izquierda)
            Expanded(
              child: precuela != null
                  ? _buildChronologyItem(theme, l10n.labelPrequel, precuela)
                  : const SizedBox.shrink(), // Hueco vacío si no hay
            ),
            // Espacio central seguro para que los textos no se toquen entre columnas
            const SizedBox(width: 16),

            // COLUMNA 2: SECUELA (Mitad Derecha)
            Expanded(
              child: secuela != null
                  ? _buildChronologyItem(theme, l10n.labelSequel, secuela)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChronologyItem(
      ThemeData theme, String label, ElementoRelacion item) {
    return Column(
      children: [
        // Título de subsección: Estilo igual a los labels de Progress Details (negrita, color del cuerpo)
        Text(
          label,
          style:
              theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ElementoDetailScreen(elementoId: item.id),
                settings: const RouteSettings(name: 'ElementoDetailScreen'),
              )),
          child: Column(
            children: [
              // Portada Centrada (ancho fijo para uniformidad)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.urlImagen != null
                    ? CachedNetworkImage(
                        imageUrl: item.urlImagen!,
                        height: 120,
                        width: 80,
                        fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[800],
                        height: 120,
                        width: 80,
                        child: const Icon(Icons.image)),
              ),
              const SizedBox(height: 8),

              // Título Marquesina Centrado (con padding horizontal para que no se toquen entre columnas)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: SizedBox(
                  height: 20,
                  // Envolvemos en Center para intentar centrar el contenido si el widget lo permite
                  child: Center(
                    child: MaybeMarquee(
                      text: item.titulo,
                      style: theme.textTheme.bodyMedium!
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Reseñas ---
  Widget _buildReviewsSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            Text('${l10n.labelReviews} (${_resenas.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            // Botón ordenar aquí
            IconButton(
              icon: Icon(
                  _sortReviewsAscending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 20),
              tooltip: _sortReviewsAscending
                  ? l10n.tooltipSortOldest
                  : l10n.tooltipSortNewest,
              onPressed: _toggleSortOrder,
            ),
            const Spacer(),
            if (!_haResenado)
              TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: Text(l10n.actionWriteReview),
                  onPressed: _openReviewModal)
            else
              Chip(
                  label: Text(l10n.labelReviewed),
                  avatar: const Icon(Icons.check, size: 14)),
          ],
        ),
        const SizedBox(height: 16),
        _buildRatingStatistics(Theme.of(context)),
        const SizedBox(height: 8),
        if (_resenas.isEmpty)
          Text(l10n.labelNoReviews, style: const TextStyle(color: Colors.grey))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _resenas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final resena = _resenas[index];
              return ResenaCard(
                resena: resena,
                onEdit: () => _handleEditReview(resena),
                onDelete: () => _handleDeleteReview(resena),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRatingStatistics(ThemeData theme) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    double average = 0.0;

    if (_resenas.isNotEmpty) {
      for (final r in _resenas) {
        distribution[r.valoracion] = (distribution[r.valoracion] ?? 0) + 1;
      }
      average = _resenas.map((r) => r.valoracion).reduce((a, b) => a + b) /
          _resenas.length;
    }

    return Row(
      children: [
        // Columna Izquierda: Promedio Grande
        Column(
          children: [
            Text(average.toStringAsFixed(1),
                style: theme.textTheme.displayMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Row(
                children: List.generate(
                    5,
                    (i) => _buildFractionalStar(average, i,
                        Colors.amber))), // Estrellas fraccionadas (Pto 10)
            const SizedBox(height: 4),
            Text('${_resenas.length} ${l10n.labelRatings}',
                style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(width: 24),
        // Columna Derecha: Barras
        Expanded(
          child: Column(
            children: [
              for (int i = 5; i >= 1; i--)
                Row(
                  children: [
                    Text('$i',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _resenas.isNotEmpty
                              ? (distribution[i]! / _resenas.length)
                              : 0.0,
                          minHeight: 8,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper para estrellas parciales (Pto 10)
  Widget _buildFractionalStar(double rating, int index, Color color) {
    if (index >= rating) {
      return Icon(Icons.star_border, size: 18, color: Colors.grey[400]);
    } else if (index < rating - 1.0) {
      return Icon(Icons.star, size: 18, color: color);
    } else {
      double percentage = rating - index;
      return ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            colors: [color, Colors.grey[400]!],
            stops: [percentage, percentage],
          ).createShader(bounds);
        },
        child: Icon(Icons.star, size: 18, color: Colors.grey[400]),
      );
    }
  }

  void _toggleSortOrder() {
    setState(() {
      _sortReviewsAscending = !_sortReviewsAscending;
      _sortResenasInternal();
    });
  }
}
