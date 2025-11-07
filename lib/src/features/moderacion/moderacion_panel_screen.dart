// lib/src/features/moderacion/moderacion_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/moderacion_service.dart';
import 'package:libratrack_client/src/model/propuesta.dart';

class ModeracionPanelScreen extends StatefulWidget {
  const ModeracionPanelScreen({super.key});

  @override
  State<ModeracionPanelScreen> createState() => _ModeracionPanelScreenState();
}

class _ModeracionPanelScreenState extends State<ModeracionPanelScreen> {
  // --- Servicios y Estado ---
  final ModeracionService _moderacionService = ModeracionService();

  bool _isLoadingPage = true;
  String? _loadingError;
  List<Propuesta> _propuestasPendientes = [];
  final Set<int> _processingItems = {};

  @override
  void initState() {
    super.initState();
    _loadPropuestas();
  }

  /// Carga la lista de propuestas pendientes (RF14)
  Future<void> _loadPropuestas() async {
    try {
      final propuestas = await _moderacionService.getPropuestasPendientes();
      if (mounted) {
        setState(() {
          _propuestasPendientes = propuestas;
          _isLoadingPage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = e.toString().replaceFirst("Exception: ", "");
          _isLoadingPage = false;
        });
      }
    }
  }
  
  /// Lógica para aprobar una propuesta (RF15)
  Future<void> _handleAprobar(int propuestaId) async {
    setState(() {
      _processingItems.add(propuestaId);
    });
    
    final msgContext = ScaffoldMessenger.of(context);

    try {
      await _moderacionService.aprobarPropuesta(propuestaId);

      if (mounted) {
        setState(() {
          _propuestasPendientes.removeWhere((p) => p.id == propuestaId);
          _processingItems.remove(propuestaId);
        });
        msgContext.showSnackBar(
          const SnackBar(content: Text('¡Propuesta aprobada!'), backgroundColor: Colors.green),
        );
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _processingItems.remove(propuestaId);
        });
        msgContext.showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  /// Lógica para rechazar una propuesta (RF15 - Simulado)
  Future<void> _handleRechazar(int propuestaId) async {
    setState(() {
      _processingItems.add(propuestaId);
    });

    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _propuestasPendientes.removeWhere((p) => p.id == propuestaId);
        _processingItems.remove(propuestaId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propuesta rechazada (simulado).'), backgroundColor: Colors.grey),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de Moderación', style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: _buildBody(context),
    );
  }

  /// Widget auxiliar para construir el body
  Widget _buildBody(BuildContext context) {
    // 1. Estado de Carga
    if (_isLoadingPage) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Estado de Error (ej. 403 No eres Moderador)
    if (_loadingError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error al cargar el panel:\n$_loadingError',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
          ),
        ),
      );
    }
    
    // 3. Estado Vacío
    if (_propuestasPendientes.isEmpty) {
      return const Center(
        child: Text('¡Buen trabajo! No hay propuestas pendientes.'),
      );
    }

    // 4. Estado con Datos (RF14)
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _propuestasPendientes.length,
      itemBuilder: (context, index) {
        final propuesta = _propuestasPendientes[index];
        final bool isProcessing = _processingItems.contains(propuesta.id);
        
        return _buildPropuestaCard(context, propuesta, isProcessing);
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
            // --- Título ---
            // CORREGIDO: Elimina ?? 'Sin Título'
            Text(
              propuesta.tituloSugerido, // Usamos '!' aquí solo para asegurar, aunque el modelo lo garantiza.
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            // --- Detalles (Proponente) ---
            Text(
              'Propuesto por: ${propuesta.proponenteUsername}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            // --- Tipo/Géneros ---
            // CORREGIDO: Elimina ?? 'N/A'
            Text(
              'Tipo: ${propuesta.tipoSugerido}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            // CORREGIDO: Elimina ?? 'N/A'
            Text(
              'Géneros: ${propuesta.generosSugeridos}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(),
            ),
            
            // --- Botones de Acción (RF15) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botón Rechazar
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red[300]),
                  onPressed: isProcessing ? null : () => _handleRechazar(propuesta.id),
                  child: const Text('Rechazar'),
                ),
                const SizedBox(width: 8),
                // Botón Aprobar
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isProcessing ? null : () => _handleAprobar(propuesta.id),
                  child: isProcessing
                      ? const SizedBox( // Spinner pequeño
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Aprobar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}