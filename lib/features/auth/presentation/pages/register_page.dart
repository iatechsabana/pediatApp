import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/document_picker_stub.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'login_page.dart';

// =======================================================
// CLASE AUXILIAR PARA DOCUMENTOS
// =======================================================

class _DocumentoItem {
  final String nombre;
  final String? url;
  final bool obligatorio;
  final Future<void> Function()? onUpload;
  final VoidCallback? onDelete;

  const _DocumentoItem({
    required this.nombre,
    required this.url,
    required this.obligatorio,
    this.onUpload,
    this.onDelete,
  });
}

// =======================================================
// MÉTODOS GLOBALES PARA SUBIDA DE DOCUMENTOS
// =======================================================

Future<void> _pickAndUploadPoliza(
  BuildContext context,
  Function(String) setPolizaUrl,
) async {
  final picked = await pickDocument();
  if (picked == null) return;

  final fileName = picked.name;
  final fileBytes = picked.bytes;
  final maxSize = 5 * 1024 * 1024;

  if (fileBytes.length > maxSize) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El archivo supera el límite de 5MB o es inválido'),
      ),
    );
    return;
  }

  final storageRef = FirebaseStorage.instance.ref().child(
    'polizas/${DateTime.now().millisecondsSinceEpoch}_$fileName',
  );

  await storageRef.putData(fileBytes);
  final url = await storageRef.getDownloadURL();
  setPolizaUrl(url);
}

Future<void> _pickAndUploadTarjetaProfesional(
  BuildContext context,
  Function(String) setTarjetaProfesionalUrl,
) async {
  final picked = await pickDocument();
  if (picked == null) return;

  final fileName = picked.name;
  final fileBytes = picked.bytes;
  final maxSize = 5 * 1024 * 1024;

  if (fileBytes.length > maxSize) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El archivo supera el límite de 5MB o es inválido'),
      ),
    );
    return;
  }

  final storageRef = FirebaseStorage.instance.ref().child(
    'tarjetas_profesional/${DateTime.now().millisecondsSinceEpoch}_$fileName',
  );

  await storageRef.putData(fileBytes);
  final url = await storageRef.getDownloadURL();
  setTarjetaProfesionalUrl(url);
}

// =======================================================
// PANTALLA DE REGISTRO
// =======================================================

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

enum AccountType { user, pediatrician }

class _RegisterPageState extends State<RegisterPage> {
  Future<void> launchUrlCustom(Uri url) async {
    if (await url_launcher.canLaunch(url.toString())) {
      await url_launcher.launch(url.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }

  bool _dataTreatmentAccepted = false;
  int _step = 0;
  bool _obscure = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _experienceController = TextEditingController();

  AccountType _accountType = AccountType.user;

  List<String> _documents = [];
  String? _polizaUrl;
  String? _tarjetaProfesionalUrl;
  String? _documentoIdentidadUrl;

  String? _selectedFileName;
  Uint8List? _selectedFileBytes;

  String? _selectedCountry;

  final List<String> _countries = [
    'Colombia',
    'Argentina',
    'México',
    'Chile',
    'Perú',
    'Ecuador',
    'Venezuela',
    'Uruguay',
    'Paraguay',
    'Bolivia',
    'Brasil',
    'Estados Unidos',
    'España',
    'Alemania',
    'Francia',
    'Italia',
    'Reino Unido',
    'Canadá',
    'Australia',
    'Otro',
  ];

  // =======================================================
  // NAVEGACIÓN STEPS
  // =======================================================

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step++);
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  // =======================================================
  // INPUT BASE
  // =======================================================

  InputDecoration _input(String hint, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.inputFill,
      hintText: hint,
      hintStyle: AppTextStyles.formFieldHint,
      prefixIcon: Icon(icon, color: AppColors.inputIcon),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingLarge,
        vertical: AppDimens.verticalPadding,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
        borderSide: BorderSide.none,
      ),
    );
  }

  // =======================================================
  // CAMPOS REUTILIZABLES
  // =======================================================

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
        icon: Icon(
          _obscure ? Icons.visibility : Icons.visibility_off,
          color: AppColors.inputIcon,
        ),
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

  // =======================================================
  // FORMULARIO USUARIO (SENCILLO)
  // =======================================================

  Widget _stepUser() => Column(
    children: [
      _fieldName(),
      _fieldEmail(),
      _fieldPassword(),
      _fieldPhone(),
      const SizedBox(height: 20),
      _submitButton("Registrar"),
    ],
  );

  // =======================================================
  // FORMULARIO PEDIATRA — STEP 1
  // =======================================================

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

  // =======================================================
  // FORMULARIO PEDIATRA — STEP 2
  // =======================================================

  Widget _pediatricianFields() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedCountry,
          isExpanded: true,
          decoration: _input("País", Icons.flag).copyWith(
            hintText: "País",
            hintStyle: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
            ),
          ),
          dropdownColor: const Color.fromARGB(19, 245, 243, 243),
          style: AppTextStyles.formFieldText,
          items: _countries
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: AppTextStyles.formFieldText),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedCountry = v),
          validator: (v) =>
              v == null || v.isEmpty ? 'Selecciona un país' : null,
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

  // =======================================================
  // FORMULARIO PEDIATRA — STEP 3
  // =======================================================

  Widget _stepP3() {
    final List<_DocumentoItem> documentos = [
      _DocumentoItem(
        nombre: "Póliza de responsabilidad única",
        url: _polizaUrl,
        obligatorio: false,
        onUpload: () async {
          await _pickAndUploadPoliza(
            context,
            (url) => setState(() => _polizaUrl = url),
          );
        },
        onDelete: () => setState(() => _polizaUrl = null),
      ),
      _DocumentoItem(
        nombre: "Tarjeta profesional",
        url: _tarjetaProfesionalUrl,
        obligatorio: false,
        onUpload: () async {
          await _pickAndUploadTarjetaProfesional(
            context,
            (url) => setState(() => _tarjetaProfesionalUrl = url),
          );
        },
        onDelete: () => setState(() => _tarjetaProfesionalUrl = null),
      ),
      _DocumentoItem(
        nombre: "Documento de identidad",
        url: _documentoIdentidadUrl,
        obligatorio: false,
        onUpload: () async {
          final picked = await pickDocument();
          if (picked == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No seleccionaste ningún documento.'),
              ),
            );
            return;
          }

          final fileName = picked.name;
          final fileBytes = picked.bytes;
          final maxSize = 5 * 1024 * 1024;

          if (fileBytes.length > maxSize) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'El archivo supera el límite de 5MB o es inválido',
                ),
              ),
            );
            return;
          }

          final storageRef = FirebaseStorage.instance.ref().child(
            'documentos_identidad/${DateTime.now().millisecondsSinceEpoch}_$fileName',
          );

          await storageRef.putData(fileBytes);
          final url = await storageRef.getDownloadURL();
          setState(() => _documentoIdentidadUrl = url);
        },
        onDelete: () => setState(() => _documentoIdentidadUrl = null),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Documentos requeridos"),
        const SizedBox(height: 12),
        ...documentos.map(
          (doc) => ListTile(
            leading: Checkbox(
              value: doc.url != null,
              onChanged: (doc.url == null && doc.onUpload != null)
                  ? (v) async => await doc.onUpload!.call()
                  : null,
              activeColor: AppColors.primary,
            ),
            title: Text(
              doc.url != null && doc.nombre == "Documento de identidad"
                  ? "Documento de identidad: subido"
                  : doc.nombre,
              style: AppTextStyles.formFieldText.copyWith(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: doc.url != null
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: doc.onDelete,
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.upload_file,
                      color: AppColors.inputIcon,
                    ),
                    onPressed: doc.onUpload,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _dataTreatmentAccepted,
              onChanged: (v) {
                setState(() {
                  _dataTreatmentAccepted = v ?? false;
                });
              },
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              'Autorizo el tratamiento de mis datos personales conforme a la ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () {
                              launchUrlCustom(
                                Uri.parse(
                                  'https://www.sic.gov.co/sites/default/files/files/Politica_de_Tratamiento_de_Datos_Personales.pdf',
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 2.0),
                              child: Text(
                                'política de tratamiento de datos',
                                style: TextStyle(
                                  color: Colors.yellow,
                                  decoration: TextDecoration.underline,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        TextSpan(
                          text: '.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =======================================================
  // WIDGETS UI AUXILIARES
  // =======================================================

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Montserrat',
      ),
    );
  }

  // =======================================================
  // SUBIDA DE DOCUMENTOS
  // =======================================================

  Future<void> _pickAndUploadDocument() async {
    final picked = await pickDocument();
    if (picked == null) return;

    setState(() {
      _selectedFileName = picked.name;
      _selectedFileBytes = picked.bytes;
      _documents.add(picked.name);
    });
  }

  // =======================================================
  // BOTÓN DE ENVÍO
  // =======================================================

  Widget _submitButton(String text) {
    return SizedBox(
      width: double.infinity,
      height: AppDimens.buttonHeight,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textWhite,
          foregroundColor: AppColors.primary,
          elevation: AppDimens.elevationMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              )
            : Text(text, style: AppTextStyles.buttonText),
      ),
    );
  }

  // =======================================================
  // ENVÍO FINAL CORREGIDO
  // =======================================================

  Future<void> _submit() async {
    if (_step == 2 && !_dataTreatmentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes autorizar el tratamiento de datos para continuar.',
          ),
        ),
      );
      return;
    }

    if (_accountType == AccountType.pediatrician) {
      if (_polizaUrl == null ||
          _tarjetaProfesionalUrl == null ||
          _documentoIdentidadUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Puedes continuar sin subir todos los documentos, pero tu cuenta quedará pendiente de revisión.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userType = _accountType == AccountType.pediatrician
          ? 'pediatra'
          : 'usuario';
      final estado = _accountType == AccountType.pediatrician
          ? 'pendiente'
          : 'habilitado';

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'type': userType,
            'estado': estado,
            if (_accountType == AccountType.pediatrician) ...{
              'country': _selectedCountry,
              'address': _addressController.text.trim(),
              'experience': _experienceController.text.trim(),
              'polizaUrl': _polizaUrl,
              'tarjetaProfesionalUrl': _tarjetaProfesionalUrl,
              'documentos': _documents,
            },
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _accountType == AccountType.pediatrician
                ? 'Registro enviado. Tu cuenta está pendiente de revisión.'
                : 'Registro exitoso. Por favor inicia sesión.',
          ),
          duration: const Duration(seconds: 6),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // ⭐⭐ NAVEGACIÓN ARREGLADA ⭐⭐
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      // Desactivar loading solo después de navegar
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  // =======================================================
  // BUILD PRINCIPAL
  // =======================================================

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
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),

                      // ========== SELECCIÓN TIPO DE CUENTA ==========
                      ToggleButtons(
                        borderRadius: BorderRadius.circular(
                          AppDimens.borderRadiusXLarge,
                        ),
                        borderColor: AppColors.primary,
                        selectedBorderColor: AppColors.primary,
                        fillColor: AppColors.primary,
                        selectedColor: Colors.white,
                        color: AppColors.primary,
                        constraints: const BoxConstraints(
                          minWidth: 120,
                          minHeight: 40,
                        ),
                        isSelected: [
                          _accountType == AccountType.user,
                          _accountType == AccountType.pediatrician,
                        ],
                        onPressed: (index) {
                          setState(() {
                            _accountType = index == 0
                                ? AccountType.user
                                : AccountType.pediatrician;
                            _step = 0;
                          });
                        },
                        children: const [
                          Text(
                            'Usuario',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Pediatra',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      if (_accountType == AccountType.user) ...[_stepUser()],

                      if (_accountType == AccountType.pediatrician) ...[
                        if (_step == 0) _stepP1(),
                        if (_step == 1) _pediatricianFields(),
                        if (_step == 2) _stepP3(),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_step > 0)
                              ElevatedButton.icon(
                                onPressed: _prevStep,
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: AppColors.primary,
                                ),
                                label: const Text(
                                  "Anterior",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Montserrat',
                                    color: AppColors.primary,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textWhite,
                                  elevation: AppDimens.elevationMedium,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.borderRadiusXLarge,
                                    ),
                                  ),
                                ),
                              ),
                            if (_step < 2)
                              ElevatedButton.icon(
                                onPressed: _nextStep,
                                icon: const Icon(
                                  Icons.arrow_forward,
                                  color: AppColors.primary,
                                ),
                                label: const Text(
                                  "Siguiente",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Montserrat',
                                    color: AppColors.primary,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textWhite,
                                  elevation: AppDimens.elevationMedium,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.borderRadiusXLarge,
                                    ),
                                  ),
                                ),
                              ),
                            if (_step == 2)
                              SizedBox(
                                height: AppDimens.buttonHeight,
                                width: 140,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.textWhite,
                                    elevation: AppDimens.elevationMedium,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.borderRadiusXLarge,
                                      ),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          "Guardar",
                                          style: AppTextStyles.buttonText,
                                        ),
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
}
