abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message';
}

class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'DatabaseException: $message';
}

class FileImportException extends AppException {
  const FileImportException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'FileImportException: $message';
}

class ValidationException extends AppException {
  final Map<String, String> fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors = const {},
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'ValidationException: $message';
}

class PermissionException extends AppException {
  const PermissionException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'PermissionException: $message';
}
