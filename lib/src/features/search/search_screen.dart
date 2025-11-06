// lib/src/features/search/search_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/elemento_service.dart';
import 'package:libratrack_client/src/core/services/tipo_service.dart'; // NUEVO
import 'package:libratrack_client/src/core/services/genero_service.dart'; // NUEVO
import 'package:libratrack_client/src/features/elemento/elemento_detail_screen.dart';
import 'package:libratrack_client/src/features/propuestas/propuesta_form_screen.dart';
import 'package:libratrack_client/src/model/elemento.dart';
import 'package:libratrack_client/src/model/tipo.dart'; // NUEVO
import 'package:libratrack_client/src/model/genero.dart'; // NUEVO

/// Pantalla para buscar y explorar contenido (Mockup 3).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // --- Servicios ---
  final ElementoService _elementoService = ElementoService();
  final TipoService _tipoService = TipoService(); // NUEVO
  final GeneroService _generoService = GeneroService(); // NUEVO
  
  // --- Estado de la Interfaz ---
  final TextEditingController _searchController = TextEditingController();
  Future<List<Elemento>>? _elementosFuture;
  
  // --- NUEVO: Estado de Filtros y Datos de Consulta ---
  // Datos cargados para los botones de exploración
  List<Tipo> _tipos = [];
  List<Genero> _generos = [];
  
  // El filtro activo. Usamos String? para permitir que el filtro se anule.
  String? _filtroTipoActivo;
  String? _filtroGeneroActivo;

  // NUEVO: Future que carga los tipos y géneros en la inicialización
  late Future<void> _consultaFuture;

  @override
  void initState() {
    super.initState();
    // 1. Inicia la carga de datos de consulta y elementos en paralelo
    _consultaFuture = _loadInitialData();
    _loadElementos(); // Inicia la primera carga de elementos
  }
  
  /// NUEVO: Carga Tipos y Géneros en paralelo
  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _tipoService.getAllTipos(),
        _generoService.getAllGeneros(),
      ]);
      
      if (mounted) {
        setState(() {
          // Asigna los resultados
          _tipos = results[0] as List<Tipo>;
          _generos = results[1] as List<Genero>;
        });
      }
    } catch (e) {
      // Manejamos el error en el cuerpo principal si falla la consulta
      if (mounted) {
        // En una app real, mostraríamos un error persistente aquí.
        debugPrint('Error al cargar datos de consulta: $e'); 
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Modificado para aplicar filtros activos
  void _loadElementos() {
    setState(() {
      // ¡CONEXIÓN DE FILTROS! Ahora pasamos los 3 parámetros de filtro a la API.
      _elementosFuture = _elementoService.getElementos(
        searchText: _searchController.text,
        tipoName: _filtroTipoActivo,     // NUEVO
        generoName: _filtroGeneroActivo, // NUEVO
      );
    });
  }
  
  void _clearSearch() {
    _searchController.clear();
    // NUEVO: Limpia los filtros activos al borrar la búsqueda
    _filtroTipoActivo = null; 
    _filtroGeneroActivo = null;
    _loadElementos();
    FocusScope.of(context).unfocus();
  }

  /// NUEVO: Maneja el tap en un botón de filtro (Tipo o Género)
  void _handleFiltroTap(String tipoFiltro, String nombre) {
    setState(() {
      if (tipoFiltro == 'tipo') {
        // Si ya estaba activo, lo desactiva. Si no, lo activa.
        _filtroTipoActivo = (_filtroTipoActivo == nombre) ? null : nombre;
      } else if (tipoFiltro == 'genero') {
        _filtroGeneroActivo = (_filtroGeneroActivo == nombre) ? null : nombre;
      }
      
      // Una vez que el estado del filtro cambia, recargamos la lista.
      // (Por ahora, _loadElementos no usa estos filtros, pero el flujo es correcto)
    });
    // Llamar a _loadElementos() para que el efecto visual se vea inmediatamente.
    // Esto es un placeholder hasta que el backend pueda filtrar por tipo/genero.
    _loadElementos();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( /* ... (Barra de búsqueda sin cambios) ... */
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar por título...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[400]),
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
        ),
      ),
      
      // REFACTORIZADO: El body ahora está dentro de un FutureBuilder
      // para esperar que los Tipos y Géneros se carguen.
      body: FutureBuilder<void>(
        future: _consultaFuture,
        builder: (context, snapshot) {
          
          // Muestra un spinner mientras carga los Tipos/Géneros
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Error en la carga de Tipos/Géneros (ej. 403 Forbidden para Moderador)
          if (snapshot.hasError && (_tipos.isEmpty || _generos.isEmpty)) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar filtros: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          
          // ÉXITO: Muestra la lista y los filtros
          return _buildSearchContent();
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Proponer Elemento'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PropuestaFormScreen(),
            ),
          ).then((_) => _loadElementos()); // Recarga la lista si se vuelve del formulario
        },
      ),
    );
  }

  /// NUEVO: Contenido principal de búsqueda y filtros
  Widget _buildSearchContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // --- Explorar por Tipo ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Explorar por Tipo', style: Theme.of(context).textTheme.titleLarge),
          ),
          _buildFiltroChips(
            data: _tipos.map((t) => t.nombre).toList(), // Solo los nombres
            tipoFiltro: 'tipo',
            filtroActivo: _filtroTipoActivo,
          ),
          
          // --- Explorar por Género ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Explorar por Género', style: Theme.of(context).textTheme.titleLarge),
          ),
          _buildFiltroChips(
            data: _generos.map((g) => g.nombre).toList(), // Solo los nombres
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
                  return Center(child: Text('Error en la búsqueda: ${snapshot.error}', style: TextStyle(color: Colors.red)));
                }
                final elementos = snapshot.data ?? [];
                
                if (elementos.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: Text('No se encontraron elementos con el filtro aplicado.'),
                  ));
                }

                // Muestra la lista de resultados
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Deshabilita el scroll
                  itemCount: elementos.length,
                  itemBuilder: (context, index) {
                    final elemento = elementos[index];
                    return _buildElementoListTile(elemento);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// NUEVO: Widget para construir los chips de Tipo/Género
  Widget _buildFiltroChips({
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
              backgroundColor: isSelected ? Colors.blue[600] : Colors.grey[700],
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey[300]),
              onPressed: () => _handleFiltroTap(tipoFiltro, nombre),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// NUEVO: Widget auxiliar para un resultado de búsqueda
  Widget _buildElementoListTile(Elemento elemento) {
    return ListTile(
      leading: const Icon(Icons.movie_filter_outlined), 
      title: Text(elemento.titulo),
      subtitle: Text('Tipo: ${elemento.tipo} | Estado: ${elemento.estadoContenido}'),
      trailing: _buildEstadoChip(elemento.estadoContenido),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ElementoDetailScreen(elementoId: elemento.id),
          ),
        ).then((_) => _loadElementos()); // Recarga si se vuelve (por si se añadió)
      },
    );
  }
  
  /// Widget auxiliar para el chip "OFICIAL" / "COMUNITARIO"
  Widget _buildEstadoChip(String estado) {
    // ... (código existente)
    final bool isOficial = estado == "OFICIAL"; 
    return Chip(
      label: Text(
        isOficial ? "OFICIAL" : "COMUNITARIO",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isOficial ? Colors.blue[600] : Colors.grey[700],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}