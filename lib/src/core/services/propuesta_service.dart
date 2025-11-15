// Archivo: lib/src/core/services/propuesta_service.dart
// (¡REFACTORIZADO!)

import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/utils/api_client.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart';
import 'package:libratrack_client/src/model/propuesta.dart';

class PropuestaService with ChangeNotifier {
  // --- ¡MODIFICADO! ---
  final ApiClient _apiClient;
  PropuestaService(this._apiClient);
  // ---

  /// Un usuario crea una nueva propuesta.
  Future<Propuesta> crearPropuesta(Map<String, dynamic> body) async {
    try {
      // ¡Lógica simplificada!
      final data = await _apiClient.post('propuestas', body);
      return Propuesta.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al enviar la propuesta: ${e.toString()}');
    }
  }
}