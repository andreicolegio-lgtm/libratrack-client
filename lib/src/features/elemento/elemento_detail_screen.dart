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
import '../../model/perfil_usuario.dart';
import '../../model/elemento_relacion.dart';
import 'widgets/resena_form_modal.dart';
import 'widgets/resena_card.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/error_translator.dart';
import '../../core/services/admin_service.dart';
import '../admin/admin_elemento_form.dart';
import '../../core/utils/api_exceptions.dart';

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

  late Future<Map<String, dynamic>> _screenDataFuture;

  bool _isInCatalog = false;
  bool _isAdding = false;
  bool _isDeleting = false;
  bool _isLoadingStatusChange = false;
  bool _isFavorito = false;

  List<Resena> _resenas = <Resena>[];
  bool _haResenado = false;
  String? _usernameActual;

  @override
  void initState() {
    super.initState();
    _elementoService = context.read<ElementoService>();
    _catalogService = context.read<CatalogService>();
    _resenaService = context.read<ResenaService>();
    _adminService = context.read<AdminService>();
    _authService = context.read<AuthService>();

    _loadScreenData();
  }

  @override
  void didUpdateWidget(ElementoDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.elementoId != oldWidget.elementoId) {
      _loadScreenData();
    }
  }

  void _loadScreenData() {
    _screenDataFuture = _fetchData();
    if (mounted) {
      setState(() {});
    }
  }

  Future<Map<String, dynamic>> _fetchData() async {
    try {
      final PerfilUsuario perfil = _authService.perfilUsuario!;
      _usernameActual = perfil.username;

      await _catalogService.fetchCatalog();
      final List<CatalogoEntrada> catalogo = _catalogService.entradas;

      final List<Object> results = await Future.wait(<Future<Object>>[
        _elementoService.getElementoById(widget.elementoId),
        _resenaService.getResenas(widget.elementoId),
      ]);

      final Elemento elemento = results[0] as Elemento;
      final List<Resena> resenas = results[1] as List<Resena>;

      final bool inCatalog = catalogo.any(
          (CatalogoEntrada entrada) => entrada.elementoId == widget.elementoId);

      final bool haResenado = resenas
          .any((Resena resena) => resena.usernameAutor == _usernameActual);

      _isInCatalog = inCatalog;
      _resenas = resenas;
      _haResenado = haResenado;

      return <String, dynamic>{'elemento': elemento, 'perfil': perfil};
    } on ApiException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleAddElemento() async {
    setState(() {
      _isAdding = true;
    });
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    try {
      await _catalogService.addElemento(widget.elementoId);
      if (!mounted) {
        return;
      }
      setState(() {
        _isAdding = false;
        _isInCatalog = true;
      });
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarCatalogAdded,
          isError: false);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isAdding = false;
      });
      SnackBarHelper.showTopSnackBar(
          context, ErrorTranslator.translate(context, e.message),
          isError: true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isAdding = false;
      });
      SnackBarHelper.showTopSnackBar(
          context, l10n.errorUnexpected(e.toString()),
          isError: true);
    }
  }

  Future<void> _handleRemoveElemento() async {
    setState(() {
      _isDeleting = true;
    });
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    try {
      await _catalogService.removeElemento(widget.elementoId);
      if (!mounted) {
        return;
      }
      setState(() {
        _isDeleting = false;
        _isInCatalog = false;
      });
      SnackBarHelper.showTopSnackBar(context, l10n.snackbarCatalogRemoved,
          isError: false);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isDeleting = false;
      });
      SnackBarHelper.showTopSnackBar(
          context, ErrorTranslator.translate(context, e.message),
          isError: true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isDeleting = false;
      });
      SnackBarHelper.showTopSnackBar(
          context, l10n.errorUnexpected(e.toString()),
          isError: true);
    }
  }

  Future<void> _openWriteReviewModal() async {
    final Resena? resultado = await showModalBottomSheet<Resena>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return ResenaFormModal(elementoId: widget.elementoId);
      },
    );
    if (resultado != null) {
      setState(() {
        _resenas.insert(0, resultado);
        _haResenado = true;
      });
    }
  }

  Future<void> _handleToggleOficial(Elemento elemento) async {
    final bool esOficial = elemento.estadoContenido == 'OFICIAL';
    setState(() {
      _isLoadingStatusChange = true;
    });
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    try {
      await _adminService.toggleElementoOficial(
        elemento.id,
        !esOficial,
      );
      if (!mounted) {
        return;
      }
      final String successMessage = esOficial
          ? l10n.snackbarAdminStatusCommunity
          : l10n.snackbarAdminStatusOfficial;
      SnackBarHelper.showTopSnackBar(context, successMessage, isError: false);
      _loadScreenData();
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      SnackBarHelper.showTopSnackBar(
          context, ErrorTranslator.translate(context, e.message),
          isError: true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      SnackBarHelper.showTopSnackBar(
          context, l10n.errorUnexpected(e.toString()),
          isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStatusChange = false;
        });
      }
    }
  }

  Future<void> _goToEditarElemento(Elemento elemento) async {
    if (_isAnyLoading()) {
      return;
    }
    final bool? seHaActualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) =>
            AdminElementoFormScreen(elemento: elemento),
      ),
    );
    if (seHaActualizado == true && mounted) {
      _loadScreenData();
    }
  }

  Future<void> _handleToggleFavorito() async {
    setState(() {
      _isFavorito = !_isFavorito;
    });
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    try {
      await _catalogService.toggleFavorite(widget.elementoId);
      SnackBarHelper.showTopSnackBar(
        context,
        _isFavorito ? l10n.snackbarFavoritoAdded : l10n.snackbarFavoritoRemoved,
        isError: false,
      );
    } on ApiException catch (e) {
      setState(() {
        _isFavorito = !_isFavorito; // Revert state on error
      });
      SnackBarHelper.showTopSnackBar(
        context,
        ErrorTranslator.translate(context, e.message),
        isError: true,
      );
    } catch (e) {
      setState(() {
        _isFavorito = !_isFavorito; // Revert state on error
      });
      SnackBarHelper.showTopSnackBar(
        context,
        l10n.errorUnexpected(e.toString()),
        isError: true,
      );
    }
  }

  bool _isAnyLoading() {
    return _isAdding || _isDeleting || _isLoadingStatusChange;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _screenDataFuture,
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            String errorMessage;
            if (snapshot.error is ApiException) {
              errorMessage = ErrorTranslator.translate(
                  context, (snapshot.error as ApiException).message);
            } else {
              errorMessage =
                  l10n.errorLoadingElement(snapshot.error.toString());
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.red),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(child: Text(l10n.elementDetailNoElement));
          }

          final Elemento elemento = snapshot.data!['elemento'];
          final PerfilUsuario perfil = snapshot.data!['perfil'];

          return CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                expandedHeight: 300.0,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 24.0),
                  title: Text(
                    elemento.titulo,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        shadows: <Shadow>[const Shadow(blurRadius: 10)],
                        fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      if (elemento.urlImagen != null &&
                          elemento.urlImagen!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: elemento.urlImagen!,
                          fit: BoxFit.cover,
                          placeholder: (BuildContext context, String url) =>
                              Container(
                                  color: Theme.of(context).colorScheme.surface),
                          errorWidget: (BuildContext context, String url,
                                  Object error) =>
                              Container(
                                  color: Theme.of(context).colorScheme.surface),
                        )
                      else
                        Container(color: Theme.of(context).colorScheme.surface),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[Colors.transparent, Colors.black87],
                            stops: <double>[0.5, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        right: 16,
                        child: _buildEstadoChip(context, elemento),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${elemento.tipo} | ${elemento.generos.join(", ")}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                          const SizedBox(height: 24),
                          _buildAdminButtons(context, perfil, elemento, l10n),
                          _buildAddOrRemoveButton(l10n),
                          const SizedBox(height: 24),
                          Text(l10n.elementDetailSynopsis,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(elemento.descripcion,
                              style: Theme.of(context).textTheme.bodyMedium),
                          _buildProgresoTotalInfo(elemento, l10n),
                          _buildRelacionesSection(
                            context,
                            l10n.elementDetailPrequels,
                            elemento.precuelas,
                          ),
                          _buildRelacionesSection(
                            context,
                            l10n.elementDetailSequels,
                            elemento.secuelas,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Divider(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                l10n.elementDetailReviews(_resenas.length),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              _buildWriteReviewButton(l10n),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildReviewList(l10n),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<int> _parseEpisodiosPorTemporada(String? data) {
    if (data == null || data.isEmpty) {
      return <int>[];
    }
    try {
      return data
          .split(',')
          .map((String e) => int.tryParse(e.trim()) ?? 0)
          .toList();
    } catch (e) {
      return <int>[];
    }
  }

  Widget _buildProgresoTotalInfo(Elemento elemento, AppLocalizations l10n) {
    final String tipo = elemento.tipo.toLowerCase();
    final List<Widget> infoWidgets = <Widget>[];
    if (tipo == 'serie') {
      final List<int> epCounts =
          _parseEpisodiosPorTemporada(elemento.episodiosPorTemporada);
      final int totalTemps = epCounts.length;
      if (totalTemps > 0) {
        infoWidgets.add(_buildInfoRow(context, Icons.movie_filter,
            l10n.elementDetailSeriesSeasons, '$totalTemps'));
        infoWidgets.add(_buildInfoRow(context, Icons.list_alt,
            l10n.elementDetailSeriesEpisodes, epCounts.join(', ')));
      }
    } else if (tipo == 'libro') {
      if (elemento.totalCapitulosLibro != null &&
          elemento.totalCapitulosLibro! > 0) {
        infoWidgets.add(_buildInfoRow(context, Icons.book_outlined,
            l10n.elementDetailBookChapters, '${elemento.totalCapitulosLibro}'));
      }
      if (elemento.totalPaginasLibro != null &&
          elemento.totalPaginasLibro! > 0) {
        infoWidgets.add(_buildInfoRow(context, Icons.pages_outlined,
            l10n.elementDetailBookPages, '${elemento.totalPaginasLibro}'));
      }
    } else if (tipo == 'anime' || tipo == 'manga') {
      if (elemento.totalUnidades != null && elemento.totalUnidades! > 0) {
        final String label = tipo == 'anime'
            ? l10n.elementDetailAnimeEpisodes
            : l10n.elementDetailMangaChapters;
        infoWidgets.add(_buildInfoRow(
            context, Icons.list, label, '${elemento.totalUnidades}'));
      }
    }
    if (infoWidgets.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Divider(),
        ),
        Text(l10n.elementDetailProgressDetails,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...infoWidgets,
      ],
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 16),
          Text('$label:',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.grey[300])),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(BuildContext context, Elemento elemento) {
    final bool isOficial = elemento.estadoContenido == 'OFICIAL';
    final Color chipColor =
        isOficial ? Theme.of(context).colorScheme.secondary : Colors.grey[700]!;
    return Chip(
      label: Text(
        elemento.estadoContenidoDisplay(context),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
      ),
      backgroundColor: chipColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildAddOrRemoveButton(AppLocalizations l10n) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    if (_isDeleting) {
      return ElevatedButton.icon(
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
        label: Text(l10n.elementDetailRemovingButton),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: null,
      );
    }
    if (_isInCatalog) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.remove_circle_outline),
        label: Text(l10n.elementDetailRemoveButton),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Colors.red[300],
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: _isAnyLoading() ? null : _handleRemoveElemento,
      );
    }
    if (_isAdding) {
      return ElevatedButton.icon(
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
        label: Text(l10n.elementDetailAddingButton),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: null,
      );
    }
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l10n.elementDetailAddButton),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: _isAnyLoading() ? null : _handleAddElemento,
        ),
        const SizedBox(height: 16),
        IconButton(
          icon: Icon(
            _isFavorito ? Icons.star : Icons.star_border,
            color: _isFavorito ? Colors.yellow : Colors.grey,
          ),
          onPressed: _handleToggleFavorito,
        ),
      ],
    );
  }

  Widget _buildWriteReviewButton(AppLocalizations l10n) {
    if (_haResenado) {
      return TextButton(
        onPressed: null,
        child: Text(l10n.elementDetailAlreadyReviewed,
            style: const TextStyle(color: Colors.grey)),
      );
    }
    return TextButton.icon(
      icon: const Icon(Icons.edit, size: 16),
      label: Text(l10n.elementDetailWriteReview),
      style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary),
      onPressed: _openWriteReviewModal,
    );
  }

  Widget _buildReviewList(AppLocalizations l10n) {
    if (_resenas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            l10n.elementDetailNoReviews,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _resenas.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return ResenaCard(resena: _resenas[index]);
      },
    );
  }

  Widget _buildAdminButtons(BuildContext context, PerfilUsuario perfil,
      Elemento elemento, AppLocalizations l10n) {
    if (!perfil.esModerador) {
      return const SizedBox.shrink();
    }
    final bool esOficial = elemento.estadoContenido == 'OFICIAL';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_note, size: 18),
              label: Text(l10n.elementDetailAdminEdit),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed:
                  _isAnyLoading() ? null : () => _goToEditarElemento(elemento),
            ),
          ),
          if (perfil.esAdministrador) ...<Widget>[
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: _isLoadingStatusChange
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(esOficial ? Icons.public_off : Icons.verified,
                        size: 18),
                label: Text(_isLoadingStatusChange
                    ? l10n.elementDetailAdminLoading
                    : (esOficial
                        ? l10n.elementDetailAdminMakeCommunity
                        : l10n.elementDetailAdminMakeOfficial)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: esOficial
                      ? Colors.grey[700]
                      : Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isAnyLoading()
                    ? null
                    : () => _handleToggleOficial(elemento),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildRelacionesSection(
    BuildContext context,
    String titulo,
    List<ElementoRelacion> relaciones,
  ) {
    if (relaciones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
          child: Text(
            titulo,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: relaciones.length,
            itemBuilder: (BuildContext context, int index) {
              final ElementoRelacion relacion = relaciones[index];
              return _RelacionCard(
                relacion: relacion,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) =>
                          ElementoDetailScreen(elementoId: relacion.id),
                    ),
                  ).then((_) => _loadScreenData());
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RelacionCard extends StatelessWidget {
  final ElementoRelacion relacion;
  final VoidCallback onTap;

  const _RelacionCard({
    required this.relacion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Card(
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SizedBox(
                  height: 130,
                  width: 120,
                  child: (relacion.urlImagen != null &&
                          relacion.urlImagen!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: relacion.urlImagen!,
                          fit: BoxFit.cover,
                          placeholder: (BuildContext context, String url) =>
                              const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                          errorWidget: (BuildContext context, String url,
                                  Object error) =>
                              Center(
                                  child: Icon(Icons.image_not_supported,
                                      color: Colors.grey[400])),
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: Icon(
                              Icons.movie,
                              color: Colors.grey[600],
                              size: 40,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                relacion.titulo,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// Fixed BuildContext usage across async gaps.
