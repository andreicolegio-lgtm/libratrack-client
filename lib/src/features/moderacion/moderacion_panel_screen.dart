// lib/src/features/moderacion/moderacion_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/moderacion_service.dart';
import 'package:libratrack_client/src/model/propuesta.dart';
import 'package:libratrack_client/src/model/estado_propuesta.dart'; 
import 'package:libratrack_client/src/core/widgets/maybe_marquee.dart';
// ¡NUEVA IMPORTACIÓN!
import 'package:libratrack_client/src/features/moderacion/propuesta_edit_screen.dart'; 

class ModeracionPanelScreen extends StatefulWidget {
  const ModeracionPanelScreen({super.key});

  @override
  State<ModeracionPanelScreen> createState() => _ModeracionPanelScreenState();
}

class _ModeracionPanelScreenState extends State<ModeracionPanelScreen> with SingleTickerProviderStateMixin {
  
  final List<EstadoPropuesta> _estados = [
    EstadoPropuesta.PENDIENTE,
    EstadoPropuesta.APROBADO,
    EstadoPropuesta.RECHAZADO,
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _estados.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Panel de Moderación', style: Theme.of(context).textTheme.titleLarge),
          backgroundColor: Theme.of(context).colorScheme.surface,
          centerTitle: true,
          bottom: TabBar(
            isScrollable: false, 
            tabAlignment: TabAlignment.center,
            tabs: _estados.map((estado) => Tab(text: estado.displayName)).toList(),
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey[500],
          ),
        ),
        body: TabBarView(
          children: _estados.map((estado) {
            return _PropuestasTab(
              estado: estado,
              key: ValueKey(estado.apiValue), 
            );
          }).toList(),
        ),
      ),
    );
  }
}


/// --- WIDGET INTERNO _PropuestasTab ---
class _PropuestasTab extends StatefulWidget {
  final EstadoPropuesta estado;
  const _PropuestasTab({super.key, required this.estado});
  @override
  State<_PropuestasTab> createState() => _PropuestasTabState();
}

class _PropuestasTabState extends State<_PropuestasTab> with AutomaticKeepAliveClientMixin {
  final ModeracionService _moderacionService = ModeracionService();
  late Future<List<Propuesta>> _propuestasFuture;
  List<Propuesta> _propuestas = [];
  final Set<int> _processingItems = {};

  @override
  void initState() {
    super.initState();
    _loadPropuestas();
  }

  @override
  bool get wantKeepAlive => true; 

  Future<void> _loadPropuestas() async {
    _propuestasFuture = _moderacionService.getPropuestasPorEstado(widget.estado.apiValue);
    try {
      _propuestas = await _propuestasFuture;
      if (mounted) {
        setState(() {}); 
      }
    } catch (e) {
      // El FutureBuilder maneja el error
    }
  }
  
  // --- ¡MÉTODO MODIFICADO (Petición d)! ---
  /// Lógica para navegar a la pantalla de Revisión/Edición
  Future<void> _handleRevisar(Propuesta propuesta) async {
    // Navegamos a la nueva pantalla y ESPERAMOS un resultado
    final bool? seHaAprobado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PropuestaEditScreen(propuesta: propuesta),
      ),
    );

    // Si la pantalla de edición nos devuelve 'true' (porque se aprobó)...
    if (seHaAprobado == true && mounted) {
      // ...quitamos la propuesta de la lista de "Pendientes"
      setState(() {
        _propuestas.removeWhere((p) => p.id == propuesta.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Propuesta aprobada!'), backgroundColor: Colors.green),
      );
    }
  }
  
  /// Lógica para rechazar (Sigue igual)
  Future<void> _handleRechazar(int propuestaId) async {
    setState(() { _processingItems.add(propuestaId); });
    await Future.delayed(const Duration(seconds: 1)); 
    if (mounted) {
      setState(() {
        _propuestas.removeWhere((p) => p.id == propuestaId);
        _processingItems.remove(propuestaId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propuesta rechazada (simulado).'), backgroundColor: Colors.grey),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context); 
    
    return FutureBuilder<List<Propuesta>>(
      future: _propuestasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error al cargar:\n${snapshot.error.toString().replaceFirst("Exception: ", "")}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
              ),
            ),
          );
        }
        if (_propuestas.isEmpty) {
          return Center(
            child: Text(
              widget.estado == EstadoPropuesta.PENDIENTE
                ? '¡Buen trabajo! No hay propuestas pendientes.'
                : 'No hay propuestas ${widget.estado.displayName.toLowerCase()}.'
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: _propuestas.length,
          itemBuilder: (context, index) {
            final propuesta = _propuestas[index];
            final bool isProcessing = _processingItems.contains(propuesta.id);
            return _buildPropuestaCard(context, propuesta, isProcessing);
          },
        );
      },
    );
  }

  /// Construye la tarjeta para una Propuesta (Mockup 4)
  Widget _buildPropuestaCard(BuildContext context, Propuesta propuesta, bool isProcessing) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MaybeMarquee(
              text: propuesta.tituloSugerido,
              style: Theme.of(context).textTheme.titleLarge ?? const TextStyle(),
              height: 28, 
            ),
            const SizedBox(height: 8),
            Text(
              'Propuesto por: ${propuesta.proponenteUsername}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tipo: ${propuesta.tipoSugerido}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Géneros: ${propuesta.generosSugeridos}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            // --- ¡BOTONES MODIFICADOS (Petición d)! ---
            if (widget.estado == EstadoPropuesta.PENDIENTE) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red[300]),
                    onPressed: isProcessing ? null : () => _handleRechazar(propuesta.id),
                    child: const Text('Rechazar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                    // Llamamos a la nueva función de navegación
                    onPressed: isProcessing ? null : () => _handleRevisar(propuesta),
                    child: isProcessing
                        ? const SizedBox( 
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        // Cambiamos el texto del botón
                        : const Text('Revisar'),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}