import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/document_picker_stub.dart';
import 'dart:typed_data';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/constants/app_text_styles.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

enum AccountType { user, pediatrician }

class _RegisterPageState extends State<RegisterPage> {
  int _step = 0;

  // Documentos
  List<String> _documents = [];

  // Agrega variables para el archivo seleccionado
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;

  void _nextStep() {
    if (_step < 2) setState(() => _step++);
  }

  void _prevStep() {
    if (_step > 0) setState(() => _step--);
  }

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Pediatrician
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
      // Crear usuario
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Datos para Firestore
      final Map<String, dynamic> data = {
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
          'documents': _documents,
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set(data);

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Registro exitoso: ${data['type']} - ${data['email']}"),
          duration: AppConfig.snackbarDuration,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context);

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          duration: AppConfig.errorSnackbarDuration,
        ),
      );
    }
  }

  Future<void> _pickAndUploadDocument() async {
    final picked = await pickDocument();
    if (picked == null) return;
    final fileName = picked.name;
    final fileBytes = picked.bytes;
    final maxSize = 5 * 1024 * 1024; // 5MB
    if (fileBytes.length > maxSize) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El archivo supera el límite de 5MB o es inválido')));
      return;
    }
    final storageRef = FirebaseStorage.instance.ref().child('certifications/${DateTime.now().millisecondsSinceEpoch}_$fileName');
    await storageRef.putData(fileBytes);
    final url = await storageRef.getDownloadURL();
    setState(() => _documents.add(url));
    setState(() {
      _selectedFileName = fileName;
      _selectedFileBytes = fileBytes;
    });
  }

  Widget _pediatricianFields() {
    return Column(
      children: [
        const SizedBox(height: AppDimens.paddingMedium),
        TextFormField(
          controller: _clinicController,
          style: AppTextStyles.formFieldText,
          decoration: _input("Nombre de la clínica", Icons.location_city),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ingresa el nombre de la clínica';
            return null;
          },
        ),
        const SizedBox(height: AppDimens.paddingMedium),
        TextFormField(
          controller: _licenseController,
          style: AppTextStyles.formFieldText,
          decoration: _input("Número de licencia", Icons.badge_outlined),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ingresa la licencia';
            return null;
          },
        ),
        const SizedBox(height: AppDimens.paddingMedium),
        TextFormField(
          controller: _specialtyController,
          style: AppTextStyles.formFieldText,
          decoration: _input("Especialidad", Icons.medical_services_outlined),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ingresa una especialidad';
            return null;
          },
        ),
        const SizedBox(height: AppDimens.paddingMedium),
        TextFormField(
          controller: _addressController,
          style: AppTextStyles.formFieldText,
          decoration: _input("Dirección de trabajo", Icons.map_outlined),
        ),
        const SizedBox(height: AppDimens.paddingMedium),
        TextFormField(
          controller: _experienceController,
          style: AppTextStyles.formFieldText,
          keyboardType: TextInputType.number,
          decoration: _input("Años de experiencia", Icons.schedule),
        ),
      ],
    );
  }

  InputDecoration _input(String hint, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.inputFill,
      hintText: hint,
      hintStyle: AppTextStyles.formFieldHint,
      prefixIcon: Icon(icon, color: AppColors.inputIcon),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingLarge, vertical: AppDimens.verticalPadding),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("Registro"),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryLight, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingXLarge),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: mq.width > 500 ? 500 : mq.width,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Image.asset('assets/images/doctorkids_logo.png', height: 170),
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

                      const SizedBox(height: 18),

                      // Tipo de cuenta
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ToggleButtons(
                          borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge),
                          borderColor: AppColors.primary,
                          selectedBorderColor: AppColors.primary,
                          fillColor: AppColors.primary,
                          selectedColor: Colors.white,
                          color: AppColors.primary,
                          constraints: const BoxConstraints(minWidth: 120, minHeight: 40),
                          isSelected: [
                            _accountType == AccountType.user,
                            _accountType == AccountType.pediatrician,
                          ],
                          onPressed: (index) {
                            setState(() {
                              _accountType = index == 0 ? AccountType.user : AccountType.pediatrician;
                              _step = 0;
                            });
                          },
                          children: const [
                            Text('Usuario', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Montserrat', fontSize: 16)),
                            Text('Pediatra', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Montserrat', fontSize: 16)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Formulario Usuario
                      if (_accountType == AccountType.user) ...[
                        _fieldName(),
                        _fieldEmail(),
                        _fieldPassword(),
                        _fieldPhone(),
                        const SizedBox(height: 20),
                        _submitButton("Registrar"),
                      ],

                      // Formulario Pediatra por pasos
                      if (_accountType == AccountType.pediatrician) ...[
                        _step == 0 ? _stepP1() : const SizedBox(),
                        _step == 1 ? _pediatricianFields() : const SizedBox(),
                        _step == 2 ? _stepP3() : const SizedBox(),

                        const SizedBox(height: 20),

                        // Botones navegación
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_step > 0)
                              ElevatedButton.icon(
                                onPressed: _prevStep,
                                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                                label: const Text("Anterior", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Montserrat', color: AppColors.primary)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textWhite,
                                  foregroundColor: AppColors.primary,
                                  elevation: AppDimens.elevationMedium,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge)),
                                ),
                              ),
                            if (_step < 2)
                              ElevatedButton.icon(
                                onPressed: _nextStep,
                                icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
                                label: const Text("Siguiente", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Montserrat', color: AppColors.primary)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textWhite,
                                  foregroundColor: AppColors.primary,
                                  elevation: AppDimens.elevationMedium,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge)),
                                ),
                              ),
                          ],
                        ),
                      ],
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

  // -----------------------------
  // CAMPOS REUTILIZABLES
  // -----------------------------

  Widget _fieldName() => TextFormField(
        controller: _nameController,
        style: AppTextStyles.formFieldText,
        decoration: _input("Nombre completo", Icons.person),
        validator: (v) => v!.isEmpty ? "Ingresa tu nombre" : null,
      );

  Widget _fieldEmail() => TextFormField(
        controller: _emailController,
        style: AppTextStyles.formFieldText,
        decoration: _input("Correo electrónico", Icons.email),
        validator: (v) => v!.contains("@") ? null : "Correo inválido",
      );

  Widget _fieldPassword() => TextFormField(
        controller: _passwordController,
        obscureText: _obscure,
        style: AppTextStyles.formFieldText,
        decoration: _input("Contraseña", Icons.lock).copyWith(
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: AppColors.inputIcon),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        validator: (v) => v!.length < 6 ? "Mínimo 6 caracteres" : null,
      );

  Widget _fieldPhone() => TextFormField(
        controller: _phoneController,
        style: AppTextStyles.formFieldText,
        decoration: _input("Teléfono", Icons.phone),
        validator: (v) => v!.isEmpty ? "Ingresa tu teléfono" : null,
      );

  Widget _submitButton(String text) => SizedBox(
        height: AppDimens.buttonHeight,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textWhite,
            foregroundColor: AppColors.primary,
            elevation: AppDimens.elevationLarge,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge)),
          ),
          child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
            : Text(text, style: AppTextStyles.buttonText),
        ),
      );

  // -----------------------------
  // PASOS FORMULARIO PEDIATRA
  // -----------------------------

  Widget _stepP1() {
    return Column(
      children: [
        _fieldName(),
        _fieldEmail(),
        _fieldPassword(),
        _fieldPhone(),
        const SizedBox(height: AppDimens.paddingMedium),
      ],
    );
  }

  Widget _stepP3() {
    return Column(
      children: [
        const Text(
          "Documentos de certificación",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Montserrat', shadows: [Shadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 4)]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        if (_selectedFileName != null) ...[
          Card(
            color: AppColors.inputFill,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: const Icon(Icons.insert_drive_file, color: AppColors.inputIcon, size: 20),
              title: Text(
                _selectedFileName!,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Montserrat',
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                onPressed: () => setState(() {
                  _selectedFileName = null;
                  _selectedFileBytes = null;
                }),
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.cloud_upload, color: AppColors.inputIcon),
            label: Text("Subir documento", style: AppTextStyles.buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textWhite,
              foregroundColor: AppColors.primary,
              elevation: AppDimens.elevationLarge,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge)),
            ),
            onPressed: () {
              if (_selectedFileName != null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona y sube un archivo primero')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un archivo primero')));
              }
            },
          ),
        ] else ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file, color: AppColors.inputIcon),
            label: Text("Seleccionar documento", style: AppTextStyles.buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textWhite,
              foregroundColor: AppColors.primary,
              elevation: AppDimens.elevationLarge,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge)),
            ),
            onPressed: _pickAndUploadDocument,
          ),
        ],
        const SizedBox(height: 10),
        ..._documents.map(
          (d) => ListTile(
            leading: const Icon(Icons.insert_drive_file, color: AppColors.inputIcon),
            title: Text(d, style: AppTextStyles.formFieldText),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => setState(() => _documents.remove(d)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _submitButton("Guardar y validar"),
      ],
    );
  }
}
