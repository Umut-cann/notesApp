// Core failure class for domain layer
abstract class Failure {
  final String message;
  
  Failure(this.message);
}

// Server related failures
class ServerFailure extends Failure {
  ServerFailure(String message) : super(message);
}

// Cache related failures
class CacheFailure extends Failure {
  CacheFailure(String message) : super(message);
}

// Local database failures
class DatabaseFailure extends Failure {
  DatabaseFailure(String message) : super(message);
}

// General app failures
class AppFailure extends Failure {
  AppFailure(String message) : super(message);
}

// Permission related failures
class PermissionFailure extends Failure {
  PermissionFailure(String message) : super(message);
}
