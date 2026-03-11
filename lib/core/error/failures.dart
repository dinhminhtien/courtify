abstract class Failure {
  final String message;
  Failure(this.message);
}

class ValidationFailure extends Failure {
  ValidationFailure(super.message);
}

class ServerFailure extends Failure {
  ServerFailure(super.message);
}

class CacheFailure extends Failure {
  CacheFailure(super.message);
}
