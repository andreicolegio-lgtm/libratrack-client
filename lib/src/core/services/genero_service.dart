import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/genero.dart';

class GeneroService with ChangeNotifier {
  final ApiClient _apiClient;
  GeneroService(this._apiClient);

  List<Genero>? _generos;
  List<Genero>? get generos => _generos;

  Future<List<Genero>> fetchGeneros() async {
    if (_generos != null) {
      return _generos!;
    }

    try {
      final List<dynamic> data = await _apiClient.get('generos');

      _generos = data.map((item) => Genero.fromJson(item)).toList();
      notifyListeners();
      return _generos!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al cargar los géneros: ${e.toString()}');
    }
  }
}
