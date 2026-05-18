import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;

  /// Autentica al usuario y retorna sus datos de Firestore.
  /// Lanza [Exception] con mensaje legible si el estado no es 'habilitado'.
  Future<UserModel> signInAndGetUser({
    required String email,
    required String password,
  });

  /// Crea la cuenta en Firebase Auth y guarda el documento en Firestore.
  Future<void> registerUser(RegisterData data);

  Future<void> signOut();
}
