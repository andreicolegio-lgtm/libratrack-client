// lib/src/features/catalog/catalog_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/catalog_service.dart';
import 'package:libratrack_client/src/model/catalogo_entrada.dart';
// --- NUEVAS IMPORTACIONES ---
import 'package:libratrack_client/src/model/estado_personal.dart';
import 'package:libratrack_client/src/features/catalog/widgets/edit_entrada_modal.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with SingleTickerProviderStateMixin {
  final CatalogService _catalogService = CatalogService();
  
  // --- REFACTORIZACIÓN DE ESTADO ---
  // Ya no usamos un FutureBuilder. Ahora gestionamos el estado manualmente
  // para permitir actualizaciones instantáneas de la UI.
  bool _isLoading = true;
  String? _loadingError;
  List<CatalogoEntrada> _catalogoCompleto = []; // Aquí vive la lista de datos
  
  // Lista de estados (sin cambios)
  final List<EstadoPersonal> _estados = [
    EstadoPersonal.EN_PROGRESO, 
    EstadoPersonal.PENDIENTE, 
    EstadoPersonal.TERMINADO, 
    EstadoPersonal.ABANDONADO
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  /// REFACTORIZADO: Ahora es un método 'async' que actualiza
  /// el estado local cuando termina.
  Future<void> _loadCatalog() async {
    try {
      final catalogo = await _catalogService.getMyCatalog();
      if (mounted) {
        setState(() {
          _catalogoCompleto = catalogo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = e.toString().replaceFirst("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  // --- NUEVO MÉTODO ---
  /// (RF06, RF07)
  /// Abre el modal para editar una entrada.
  Future<void> _openEditModal(CatalogoEntrada entrada) async {
    // 1. Muestra el 'Modal Bottom Sheet' y ESPERA a que se cierre.
    // 'showModalBottomSheet' devuelve un valor (el que pasamos a 'Navigator.pop')
    final resultado = await showModalBottomSheet<CatalogoEntrada>(
      context: context,
      isScrollControlled: true, // Permite que el modal crezca con el teclado
      builder: (ctx) {
        return EditEntradaModal(entrada: entrada); // Muestra el formulario
      },
    );

    // 2. Comprueba el resultado
    // Si 'resultado' no es nulo, significa que el usuario pulsó "Guardar"
    // y nuestro modal devolvió la 'entradaActualizada'.
    if (resultado != null) {
      // 3. (MEJOR PRÁCTICA) Actualiza la lista local (sin recargar de la API)
      setState(() {
        // Busca el índice del ítem antiguo en nuestra lista
        final index = _catalogoCompleto.indexWhere((e) => e.id == resultado.id);
        if (index != -1) {
          // Reemplaza el ítem antiguo por el actualizado
          _catalogoCompleto[index] = resultado;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _estados.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi Catálogo'),
          centerTitle: true,
          // 1. Pestañas de Filtro (Bottom Tab Bar - RF08)
          bottom: TabBar(
            isScrollable: true,
            // REFACTORIZADO: Usa el Enum 'EstadoPersonal'
            tabs: _estados.map((estado) => Tab(text: estado.displayName)).toList(),
            labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
          ),
        ),
        
        // REFACTORIZADO: El 'body' ya no usa FutureBuilder.
        // Ahora usa la lógica de estado local.
        body: _buildBody(),
      ),
    );
  }

  /// REFACTORIZADO: Widget auxiliar para construir el body
  Widget _buildBody() {
    // --- Caso 1: Cargando ---
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // --- Caso 2: Error ---
    if (_loadingError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: $_loadingError',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    
    // --- Caso 3: Éxito (mostrar TabBarView) ---
    return TabBarView(
      children: _estados.map((estado) {
        // REFACTORIZADO: Filtra la lista local '_catalogoCompleto'
        final filteredList = _catalogoCompleto
            .where((item) => item.estadoPersonal == estado.apiValue)
            .toList();

        if (filteredList.isEmpty) {
          return Center(
            child: Text('No hay elementos en estado: ${estado.displayName}'),
          );
        }

        // Muestra la lista de tarjetas filtradas
        return ListView.builder(
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final item = filteredList[index];
            return _buildCatalogCard(item);
          },
        );
      }).toList(),
    );
  }

  /// Construye la Tarjeta de Catálogo (Mockup 7)
  Widget _buildCatalogCard(CatalogoEntrada item) {
    final String titulo = item.elementoTitulo;
    final String progreso = item.progresoEspecifico ?? '';
    
    final double progresoValue;
    if (item.estadoPersonal == EstadoPersonal.TERMINADO.apiValue) {
      progresoValue = 1.0;
    } else if (item.estadoPersonal == EstadoPersonal.EN_PROGRESO.apiValue && progreso.isNotEmpty) {
      progresoValue = 0.5; // Simulado
    } else {
      progresoValue = 0.0;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
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
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progresoValue,
                    backgroundColor: Colors.grey[700],
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 4),
                  if (progreso.isNotEmpty)
                    Text(
                      progreso,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            
            // --- BOTÓN CONECTADO ---
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.grey),
              tooltip: 'Editar progreso',
              // NUEVO: Llama al método para abrir el modal
              onPressed: () => _openEditModal(item),
            ),
          ],
        ),
      ),
    );
  }
}