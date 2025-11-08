// Archivo: lib/src/core/services/propuesta_service.dart

// Se eliminan imports innecesarios: dart:convert, http, flutter_secure_storage
import 'package:libratrack_client/src/core/utils/api_client.dart'; // Importar el nuevo ApiClient

/// Servicio para gestionar las llamadas a la API relacionadas con la
/// proposición de nuevo contenido (RF13).
/// REFACTORIZADO: Utiliza ApiClient.
class PropuestaService {
  
  // Ruta base relativa al ApiClient.baseUrl
  final String _basePath = '/propuestas';

  /// Envía una nueva propuesta de elemento a la cola de moderación (RF13).
  /// @param imagenUrl (NUEVO) La URL de la imagen de portada.
  Future<void> proponerElemento({
    required String titulo,
    required String descripcion,
    required String tipo,
    required String generos,
    String? imagenUrl,
  }) async {
    
    // Las claves DEBEN coincidir con el 'PropuestaRequestDTO' de la API
    final Map<String, String?> body = {
      'tituloSugerido': titulo,
      'descripcionSugerida': descripcion,
      'tipoSugerido': tipo,
      'generosSugeridos': generos,
      'imagenPortadaUrl': imagenUrl,
    };

    // 1. Llamar al ApiClient.post
    // (ApiClient se encarga de las cabeceras, try-catch, y errores 400/403)
    await api.post(
      _basePath,
      body: body,
    );
  }
}