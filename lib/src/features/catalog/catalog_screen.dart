// lib/src/features/catalog/catalog_screen.dart
import 'package:flutter/material.dart';
// REFACTORIZADO: Imports de Auth/Login eliminados (no es su responsabilidad)
import 'package:libratrack_client/src/core/services/catalog_service.dart';
import 'package:libratrack_client/src/model/catalogo_entrada.dart'; // NUEVO: Importa el modelo

/// Pantalla principal que muestra el catálogo personal del usuario (Mockup 7).
/// Implementa los requisitos RF06, RF07, RF08.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with SingleTickerProviderStateMixin {
  final CatalogService _catalogService = CatalogService();
  
  // REFACTORIZADO: El Future ahora usa nuestro modelo 'CatalogoEntrada'
  Future<List<CatalogoEntrada>>? _catalogFuture;
  
  // Lista de todos los posibles estados personales (RF06)
  // (Esta lógica es correcta)
  final List<String> _estados = [
    'EN_PROGRESO', 
    'PENDIENTE', 
    'TERMINADO', 
    'ABANDONADO'
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  /// Método para cargar (o recargar) el catálogo
  void _loadCatalog() {
    setState(() {
      // Llama al servicio (que ahora devuelve List<CatalogoEntrada>)
      _catalogFuture = _catalogService.getMyCatalog();
    });
  }

  // REFACTORIZADO: Se eliminó el método _handleLogout.
  // La lógica de Logout ahora reside únicamente en 'profile_screen.dart'
  // para mantener el Principio de Responsabilidad Única.

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _estados.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi Catálogo'),
          centerTitle: true,
          // REFACTORIZADO: Se eliminó el 'actions' (botón de logout)
          
          // 1. Pestañas de Filtro (Bottom Tab Bar - RF08)
          bottom: TabBar(
            isScrollable: true,
            tabs: _estados.map((estado) => Tab(text: _getDisplayName(estado))).toList(),
            labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
          ),
        ),
        
        body: TabBarView(
          children: _estados.map((estado) {
            // 2. Por cada estado, construimos un FutureBuilder
            
            // REFACTORIZADO: El FutureBuilder ahora espera una List<CatalogoEntrada>
            return FutureBuilder<List<CatalogoEntrada>>(
              future: _catalogFuture,
              builder: (context, snapshot) {
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                // REFACTORIZADO: 'allItems' es ahora una lista con tipo seguro
                final List<CatalogoEntrada> allItems = snapshot.data ?? [];

                // REFACTORIZADO: El filtro ahora usa 'item.estadoPersonal'
                final filteredList = allItems
                    .where((item) => item.estadoPersonal == estado)
                    .toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Text('No hay elementos en estado: ${_getDisplayName(estado)}'),
                  );
                }

                // 3. Muestra la lista de tarjetas filtradas
                return ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    // REFACTORIZADO: Pasamos el objeto 'CatalogoEntrada'
                    return _buildCatalogCard(item);
                  },
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// REFACTORIZADO: Construye la Tarjeta de Catálogo (Mockup 7)
  /// Ahora recibe un objeto 'CatalogoEntrada' (type-safe).
  Widget _buildCatalogCard(CatalogoEntrada item) {
    // REFACTORIZADO: Acceso a propiedades con '.'
    final String titulo = item.elementoTitulo;
    final String progreso = item.progresoEspecifico ?? '';
    
    // REFACTORIZADO: Lógica de barra de progreso
    final double progresoValue;
    if (item.estadoPersonal == 'TERMINADO') {
      progresoValue = 1.0;
    } else if (item.estadoPersonal == 'EN_PROGRESO' && progreso.isNotEmpty) {
      // TO DO: Lógica futura para parsear "T2:E5" / "Cap 5"
      progresoValue = 0.5; // Simulado
    } else {
      progresoValue = 0.0; // PENDIENTE o ABANDONADO
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icono de Marcador de posición
            // TO DO: Cargar 'elemento.imagenPortadaUrl' (requiere modificar DTO)
            const Icon(Icons.movie_filter_outlined, size: 40, color: Colors.blueGrey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  // REFACTORIZADO: Se eliminó el 'Text(tipo)'
                  // El 'CatalogoPersonalResponseDTO' no provee el tipo,
                  // solo el título del elemento.
                  const SizedBox(height: 8),
                  
                  // Barra de Progreso (Simulación de RF07)
                  LinearProgressIndicator(
                    value: progresoValue,
                    backgroundColor: Colors.grey[700],
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 4),
                  
                  // Texto de Progreso Específico (RF07)
                  if (progreso.isNotEmpty)
                    Text(
                      progreso,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            
            // NUEVO: Botón de editar (Mockup 7)
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.grey),
              tooltip: 'Editar progreso',
              onPressed: () {
                // TO DO: Implementar lógica de RF06/RF07
                // (Llamar a catalogService.updateElemento)
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// Traduce los ENUMs a nombres amigables
  String _getDisplayName(String enumValue) {
    switch (enumValue) {
      case 'EN_PROGRESO': return 'En Progreso';
      case 'PENDIENTE': return 'Pendiente';
      case 'TERMINADO': return 'Terminado';
      case 'ABANDONADO': return 'Abandonado';
      default: return enumValue;
    }
  }
}