import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/elemento_service.dart';
import '../../core/utils/api_exceptions.dart';
import '../../core/utils/error_translator.dart';
import '../../core/widgets/maybe_marquee.dart';
import '../../core/widgets/custom_search_bar.dart';
import '../../core/widgets/filter_modal.dart';
import '../../model/elemento.dart';
import '../../model/paginated_response.dart';
import '../elemento/elemento_detail_screen.dart';
import '../propuestas/propuesta_form_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final ElementoService _elementoService;
  late final AuthService _authService;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  final List<Elemento> _elementos = [];

  int _currentPage = 0;
  bool _hasNextPage = true;
  bool _isLoadingFirstPage = true;
  bool _isLoadingMore = false;
  String? _loadingError;

  // Flag para controlar la inicialización segura
  bool _isInitialized = false;

  List<String> _selectedTypes = [];
  List<String> _selectedGenres = [];
  String _sortMode = 'DATE';
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    _elementoService = context.read<ElementoService>();
    _authService = context.read<AuthService>();
    _scrollController.addListener(_onScroll);

    // ERROR CORREGIDO: No llamamos a _loadElementos aquí porque usa AppLocalizations
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Aquí es seguro usar AppLocalizations.of(context)
    if (!_isInitialized) {
      _loadElementos(isFirstPage: true);
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadElementos({bool isFirstPage = false}) async {
    // AppLocalizations necesita el contexto listo
    final l10n = AppLocalizations.of(context);

    if (isFirstPage) {
      setState(() {
        _isLoadingFirstPage = true;
        _currentPage = 0;
        _elementos.clear();
        _hasNextPage = true;
        _loadingError = null;
      });
    } else {
      if (_isLoadingMore || !_hasNextPage) {
        return;
      }
      setState(() => _isLoadingMore = true);
    }

    try {
      final PaginatedResponse<Elemento> response =
          await _elementoService.searchElementos(
        query: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        types: _selectedTypes.isEmpty ? null : _selectedTypes,
        genres: _selectedGenres.isEmpty ? null : _selectedGenres,
        page: _currentPage,
        sortMode: _sortMode,
        isAscending: _isAscending,
      );

      if (mounted) {
        setState(() {
          _elementos.addAll(response.content);
          _currentPage++;
          _hasNextPage = !response.isLast;
          _isLoadingFirstPage = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFirstPage = false;
          _isLoadingMore = false;
          if (isFirstPage) {
            _loadingError = _getErrorMessage(e, l10n);
          }
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadElementos();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadElementos(isFirstPage: true);
    });
  }

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterModal(
        selectedTypes: _selectedTypes,
        selectedGenres: _selectedGenres,
        currentSortMode: _sortMode,
        isAscending: _isAscending,
        onSortChanged: (mode, ascending) {
          setState(() {
            _sortMode = mode;
            _isAscending = ascending;
          });
          _loadElementos(isFirstPage: true);
        },
        onApply: (types, genres) {
          setState(() {
            _selectedTypes = types;
            _selectedGenres = genres;
          });
          _loadElementos(isFirstPage: true);
        },
      ),
    );
  }

  String _getErrorMessage(Object e, AppLocalizations l10n) {
    if (e is ApiException) {
      if (e is UnauthorizedException) {
        _authService.logout();
      }
      return ErrorTranslator.translate(context, e.message);
    }
    return l10n.errorUnexpected(e.toString());
  }

  Future<void> _handleRefresh() async {
    return _loadElementos(isFirstPage: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. CABECERA MARCA
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/isotipo_libratrack.svg',
                    height: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'LibraTrack',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // 2. BARRA BÚSQUEDA
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: CustomSearchBar(
                controller: _searchController,
                hintText: l10n.searchFieldHint,
                onFilterPressed: _openFilterModal,
                onChanged: _onSearchChanged,
              ),
            ),

            const SizedBox(height: 12),

            // 3. CONTENIDO
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: _buildContent(l10n),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PropuestaFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.searchProposeButton),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_isLoadingFirstPage) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadingError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_loadingError!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadElementos(isFirstPage: true),
              child: const Text('Reintentar'),
            )
          ],
        ),
      );
    }

    if (_elementos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(l10n.searchEmptyState,
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 80),
      itemCount: _elementos.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _elementos.length) {
          return _isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()))
              : const SizedBox(height: 40);
        }

        return _SearchCard(
          elemento: _elementos[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ElementoDetailScreen(elementoId: _elementos[index].id),
                settings: const RouteSettings(name: 'ElementoDetailScreen'),
              ),
            );
          },
        );
      },
    );
  }
}

class _SearchCard extends StatelessWidget {
  final Elemento elemento;
  final VoidCallback onTap;

  const _SearchCard({
    required this.elemento,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOficial = elemento.estadoContenido == 'OFICIAL';
    final statusColor = isOficial ? Colors.blueAccent : Colors.orange;

    final String availability = elemento.estadoPublicacion ?? 'Unknown';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // IMAGEN
              SizedBox(
                width: 100,
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: elemento.urlImagen != null
                      ? CachedNetworkImage(
                          imageUrl: elemento.urlImagen!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              color: theme.colorScheme.surfaceContainerHighest),
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.grey),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image)),
                ),
              ),

              // CONTENIDO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CABECERA: Título + Tag Estado
                    Container(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 22,
                              child: MaybeMarquee(
                                text: elemento.titulo,
                                style: theme.textTheme.titleMedium!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isOficial ? 'OFICIAL' : 'COMUNITARIO',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // CUERPO
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 20,
                              child: MaybeMarquee(
                                text:
                                    "${elemento.tipo} • ${elemento.generos.join(', ')}",
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            const Spacer(),

                            // PIE: Tag Disponibilidad
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3), // Un poco más ancho
                                decoration: BoxDecoration(
                                  // CAMBIO DE COLOR: Usamos un tono morado/índigo para diferenciar
                                  color: Colors.deepPurple.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.deepPurple.shade200),
                                ),
                                child: Text(
                                  availability,
                                  style: TextStyle(
                                    color: Colors.deepPurple
                                        .shade700, // Texto oscuro para contraste
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
