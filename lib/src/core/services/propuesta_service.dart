// lib/src/core/services/propuesta_service.dart
import 'package:libratrack_client/src/core/utils/api_client.dart'; 

/// Servicio para gestionar las llamadas a la API de Propuestas (RF13).
/// --- ¡ACTUALIZADO (Sprint 3)! ---
class PropuestaService {
  
  final String _basePath = '/propuestas';

  /// Llama al endpoint de crear una nueva propuesta (RF13).
  Future<void> proponerElemento({
    required String titulo,
    required String descripcion,
    required String tipo,
    required String generos,
    // --- (Campos de Progreso) ---
    String? episodiosPorTemporada, 
    int? totalUnidades,           
    int? totalCapitulosLibro,     
    int? totalPaginasLibro,       
    // String? imagenUrl, // <-- ¡ELIMINADO! (Petición 12)
  }) async {
    
    final Map<String, dynamic> body = { 
      'tituloSugerido': titulo,
      'descripcionSugerida': descripcion,
      'tipoSugerido': tipo,
      'generosSugeridos': generos,
      
      'episodiosPorTemporada': episodiosPorTemporada,
      'totalUnidades': totalUnidades,
      'totalCapitulosLibro': totalCapitulosLibro,
      'totalPaginasLibro': totalPaginasLibro,
      // 'imagenPortadaUrl': imagenUrl, // <-- ¡ELIMINADO!
    };
    
    body.removeWhere((key, value) => value == null);

    await api.post(
      _basePath,
      body: body,
      protected: true, 
    );
  }
}