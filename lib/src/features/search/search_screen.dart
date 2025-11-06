import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/elemento_service.dart';
import 'package:libratrack_client/src/features/elemento/elemento_detail_screen.dart';

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
  
  // El Future ahora puede depender del texto de búsqueda
  Future<List<dynamic>>? _elementosFuture;

  @override
  void initState() {
    super.initState();
    // 1. Carga inicial (muestra todos los elementos al abrir)
    _loadElementos();
  }
  
  // Limpia el controlador cuando el widget se destruye
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Método para cargar (o recargar) los elementos.
  /// Llama al servicio con el texto actual del controlador.
  void _loadElementos() {
    setState(() {
      // Llama al servicio, pasando el texto de la barra de búsqueda
      _elementosFuture = _elementoService.getElementos(
        searchText: _searchController.text,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 2. Barra de Búsqueda (Mockup 3)
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar por título, género o tipo...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          ),
          // 3. Ejecuta la búsqueda cuando el usuario pulsa Enter en el teclado
          onSubmitted: (value) {
            _loadElementos(); // Recarga la lista con el nuevo término
          },
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _elementosFuture,
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar elementos:\n${snapshot.error}', textAlign: TextAlign.center),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No se encontraron elementos.'),
            );
          }

          final elementos = snapshot.data!;
          
          // 4. Muestra la lista de resultados
          return ListView.builder(
            itemCount: elementos.length,
            itemBuilder: (context, index) {
              final elemento = elementos[index];
              final String titulo = elemento['titulo'] ?? 'Sin Título';
              final String tipo = elemento['tipo'] ?? 'Sin Tipo';
              final String estado = elemento['estadoContenido'] ?? 'COMUNITARIO'; // RF11

              return ListTile(
                leading: const Icon(Icons.movie),
                title: Text(titulo),
                subtitle: Text('Tipo: $tipo | Estado: $estado'),
                onTap: () {
                  // Navega a la pantalla de Ficha de Elemento (RF10)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Pasamos el ID como int (ElementoResponseDTO lo tiene como Long, pero Flutter lo maneja como int)
                      builder: (context) => ElementoDetailScreen(elementoId: elemento['id']),
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
}