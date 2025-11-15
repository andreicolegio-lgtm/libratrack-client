// Archivo: lib/src/core/utils/api_exceptions.dart
// (¡CORREGIDO con Super Parameters de Dart 3!)

/// Excepción base para todos los errores relacionados con la API.
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

/// Lanzada para errores de red o conexión (ej. sin internet, DNS no encontrado).
class ConnectionException extends ApiException {
  // ¡CORREGIDO! Se usa 'super.message'
  ConnectionException(super.message);
}

/// Lanzada para errores 400 (Bad Request).
/// Típicamente usado para errores de validación del formulario.
class BadRequestException extends ApiException {
  /// Un mapa que puede contener detalles de los campos que fallaron.
  final Map<String, dynamic>? errors;

  // ¡CORREGIDO! Se usa 'super.message'
  BadRequestException(super.message, [this.errors]);
}

/// Lanzada para errores 401 (Unauthorized) y 403 (Forbidden).
/// Indica que el usuario debe volver a iniciar sesión o no tiene permisos.
class UnauthorizedException extends ApiException {
  // ¡CORREGIDO! Se usa 'super.message'
  UnauthorizedException(super.message);
}

/// Lanzada para errores 404 (Not Found).
class NotFoundException extends ApiException {
  // ¡CORREGIDO! Se usa 'super.message'
  NotFoundException(super.message);
}

/// Lanzada para errores 409 (Conflict).
/// Indica que el recurso ya existe (ej. email duplicado).
class ConflictException extends ApiException {
  // ¡CORREGIDO! Se usa 'super.message'
  ConflictException(super.message);
}

/// Lanzada para errores 500 (Internal Server Error) o cualquier otro
/// error inesperado del lado del servidor.
class ServerException extends ApiException {
  // ¡CORREGIDO! Se usa 'super.message'
  ServerException(super.message);
}