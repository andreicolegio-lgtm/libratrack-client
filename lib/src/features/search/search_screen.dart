// lib/src/features/search/search_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/elemento_service.dart';
import 'package:libratrack_client/src/core/services/tipo_service.dart';
import 'package:libratrack_client/src/core/services/genero_service.dart';
import 'package:libratrack_client/src/features/elemento/elemento_detail_screen.dart';
import 'package:libratrack_client/src/features/propuestas/propuesta_form_screen.dart';
import 'package:libratrack_client/src/model/elemento.dart';
import 'package:libratrack_client/src/model/tipo.dart';
import 'package:libratrack_client/src/model/genero.dart';

/// Pantalla para buscar y explorar contenido (Mockup 3)
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // --- Servicios y Estado ---
  final ElementoService _elementoService = ElementoService();
  final TipoService _tipoService = TipoService();
  final GeneroService _generoService = GeneroService();
  
  final TextEditingController _searchController = TextEditingController();
  Future<List<Elemento>>? _elementosFuture;
  
  List<Tipo> _tipos = [];
  List<Genero> _generos = [];
  
  String? _filtroTipoActivo;
  String? _filtroGeneroActivo;

  late Future<void> _consultaFuture;

  @override
  void initState() {
    super.initState();
    _consultaFuture = _loadInitialData();
    _loadElementos();
  }
  
  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _tipoService.getAllTipos(),
        _generoService.getAllGeneros(),
      ]);
      
      if (mounted) {
        setState(() {
          _tipos = results[0] as List<Tipo>;
          _generos = results[1] as List<Genero>;
        });
      }
    } catch (e) {
        debugPrint('Error al cargar datos de consulta: $e'); 
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Conecta la UI con los 3 filtros de la API (RF09)
  void _loadElementos() {
    setState(() {
      _elementosFuture = _elementoService.getElementos(
        searchText: _searchController.text,
        tipoName: _filtroTipoActivo,
        generoName: _filtroGeneroActivo,
      );
    });
  }
  
  void _clearSearch() {
    _searchController.clear();
    _filtroTipoActivo = null; 
    _filtroGeneroActivo = null;
    _loadElementos();
    FocusScope.of(context).unfocus();
  }

  void _handleFiltroTap(String tipoFiltro, String nombre) {
    setState(() {
      if (tipoFiltro == 'tipo') {
        _filtroTipoActivo = (_filtroTipoActivo == nombre) ? null : nombre;
        _filtroGeneroActivo = null; 
      } else if (tipoFiltro == 'genero') {
        _filtroGeneroActivo = (_filtroGeneroActivo == nombre) ? null : nombre;
        _filtroTipoActivo = null; 
      }
    });
    _loadElementos();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface, 
        title: _buildSearchTextField(context),
      ),
      
      body: FutureBuilder<void>(
        future: _consultaFuture,
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError && (_tipos.isEmpty || _generos.isEmpty)) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar filtros: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                ),
              ),
            );
          }
          
          return _buildSearchContent(context);
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Proponer Elemento'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PropuestaFormScreen(),
            ),
          ).then((_) => _loadElementos());
        },
      ),
    );
  }
  
  // --- WIDGETS AUXILIARES ---
  
  Widget _buildSearchTextField(BuildContext context) {
    final Color iconColor = Theme.of(context).colorScheme.onSurface.withAlpha(0x80);
    
    return TextField(
      controller: _searchController,
      style: Theme.of(context).textTheme.titleMedium,
      decoration: InputDecoration(
        hintText: 'Buscar por título...',
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
      onSubmitted: (value) {
        _loadElementos();
      },
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildSearchContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // --- Explorar por Tipo (RF09) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Explorar por Tipo', style: Theme.of(context).textTheme.titleLarge),
          ),
          _buildFiltroChips(
            context,
            data: _tipos.map((t) => t.nombre).toList(),
            tipoFiltro: 'tipo',
            filtroActivo: _filtroTipoActivo,
          ),
          
          // --- Explorar por Género (RF09) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Explorar por Género', style: Theme.of(context).textTheme.titleLarge),
          ),
          _buildFiltroChips(
            context,
            data: _generos.map((g) => g.nombre).toList(),
            tipoFiltro: 'genero',
            filtroActivo: _filtroGeneroActivo,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(),
          ),
          
          // --- Lista de Resultados (Elementos) ---
          Padding(
            padding: const EdgeInsets.only(bottom: 80.0),
            child: FutureBuilder<List<Elemento>>(
              future: _elementosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error en la búsqueda: ${snapshot.error}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red)));
                }
                final elementos = snapshot.data ?? [];
                
                if (elementos.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: Text('No se encontraron elementos con el filtro aplicado.'),
                  ));
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: elementos.length,
                  itemBuilder: (context, index) {
                    final elemento = elementos[index];
                    return _buildElementoListTile(context, elemento);
                  },
                  separatorBuilder: (context, index) => const Divider(height: 1),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChips(
    BuildContext context,
    {
      required List<String> data,
      required String tipoFiltro,
      required String? filtroActivo,
    }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: data.map((nombre) {
          final bool isSelected = nombre == filtroActivo;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(nombre),
              backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
              labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.grey[400],
              ),
              onPressed: () => _handleFiltroTap(tipoFiltro, nombre),
            ),
          );
        }).toList(),
      ),
    );
  }

  // REFACTORIZADO: Resultado de búsqueda más inmersivo (similar a miniatura de YouTube)
  Widget _buildElementoListTile(BuildContext context, Elemento elemento) {
    final Color iconColor = Theme.of(context).colorScheme.onSurface.withAlpha(0x80);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
            Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ElementoDetailScreen(elementoId: elemento.id),
            ),
          ).then((_) => _loadElementos());
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Imagen de Portada (Miniatura)
            Container(
              width: 120, 
              height: 75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5.0),
                child: elemento.imagenPortadaUrl != null && elemento.imagenPortadaUrl!.isNotEmpty
                    ? Image.network(
                        elemento.imagenPortadaUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Icon(Icons.image_not_supported, color: iconColor),
                      )
                    : Icon(Icons.movie_filter, color: iconColor, size: 30),
              ),
            ),
            const SizedBox(width: 12),
            
            // 2. Título y Subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título principal
                  Text(
                    elemento.titulo,
                    style: Theme.of(context).textTheme.titleMedium,
                    // --- CORRECCIÓN (Punto 7) ---
                    // Fuerza el título a una sola línea y lo corta con "..."
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Subtítulo con tipo y estado
                  Text(
                    '${elemento.tipo} | ${elemento.estadoContenido}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            // 3. Chip de estado (OFICIAL/COMUNITARIO)
            _buildEstadoChip(context, elemento.estadoContenido),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEstadoChip(BuildContext context, String estado) {
    final bool isOficial = estado == "OFICIAL"; 
    
    return Chip(
      label: Text(
        isOficial ? "OFICIAL" : "COMUNITARIO",
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isOficial ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}