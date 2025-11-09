abstract class Failure {
  final String message;
  final String? code;

  Failure(this.message, {this.code});
}

class AuthFailure extends Failure {
  AuthFailure(String message, {String? code}) : super(message, code: code);
}

class NetworkFailure extends Failure {
  NetworkFailure(String message, {String? code}) : super(message, code: code);
}