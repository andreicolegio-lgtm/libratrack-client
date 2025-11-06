// lib/src/features/search/search_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/elemento_service.dart';
import 'package:libratrack_client/src/features/elemento/elemento_detail_screen.dart';
import 'package:libratrack_client/src/model/elemento.dart';
// --- NUEVA IMPORTACIÓN ---
import 'package:libratrack_client/src/features/propuestas/propuesta_form_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ElementoService _elementoService = ElementoService();
  final TextEditingController _searchController = TextEditingController();
  
  Future<List<Elemento>>? _elementosFuture;

  @override
  void initState() {
    super.initState();
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
      _elementosFuture = _elementoService.getElementos(
        searchText: _searchController.text,
      );
    });
  }
  
  /// Método para limpiar la búsqueda y recargar
  void _clearSearch() {
    _searchController.clear();
    _loadElementos();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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

          final elementos = snapshot.data!;
          
          return ListView.builder(
            itemCount: elementos.length,
            itemBuilder: (context, index) {
              
              final elemento = elementos[index];
              final String titulo = elemento.titulo;
              final String tipo = elemento.tipo;
              final String estado = elemento.estadoContenido;

              return ListTile(
                leading: const Icon(Icons.movie_filter_outlined), 
                title: Text(titulo),
                subtitle: Text('Tipo: $tipo | Estado: $estado'),
                trailing: _buildEstadoChip(estado),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ElementoDetailScreen(elementoId: elemento.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      // --- CÓDIGO NUEVO AÑADIDO ---
      // Botón de Acción Flotante para RF13
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Proponer Elemento'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        onPressed: () {
          // Navega a la nueva pantalla de formulario que creamos
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PropuestaFormScreen(),
            ),
          );
        },
      ),
      // --- FIN DEL CÓDIGO NUEVO ---
    );
  }
  
  /// Widget auxiliar para el chip "OFICIAL" / "COMUNITARIO"
  Widget _buildEstadoChip(String estado) {
    // ... (código del chip sin cambios)
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