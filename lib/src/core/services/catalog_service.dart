import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../utils/api_exceptions.dart';
import '../../model/catalogo_entrada.dart';

/// Servicio encargado de gestionar la biblioteca personal del usuario.
/// Mantiene un estado local (_entradas) sincronizado con el backend.
class CatalogService with ChangeNotifier {
  final ApiClient _apiClient;

  List<CatalogoEntrada> _entradas = [];
  bool _isLoading = false;

  CatalogService(this._apiClient);

  List<CatalogoEntrada> get entradas => _entradas;
  bool get isLoading => _isLoading;

  /// Carga el catálogo completo del usuario desde el servidor.
  Future<void> fetchCatalog() async {
    _isLoading = true;
    // Notificamos solo si la lista está vacía para mostrar spinner inicial.
    // Si ya hay datos, cargamos en "segundo plano" sin limpiar la pantalla.
    if (_entradas.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }

    try {
      final List<dynamic> data = await _apiClient.get('catalogo');
      _entradas = data.map((json) => CatalogoEntrada.fromJson(json)).toList();
    } catch (e) {
      // En caso de error, si es la primera carga, propagamos.
      // Si ya había datos, podríamos optar por mantenerlos o mostrar snackbar.
      if (_entradas.isEmpty) {
        rethrow;
      }
      debugPrint('Error refrescando catálogo: $e');
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Añade un elemento al catálogo (Estado inicial: PENDIENTE).
  Future<void> addElemento(int elementoId) async {
    try {
      final data = await _apiClient.post(
        'catalogo/elementos/$elementoId',
        {}, // Body vacío
      );
      final nuevaEntrada = CatalogoEntrada.fromJson(data);

      _entradas.add(nuevaEntrada);
      notifyListeners();
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al añadir al catálogo: $e');
    }
  }

  /// Elimina un elemento del catálogo.
  Future<void> removeElemento(int elementoId) async {
    // Guardamos copia por si hay que revertir (Optimistic Update manual)
    final entradaEliminadaIndex =
        _entradas.indexWhere((e) => e.elementoId == elementoId);
    if (entradaEliminadaIndex == -1) {
      return;
    }

    final entradaBackup = _entradas[entradaEliminadaIndex];

    // Actualizamos UI primero
    _entradas.removeAt(entradaEliminadaIndex);
    notifyListeners();

    try {
      await _apiClient.delete('catalogo/elementos/$elementoId');
    } catch (e) {
      // Revertimos si falla
      _entradas.insert(entradaEliminadaIndex, entradaBackup);
      notifyListeners();
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al eliminar del catálogo: $e');
    }
  }

  /// Actualiza estado o progreso de una entrada existente.
  Future<void> updateEntrada(
      int elementoId, Map<String, dynamic> updates) async {
    try {
      final data = await _apiClient.put(
        'catalogo/elementos/$elementoId',
        updates,
      );

      final entradaActualizada = CatalogoEntrada.fromJson(data);
      final index = _entradas.indexWhere((e) => e.elementoId == elementoId);

      if (index != -1) {
        _entradas[index] = entradaActualizada;
        notifyListeners();
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error al actualizar entrada: $e');
    }
  }

  /// Alterna el estado de favorito.
  Future<void> toggleFavorite(int elementoId) async {
    // Encontramos la entrada localmente
    final index = _entradas.indexWhere((e) => e.elementoId == elementoId);

    if (index != -1) {
      // Optimistic Update: Cambiamos localmente primero
      final originalState = _entradas[index].esFavorito;
      _entradas[index] = _entradas[index].copyWith(esFavorito: !originalState);
      notifyListeners();

      try {
        await _apiClient.put('catalogo/favorito/$elementoId', {});
      } catch (e) {
        // Revertir en caso de error
        _entradas[index] = _entradas[index].copyWith(esFavorito: originalState);
        notifyListeners();
        rethrow;
      }
    } else {
      // Si no está en el catálogo local, llamamos al servidor para que lo cree y añada
      // Luego recargamos el catálogo para sincronizar
      try {
        await _apiClient.put('catalogo/favorito/$elementoId', {});
        await fetchCatalog(); // Recarga completa necesaria para obtener la nueva entrada
      } catch (e) {
        rethrow;
      }
    }
  }

  /// Verifica si un elemento está en el catálogo local.
  bool isEnCatalogo(int elementoId) {
    return _entradas.any((e) => e.elementoId == elementoId);
  }

  /// Obtiene la entrada de catálogo para un elemento dado (si existe).
  CatalogoEntrada? getEntradaPorElementoId(int elementoId) {
    try {
      return _entradas.firstWhere((e) => e.elementoId == elementoId);
    } catch (e) {
      return null;
    }
  }
}
