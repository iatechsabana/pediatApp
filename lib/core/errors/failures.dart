abstract class Failure {
  final String message;
  final String? code;

  Failure(this.message, {this.code});
}

class AuthFailure extends Failure {
  AuthFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  NetworkFailure(super.message, {super.code});
}