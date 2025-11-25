import '../../core/utils/error_translator.dart';
import '../../core/utils/content_translator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/maybe_marquee.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/elemento_service.dart';
import '../../core/services/tipo_service.dart';
import '../../core/services/genero_service.dart';
import '../elemento/elemento_detail_screen.dart';
import '../propuestas/propuesta_form_screen.dart';
import '../../model/elemento.dart';
import '../../model/tipo.dart';
import '../../model/genero.dart';
import '../../model/paginated_response.dart';
import '../../core/utils/api_exceptions.dart';
import '../../core/services/auth_service.dart';
import '../../core/l10n/app_localizations.dart';
import 'dart:async';
import 'dart:collection';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final ElementoService _elementoService;
  late final TipoService _tipoService;
  late final GeneroService _generoService;
  late AuthService _authService;

  final TextEditingController _searchController = TextEditingController();
  List<Tipo> _tipos = <Tipo>[];
  Future<void>? _filtrosFuture;
  final ScrollController _scrollController = ScrollController();
  final List<Elemento> _elementos = <Elemento>[];
  int _currentPage = 0;
  bool _hasNextPage = true;
  bool _isLoadingFirstPage = true;
  bool _isLoadingMore = false;
  String? _loadingError;

  bool _isDataLoaded = false;
  Timer? _debounce;

  final Set<int> _selectedTypeIds = HashSet<int>();
  final Set<int> _selectedGenreIds = HashSet<int>();

  @override
  void initState() {
    super.initState();
    _elementoService = context.read<ElementoService>();
    _tipoService = context.read<TipoService>();
    _generoService = context.read<GeneroService>();
    _authService = context.read<AuthService>();

    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      _filtrosFuture = _loadInitialData();
      _loadElementos(isFirstPage: true);
      _isDataLoaded = true;
    }
  }

  Future<void> _loadInitialData() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    try {
      final List<List<Object>> results =
          await Future.wait(<Future<List<Object>>>[
        _tipoService.fetchTipos(l10n.errorLoadingElements('')),
        _generoService.fetchGeneros(),
      ]);
      if (mounted) {
        setState(() {
          _tipos = results[0] as List<Tipo>;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = ErrorTranslator.translate(context, e.message);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = l10n.errorLoadingFilters(e.toString());
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    if (_isLoadingMore || !_hasNextPage) {
      return;
    }
    _loadElementos();
  }

  Future<void> _loadElementos({bool isFirstPage = false}) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (isFirstPage) {
      setState(() {
        _isLoadingFirstPage = true;
        _currentPage = 0;
        _elementos.clear();
        _hasNextPage = true;
        _loadingError = null;
      });
    } else {
      if (_isLoadingMore) {
        return;
      }
      setState(() {
        _isLoadingMore = true;
      });
    }
    try {
      final PaginatedResponse<Elemento> respuesta =
          await _elementoService.searchElementos(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        tipo: _selectedTypeIds.isEmpty ? null : _selectedTypeIds.join(','),
        genero: _selectedGenreIds.isEmpty ? null : _selectedGenreIds.join(','),
        page: _currentPage,
      );

      if (mounted) {
        setState(() {
          _elementos.addAll(respuesta.content);
          _currentPage++;
          _hasNextPage = !respuesta.isLast;
          _isLoadingFirstPage = false;
          _isLoadingMore = false;
        });
      }
    } on UnauthorizedException {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = ErrorTranslator.translate(context, e.message);
          _isLoadingFirstPage = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = l10n.errorLoadingElements(e.toString());
          _isLoadingFirstPage = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _reiniciarBusqueda() {
    FocusScope.of(context).unfocus();
    _loadElementos(isFirstPage: true);
  }

  void _clearSearch() {
    _searchController.clear();
    _reiniciarBusqueda();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _reiniciarBusqueda();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: _buildSearchTextField(context, l10n),
      ),
      body: _buildBody(l10n),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.searchProposeButton),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const PropuestaFormScreen(),
            ),
          ).then((_) => _reiniciarBusqueda());
        },
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FutureBuilder<void>(
            future: _filtrosFuture,
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _tipos.isEmpty) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ));
              }
              if (snapshot.hasError && _tipos.isEmpty) {
                return Center(
                    child: Text(
                        l10n.errorLoadingFilters(snapshot.error.toString()),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.red)));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(l10n.searchExploreType,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  _buildTypeFilterChips(),
                  if (_selectedTypeIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(l10n.searchExploreGenre,
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                  if (_selectedTypeIds.isNotEmpty) _buildGenreFilterChips(),
                ],
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 80.0),
            child: _buildResultadosLista(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildResultadosLista(AppLocalizations l10n) {
    if (_isLoadingFirstPage) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.only(top: 50.0),
        child: CircularProgressIndicator(),
      ));
    }
    if (_loadingError != null) {
      return Center(
          child: Text(_loadingError!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red)));
    }
    if (_elementos.isEmpty) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: Text(l10n.searchEmptyState),
      ));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _elementos.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == _elementos.length) {
          return _isLoadingMore
              ? const Center(
                  child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ))
              : const SizedBox(height: 1);
        }
        final Elemento elemento = _elementos[index];
        return _buildElementoListTile(context, elemento);
      },
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1),
    );
  }

  Widget _buildSearchTextField(BuildContext context, AppLocalizations l10n) {
    final Color iconColor =
        Theme.of(context).colorScheme.onSurface.withAlpha(0x80);
    return TextField(
      controller: _searchController,
      style: Theme.of(context).textTheme.titleMedium,
      decoration: InputDecoration(
        hintText: l10n.searchFieldHint,
        hintStyle: Theme.of(context).textTheme.labelLarge,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(Icons.search, color: iconColor),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: iconColor),
                onPressed: _clearSearch,
              )
            : null,
      ),
      onSubmitted: (String value) {
        _reiniciarBusqueda();
      },
      onChanged: (String value) {
        setState(() {});
      },
    );
  }

  Widget _buildElementoListTile(BuildContext context, Elemento elemento) {
    final Color iconColor =
        Theme.of(context).colorScheme.onSurface.withAlpha(0x80);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) =>
                  ElementoDetailScreen(elementoId: elemento.id),
            ),
          ).then((_) => _reiniciarBusqueda());
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 120,
              height: 75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5.0),
                child: elemento.urlImagen != null &&
                        elemento.urlImagen!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: elemento.urlImagen!,
                        fit: BoxFit.cover,
                        placeholder: (BuildContext context, String url) =>
                            Icon(Icons.downloading, color: iconColor),
                        errorWidget: (BuildContext context, String url,
                                Object error) =>
                            Icon(Icons.image_not_supported, color: iconColor),
                      )
                    : Icon(Icons.movie_filter, color: iconColor, size: 30),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MaybeMarquee(
                    text: elemento.titulo,
                    style: Theme.of(context).textTheme.titleMedium ??
                        const TextStyle(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${elemento.tipo} | ${elemento.generos.join(", ")}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          overflow: TextOverflow.ellipsis,
                        ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),
                  _buildEstadoChip(context, elemento),
                ],
              ),
            ),
          ],
        ),
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
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
      ),
      backgroundColor: chipColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildTypeFilterChips() {
    return Wrap(
      spacing: 8.0,
      children: _tipos.map((Tipo tipo) {
        final bool isSelected = _selectedTypeIds.contains(tipo.id);
        return FilterChip(
          label: Text(ContentTranslator.translateType(context, tipo.nombre)),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedTypeIds.add(tipo.id);
              } else {
                _selectedTypeIds.remove(tipo.id);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildGenreFilterChips() {
    final Set<Genero> visibleGenres = _getVisibleGenres();
    return Wrap(
      spacing: 8.0,
      children: visibleGenres.map((Genero genero) {
        final bool isSelected = _selectedGenreIds.contains(genero.id);
        return FilterChip(
          label: Text(ContentTranslator.translateGenre(context, genero.nombre)),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedGenreIds.add(genero.id);
              } else {
                _selectedGenreIds.remove(genero.id);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Set<Genero> _getVisibleGenres() {
    final Set<Genero> visibleGenres = {};
    for (final Tipo tipo in _tipos) {
      if (_selectedTypeIds.contains(tipo.id)) {
        visibleGenres.addAll(tipo.validGenres);
      }
    }
    return visibleGenres;
  }
}
