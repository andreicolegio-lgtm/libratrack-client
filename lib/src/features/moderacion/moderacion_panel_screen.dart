// lib/src/features/moderacion/moderacion_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/moderacion_service.dart';
import 'package:libratrack_client/src/model/propuesta.dart'; // Importa el modelo

/// Pantalla del Panel de Moderación (Mockup 4).
///
/// Implementa RF14 (Ver pendientes) y RF15 (Aprobar/Rechazar).
/// Es un [StatefulWidget] para gestionar la lista de propuestas
/// y el estado de carga de cada ítem.
class ModeracionPanelScreen extends StatefulWidget {
  const ModeracionPanelScreen({super.key});

  @override
  State<ModeracionPanelScreen> createState() => _ModeracionPanelScreenState();
}

class _ModeracionPanelScreenState extends State<ModeracionPanelScreen> {
  // --- Servicios y Estado ---
  final ModeracionService _moderacionService = ModeracionService();

  // Estado de la UI
  bool _isLoadingPage = true; // Para la carga inicial de la página
  String? _loadingError;
  
  // La lista local de propuestas. La gestionamos manualmente
  // para poder quitar ítems al aprobar/rechazar (UI Optimista).
  List<Propuesta> _propuestasPendientes = [];
  
  // Un Set para rastrear qué ítems están siendo procesados
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
    // 1. Marcar el ítem como "procesando" para mostrar un spinner
    setState(() {
      _processingItems.add(propuestaId);
    });
    
    final msgContext = ScaffoldMessenger.of(context);

    try {
      // 2. Llamar al servicio
      await _moderacionService.aprobarPropuesta(propuestaId);

      // 3. (ÉXITO) Actualización optimista de la UI:
      // Quita el ítem de la lista local SIN recargar la página.
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
      // 4. (ERROR)
      if (mounted) {
        setState(() {
          _processingItems.remove(propuestaId); // Quita el spinner
        });
        msgContext.showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  /// TO DO: Lógica para rechazar una propuesta (RF15)
  Future<void> _handleRechazar(int propuestaId) async {
    // 1. Marcar como "procesando"
    setState(() {
      _processingItems.add(propuestaId);
    });

    // --- Lógica de Rechazo (FUTURO) ---
    // Simula un retraso y quita el ítem
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
    // --- Fin de la simulación ---
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Moderación'),
      ),
      // Construye el body según el estado de la carga
      body: _buildBody(),
    );
  }

  /// Widget auxiliar para construir el body
  Widget _buildBody() {
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
            style: const TextStyle(color: Colors.red),
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
        // Comprueba si este ítem específico está siendo procesado
        final bool isProcessing = _processingItems.contains(propuesta.id);
        
        return _buildPropuestaCard(propuesta, isProcessing);
      },
    );
  }

  /// Construye la tarjeta para una Propuesta (Mockup 4)
  Widget _buildPropuestaCard(Propuesta propuesta, bool isProcessing) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Título ---
            Text(
              propuesta.tituloSugerido,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // --- Detalles (Tipo, Géneros, Proponente) ---
            Text(
              'Propuesto por: ${propuesta.proponenteUsername}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text('Tipo: ${propuesta.tipoSugerido}'),
            const SizedBox(height: 4),
            Text('Géneros: ${propuesta.generosSugeridos}'),
            
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
                  // Deshabilita si este (u otro) ítem se está procesando
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
                  // Deshabilita si este ítem se está procesando
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