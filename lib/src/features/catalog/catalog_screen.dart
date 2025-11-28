import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../core/services/catalog_service.dart';
import '../../core/services/auth_service.dart';
import '../../model/catalogo_entrada.dart';
import '../../model/estado_personal.dart';
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
  late final AuthService _authService;
  late TabController _tabController;

  bool _isDataLoaded = false;
  String? _loadingError;

  // Estado de Filtros
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedTypes = [];
  List<String> _selectedGenres = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _catalogService = context.read<CatalogService>();
    _authService = context.read<AuthService>();

    // 6 Pestañas: All, Favorites, In Progress, Pending, Finished, Dropped
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
      if (e is UnauthorizedException) {
        _authService.logout();
      } else {
        setState(() {
          _loadingError = ErrorTranslator.translate(context, e.message);
        });
      }
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

    // Pequeño debounce para no saltar de tab mientras escribes rápido
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) {
        setState(() {}); // Solo repintar para quitar filtros de texto
        return;
      }

      // 1. Buscamos la mejor coincidencia en todo el catálogo
      final allEntries = _catalogService.entradas;
      final match = allEntries.firstWhere(
        (e) => e.elementoTitulo.toLowerCase().contains(query),
        orElse: () => allEntries.first, // Fallback (no crítico)
      );

      // 2. Si hay coincidencia válida y contiene el texto buscado
      if (match.elementoTitulo.toLowerCase().contains(query)) {
        // 3. Obtenemos la Tab correspondiente a su estado
        final targetIndex = _getTabIndexForState(match);

        // 4. Redirigimos si no estamos en 'All' (0) o en la tab correcta
        // NOTA: Nunca forzamos ir a 'All' (0) automáticamente.
        if (_tabController.index != targetIndex && targetIndex != 0) {
          _tabController.animateTo(targetIndex);
        }
      }

      setState(() {}); // Actualizar listas filtradas
    });
  }

  int _getTabIndexForState(CatalogoEntrada entrada) {
    if (entrada.esFavorito) {
      return 1; // Prioridad a Favs si se quiere, o por estado
    }

    // Mapeo Estado -> Índice de Tab
    // Tabs: [0:All, 1:Favs, 2:Progress, 3:Pending, 4:Finished, 5:Dropped]
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
        return 0; // Otros (Pausado) van a All
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
      // Filtro Género (busca si el string de géneros contiene alguno de los seleccionados)
      if (_selectedGenres.isNotEmpty) {
        // e.elementoGeneros es un String "Acción, Aventura".
        // Verificamos si CUALQUIERA de los seleccionados está presente.
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

  List<CatalogoEntrada> _sortForAllTab(List<CatalogoEntrada> list) {
    // Orden personalizado para la tab "All" (Punto 5)
    // Orden: En Progreso > Pendiente > Pausado > Terminado > Abandonado
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
    return list;
  }

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FilterModal(
        selectedTypes: _selectedTypes,
        selectedGenres: _selectedGenres,
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

    // Nombres de las Tabs
    final List<Widget> tabs = [
      Tab(text: l10n.adminPanelFilterAll),
      const Tab(text: 'Favorites'), // Punto 1: "Favorite" (o Favorites)
      Tab(text: l10n.catalogInProgress),
      Tab(text: l10n.catalogPending),
      Tab(text: l10n.catalogFinished),
      Tab(text: l10n.catalogDropped),
    ];

    return Scaffold(
      // SafeArea para proteger bordes
      body: SafeArea(
        child: Column(
          children: [
            // 1. Cabecera Personalizada
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/isotipo_libratrack.svg',
                    height: 32,
                    // Si el SVG tiene color fijo, quitar colorFilter. Si es negro, colorear.
                    // colorFilter: ColorFilter.mode(theme.primaryColor, BlendMode.srcIn),
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

            // 2. Buscador y Filtros
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: CustomSearchBar(
                controller: _searchController,
                hintText: 'Buscar en mi catálogo...',
                onFilterPressed: _openFilterModal,
                onChanged: _onSearchChanged, // Trigger búsqueda al limpiar
              ),
            ),

            // 3. Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: tabs,
              dividerColor: Colors.transparent,
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

                  // Filtramos globalmente primero (Búsqueda + Filtros Modal)
                  final globalFiltered = _filterList(catalogService.entradas);

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 0: All (Ordenado por estado)
                      _buildCatalogList(
                          _sortForAllTab(List.from(globalFiltered))),

                      // Tab 1: Favorites
                      _buildCatalogList(
                          globalFiltered.where((e) => e.esFavorito).toList()),

                      // Tab 2: In Progress
                      _buildCatalogList(globalFiltered
                          .where((e) =>
                              e.estadoPersonal ==
                              EstadoPersonal.enProgreso.apiValue)
                          .toList()),

                      // Tab 3: Pending
                      _buildCatalogList(globalFiltered
                          .where((e) =>
                              e.estadoPersonal ==
                              EstadoPersonal.pendiente.apiValue)
                          .toList()),

                      // Tab 4: Finished
                      _buildCatalogList(globalFiltered
                          .where((e) =>
                              e.estadoPersonal ==
                              EstadoPersonal.terminado.apiValue)
                          .toList()),

                      // Tab 5: Dropped
                      _buildCatalogList(globalFiltered
                          .where((e) =>
                              e.estadoPersonal ==
                              EstadoPersonal.abandonado.apiValue)
                          .toList()),
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

  Widget _buildCatalogList(List<CatalogoEntrada> list) {
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
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          return CatalogEntryCard(
            key: ValueKey(list[i].id),
            entrada: list[i],
            onUpdate: () {}, // El provider actualiza auto, callback opcional
          );
        },
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
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
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
}
