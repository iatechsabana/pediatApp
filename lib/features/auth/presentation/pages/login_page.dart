import 'package:flutter/material.dart';

import 'register_page.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart' as dashboard;
import '../../../dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../../dashboard/presentation/pages/pediatrician_dashboard_page.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_config.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// ==========================================================
  /// LOGIN
  /// ==========================================================
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      // 1. Login con Firebase Auth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Obtener documento desde Firestore (tu ID = UID)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        if (mounted) setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró información de usuario.'),
            duration: AppConfig.errorSnackbarDuration,
          ),
        );
        return;
      }

      final userData = userDoc.data()!;

      // 3. Normalizar tipo de usuario (ARREGLADO)
      String tipoRaw = (userData['type'] ?? '')
          .toString()
          .toLowerCase()
          .trim();

      // Normalización completa
      tipoRaw = tipoRaw
          .replaceAll('á', 'a')
          .replaceAll('é', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u')
          .replaceAll(RegExp(r'[^a-z]'), ''); // Elimina espacios/tildes/símbolos

      String tipo = 'usuario'; // por defecto

      if (tipoRaw == 'admin') {
        tipo = 'admin';
      } else if (tipoRaw.startsWith('pediatra')) {
        tipo = 'pediatra';
      }

      // 4. Guardar datos del usuario en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', credential.user!.uid);
      await prefs.setString('email', userData['email'] ?? '');
      await prefs.setString('name', userData['name'] ?? '');
      await prefs.setString('type', tipo);

      if (mounted) setState(() => _isLoading = false);

      // 5. Navegación correcta según tipo
      Widget nextPage;

      if (tipo == 'admin') {
        nextPage = AdminDashboardPage();
      } else if (tipo == 'pediatra') {
        nextPage = const PediatricianDashboardPage();
      } else {
        nextPage = const dashboard.DashboardPage();
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => nextPage),
        (route) => false,
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: AppConfig.errorSnackbarDuration,
        ),
      );
    }
  }

  /// ==========================================================
  /// UI
  /// ==========================================================
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.primary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingXXLarge,
                  vertical: AppDimens.paddingHuge),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: mq.width > AppDimens.maxContentWidth
                      ? AppDimens.maxContentWidth
                      : mq.width,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),

                    Image.asset(
                      'assets/images/doctorkids_logo.png',
                      height: 170,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Bienvenido de nuevo',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Inicia sesión para continuar',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          /// EMAIL
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.inputFill,
                              hintText: 'tucorreo@ejemplo.com',
                              hintStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimens.borderRadiusLarge),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Ingresa tu email';
                              }
                              if (!v.contains('@')) {
                                return 'Email inválido';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          /// PASSWORD
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.inputFill,
                              hintText: 'Contraseña',
                              hintStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimens.borderRadiusLarge),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() => _obscure = !_obscure);
                                },
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Ingresa tu contraseña';
                              }
                              if (v.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 40),

                          /// BOTÓN LOGIN
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimens.borderRadiusXLarge),
                              ),
                              minimumSize:
                                  const Size(double.infinity, 50),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: AppColors.primary)
                                : const Text('Iniciar sesión'),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '¿No tienes cuenta?',
                                style: TextStyle(color: Colors.white),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const RegisterPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Regístrate',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
