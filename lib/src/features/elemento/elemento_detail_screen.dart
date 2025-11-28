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
import '../../model/resena.dart';
import '../../model/elemento_relacion.dart';
import 'widgets/resena_form_modal.dart';
import 'widgets/resena_card.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/error_translator.dart';
import '../../core/services/admin_service.dart';
import '../admin/admin_elemento_form.dart';
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

  /// Carga inicial de todos los datos necesarios.
  Future<void> _loadData() async {
    try {
      // 1. Cargar Elemento y Reseñas en paralelo
      final results = await Future.wait([
        _elementoService.getElementoById(widget.elementoId),
        _resenaService.getResenas(widget.elementoId),
      ]);

      _elemento = results[0] as Elemento;
      _resenas = results[1] as List<Resena>;

      // 2. Verificar estado en el catálogo (usando caché del servicio si es posible)
      // Nota: Si el catálogo no está cargado, podríamos forzar una carga rápida o comprobar solo este ID
      final CatalogoEntrada? entrada =
          _catalogService.getEntradaPorElementoId(widget.elementoId);

      _isInCatalog = entrada != null;
      _isFavorito = entrada?.esFavorito ?? false;

      // 3. Verificar si el usuario actual ya reseñó
      final username = _authService.perfilUsuario?.username;
      if (username != null) {
        _haResenado = _resenas.any((r) => r.usernameAutor == username);
      }
    } catch (e) {
      // Dejamos que el FutureBuilder maneje el error en la UI
      rethrow;
    }
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
        // Al añadir, por defecto no es favorito a menos que el backend diga lo contrario,
        // pero asumimos false inicial.
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
        _isFavorito =
            false; // Si se quita del catálogo, ya no es favorito visiblemente
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

    // Optimistic UI Update
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

      // Si no estaba en catálogo y se marcó favorito, ahora está en catálogo implícitamente
      if (!_isInCatalog && _isFavorito) {
        setState(() => _isInCatalog = true);
      }
    } catch (e) {
      // Revertir en caso de error
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
      });
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarReviewPublished,
          isError: false);
    }
  }

  // --- Acciones de Admin ---

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
        !esOficialActual, // Invertir estado
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
          builder: (_) => AdminElementoFormScreen(elemento: _elemento)),
    );

    if (result == true) {
      // Recargar datos si hubo edición exitosa
      setState(() {
        _screenDataFuture = _loadData();
      });
    }
  }

  Future<void> _handleDeleteReview(Resena resena) async {
    final l10n = AppLocalizations.of(context);

    // Diálogo de confirmación
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar reseña?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Borrar'),
          ),
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

        // Si borré mi propia reseña, actualizo el estado
        if (resena.usernameAutor == _authService.perfilUsuario?.username) {
          _haResenado = false;
        }
      });

      SnackBarHelper.showTopSnackBar(context, 'Reseña eliminada',
          isError: false);
    } catch (e) {
      _handleError(e, l10n);
    }
  }

  Future<void> _handleEditReview(Resena resena) async {
    // Reutilizamos el modal existente pasándole la reseña
    final Resena? resenaActualizada = await showModalBottomSheet<Resena>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ResenaFormModal(
        elementoId: widget.elementoId,
        resenaExistente: resena, // Nuevo parámetro
      ),
    );

    if (resenaActualizada != null && mounted) {
      setState(() {
        final index = _resenas.indexWhere((r) => r.id == resenaActualizada.id);
        if (index != -1) {
          _resenas[index] = resenaActualizada;
        }
      });

      SnackBarHelper.showTopSnackBar(context, 'Reseña actualizada',
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

  // --- UI Builder ---

  void _reloadData() async {
    final newDataFuture = _loadData(); // Start the async operation
    setState(() {
      _screenDataFuture = newDataFuture; // Update the state synchronously
    });
  }

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
                  Text(
                      'Error: ${snapshot.error}\nStack: ${snapshot.stackTrace}',
                      textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _reloadData, // Use the new method here
                    child: const Text('Reintentar'),
                  )
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
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderInfo(context),
                        const SizedBox(height: 24),
                        _buildAdminActions(context, l10n),
                        _buildUserActions(context, l10n),
                        const SizedBox(height: 24),

                        // Sinopsis
                        Text(l10n.elementDetailSynopsis,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          _elemento!.descripcion,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.5),
                        ),

                        _buildTechnicalDetails(context, l10n),

                        // Relaciones
                        if (_elemento!.precuelas.isNotEmpty)
                          _buildRelationsList(context,
                              l10n.elementDetailPrequels, _elemento!.precuelas),
                        if (_elemento!.secuelas.isNotEmpty)
                          _buildRelationsList(context,
                              l10n.elementDetailSequels, _elemento!.secuelas),

                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Divider()),

                        // Reseñas
                        _buildReviewsSection(context, l10n),
                        const SizedBox(height: 40), // Bottom padding
                      ],
                    ),
                  ),
                ]),
              ),
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
      flexibleSpace: FlexibleSpaceBar(
        title: MaybeMarquee(
          text: _elemento!.titulo,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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

            // Gradiente para legibilidad
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.6, 1.0],
                ),
              ),
            ),

            // Chip de Estado
            Positioned(
              top: kToolbarHeight + 16, // Ajustar según SafeArea
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

  Widget _buildHeaderInfo(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _elemento!.tipo,
          style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _elemento!.generos
              .map((g) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(g, style: theme.textTheme.bodySmall),
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
            child: Text(
          _isAddingToCatalog
              ? l10n.elementDetailAddingButton
              : l10n.elementDetailRemovingButton,
          style: const TextStyle(fontStyle: FontStyle.italic),
        )),
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
          tooltip: 'Favorito',
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
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Icon(Icons.security, size: 16),
              const SizedBox(width: 8),
              Text('Mod Actions',
                  style: Theme.of(context).textTheme.labelMedium),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: Text(l10n.elementDetailAdminEdit),
                onPressed: _goToEditElement,
              ),
              if (perfil.esAdministrador)
                IconButton(
                  icon: _isUpdatingAdminStatus
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_elemento!.estadoContenido == 'OFICIAL'
                          ? Icons.verified
                          : Icons.public),
                  onPressed:
                      _isUpdatingAdminStatus ? null : _handleToggleOfficial,
                  tooltip: 'Cambiar Estado Oficial',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicalDetails(BuildContext context, AppLocalizations l10n) {
    final List<Widget> details = [];
    final e = _elemento!;

    if (e.fechaLanzamiento != null) {
      details.add(
          _detailRow(Icons.calendar_today, 'Lanzamiento', e.fechaLanzamiento!));
    }
    if (e.duracion != null) {
      details.add(_detailRow(Icons.timer, l10n.duration, e.duracion!));
    }

    // Detalles específicos por tipo
    if (e.tipo == 'Series' && e.episodiosPorTemporada != null) {
      details.add(_detailRow(
          Icons.tv, l10n.episodesPerSeason, e.episodiosPorTemporada!));
    } else if (e.tipo == 'Book') {
      if (e.totalPaginasLibro != null) {
        details.add(_detailRow(
            Icons.menu_book, l10n.totalPages, '${e.totalPaginasLibro}'));
      }
    } else if (e.tipo == 'Anime') {
      if (e.totalUnidades != null) {
        details.add(_detailRow(Icons.play_circle_outline, l10n.totalEpisodes,
            '${e.totalUnidades}'));
      }
    }

    if (details.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(l10n.elementDetailProgressDetails,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...details,
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildRelationsList(
      BuildContext context, String title, List<ElementoRelacion> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ElementoDetailScreen(elementoId: item.id)),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.urlImagen != null
                              ? CachedNetworkImage(
                                  imageUrl: item.urlImagen!, fit: BoxFit.cover)
                              : Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(item.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.elementDetailReviews(_resenas.length),
                style: Theme.of(context).textTheme.titleLarge),
            if (!_haResenado)
              TextButton.icon(
                icon: const Icon(Icons.rate_review),
                label: Text(l10n.elementDetailWriteReview),
                onPressed: _openReviewModal,
              )
            else
              Chip(
                label: Text(l10n.elementDetailAlreadyReviewed),
                avatar: const Icon(Icons.check, size: 16),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_resenas.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(l10n.elementDetailNoReviews,
                style: const TextStyle(color: Colors.grey)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _resenas.length,
            separatorBuilder: (_, __) => const Divider(height: 32),
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
}
