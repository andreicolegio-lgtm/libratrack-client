import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/auth_service.dart';
import 'package:libratrack_client/src/core/services/catalog_service.dart';
import 'package:libratrack_client/src/features/auth/login_screen.dart';

/// Pantalla principal que muestra el catálogo personal del usuario (Mockup 7).
/// Implementa los requisitos RF06, RF07, RF08.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with SingleTickerProviderStateMixin {
  final CatalogService _catalogService = CatalogService();
  final AuthService _authService = AuthService();
  
  // El Future almacenará el catálogo cargado
  Future<List<dynamic>>? _catalogFuture;
  
  // Lista de todos los posibles estados personales (RF06)
  final List<String> _estados = [
    'EN_PROGRESO', 
    'PENDIENTE', 
    'TERMINADO', 
    'ABANDONADO'
  ];

  @override
  void initState() {
    super.initState();
    // Llama al método para cargar el catálogo al inicio
    _loadCatalog();
  }

  /// Método para cargar (o recargar) el catálogo
  void _loadCatalog() {
    setState(() {
      _catalogFuture = _catalogService.getMyCatalog();
    });
  }

  /// Lógica de Logout (RF02)
  Future<void> _handleLogout() async {
    final navContext = Navigator.of(context);
    
    // 1. Borra el token guardado
    await _authService.logout();
    
    // 2. Navega a Login y elimina todas las pantallas anteriores
    navContext.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _estados.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi Catálogo'),
          centerTitle: true,
          actions: [
            /// Botón de Cerrar Sesión (RF02)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
              tooltip: 'Cerrar Sesión',
            ),
          ],
          // 1. Pestañas de Filtro (Bottom Tab Bar - RF08)
          bottom: TabBar(
            isScrollable: true,
            tabs: _estados.map((estado) => Tab(text: _getDisplayName(estado))).toList(),
            labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
          ),
        ),
        
        body: TabBarView(
          children: _estados.map((estado) {
            // 2. Por cada estado, construimos un FutureBuilder (la lista)
            return FutureBuilder<List<dynamic>>(
              future: _catalogFuture,
              builder: (context, snapshot) {
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                  );
                }

                // Filtra la lista para el estado actual de la pestaña
                final filteredList = snapshot.data!
                    .where((item) => item['estadoPersonal'] == estado)
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

  /// Construye la Tarjeta de Catálogo (Similar al Mockup 7)
  Widget _buildCatalogCard(Map<String, dynamic> item) {
    final String titulo = item['elementoTitulo'] ?? 'Sin Título';
    final String tipo = item['elementoTipo'] ?? 'Sin Tipo'; // Asumiremos que el DTO tendrá 'elementoTipo'
    final String progreso = item['progresoEspecifico'] ?? '';
    // Lógica para progreso: si está completo (TERMINADO), la barra debe estar llena
    final double progresoValue = item['estadoPersonal'] == 'TERMINADO' ? 1.0 : 0.5; // Valor estático por ahora

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icono de Marcador de posición para la Imagen
            const Icon(Icons.movie_filter, size: 40, color: Colors.blueGrey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(tipo, style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 8),
                  // Barra de Progreso (Simulación de RF07)
                  LinearProgressIndicator(
                    value: progresoValue, // 0.5 o 1.0
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
            // TO DO: Añadir un botón para editar la entrada (Mockup 7)
          ],
        ),
      ),
    );
  }
  
  /// Traduce los ENUMs a nombres amigables para el usuario
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

// TODO: Crear el archivo lib/src/model/estado_personal.dart (Simplemente para el import)