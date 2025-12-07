import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/custom_search_bar.dart';
import '../../core/widgets/filter_modal.dart';
import '../../core/widgets/maybe_marquee.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/moderacion_service.dart'; // Usamos el servicio correcto
import '../../model/elemento.dart';
import '../../model/paginated_response.dart';
import '../elemento/elemento_detail_screen.dart';

class CreatedElementsScreen extends StatefulWidget {
  const CreatedElementsScreen({super.key});

  @override
  State<CreatedElementsScreen> createState() => _CreatedElementsScreenState();
}

class _CreatedElementsScreenState extends State<CreatedElementsScreen> {
  late final ModeracionService _moderacionService;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<Elemento> _elementos = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasNextPage = true;
  int _currentPage = 0;
  String? _error;
  Timer? _debounce;

  // Filtros UI
  String _sortMode = 'DATE';
  bool _sortAscending = false;
  List<String> _selectedTypes = [];
  List<String> _selectedGenres = [];

  @override
  void initState() {
    super.initState();
    _moderacionService = context.read<ModeracionService>();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _loadData(firstPage: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadData();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadData(firstPage: true);
    });
  }

  Future<void> _loadData({bool firstPage = false}) async {
    if (firstPage) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _elementos.clear();
        _hasNextPage = true;
        _error = null;
      });
    } else {
      if (_isLoadingMore || !_hasNextPage) {
        return;
      }
      setState(() => _isLoadingMore = true);
    }

    final String? searchQuery =
        _searchController.text.isEmpty ? null : _searchController.text.trim();

    try {
      // Llamada al nuevo endpoint en ModeracionService
      final PaginatedResponse<Elemento> response =
          await _moderacionService.getElementosCreados(
        page: _currentPage,
        search: searchQuery,
        types: _selectedTypes,
        genres: _selectedGenres,
        sort: _sortMode,
        asc: _sortAscending,
      );

      if (mounted) {
        setState(() {
          _elementos.addAll(response.content);
          _currentPage++;
          _hasNextPage = !response.isLast;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _error = e.toString();
        });
      }
    }
  }

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterModal(
        currentSortMode: _sortMode,
        isAscending: _sortAscending,
        selectedTypes: _selectedTypes,
        selectedGenres: _selectedGenres,
        onSortChanged: (mode, ascending) {
          setState(() {
            _sortMode = mode;
            _sortAscending = ascending;
          });
          // Opcional: Recargar al cambiar orden inmediatamente
          _loadData(firstPage: true);
        },
        onApply: (types, genres) {
          setState(() {
            _selectedTypes = types;
            _selectedGenres = genres;
            _loadData(firstPage: true);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Creaciones'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CustomSearchBar(
              controller: _searchController,
              hintText: 'Buscar por título...',
              onFilterPressed: _openFilterModal,
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: SafeArea(
        // FIX: Eliminado Expanded para evitar crash "Incorrect use of ParentDataWidget"
        // ListView ya ocupa el espacio disponible.
        child: _buildList(l10n),
      ),
    );
  }

  Widget _buildList(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_elementos.isEmpty) {
      return const Center(child: Text('No has creado elementos aún.'));
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
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

        return _HistoryCard(
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

class _HistoryCard extends StatelessWidget {
  final Elemento elemento;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.elemento,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOficial = elemento.estadoContenido == 'OFICIAL';
    // Color base según estado (Azul oficial, Naranja comunitario)
    final statusColor = isOficial ? Colors.blueAccent : Colors.orange;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // IMAGEN (Izquierda - Ratio 2:3)
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

              // CONTENIDO (Derecha)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. BARRA DE TÍTULO Y TAG (Punto 2)
                    Container(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          // Título (Marquee)
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
                          // Tag de Estado (Punto 1 - Alineado derecha)
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

                    // 2. CUERPO DE DATOS (Punto 3)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tipo y Género con Marquee y Color Primario
                            SizedBox(
                              height: 20, // Altura fija para el deslizamiento
                              child: MaybeMarquee(
                                text:
                                    "${elemento.tipo} • ${elemento.generos.join(', ')}",
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: theme.colorScheme
                                      .primary, // Color Azul/Primario
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            const Spacer(),

                            // 3. AUTOR (Punto 4 - Derecha y Destacado)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Created by:',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: Colors.grey, fontSize: 10),
                                  ),
                                  Text(
                                    elemento.autorNombre ?? 'Unknown',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme
                                          .primary, // Color destacado
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  if (elemento.autorEmail != null)
                                    Text(
                                      '(${elemento.autorEmail})',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              fontSize: 10, color: Colors.grey),
                                    ),
                                ],
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
