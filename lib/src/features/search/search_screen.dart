// lib/src/features/search/search_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/elemento_service.dart';
import 'package:libratrack_client/src/features/elemento/elemento_detail_screen.dart';
import 'package:libratrack_client/src/model/elemento.dart'; // NUEVO: Importa el modelo

/// Pantalla para buscar y explorar contenido (Mockup 3).
///
/// Permite al usuario buscar por texto (RF09).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ElementoService _elementoService = ElementoService();
  final TextEditingController _searchController = TextEditingController();
  
  // REFACTORIZADO: El Future ahora usa nuestro modelo 'Elemento'
  // para darnos seguridad de tipos (type-safety).
  Future<List<Elemento>>? _elementosFuture;

  @override
  void initState() {
    super.initState();
    // 1. Carga inicial (muestra todos los elementos al abrir)
    _loadElementos();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Método para cargar (o recargar) los elementos.
  void _loadElementos() {
    setState(() {
      // Llama al servicio (que ahora devuelve List<Elemento>)
      _elementosFuture = _elementoService.getElementos(
        searchText: _searchController.text,
      );
    });
  }
  
  /// NUEVO: Método para limpiar la búsqueda y recargar
  void _clearSearch() {
    _searchController.clear();
    _loadElementos();
    // Oculta el teclado
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 2. Barra de Búsqueda (Mockup 3)
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar por título...', // Tu API busca por título
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            
            // NUEVO: Botón para limpiar la barra de búsqueda (Mejor Práctica UX)
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[400]),
                    onPressed: _clearSearch,
                  )
                : null, // No muestra nada si está vacío
          ),
          // 3. Ejecuta la búsqueda cuando el usuario pulsa Enter
          onSubmitted: (value) {
            _loadElementos();
          },
          // NUEVO: Actualiza la UI para mostrar el botón 'clear' mientras escribes
          onChanged: (value) {
            setState(() {
              // Esto solo reconstruye el 'suffixIcon', no recarga la lista
            });
          },
        ),
      ),
      // REFACTORIZADO: El FutureBuilder ahora espera una List<Elemento>
      body: FutureBuilder<List<Elemento>>(
        future: _elementosFuture,
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar elementos:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No se encontraron elementos.'),
            );
          }

          // REFACTORIZADO: 'elementos' es ahora una List<Elemento>
          final elementos = snapshot.data!;
          
          // 4. Muestra la lista de resultados
          return ListView.builder(
            itemCount: elementos.length,
            itemBuilder: (context, index) {
              
              // REFACTORIZADO: 'elemento' es un objeto Elemento, no un Map
              final elemento = elementos[index];
              
              // REFACTORIZADO: Accedemos a las propiedades con '.' (type-safe)
              final String titulo = elemento.titulo;
              final String tipo = elemento.tipo;
              final String estado = elemento.estadoContenido; // RF11

              return ListTile(
                // TO DO: Reemplazar con 'elemento.imagenPortadaUrl' cuando
                // tengamos el widget de imagen.
                leading: const Icon(Icons.movie_filter_outlined), 
                title: Text(titulo),
                subtitle: Text('Tipo: $tipo | Estado: $estado'),
                trailing: _buildEstadoChip(estado), // NUEVO: Chip visual (RF11)
                onTap: () {
                  // Navega a la pantalla de Ficha de Elemento (RF10)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // REFACTORIZADO: Accedemos con 'elemento.id'
                      builder: (context) => ElementoDetailScreen(elementoId: elemento.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
  
  /// (RF11) Widget auxiliar para mostrar 
  /// el chip "OFICIAL" o "COMUNITARIO" (reutilizado de 110-HH)
  Widget _buildEstadoChip(String estado) {
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