import 'package:flutter/material.dart';

import 'register_page.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // 1. Login con Firebase Auth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Obtener datos del usuario desde Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(credential.user?.uid).get();
      if (!userDoc.exists) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se encontró información de usuario.'),
          duration: AppConfig.errorSnackbarDuration,
        ));
        return;
      }
      final userData = userDoc.data();
      final tipo = userData?['type'] ?? 'usuario';

      // Guardar datos del usuario en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', credential.user?.uid ?? '');
      await prefs.setString('email', userData?['email'] ?? '');
      await prefs.setString('name', userData?['name'] ?? '');
      await prefs.setString('type', tipo);

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bienvenido, tipo: $tipo'),
        duration: AppConfig.snackbarDuration,
      ));
      // Navegar a dashboard según tipo de usuario
      if (mounted) {
        if (tipo == 'pediatra') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const PediatricianDashboardPage()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.message}'),
        duration: AppConfig.errorSnackbarDuration,
      ));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error inesperado: $e'),
        duration: AppConfig.errorSnackbarDuration,
      ));
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
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingXXLarge, vertical: AppDimens.paddingHuge),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: mq.width > AppDimens.maxContentWidth ? AppDimens.maxContentWidth : mq.width),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Encabezado
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppDimens.paddingSmall),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.inputFill,
                          ),
                          child: const Icon(Icons.local_hospital_rounded, size: AppDimens.iconSizeXLarge, color: AppColors.inputIcon),
                        ),
                        const SizedBox(width: AppDimens.paddingMedium),
                        const Expanded(
                          child: Text(
                            'Bienvenido de nuevo',
                            style: AppTextStyles.heading2White,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimens.paddingXLarge),

                    Text('Inicia sesión para continuar', style: AppTextStyles.subtitle2White),
                    const SizedBox(height: AppDimens.paddingXLarge),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: AppTextStyles.formFieldText,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.inputFill,
                              hintText: 'tucorreo@ejemplo.com',
                              hintStyle: AppTextStyles.formFieldHint,
                              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.inputIcon),
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingLarge, vertical: AppDimens.verticalPadding),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge), borderSide: BorderSide.none),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa tu email';
                              if (!v.contains('@')) return 'Email inválido';
                              return null;
                            },
                          ),

                          const SizedBox(height: AppDimens.paddingMedium),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            style: AppTextStyles.formFieldText,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.inputFill,
                              hintText: 'Contraseña',
                              hintStyle: AppTextStyles.formFieldHint,
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.inputIcon),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.inputIcon),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingLarge, vertical: AppDimens.verticalPadding),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge), borderSide: BorderSide.none),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                              if (v.length < AppConfig.minPasswordLength) return 'Mínimo ${AppConfig.minPasswordLength} caracteres';
                              return null;
                            },
                          ),

                          const SizedBox(height: AppDimens.paddingXLarge),

                          // Botón
                          SizedBox(
                            height: AppDimens.buttonHeight,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.textWhite,
                                foregroundColor: AppColors.primary,
                                elevation: AppDimens.elevationLarge,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge)),
                              ),
                              child: _isLoading
                                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                                  : const Text('Iniciar sesión', style: AppTextStyles.buttonText),
                            ),
                          ),

                          const SizedBox(height: AppDimens.paddingMedium),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('¿No tienes cuenta?', style: AppTextStyles.subtitle2White),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPage()));
                                },
                                child: const Text('Regístrate', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textWhite)),
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