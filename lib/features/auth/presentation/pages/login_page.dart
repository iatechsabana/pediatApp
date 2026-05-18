import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_config.dart';
import '../providers/auth_provider.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart' as dashboard;
import '../../../dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../../dashboard/presentation/pages/pediatrician_dashboard_page.dart';
import 'register_page.dart';

String _authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet.';
      default:
        return 'Ocurrió un error. Inténtalo de nuevo.';
    }
  }
  // Mensajes lanzados desde el repositorio (estado pendiente / no habilitado)
  if (error is Exception) {
    final msg = error.toString().replaceFirst('Exception: ', '');
    if (msg.isNotEmpty) return msg;
  }
  return 'Ocurrió un error inesperado.';
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = await ref.read(authControllerProvider).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final Widget nextPage = switch (user.type) {
        'admin' => AdminDashboardPage(),
        'pediatra' => const PediatricianDashboardPage(),
        _ => const dashboard.DashboardPage(),
      };

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => nextPage),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authErrorMessage(e)),
          duration: AppConfig.errorSnackbarDuration,
        ),
      );
    }
  }

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
                vertical: AppDimens.paddingHuge,
              ),
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
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.inputFill,
                              hintText: 'tucorreo@ejemplo.com',
                              hintStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa tu email';
                              final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
                              return emailRegex.hasMatch(v) ? null : 'Email inválido';
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.inputFill,
                              hintText: 'Contraseña',
                              hintStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white70,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                              if (v.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: AppColors.primary)
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
                                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                                  );
                                },
                                child: const Text(
                                  'Regístrate',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
