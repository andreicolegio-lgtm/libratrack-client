// lib/src/core/services/resena_service.dart
import 'package:libratrack_client/src/core/utils/api_client.dart'; 
import 'package:libratrack_client/src/model/resena.dart'; 

/// Servicio para gestionar las llamadas a la API relacionadas con las Reseñas (RF12).
/// REFACTORIZADO: Utiliza ApiClient.
class ResenaService {
  
  final String _basePath = '/resenas'; 

  /// Obtiene la lista de reseñas de un elemento (RF12).
  Future<List<Resena>> getResenas(int elementoId) async {
    
    final List<dynamic> jsonList = await api.get('$_basePath/elemento/$elementoId') as List<dynamic>;
    
    return jsonList
        .map((json) => Resena.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Crea una nueva reseña para un elemento (RF12).
  Future<Resena> crearResena({
    required int elementoId,
    required int valoracion,
    String? textoResena,
  }) async {
    
    final Map<String, dynamic> body = {
      'elementoId': elementoId,
      'valoracion': valoracion,
      'textoResena': textoResena,
    };

    final dynamic responseData = await api.post(
      _basePath,
      body: body,
    );

    return Resena.fromJson(responseData as Map<String, dynamic>);
  }
}