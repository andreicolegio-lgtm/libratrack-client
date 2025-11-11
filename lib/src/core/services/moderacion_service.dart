// lib/src/core/services/moderacion_service.dart
import 'package:libratrack_client/src/core/utils/api_client.dart'; 
import 'package:libratrack_client/src/model/propuesta.dart'; 

/// Servicio para gestionar las llamadas a la API de Moderación (RF14, RF15).
/// --- ¡ACTUALIZADO (Sprint 2 / V2)! ---
class ModeracionService {
  
  final String _basePath = '/moderacion'; 

  /// Obtiene la lista de propuestas por un estado específico (RF14).
  Future<List<Propuesta>> getPropuestasPorEstado(String estado) async {
    
    final Map<String, String> queryParams = {
      'estado': estado,
    };

    final List<dynamic> jsonList = await api.get(
      _basePath, 
      queryParams: queryParams
    ) as List<dynamic>;
    
    return jsonList
        .map((json) => Propuesta.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Aprueba una propuesta (RF15).
  /// --- ¡REFACTORIZADO (Petición d)! ---
  /// Ahora envía el body con las ediciones del moderador.
  Future<void> aprobarPropuesta(int propuestaId, Map<String, dynamic> body) async {
    // El 'body' debe coincidir con el PropuestaUpdateDTO.java
    await api.post(
      '$_basePath/aprobar/$propuestaId',
      body: body,
    );
  }
}