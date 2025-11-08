// Archivo: lib/src/core/services/genero_service.dart

// Se eliminan imports innecesarios: dart:convert, http, flutter_secure_storage
import 'package:libratrack_client/src/core/utils/api_client.dart'; // Importar el nuevo ApiClient
import 'package:libratrack_client/src/model/genero.dart';

/// Servicio para obtener la lista de Géneros de contenido (ej. Fantasía, Drama).
/// REFACTORIZADO: Utiliza ApiClient.
class GeneroService {
  
  // Ruta base relativa al ApiClient.baseUrl
  final String _basePath = '/generos'; 

  /// Obtiene la lista de todos los Géneros (RF09).
  Future<List<Genero>> getAllGeneros() async {
    
    // 1. Llamar al ApiClient.get
    // (ApiClient se encarga de las cabeceras, try-catch, y errores 403)
    final List<dynamic> jsonList = await api.get(_basePath) as List<dynamic>;

    // 2. Mapear la respuesta
    // El JSON ahora viene del GeneroResponseDTO
    return jsonList
        .map((json) => Genero.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}