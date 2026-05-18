import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/constants/firebase_paths.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserModel> signInAndGetUser({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final doc = await _firestore.collection(FirebasePaths.users).doc(uid).get();

    if (!doc.exists) {
      await _auth.signOut();
      throw Exception('No se encontró información de usuario.');
    }

    final user = UserModel.fromFirestore(uid, doc.data()!);

    if (!user.isEnabled) {
      await _auth.signOut();
      throw Exception(
        user.isPending
            ? 'Tu cuenta está pendiente de habilitación.'
            : 'Tu cuenta no está habilitada para acceder.',
      );
    }

    await _savePrefs(user);
    return user;
  }

  @override
  Future<void> registerUser(RegisterData data) async {
    final userType = data.isPediatrician ? 'pediatra' : 'usuario';
    final estado = data.isPediatrician ? 'pendiente' : 'habilitado';

    final cred = await _auth.createUserWithEmailAndPassword(
      email: data.email,
      password: data.password,
    );

    await _firestore.collection(FirebasePaths.users).doc(cred.user!.uid).set({
      'name': data.name,
      'email': data.email,
      'phone': data.phone,
      'type': userType,
      'estado': estado,
      'address': data.address,
      'birthDate': data.birthDate.toIso8601String(),
      if (data.isPediatrician) ...{
        'country': data.country,
        'workAddress': data.workAddress,
        'startDate': data.startDate?.toIso8601String(),
        'polizaUrl': data.polizaUrl,
        'tarjetaProfesionalUrl': data.tarjetaProfesionalUrl,
        'documentoIdentidadFrenteUrl': data.documentoIdentidadFrenteUrl,
        'documentoIdentidadReversoUrl': data.documentoIdentidadReversoUrl,
      },
    });

    // Cerrar sesión para que el usuario inicie explícitamente
    await _auth.signOut();
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _savePrefs(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', user.uid);
    await prefs.setString('email', user.email);
    await prefs.setString('name', user.name);
    await prefs.setString('type', user.type);
  }
}
