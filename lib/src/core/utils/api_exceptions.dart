/// Clase base para todas las excepciones de la API.
class ApiException implements Exception {
  final String message;
  final String? code;

  ApiException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Error de conexión (sin internet, timeout).
class ConnectionException extends ApiException {
  ConnectionException(super.message) : super(code: 'CONNECTION_ERROR');
}

/// Error 400 Bad Request (Validaciones fallidas).
class BadRequestException extends ApiException {
  final Map<String, dynamic>? fieldErrors;

  BadRequestException(super.message, [this.fieldErrors])
      : super(code: 'VALIDATION_ERROR');
}

/// Error 401/403 (No autorizado o Token expirado).
class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message) : super(code: 'UNAUTHORIZED');
}

/// Error 404 Not Found.
class NotFoundException extends ApiException {
  NotFoundException(super.message) : super(code: 'NOT_FOUND');
}

/// Error 409 Conflict (Duplicados, estado incorrecto).
class ConflictException extends ApiException {
  ConflictException(super.message) : super(code: 'CONFLICT');
}

/// Error 500 Internal Server Error.
class ServerException extends ApiException {
  ServerException(super.message) : super(code: 'SERVER_ERROR');
}
