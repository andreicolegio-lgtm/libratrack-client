// lib/src/features/catalog/catalog_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/catalog_service.dart';
import 'package:libratrack_client/src/model/catalogo_entrada.dart';
import 'package:libratrack_client/src/model/estado_personal.dart';
import 'package:libratrack_client/src/features/catalog/widgets/catalog_entry_card.dart';

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


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _estados.length,
      child: Scaffold(
        appBar: AppBar(
          // REFACTORIZADO: Usa tipografía titleLarge y centrado (Corrección 6)
          title: Text('LibraTrack', style: Theme.of(context).textTheme.titleLarge), 
          centerTitle: true,
          bottom: TabBar(
            // --- LÍNEAS CORREGIDAS (Corrección 8) ---
            isScrollable: false,
            tabAlignment: TabAlignment.center,
            // ---
            tabs: _estados.map((estado) => Tab(text: estado.displayName)).toList(),
            labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
            // NUEVO: Indicador y color del texto del tab unificados con el tema
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey[500],
          ),
        ),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
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
            child: Text(
              'No hay elementos en estado: ${estado.displayName}',
              textAlign: TextAlign.center, // Alineación central
              style: Theme.of(context).textTheme.bodyMedium, 
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final item = filteredList[index];
            // La lógica de actualización está dentro de CatalogEntryCard
            return CatalogEntryCard(
              entrada: item,
              onUpdate: _loadCatalog, 
            );
          },
        );
      }).toList(),
    );
  }
}