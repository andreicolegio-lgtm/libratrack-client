import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../core/services/catalog_service.dart';
import '../../model/catalogo_entrada.dart';
import '../../model/estado_personal.dart'; // Asegúrate de que este import sea correcto
import '../../core/utils/error_translator.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/api_exceptions.dart';
import 'widgets/catalog_entry_card.dart';
import '../../core/widgets/custom_search_bar.dart';
import '../../core/widgets/filter_modal.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen>
    with SingleTickerProviderStateMixin {
  late final CatalogService _catalogService;

  // Controlador manual necesario para cambiar tabs desde la búsqueda
  late TabController _tabController;

  bool _isDataLoaded = false;
  String? _loadingError;

  // Estado de Filtros
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedTypes = [];
  List<String> _selectedGenres = [];
  Timer? _debounce;

  // Variables de Ordenación
  String _sortMode = 'DATE';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _catalogService = context.read<CatalogService>();

    // 6 Tabs: All, Favs, Progress, Pending, Finished, Dropped
    _tabController = TabController(length: 6, vsync: this);

    // Listener para la búsqueda inteligente
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      _loadCatalog();
      _isDataLoaded = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      await _catalogService.fetchCatalog();
      if (mounted) {
        setState(() => _loadingError = null);
      }
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      // La lógica de logout ya debería estar centralizada en AuthService/ApiClient,
      // pero mantenemos el manejo visual del error aquí.
      setState(() {
        _loadingError = ErrorTranslator.translate(context, e.message);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingError = l10n.errorLoadingCatalog(e.toString());
      });
    }
  }

  // --- LÓGICA DE BÚSQUEDA INTELIGENTE ---

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim().toLowerCase();

      // Siempre actualizamos el estado para filtrar la lista visualmente
      setState(() {});

      if (query.isEmpty) {
        return;
      }

      // Lógica de redirección de tab
      final allEntries = _catalogService.entradas;
      final match = allEntries.firstWhere(
        (e) => e.elementoTitulo.toLowerCase().contains(query),
        orElse: () => allEntries.first, // Fallback seguro (no crítico)
      );

      // Si encontramos una coincidencia real
      if (match.elementoTitulo.toLowerCase().contains(query)) {
        final targetIndex = _getTabIndexForState(match);
        // Evitamos saltar si ya estamos ahí o si el target es 'All' (0)
        if (_tabController.index != targetIndex && targetIndex != 0) {
          _tabController.animateTo(targetIndex);
        }
      }
    });
  }

  int _getTabIndexForState(CatalogoEntrada entrada) {
    if (entrada.esFavorito) {
      return 1;
    }

    // Usamos los valores de la API (String) para comparar
    switch (entrada.estadoPersonal) {
      case 'EN_PROGRESO':
        return 2;
      case 'PENDIENTE':
        return 3;
      case 'TERMINADO':
        return 4;
      case 'ABANDONADO':
        return 5;
      default:
        return 0;
    }
  }

  // --- FILTRADO Y ORDENACIÓN ---

  List<CatalogoEntrada> _filterList(List<CatalogoEntrada> source) {
    final query = _searchController.text.trim().toLowerCase();

    return source.where((e) {
      // Filtro Texto
      if (query.isNotEmpty && !e.elementoTitulo.toLowerCase().contains(query)) {
        return false;
      }
      // Filtro Tipo
      if (_selectedTypes.isNotEmpty &&
          !_selectedTypes.contains(e.elementoTipoNombre)) {
        return false;
      }
      // Filtro Género
      if (_selectedGenres.isNotEmpty) {
        final elementGenres = e.elementoGeneros?.toLowerCase() ?? '';
        bool hasMatch = false;
        for (final g in _selectedGenres) {
          if (elementGenres.contains(g.toLowerCase())) {
            hasMatch = true;
            break;
          }
        }
        if (!hasMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<CatalogoEntrada> _sortList(List<CatalogoEntrada> list,
      {bool isAllTab = false}) {
    // 1. Ordenación base (para Tab All: por estado)
    if (isAllTab) {
      final orderMap = {
        'EN_PROGRESO': 1,
        'PENDIENTE': 2,
        'PAUSADO': 3,
        'TERMINADO': 4,
        'ABANDONADO': 5,
      };
      list.sort((a, b) {
        final orderA = orderMap[a.estadoPersonal] ?? 99;
        final orderB = orderMap[b.estadoPersonal] ?? 99;
        return orderA.compareTo(orderB);
      });
    }

    // 2. Ordenación dinámica (Usuario)
    if (_sortMode == 'DATE') {
      list.sort((a, b) {
        final dateA = a.agregadoEn;
        final dateB = b.agregadoEn;
        return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      });
    } else if (_sortMode == 'ALPHA') {
      list.sort((a, b) {
        return _sortAscending
            ? a.elementoTitulo.compareTo(b.elementoTitulo)
            : b.elementoTitulo.compareTo(a.elementoTitulo);
      });
    }

    return list;
  }

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FilterModal(
        selectedTypes: _selectedTypes,
        selectedGenres: _selectedGenres,

        // DESCOMENTADO Y CONECTADO:
        currentSortMode: _sortMode,
        isAscending: _sortAscending,
        onSortChanged: (mode, ascending) {
          // Implementación real en lugar de '...'
          setState(() {
            _sortMode = mode;
            _sortAscending = ascending;
          });
        },

        onApply: (types, genres) {
          setState(() {
            _selectedTypes = types;
            _selectedGenres = genres;
          });
        },
      ),
    );
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final List<Widget> tabs = [
      Tab(text: l10n.adminPanelFilterAll),
      const Tab(text: 'Favorites'),
      Tab(text: l10n.catalogInProgress),
      Tab(text: l10n.catalogPending),
      Tab(text: l10n.catalogFinished),
      Tab(text: l10n.catalogDropped),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Cabecera
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

            // 2. Buscador
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: CustomSearchBar(
                controller: _searchController,
                hintText: 'Buscar en mi catálogo...',
                onFilterPressed: _openFilterModal,
                onChanged: _onSearchChanged,
              ),
            ),

            // 3. Tabs (Con controlador manual)
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: tabs,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.normal),
            ),

            // 4. Contenido
            Expanded(
              child: Consumer<CatalogService>(
                builder: (context, catalogService, child) {
                  if (catalogService.isLoading &&
                      catalogService.entradas.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_loadingError != null) {
                    return _buildErrorState(_loadingError!);
                  }

                  final globalFiltered = _filterList(catalogService.entradas);

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // All
                      _buildCatalogList(
                          _sortList(List.from(globalFiltered), isAllTab: true),
                          0),
                      // Favs
                      _buildCatalogList(
                          _sortList(globalFiltered
                              .where((e) => e.esFavorito)
                              .toList()),
                          1),
                      // In Progress
                      _buildCatalogList(
                          _sortList(globalFiltered
                              .where((e) =>
                                  e.estadoPersonal ==
                                  EstadoPersonal.enProgreso.apiValue)
                              .toList()),
                          2),
                      // Pending
                      _buildCatalogList(
                          _sortList(globalFiltered
                              .where((e) =>
                                  e.estadoPersonal ==
                                  EstadoPersonal.pendiente.apiValue)
                              .toList()),
                          3),
                      // Finished
                      _buildCatalogList(
                          _sortList(globalFiltered
                              .where((e) =>
                                  e.estadoPersonal ==
                                  EstadoPersonal.terminado.apiValue)
                              .toList()),
                          4),
                      // Dropped
                      _buildCatalogList(
                          _sortList(globalFiltered
                              .where((e) =>
                                  e.estadoPersonal ==
                                  EstadoPersonal.abandonado.apiValue)
                              .toList()),
                          5),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadCatalog,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          )
        ],
      ),
    );
  }

  Widget _buildCatalogList(List<CatalogoEntrada> list, int tabIndex) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron elementos.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCatalog,
      child: ListView.separated(
        // Clave única para preservar scroll por pestaña
        key: PageStorageKey('catalog_tab_$tabIndex'),
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          return CatalogEntryCard(
            key: ValueKey(list[i].id),
            entrada: list[i],
            onUpdate: () {},
          );
        },
      ),
    );
  }
}
