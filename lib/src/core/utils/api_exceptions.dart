class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

class ConnectionException extends ApiException {
  ConnectionException(super.message);
}

class BadRequestException extends ApiException {
  final Map<String, dynamic>? errors;

  BadRequestException(super.message, [this.errors]);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class ConflictException extends ApiException {
  ConflictException(super.message);
}

class ServerException extends ApiException {
  ServerException(super.message);
}
