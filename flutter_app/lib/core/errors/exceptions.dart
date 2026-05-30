class AppException implements Exception {
  final String message;
  final String? code;
  const AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: $message${code != null ? " ($code)" : ""}';
}

class AuthException      extends AppException { const AuthException(super.message, [super.code]); }
class NetworkException   extends AppException { const NetworkException(super.message, [super.code]); }
class ServerException    extends AppException { const ServerException(super.message, [super.code]); }
class PaymentException   extends AppException { const PaymentException(super.message, [super.code]); }
class EscrowException    extends AppException { const EscrowException(super.message, [super.code]); }
class StorageException   extends AppException { const StorageException(super.message, [super.code]); }
class ValidationException extends AppException { const ValidationException(super.message, [super.code]); }
class InsufficientFundsException extends AppException {
  final int required;
  final int available;
  InsufficientFundsException(this.required, this.available)
      : super('Insufficient balance. Required: $required AXC, Available: $available AXC');
}
