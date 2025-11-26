import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/elemento_service.dart';
import '../../core/services/genero_service.dart';
import '../../core/services/tipo_service.dart';
import '../../core/utils/api_exceptions.dart';
import '../../core/utils/content_translator.dart';
import '../../core/utils/error_translator.dart';
import '../../core/widgets/maybe_marquee.dart';
import '../../model/elemento.dart';
import '../../model/genero.dart';
import '../../model/paginated_response.dart';
import '../../model/tipo.dart';
import '../elemento/elemento_detail_screen.dart';
import '../propuestas/propuesta_form_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Servicios
  late final ElementoService _elementoService;
  late final TipoService _tipoService;
  late final GeneroService _generoService;
  late final AuthService _authService;

  // Controladores
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  // Estado de Datos
  List<Tipo> _tipos = [];
  final List<Elemento> _elementos = [];
  Future<void>? _filtrosFuture;

  // Estado de Paginación
  int _currentPage = 0;
  bool _hasNextPage = true;
  bool _isLoadingFirstPage = true;
  bool _isLoadingMore = false;
  String? _loadingError;

  // Estado de Filtros
  final Set<int> _selectedTypeIds = HashSet<int>();
  final Set<int> _selectedGenreIds = HashSet<int>();

  // Flag de inicialización
  bool _isDataLoaded = false;

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

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- Carga de Datos ---

  Future<void> _loadInitialData() async {
    final l10n = AppLocalizations.of(context);
    try {
      // Carga paralela de metadatos
      final results = await Future.wait([
        _tipoService.fetchTipos(l10n.errorLoadingFilters('')),
        _generoService.fetchGeneros(),
      ]);

      if (mounted) {
        setState(() {
          _tipos = results[0] as List<Tipo>;
          // Los géneros se cargan en el servicio, no necesitamos guardarlos localmente aquí
          // ya que los filtraremos dinámicamente según los tipos seleccionados.
        });
      }
    } catch (e) {
      _handleError(e, l10n);
    }
  }

  Future<void> _loadElementos({bool isFirstPage = false}) async {
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

    // Preparar filtros para la API
    // Convertimos IDs a nombres porque así lo espera el backend actualmente
    final List<String> typeNames = _tipos
        .where((t) => _selectedTypeIds.contains(t.id))
        .map((t) => t.nombre)
        .toList();

    // Solo enviamos géneros que pertenezcan a los tipos seleccionados (o todos si no hay tipo)
    final Set<Genero> visibleGenres = _getVisibleGenres();
    final List<String> genreNames = visibleGenres
        .where((g) => _selectedGenreIds.contains(g.id))
        .map((g) => g.nombre)
        .toList();

    try {
      final PaginatedResponse<Elemento> response =
          await _elementoService.searchElementos(
        query: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        types: typeNames.isEmpty ? null : typeNames,
        genres: genreNames.isEmpty ? null : genreNames,
        page: _currentPage,
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
          // Si falla la primera página, mostramos error en pantalla.
          // Si falla la paginación, podríamos mostrar un snackbar o reintentar silenciosamente.
          if (isFirstPage) {
            _loadingError = _getErrorMessage(e, l10n);
          }
        });
      }
    }
  }

  // --- Lógica de UI ---

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

  void _clearSearch() {
    _searchController.clear();
    _loadElementos(isFirstPage: true);
  }

  void _handleError(Object e, AppLocalizations l10n) {
    if (e is UnauthorizedException) {
      _authService.logout(); // El AuthWrapper redirigirá
    } else {
      // Solo logueamos, la UI mostrará el estado de error si es crítico
      debugPrint('Error en búsqueda: $e');
    }
  }

  String _getErrorMessage(Object e, AppLocalizations l10n) {
    if (e is ApiException) {
      return ErrorTranslator.translate(context, e.message);
    }
    return l10n.errorUnexpected(e.toString());
  }

  /// Obtiene los géneros válidos basados en los Tipos seleccionados.
  Set<Genero> _getVisibleGenres() {
    // Si no hay tipos seleccionados, ¿mostramos todos o ninguno?
    // Asumiremos ninguno para guiar al usuario a seleccionar primero un Tipo.
    if (_selectedTypeIds.isEmpty) {
      return {};
    }

    final Set<Genero> visibleGenres = {};
    for (final Tipo tipo in _tipos) {
      if (_selectedTypeIds.contains(tipo.id)) {
        visibleGenres.addAll(tipo.validGenres);
      }
    }
    return visibleGenres;
  }

  // --- Modales de Filtro ---

  void _openTypesModal() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MultiSelectModal(
        title: l10n.searchExploreType,
        items: _tipos,
        selectedIds: Set.from(_selectedTypeIds),
        labelBuilder: (item) =>
            ContentTranslator.translateType(context, (item as Tipo).nombre),
        idExtractor: (item) => (item as Tipo).id,
        onApply: (newSelection) {
          setState(() {
            _selectedTypeIds.clear();
            _selectedTypeIds.addAll(newSelection);

            // Limpiar géneros inválidos si cambiamos de tipo
            final validGenres = _getVisibleGenres();
            _selectedGenreIds
                .removeWhere((id) => !validGenres.any((g) => g.id == id));
          });
          _loadElementos(isFirstPage: true);
        },
      ),
    );
  }

  void _openGenresModal() {
    final l10n = AppLocalizations.of(context);
    final visibleGenres = _getVisibleGenres();

    if (visibleGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                l10n.validationTypeRequired)), // "Selecciona un tipo primero"
      );
      return;
    }

    final sortedGenres = visibleGenres.toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MultiSelectModal(
        title: l10n.searchExploreGenre,
        items: sortedGenres,
        selectedIds: Set.from(_selectedGenreIds),
        labelBuilder: (item) =>
            ContentTranslator.translateGenre(context, (item as Genero).nombre),
        idExtractor: (item) => (item as Genero).id,
        onApply: (newSelection) {
          setState(() {
            _selectedGenreIds.clear();
            _selectedGenreIds.addAll(newSelection);
          });
          _loadElementos(isFirstPage: true);
        },
      ),
    );
  }

  // --- Construcción de UI ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(l10n),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(l10n),
          const Divider(height: 1),
          Expanded(
            child: _buildContent(l10n),
          ),
        ],
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

  Widget _buildSearchBar(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: l10n.searchFieldHint,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(128),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _loadElementos(isFirstPage: true),
    );
  }

  Widget _buildFilterBar(AppLocalizations l10n) {
    return FutureBuilder<void>(
      future: _filtrosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _tipos.isEmpty) {
          return const LinearProgressIndicator(minHeight: 2);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: _FilterButton(
                  label: l10n.adminFormTypeLabel.split('(')[0].trim(), // "Tipo"
                  count: _selectedTypeIds.length,
                  icon: Icons.category_outlined,
                  onPressed: _openTypesModal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilterButton(
                  label: l10n.adminFormGenresLabel
                      .split('(')[0]
                      .trim(), // "Géneros"
                  count: _selectedGenreIds.length,
                  icon: Icons.filter_list,
                  onPressed: _openGenresModal,
                  // Deshabilitar si no hay tipos seleccionados (opcional, depende de UX)
                  isDisabled: _selectedTypeIds.isEmpty,
                ),
              ),
            ],
          ),
        );
      },
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
      padding: const EdgeInsets.only(top: 8, bottom: 80), // Espacio para FAB
      itemCount: _elementos.length + 1,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        if (index == _elementos.length) {
          return _isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()))
              : const SizedBox(height: 40);
        }

        return _ElementoListTile(elemento: _elementos[index]);
      },
    );
  }
}

// --- Widgets Privados ---

class _ElementoListTile extends StatelessWidget {
  final Elemento elemento;

  const _ElementoListTile({required this.elemento});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ElementoDetailScreen(elementoId: elemento.id)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 90,
                child: elemento.urlImagen != null
                    ? CachedNetworkImage(
                        imageUrl: elemento.urlImagen!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: theme.colorScheme.surfaceContainerHighest),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.image_not_supported),
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.movie, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MaybeMarquee(
                    text: elemento.titulo,
                    style: theme.textTheme.titleMedium!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    elemento.tipo,
                    style: theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    elemento.generos.take(3).join(', '),
                    style: theme.textTheme.bodySmall!
                        .copyWith(color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusChip(context, elemento),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, Elemento elemento) {
    final bool isOficial = elemento.estadoContenido == 'OFICIAL';
    if (!isOficial) {
      return const SizedBox
          .shrink(); // Solo mostramos si es Oficial para no saturar
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'OFICIAL', // O usar l10n
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSecondaryContainer),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onPressed;
  final IconData icon;
  final bool isDisabled;

  const _FilterButton({
    required this.label,
    required this.count,
    required this.onPressed,
    required this.icon,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = count > 0;

    return OutlinedButton(
      onPressed: isDisabled ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isActive ? scheme.primaryContainer : null,
        foregroundColor:
            isActive ? scheme.onPrimaryContainer : scheme.onSurface,
        side: BorderSide(
          color: isActive ? scheme.primary : scheme.outline.withAlpha(100),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
          if (isActive) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 10,
              backgroundColor: scheme.primary,
              child: Text(
                count.toString(),
                style: TextStyle(
                    fontSize: 10,
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.bold),
              ),
            )
          ]
        ],
      ),
    );
  }
}

class _MultiSelectModal extends StatefulWidget {
  final String title;
  final List<dynamic> items;
  final Set<int> selectedIds;
  final String Function(dynamic) labelBuilder;
  final int Function(dynamic) idExtractor;
  final Function(Set<int>) onApply;

  const _MultiSelectModal({
    required this.title,
    required this.items,
    required this.selectedIds,
    required this.labelBuilder,
    required this.idExtractor,
    required this.onApply,
  });

  @override
  State<_MultiSelectModal> createState() => _MultiSelectModalState();
}

class _MultiSelectModalState extends State<_MultiSelectModal> {
  late Set<int> _tempSelectedIds;

  @override
  void initState() {
    super.initState();
    _tempSelectedIds = Set.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                onPressed: () => setState(() => _tempSelectedIds.clear()),
                child: const Text('Limpiar'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // List
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final id = widget.idExtractor(item);
              final isSelected = _tempSelectedIds.contains(id);

              return CheckboxListTile(
                title: Text(widget.labelBuilder(item)),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _tempSelectedIds.add(id);
                    } else {
                      _tempSelectedIds.remove(id);
                    }
                  });
                },
              );
            },
          ),
        ),

        // Footer Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(_tempSelectedIds);
                Navigator.pop(context);
              },
              child: const Text('Aplicar Filtros'),
            ),
          ),
        ),
      ],
    );
  }
}
