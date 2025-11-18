import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

enum AccountType { user, pediatrician }

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Pediatrician extra fields
  final _clinicController = TextEditingController();
  final _licenseController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _addressController = TextEditingController();
  final _experienceController = TextEditingController();

  AccountType _accountType = AccountType.user;
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _clinicController.dispose();
    _licenseController.dispose();
    _specialtyController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // 1. Crear usuario en Firebase Auth
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Preparar datos para Firestore
      final data = {
        'uid': credential.user?.uid,
        'type': _accountType == AccountType.user ? 'usuario' : 'pediatra',
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
      if (_accountType == AccountType.pediatrician) {
        data.addAll({
          'clinic': _clinicController.text.trim(),
          'license': _licenseController.text.trim(),
          'specialty': _specialtyController.text.trim(),
          'address': _addressController.text.trim(),
          'experience': _experienceController.text.trim(),
        });
      }

      // 3. Guardar datos en Firestore
      await FirebaseFirestore.instance.collection('users').doc(credential.user?.uid).set(data);

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Registro exitoso: ${data['type']} - ${data['email']}'),
        duration: AppConfig.snackbarDuration,
      ));
      // Redirigir al login después de registro exitoso
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop(); // Vuelve a la pantalla anterior (login)
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

  Widget _pediatricianFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDimens.paddingMedium),
        TextFormField(
          controller: _clinicController,
          style: AppTextStyles.formFieldText,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFill,
            hintText: 'Nombre de la clínica',
            hintStyle: AppTextStyles.formFieldHint,
            prefixIcon: const Icon(Icons.location_city, color: AppColors.inputIcon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge), borderSide: BorderSide.none),
          ),
          validator: (v) {
            if (_accountType == AccountType.pediatrician && (v == null || v.isEmpty)) return 'Ingresa el nombre de la clínica';
            return null;
          },
        ),

        const SizedBox(height: AppDimens.paddingMedium),
        TextFormField(
          controller: _licenseController,
          style: AppTextStyles.formFieldText,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFill,
            hintText: 'Número de licencia profesional',
            hintStyle: AppTextStyles.formFieldHint,
            prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.inputIcon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge), borderSide: BorderSide.none),
          ),
          validator: (v) {
            if (_accountType == AccountType.pediatrician && (v == null || v.isEmpty)) return 'Ingresa número de licencia';
            return null;
          },
        ),

        const SizedBox(height: AppDimens.paddingMedium),
        TextFormField(
          controller: _specialtyController,
          style: AppTextStyles.formFieldText,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFill,
            hintText: 'Especialidad (p. ej. Neonatología)',
            hintStyle: AppTextStyles.formFieldHint,
            prefixIcon: const Icon(Icons.medical_services_outlined, color: AppColors.inputIcon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge), borderSide: BorderSide.none),
          ),
          validator: (v) {
            if (_accountType == AccountType.pediatrician && (v == null || v.isEmpty)) return 'Ingresa especialidad';
            return null;
          },
        ),

        const SizedBox(height: AppDimens.paddingMedium),
        TextFormField(
          controller: _addressController,
          style: AppTextStyles.formFieldText,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFill,
            hintText: 'Dirección de trabajo',
            hintStyle: AppTextStyles.formFieldHint,
            prefixIcon: const Icon(Icons.map_outlined, color: AppColors.inputIcon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge), borderSide: BorderSide.none),
          ),
        ),

        const SizedBox(height: AppDimens.paddingMedium),
        TextFormField(
          controller: _experienceController,
          keyboardType: TextInputType.number,
          style: AppTextStyles.formFieldText,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFill,
            hintText: 'Años de experiencia',
            hintStyle: AppTextStyles.formFieldHint,
            prefixIcon: const Icon(Icons.schedule, color: AppColors.inputIcon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Registro'),
        elevation: 0,
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingXLarge, vertical: AppDimens.paddingXLarge),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: mq.width > AppDimens.maxContentWidth ? AppDimens.maxContentWidth : mq.width),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      // Logo de la app
                      Image.asset(
                        'assets/images/doctorkids_logo.png',
                        height: 170,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Crear cuenta',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimens.paddingSmall),
                      const Text(
                        'Elige tipo de cuenta y completa los datos',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Montserrat',
                          letterSpacing: 0.2,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimens.paddingLarge),
                      // Account type toggle
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _accountType = AccountType.user),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingMedium),
                                decoration: BoxDecoration(
                                  color: _accountType == AccountType.user ? AppColors.inputFill : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppDimens.borderRadiusMedium),
                                  border: Border.all(color: AppColors.inputFillDark),
                                ),
                                child: const Center(child: Text('Usuario', style: AppTextStyles.subtitle2White)),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimens.paddingMedium),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _accountType = AccountType.pediatrician),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingMedium),
                                decoration: BoxDecoration(
                                  color: _accountType == AccountType.pediatrician ? AppColors.inputFill : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppDimens.borderRadiusMedium),
                                  border: Border.all(color: AppColors.inputFillDark),
                                ),
                                child: const Center(child: Text('Pediatra', style: AppTextStyles.subtitle2White)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppDimens.paddingLarge),

                      // Common fields
                      TextFormField(
                        controller: _nameController,
                        style: AppTextStyles.formFieldText,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.inputFill,
                          hintText: 'Nombre completo',
                          hintStyle: AppTextStyles.formFieldHint,
                          prefixIcon: const Icon(Icons.person_outline, color: AppColors.inputIcon),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge), borderSide: BorderSide.none),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu nombre' : null,
                      ),

                      const SizedBox(height: AppDimens.paddingMedium),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge), borderSide: BorderSide.none),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu email';
                          if (!v.contains('@')) return 'Email inválido';
                          return null;
                        },
                      ),

                      const SizedBox(height: AppDimens.paddingMedium),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge), borderSide: BorderSide.none),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                          if (v.length < AppConfig.minPasswordLength) return 'Mínimo ${AppConfig.minPasswordLength} caracteres';
                          return null;
                        },
                      ),

                      const SizedBox(height: AppDimens.paddingMedium),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: AppTextStyles.formFieldText,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.inputFill,
                          hintText: 'Teléfono (opcional)',
                          hintStyle: AppTextStyles.formFieldHint,
                          prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.inputIcon),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge), borderSide: BorderSide.none),
                        ),
                      ),

                      // Pediatrician extra fields
                      if (_accountType == AccountType.pediatrician) _pediatricianFields(),

                      const SizedBox(height: AppDimens.paddingXLarge),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.textWhite,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge)),
                          ),
                          child: _isLoading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)) : const Text('Crear cuenta', style: AppTextStyles.buttonText),
                        ),
                      ),

                      const SizedBox(height: AppDimens.paddingMedium),
                      const Center(child: Text('Al registrarte aceptas los términos', style: AppTextStyles.captionWhite)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
