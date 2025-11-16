import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../../model/elemento.dart';
import '../../model/paginated_response.dart';
import '../../model/elemento_relacion.dart';

class ElementoService with ChangeNotifier {
  final ApiClient _apiClient;
  ElementoService(this._apiClient);

  Future<PaginatedResponse<Elemento>> searchElementos(
      {int page = 0,
      int size = 20,
      String? search,
      String? tipo,
      String? genero}) async {
    final Map<String, String> queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
      if (genero != null && genero.isNotEmpty) 'genero': genero,
    };

    final dynamic jsonResponse =
        await _apiClient.get('elementos', queryParams: queryParams);

    return PaginatedResponse.fromJson(jsonResponse, Elemento.fromJson);
  }

  Future<Elemento> getElementoById(int elementoId) async {
    final dynamic jsonResponse = await _apiClient.get('elementos/$elementoId');
    return Elemento.fromJson(jsonResponse);
  }

  Future<List<ElementoRelacion>> getSimpleElementoList() async {
    final dynamic jsonResponse = await _apiClient.get('elementos/all-simple');

    final List<dynamic> list =
        jsonResponse is List ? jsonResponse : <dynamic>[jsonResponse];

    return list
        .map((json) => ElementoRelacion.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
