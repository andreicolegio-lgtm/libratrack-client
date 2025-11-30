import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/custom_search_bar.dart';
import '../../core/widgets/filter_modal.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/admin_service.dart';
import '../../model/elemento.dart';
import '../../model/paginated_response.dart';
import '../elemento/elemento_detail_screen.dart';

class CreatedElementsScreen extends StatefulWidget {
  const CreatedElementsScreen({super.key});

  @override
  State<CreatedElementsScreen> createState() => _CreatedElementsScreenState();
}

class _CreatedElementsScreenState extends State<CreatedElementsScreen> {
  late final AdminService _adminService;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<Elemento> _elementos = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasNextPage = true;
  int _currentPage = 0;
  String? _error;
  Timer? _debounce;

  // Estado de Filtros (Aunque el backend aún no filtra por esto, lo preparamos en UI)
  String _sortMode = 'DATE';
  bool _sortAscending = true;
  List<String> _selectedTypes = [];
  List<String> _selectedGenres = [];

  @override
  void initState() {
    super.initState();
    _adminService = context.read<AdminService>();
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
      final PaginatedResponse<Elemento> response =
          await _adminService.getMisElementosCreados(
        page: _currentPage,
        search: searchQuery,
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

  void _goToDetail(Elemento elemento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ElementoDetailScreen(elementoId: elemento.id),
        settings: const RouteSettings(name: 'ElementoDetailScreen'),
      ),
    );
  }

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Importante para que el modal crezca
      builder: (context) => FilterModal(
        // Pasar parámetros de ordenamiento si FilterModal los soporta (Grupo 1)
        currentSortMode: _sortMode,
        isAscending: _sortAscending,
        onSortChanged: (mode, ascending) {
          setState(() {
            _sortMode = mode;
            _sortAscending = ascending;
            _loadData(firstPage: true);
          });
        },

        selectedTypes: _selectedTypes,
        selectedGenres: _selectedGenres,

        // CORRECCIÓN: El callback recibe dos listas tipadas, no un mapa dinámico
        onApply: (types, genres) {
          setState(() {
            _selectedTypes = types;
            _selectedGenres = genres;
            // Recargar datos con los nuevos filtros
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de Búsqueda con padding
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomSearchBar(
                controller: _searchController,
                onFilterPressed: _openFilterModal,
                onChanged: _onSearchChanged, // Trigger al limpiar
              ),
            ),

            // Lista de Resultados
            Expanded(
              child: _buildList(l10n),
            ),
          ],
        ),
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _elementos.length + 1,
      itemBuilder: (context, index) {
        if (index == _elementos.length) {
          return _isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()))
              : const SizedBox(height: 40);
        }

        final elemento = _elementos[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: elemento.urlImagen != null
                ? Image.network(
                    elemento.urlImagen!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image_not_supported, size: 50),
            title: Text(elemento.titulo,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(elemento.tipo),
            onTap: () => _goToDetail(elemento),
          ),
        );
      },
    );
  }
}
