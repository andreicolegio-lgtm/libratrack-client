import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/catalogo_entrada.dart';

class CatalogService with ChangeNotifier {
  final ApiClient _apiClient;
  CatalogService(this._apiClient);

  List<CatalogoEntrada> _entradas = <CatalogoEntrada>[];
  bool _isLoading = true;

  List<CatalogoEntrada> get entradas => _entradas;
  bool get isLoading => _isLoading;

  Future<void> fetchCatalog() async {
    try {
      _isLoading = true;

      final List<dynamic> data = await _apiClient.get('catalogo');
      _entradas = data.map((item) => CatalogoEntrada.fromJson(item)).toList();
    } on ApiException {
      _entradas = <CatalogoEntrada>[];
      rethrow;
    } catch (e) {
      _entradas = <CatalogoEntrada>[];
      throw ApiException('Error al cargar el catálogo: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addElemento(int elementoId) async {
    try {
      final data = await _apiClient.post(
          'catalogo/elementos/${elementoId.toString()}', <String, dynamic>{});

      final CatalogoEntrada nuevaEntrada = CatalogoEntrada.fromJson(data);
      _entradas.add(nuevaEntrada);
      notifyListeners();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al añadir elemento: ${e.toString()}');
    }
  }

  Future<void> removeElemento(int elementoId) async {
    try {
      await _apiClient.delete('catalogo/elementos/${elementoId.toString()}');

      _entradas.removeWhere(
          (CatalogoEntrada entrada) => entrada.elementoId == elementoId);
      notifyListeners();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al eliminar elemento: ${e.toString()}');
    }
  }

  Future<void> updateProgreso(int elementoId, Map<String, dynamic> body) async {
    try {
      final data = await _apiClient.put(
          'catalogo/elementos/${elementoId.toString()}', body);

      final CatalogoEntrada entradaActualizada = CatalogoEntrada.fromJson(data);
      _actualizarEntradaEnLista(entradaActualizada);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al actualizar el progreso: ${e.toString()}');
    }
  }

  Future<void> updateEstado(int elementoId, String estado) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'estadoPersonal': estado
      };
      final data = await _apiClient.put(
          'catalogo/elementos/${elementoId.toString()}', body);

      final CatalogoEntrada entradaActualizada = CatalogoEntrada.fromJson(data);
      _actualizarEntradaEnLista(entradaActualizada);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al actualizar el estado: ${e.toString()}');
    }
  }

  Future<void> toggleFavorite(int id) async {
    try {
      await _apiClient
          .put('catalogo/favorito/${id.toString()}', <String, dynamic>{});
      final index = _entradas.indexWhere((e) => e.id == id);
      if (index != -1) {
        _entradas[index] =
            _entradas[index].copyWith(esFavorito: !_entradas[index].esFavorito);
      }
    } catch (e) {
      throw ApiException('Error toggling favorite: ${e.toString()}');
    }
  }

  void _actualizarEntradaEnLista(CatalogoEntrada entradaActualizada) {
    final int index = _entradas.indexWhere(
        (CatalogoEntrada entrada) => entrada.id == entradaActualizada.id);
    if (index != -1) {
      _entradas[index] = entradaActualizada;
      notifyListeners();
    }
  }
}
