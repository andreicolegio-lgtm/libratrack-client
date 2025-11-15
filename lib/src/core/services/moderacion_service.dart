// Archivo: lib/src/core/services/moderacion_service.dart
// (¡CORREGIDO!)

import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/utils/api_client.dart';
import 'package:libratrack_client/src/core/utils/api_exceptions.dart';
import 'package:libratrack_client/src/model/elemento.dart';
import 'package:libratrack_client/src/model/propuesta.dart';

class ModeracionService with ChangeNotifier {
  final ApiClient _apiClient;
  ModeracionService(this._apiClient);

  /// Obtiene la lista de propuestas por estado (PENDIENTE, APROBADO, etc.)
  Future<List<Propuesta>> fetchPropuestasPorEstado(String estado) async {
    try {
      final List<dynamic> data =
          await _apiClient.get('moderacion?estado=$estado');
      return data.map((item) => Propuesta.fromJson(item)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al cargar las propuestas: ${e.toString()}');
    }
  }

  /// Aprueba una propuesta (y la convierte en Elemento).
  // --- ¡CORREGIDO (ID: QA-051)! Acepta int propuestaId ---
  Future<Elemento> aprobarPropuesta(
      int propuestaId, Map<String, dynamic> body) async {
    try {
      // Convierte a String en el último momento
      final data = await _apiClient.post(
          'moderacion/aprobar/${propuestaId.toString()}', body);
      return Elemento.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al aprobar la propuesta: ${e.toString()}');
    }
  }
}