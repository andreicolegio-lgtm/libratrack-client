// lib/src/features/catalog/catalog_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/catalog_service.dart';
import 'package:libratrack_client/src/model/catalogo_entrada.dart';
import 'package:libratrack_client/src/model/estado_personal.dart';
// Eliminamos la dependencia a EditEntradaModal
// Eliminamos la dependencia a widgets/edit_entrada_modal.dart
import 'package:libratrack_client/src/features/catalog/widgets/catalog_entry_card.dart'; // ¡NUEVA IMPORTACIÓN!

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

  /// Método para cargar (o recargar) el catálogo (RF08)
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

  // --- MÉTODO ELIMINADO ---
  // Se eliminó _openEditModal, ya que la edición se hace en línea en la tarjeta.
  // El onUpdate callback en el widget de la tarjeta llama a _loadCatalog()
  // si el estado cambia (para mover la tarjeta a otra pestaña).

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
            // ¡NUEVO USO DEL WIDGET!
            return CatalogEntryCard(
              entrada: item,
              // Si la tarjeta actualiza su estado (ej. de PENDIENTE a EN_PROGRESO),
              // recargamos la lista completa para que la tarjeta se mueva de pestaña.
              onUpdate: _loadCatalog, 
            );
          },
        );
      }).toList(),
    );
  }
}