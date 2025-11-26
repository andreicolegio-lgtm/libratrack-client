import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/elemento.dart';
import '../../model/propuesta.dart';

/// Servicio utilizado por el panel de moderación para gestionar solicitudes de contenido.
class ModeracionService with ChangeNotifier {
  final ApiClient _apiClient;
  ModeracionService(this._apiClient);

  /// Obtiene una lista de propuestas filtradas por su estado (PENDIENTE, APROBADO, RECHAZADO).
  Future<List<Propuesta>> fetchPropuestasPorEstado(String estado) async {
    try {
      final dynamic response =
          await _apiClient.get('moderacion', queryParams: {'estado': estado});

      // Validación de tipo segura
      final List<dynamic> data = response is List ? response : [];

      return data
          .map((item) => Propuesta.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al cargar las propuestas: $e');
    }
  }

  /// Aprueba una propuesta y crea el elemento correspondiente.
  Future<Elemento> aprobarPropuesta(
      int propuestaId, Map<String, dynamic> body) async {
    try {
      final dynamic data =
          await _apiClient.post('moderacion/aprobar/$propuestaId', body);
      return Elemento.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al aprobar la propuesta: $e');
    }
  }
}
