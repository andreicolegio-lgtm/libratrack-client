// lib/src/features/catalog/catalog_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/catalog_service.dart';
import 'package:libratrack_client/src/model/catalogo_entrada.dart';
import 'package:libratrack_client/src/model/estado_personal.dart';
import 'package:libratrack_client/src/features/catalog/widgets/edit_entrada_modal.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with SingleTickerProviderStateMixin {
  final CatalogService _catalogService = CatalogService();
  
  bool _isLoading = true;
  String? _loadingError;
  List<CatalogoEntrada> _catalogoCompleto = [];
  
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

  Future<void> _openEditModal(CatalogoEntrada entrada) async {
    final resultado = await showModalBottomSheet<CatalogoEntrada>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return EditEntradaModal(entrada: entrada);
      },
    );

    if (resultado != null) {
      // Actualiza la lista local sin recargar de la API
      setState(() {
        final index = _catalogoCompleto.indexWhere((e) => e.id == resultado.id);
        if (index != -1) {
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
          bottom: TabBar(
            isScrollable: true,
            tabs: _estados.map((estado) => Tab(text: estado.displayName)).toList(),
            labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
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
    
    return TabBarView(
      children: _estados.map((estado) {
        final filteredList = _catalogoCompleto
            .where((item) => item.estadoPersonal == estado.apiValue)
            .toList();

        if (filteredList.isEmpty) {
          return Center(
            child: Text('No hay elementos en estado: ${estado.displayName}'),
          );
        }

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

  /// REFACTORIZADO: Construye la Tarjeta de Catálogo con Diseño Visual
  /// Implementa Mejora 2 (Imágenes) y prepara para Mejora 3 (Edición en línea).
  Widget _buildCatalogCard(CatalogoEntrada item) {
    final String titulo = item.elementoTitulo;
    final String progreso = item.progresoEspecifico ?? '';
    
    final double progresoValue;
    if (item.estadoPersonal == EstadoPersonal.TERMINADO.apiValue) {
      progresoValue = 1.0;
    } else if (item.estadoPersonal == EstadoPersonal.EN_PROGRESO.apiValue) {
      progresoValue = 0.5; // Simulado
    } else {
      progresoValue = 0.0;
    }

    // --- Contenido de la Tarjeta ---
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[850],
      child: InkWell( // Hace que toda la tarjeta sea clickable
        onTap: () {
          // TO DO: Navegar a ElementoDetailScreen(elementoId: item.elementoId)
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Imagen de Portada (Mejora 2)
              Container(
                width: 70,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.grey[800],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: item.elementoImagenPortadaUrl.isNotEmpty
                      ? Image.network(
                          item.elementoImagenPortadaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.broken_image, color: Colors.blueGrey),
                        )
                      : const Icon(Icons.image, size: 40, color: Colors.blueGrey),
                ),
              ),
              const SizedBox(width: 16),
              
              // 2. Título y Progreso
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Título
                        Expanded(
                          child: Text(
                            titulo,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Botón de Edición (RF06/RF07)
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: Colors.grey),
                          tooltip: 'Editar progreso',
                          onPressed: () => _openEditModal(item),
                        ),
                      ],
                    ),
                    
                    // Progreso Específico (T2:E5)
                    if (progreso.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          progreso,
                          style: const TextStyle(fontSize: 14, color: Colors.blue),
                        ),
                      ),
                      
                    // Barra de Progreso
                    LinearProgressIndicator(
                      value: progresoValue,
                      backgroundColor: Colors.grey[700],
                      color: Colors.blue,
                    ),
                    
                    // Estado Personal (ej. Pendiente)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        EstadoPersonal.fromString(item.estadoPersonal).displayName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}