import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/propuesta.dart';

/// Servicio para que los usuarios normales envíen nuevas sugerencias de contenido.
class PropuestaService with ChangeNotifier {
  final ApiClient _apiClient;
  PropuestaService(this._apiClient);

  /// Envía una nueva propuesta al backend para su revisión.
  Future<Propuesta> crearPropuesta(Map<String, dynamic> body) async {
    try {
      final dynamic data = await _apiClient.post('propuestas', body);
      return Propuesta.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al enviar la propuesta: $e');
    }
  }
}
