// lib/src/core/services/propuesta_service.dart
import 'package:libratrack_client/src/core/utils/api_client.dart'; 

/// Servicio para gestionar las llamadas a la API de Propuestas (RF13).
/// --- ¡ACTUALIZADO (Sprint 2 / V2)! ---
class PropuestaService {
  
  final String _basePath = '/propuestas';

  /// Llama al endpoint de crear una nueva propuesta (RF13).
  Future<void> proponerElemento({
    required String titulo,
    required String descripcion,
    required String tipo,
    required String generos,
    String? imagenUrl,
    // --- ¡PARÁMETROS REFACTORIZADOS! ---
    String? episodiosPorTemporada, // Para Series
    int? totalUnidades,           // Para Anime / Manga
    int? totalCapitulosLibro,     // Para Libros
    int? totalPaginasLibro,       // Para Libros
  }) async {
    
    // El body ahora acepta nulos
    final Map<String, dynamic> body = { 
      'tituloSugerido': titulo,
      'descripcionSugerida': descripcion,
      'tipoSugerido': tipo,
      'generosSugeridos': generos,
      'imagenPortadaUrl': imagenUrl,
      
      // --- ¡NUEVOS CAMPOS! ---
      'episodiosPorTemporada': episodiosPorTemporada,
      'totalUnidades': totalUnidades,
      'totalCapitulosLibro': totalCapitulosLibro,
      'totalPaginasLibro': totalPaginasLibro,
    };
    
    // Eliminamos nulos para un JSON limpio
    body.removeWhere((key, value) => value == null);

    await api.post(
      _basePath,
      body: body,
      protected: true, 
    );
  }
}