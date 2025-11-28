import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/admin_service.dart';
import '../../model/elemento.dart';
import '../../model/paginated_response.dart';
import '../elemento/elemento_detail_screen.dart'; // Para navegar al detalle

class AdminCreatedElementsScreen extends StatefulWidget {
  const AdminCreatedElementsScreen({super.key});

  @override
  State<AdminCreatedElementsScreen> createState() =>
      _AdminCreatedElementsScreenState();
}

class _AdminCreatedElementsScreenState
    extends State<AdminCreatedElementsScreen> {
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

    try {
      // NOTA: Asegúrate de añadir el método getMisElementosCreados en tu AdminService
      // que llame al endpoint correspondiente del backend (ej. /admin/my-elements)
      final PaginatedResponse<Elemento> response =
          await _adminService.getMisElementosCreados(
        page: _currentPage,
        search: _searchController.text.isEmpty ? null : _searchController.text,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Creaciones'), // Usar l10n idealmente
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de Búsqueda
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar en mis elementos...', // Usar l10n
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, child) {
                      if (value.text.isNotEmpty) {
                        return IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
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
