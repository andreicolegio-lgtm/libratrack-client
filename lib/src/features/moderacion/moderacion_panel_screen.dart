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
    // ... (Lógica de aprobar sin cambios) ...
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
  
  /// Lógica para rechazar una propuesta (RF15)
  Future<void> _handleRechazar(int propuestaId) async {
    // ... (Lógica de rechazar sin cambios) ...
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
        title: const Text('Panel de Moderación'),
      ),
      body: _buildBody(),
    );
  }

  /// Widget auxiliar para construir el body
  Widget _buildBody() {
    if (_isLoadingPage) {
      return const Center(child: CircularProgressIndicator());
    }
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
    if (_propuestasPendientes.isEmpty) {
      return const Center(
        child: Text('¡Buen trabajo! No hay propuestas pendientes.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _propuestasPendientes.length,
      itemBuilder: (context, index) {
        final propuesta = _propuestasPendientes[index];
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
            // CORREGIDO: Ya no necesita '!' ni '??' porque el modelo
            // 'propuesta.dart' ahora define 'tituloSugerido' como no-nulable,
            // tal como tú confirmaste.
            Text(
              propuesta.tituloSugerido,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // --- Detalles ---
            Text(
              'Propuesto por: ${propuesta.proponenteUsername}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 4),
            // CORREGIDO: 'tipoSugerido' tampoco es nulo
            Text('Tipo: ${propuesta.tipoSugerido}'),
            const SizedBox(height: 4),
            // CORREGIDO: 'generosSugeridos' tampoco es nulo
            Text('Géneros: ${propuesta.generosSugeridos}'),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(),
            ),
            
            // --- Botones de Acción (RF15) ---
            Row(
              // ... (Lógica de botones sin cambios) ...
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
                  onPressed: isProcessing ? null : () => _handleAprobar(propuesta.id),
                  child: isProcessing
                      ? const SizedBox(
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