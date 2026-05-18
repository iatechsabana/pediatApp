import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authControllerProvider = Provider((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController {
  final AuthRepository _repository;

  AuthController(this._repository);

  /// Retorna el [UserModel] del usuario autenticado.
  /// Lanza [Exception] con mensaje en español si las credenciales o el estado son inválidos.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) {
    return _repository.signInAndGetUser(email: email, password: password);
  }

  Future<void> register(RegisterData data) {
    return _repository.registerUser(data);
  }

  Future<void> signOut() {
    return _repository.signOut();
  }
}
