// lib/src/core/services/moderacion_service.dart
import 'package:libratrack_client/src/core/utils/api_client.dart'; 
import 'package:libratrack_client/src/model/propuesta.dart'; 

/// Servicio para gestionar las llamadas a la API de Moderación (RF14, RF15).
/// REFACTORIZADO: Utiliza ApiClient.
class ModeracionService {
  
  final String _basePath = '/moderacion'; 

  /// Obtiene la lista de propuestas pendientes (RF14).
  Future<List<Propuesta>> getPropuestasPendientes() async {
    
    final List<dynamic> jsonList = await api.get('$_basePath/pendientes') as List<dynamic>;
    
    return jsonList
        .map((json) => Propuesta.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Aprueba una propuesta (RF15).
  Future<void> aprobarPropuesta(int propuestaId) async {
    await api.post('$_basePath/aprobar/$propuestaId');
  }
}