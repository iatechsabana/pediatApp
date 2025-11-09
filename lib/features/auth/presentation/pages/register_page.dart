import 'package:flutter/material.dart';

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

  static const Color baseColor = Color(0xFFFF8A6B);

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
    await Future.delayed(const Duration(seconds: 2));

    final data = {
      'type': _accountType == AccountType.user ? 'Usuario' : 'Pediatra',
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

    if (!mounted) return;
    setState(() => _isLoading = false);
    // For now show a summary SnackBar. In production you'd send this to backend.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Registro simulado: ${data['type']} - ${data['email']}'),
      duration: const Duration(seconds: 3),
    ));

    // print collected data to console for developer
    // ignore: avoid_print
    print('Registro simulado datos: $data');
  }

  Widget _pediatricianFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        TextFormField(
          controller: _clinicController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white24,
            hintText: 'Nombre de la clínica',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.location_city, color: Colors.white),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: (v) {
            if (_accountType == AccountType.pediatrician && (v == null || v.isEmpty)) return 'Ingresa el nombre de la clínica';
            return null;
          },
        ),

        const SizedBox(height: 12),
        TextFormField(
          controller: _licenseController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white24,
            hintText: 'Número de licencia profesional',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.badge_outlined, color: Colors.white),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: (v) {
            if (_accountType == AccountType.pediatrician && (v == null || v.isEmpty)) return 'Ingresa número de licencia';
            return null;
          },
        ),

        const SizedBox(height: 12),
        TextFormField(
          controller: _specialtyController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white24,
            hintText: 'Especialidad (p. ej. Neonatología)',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.medical_services_outlined, color: Colors.white),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: (v) {
            if (_accountType == AccountType.pediatrician && (v == null || v.isEmpty)) return 'Ingresa especialidad';
            return null;
          },
        ),

        const SizedBox(height: 12),
        TextFormField(
          controller: _addressController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white24,
            hintText: 'Dirección de trabajo',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.map_outlined, color: Colors.white),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),

        const SizedBox(height: 12),
        TextFormField(
          controller: _experienceController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white24,
            hintText: 'Años de experiencia',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.schedule, color: Colors.white),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
        backgroundColor: baseColor,
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
            colors: [Color(0xFFFFF0EB), baseColor],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: mq.width > 700 ? 700 : mq.width),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const Text('Crear cuenta', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text('Elige tipo de cuenta y completa los datos', style: TextStyle(color: Colors.white70)),

                      const SizedBox(height: 16),
                      // Account type toggle
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _accountType = AccountType.user),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _accountType == AccountType.user ? Colors.white24 : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: const Center(child: Text('Usuario', style: TextStyle(color: Colors.white))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _accountType = AccountType.pediatrician),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _accountType == AccountType.pediatrician ? Colors.white24 : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: const Center(child: Text('Pediatra', style: TextStyle(color: Colors.white))),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Common fields
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white24,
                          hintText: 'Nombre completo',
                          hintStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.white),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu nombre' : null,
                      ),

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white24,
                          hintText: 'tucorreo@ejemplo.com',
                          hintStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.white),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu email';
                          if (!v.contains('@')) return 'Email inválido';
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white24,
                          hintText: 'Contraseña',
                          hintStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white24,
                          hintText: 'Teléfono (opcional)',
                          hintStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.phone_outlined, color: Colors.white),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),

                      // Pediatrician extra fields
                      if (_accountType == AccountType.pediatrician) _pediatricianFields(),

                      const SizedBox(height: 18),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: baseColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: baseColor, strokeWidth: 2)) : const Text('Crear cuenta', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Center(child: Text('Al registrarte aceptas los términos', style: TextStyle(color: Colors.white70))),
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
