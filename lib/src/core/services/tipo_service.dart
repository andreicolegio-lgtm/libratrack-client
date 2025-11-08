// Archivo: lib/src/core/services/tipo_service.dart

// Se eliminan imports innecesarios: dart:convert, http, flutter_secure_storage
import 'package:libratrack_client/src/core/utils/api_client.dart'; // Importar el nuevo ApiClient
import 'package:libratrack_client/src/model/tipo.dart';

/// Servicio para obtener la lista de Tipos de contenido (ej. Serie, Libro).
/// REFACTORIZADO: Utiliza ApiClient.
class TipoService {
  
  // Ruta base relativa al ApiClient.baseUrl
  final String _basePath = '/tipos'; 

  /// Obtiene la lista de todos los Tipos (RF09).
  Future<List<Tipo>> getAllTipos() async {
    
    // 1. Llamar al ApiClient.get
    // (ApiClient se encarga de las cabeceras, try-catch, y errores 403)
    final List<dynamic> jsonList = await api.get(_basePath) as List<dynamic>;
    
    // 2. Mapear la respuesta
    // El JSON ahora viene del TipoResponseDTO
    return jsonList
        .map((json) => Tipo.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}