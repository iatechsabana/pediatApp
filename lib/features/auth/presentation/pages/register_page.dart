import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/document_picker_stub.dart';
import '../providers/auth_provider.dart';
import '../../domain/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';
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
// FUNCIÓN UNIFICADA PARA SUBIDA DE DOCUMENTOS
// =======================================================

Future<void> _pickAndUploadDocument(
  BuildContext context,
  String storagePath,
  Function(String) onUrl,
) async {
  final picked = await pickDocument();
  if (picked == null) return;

  final fileBytes = picked.bytes;
  const maxSize = 5 * 1024 * 1024;

  if (fileBytes.length > maxSize) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El archivo supera el límite de 5MB o es inválido')),
      );
    }
    return;
  }

  final storageRef = FirebaseStorage.instance.ref().child(
    '$storagePath/${DateTime.now().millisecondsSinceEpoch}_${picked.name}',
  );

  await storageRef.putData(fileBytes);
  final url = await storageRef.getDownloadURL();
  onUrl(url);
}

// =======================================================
// PANTALLA DE REGISTRO
// =======================================================

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

enum AccountType { user, pediatrician }

class _RegisterPageState extends ConsumerState<RegisterPage> {
  bool _dataTreatmentAccepted = false;
  int _step = 0;
  bool _obscure = true;
  bool _isLoading = false;

  String? _documentoIdentidadFrenteUrl;
  String? _documentoIdentidadReversoUrl;
  DateTime? _birthDate;
  DateTime? _startDate;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  AccountType _accountType = AccountType.user;
  final _workAddressController = TextEditingController();

  String? _polizaUrl;
  String? _tarjetaProfesionalUrl;
  String? _selectedCountry = 'Colombia';

  final List<String> _countries = [
    'Colombia', 'Argentina', 'México', 'Chile', 'Perú',
    'Ecuador', 'Venezuela', 'Uruguay', 'Paraguay', 'Bolivia',
    'Brasil', 'Estados Unidos', 'España', 'Alemania', 'Francia',
    'Italia', 'Reino Unido', 'Canadá', 'Australia', 'Otro',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _workAddressController.dispose();
    super.dispose();
  }

  Future<bool> _requestFileAndCameraPermissions() async {
    if (!mounted) return false;
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();
    final photosStatus = await Permission.photos.request();
    return cameraStatus.isGranted && (storageStatus.isGranted || photosStatus.isGranted);
  }

  Future<void> _launchUrlCustom(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace.')),
        );
      }
    }
  }

  // =======================================================
  // NAVEGACIÓN STEPS
  // =======================================================

  void _nextStep() {
    if (!_formKey.currentState!.validate()) return;
    if (_step < 2) setState(() => _step++);
  }

  void _prevStep() {
    if (_step > 0) setState(() => _step--);
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
    decoration: _input('Nombre completo', Icons.person),
    validator: (v) => v!.isEmpty ? 'Ingresa tu nombre' : null,
  );

  Widget _fieldEmail() => TextFormField(
    controller: _emailController,
    keyboardType: TextInputType.emailAddress,
    style: AppTextStyles.formFieldText,
    decoration: _input('Correo electrónico', Icons.email),
    validator: (v) {
      if (v == null || v.isEmpty) return 'Ingresa tu correo';
      final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
      return emailRegex.hasMatch(v) ? null : 'Correo inválido';
    },
  );

  Widget _fieldPassword() => TextFormField(
    controller: _passwordController,
    obscureText: _obscure,
    style: AppTextStyles.formFieldText,
    decoration: _input('Contraseña', Icons.lock).copyWith(
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility : Icons.visibility_off,
          color: AppColors.inputIcon,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    ),
    validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
  );

  Widget _fieldPhone() => TextFormField(
    controller: _phoneController,
    keyboardType: TextInputType.phone,
    style: AppTextStyles.formFieldText,
    decoration: _input('Teléfono', Icons.phone),
    validator: (v) => v!.isEmpty ? 'Ingresa tu teléfono' : null,
  );

  Widget _fieldBirthDate() => GestureDetector(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime(2000),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (picked != null) setState(() => _birthDate = picked);
    },
    child: AbsorbPointer(
      child: TextFormField(
        decoration: _input('Fecha de nacimiento', Icons.cake),
        controller: TextEditingController(
          text: _birthDate == null
            ? ''
            : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
        ),
        validator: (v) => _birthDate == null ? 'Selecciona tu fecha de nacimiento' : null,
        style: AppTextStyles.formFieldText,
      ),
    ),
  );

  // =======================================================
  // DATOS PERSONALES — compartido por usuario y pediatra step 1
  // =======================================================

  Widget _stepPersonalData({bool showSubmit = false}) => Column(
    children: [
      _fieldName(),
      const SizedBox(height: AppDimens.paddingMedium),
      _fieldEmail(),
      const SizedBox(height: AppDimens.paddingMedium),
      _fieldPassword(),
      const SizedBox(height: AppDimens.paddingMedium),
      _fieldPhone(),
      const SizedBox(height: AppDimens.paddingMedium),
      TextFormField(
        controller: _addressController,
        style: AppTextStyles.formFieldText,
        decoration: _input('Dirección', Icons.map_outlined),
        validator: (v) => v!.isEmpty ? 'Ingresa tu dirección' : null,
      ),
      const SizedBox(height: AppDimens.paddingMedium),
      _fieldBirthDate(),
      if (showSubmit) ...[
        const SizedBox(height: 20),
        _habitusDataCheckbox(),
        const SizedBox(height: 16),
        _submitButton('Registrar'),
      ] else
        const SizedBox(height: 20),
    ],
  );

  // =======================================================
  // FORMULARIO PEDIATRA — STEP 2: datos profesionales
  // =======================================================

  Widget _stepProfessionalData() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedCountry,
          isExpanded: true,
          decoration: _input('País', Icons.flag).copyWith(
            hintText: 'País',
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
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: AppTextStyles.formFieldText),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedCountry = v),
          validator: (v) => v == null || v.isEmpty ? 'Selecciona un país' : null,
        ),
        const SizedBox(height: AppDimens.paddingMedium),
        TextFormField(
          controller: _workAddressController,
          style: AppTextStyles.formFieldText,
          decoration: _input('Dirección de trabajo', Icons.map_outlined),
        ),
        const SizedBox(height: AppDimens.paddingMedium),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1970),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _startDate = picked);
          },
          child: AbsorbPointer(
            child: TextFormField(
              decoration: _input('Fecha de inicio de labores', Icons.date_range),
              controller: TextEditingController(
                text: _startDate == null
                  ? ''
                  : '${_startDate!.day.toString().padLeft(2, '0')}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.year}',
              ),
              validator: (v) => _startDate == null ? 'Selecciona la fecha de inicio' : null,
              style: AppTextStyles.formFieldText,
            ),
          ),
        ),
      ],
    );
  }

  // =======================================================
  // FORMULARIO PEDIATRA — STEP 3: documentos
  // =======================================================

  Widget _stepDocuments() {
    final String? identidadLabel = _documentoIdentidadFrenteUrl != null &&
            _documentoIdentidadReversoUrl != null
        ? 'Ambos lados subidos'
        : _documentoIdentidadFrenteUrl != null
            ? 'Frente subido'
            : _documentoIdentidadReversoUrl != null
                ? 'Reverso subido'
                : null;

    final documentos = [
      _DocumentoItem(
        nombre: 'Póliza de responsabilidad única',
        url: _polizaUrl,
        obligatorio: false,
        onUpload: () async {
          await _pickAndUploadDocument(
            context,
            'polizas',
            (url) => setState(() => _polizaUrl = url),
          );
        },
        onDelete: () => setState(() => _polizaUrl = null),
      ),
      _DocumentoItem(
        nombre: 'Tarjeta profesional',
        url: _tarjetaProfesionalUrl,
        obligatorio: false,
        onUpload: () async {
          await _pickAndUploadDocument(
            context,
            'tarjetas_profesional',
            (url) => setState(() => _tarjetaProfesionalUrl = url),
          );
        },
        onDelete: () => setState(() => _tarjetaProfesionalUrl = null),
      ),
      _DocumentoItem(
        nombre: 'Documento de identidad (frente y reverso)',
        url: identidadLabel,
        obligatorio: false,
        onUpload: () async {
          final hasPermission = await _requestFileAndCameraPermissions();
          if (!hasPermission) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permiso denegado para acceder a archivos o cámara.')),
              );
            }
            return;
          }
          if (!mounted) return;
          final option = await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Tomar foto frente'),
                  onTap: () => Navigator.of(ctx).pop('frente'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_back),
                  title: const Text('Tomar foto reverso'),
                  onTap: () => Navigator.of(ctx).pop('reverso'),
                ),
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Seleccionar archivo'),
                  onTap: () => Navigator.of(ctx).pop('archivo'),
                ),
              ],
            ),
          );
          if (option == null) return;

          if (option == 'frente' || option == 'reverso') {
            final image = await ImagePicker().pickImage(source: ImageSource.camera);
            if (image == null) return;
            final bytes = await image.readAsBytes();
            if (bytes.length > 5 * 1024 * 1024) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('La imagen supera el límite de 5MB')),
                );
              }
              return;
            }
            final storageRef = FirebaseStorage.instance.ref().child(
              'documentos_identidad/${DateTime.now().millisecondsSinceEpoch}_${option}_${image.name}',
            );
            await storageRef.putData(bytes);
            final url = await storageRef.getDownloadURL();
            if (mounted) {
              setState(() {
                if (option == 'frente') {
                  _documentoIdentidadFrenteUrl = url;
                } else {
                  _documentoIdentidadReversoUrl = url;
                }
              });
            }
          } else {
            final picked = await pickDocument();
            if (picked == null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No seleccionaste ningún documento.')),
                );
              }
              return;
            }
            if (picked.bytes.length > 5 * 1024 * 1024) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El archivo supera el límite de 5MB o es inválido')),
                );
              }
              return;
            }
            final storageRef = FirebaseStorage.instance.ref().child(
              'documentos_identidad/${DateTime.now().millisecondsSinceEpoch}_archivo_${picked.name}',
            );
            await storageRef.putData(picked.bytes);
            final url = await storageRef.getDownloadURL();
            if (mounted) {
              setState(() {
                _documentoIdentidadFrenteUrl = url;
                _documentoIdentidadReversoUrl = url;
              });
            }
          }
        },
        onDelete: () => setState(() {
          _documentoIdentidadFrenteUrl = null;
          _documentoIdentidadReversoUrl = null;
        }),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Documentos requeridos'),
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
              doc.url ?? doc.nombre,
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
                    icon: const Icon(Icons.upload_file, color: AppColors.inputIcon),
                    onPressed: doc.onUpload,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        _habitusDataCheckbox(),
      ],
    );
  }

  // =======================================================
  // HABEAS DATA
  // =======================================================

  Widget _habitusDataCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _dataTreatmentAccepted,
          onChanged: (v) => setState(() => _dataTreatmentAccepted = v ?? false),
          activeColor: AppColors.primary,
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Autorizo el tratamiento de mis datos personales conforme a la ',
                  style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: 'Montserrat'),
                ),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => _launchUrlCustom(
                      Uri.parse('https://www.sic.gov.co/sites/default/files/files/Politica_de_Tratamiento_de_Datos_Personales.pdf'),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 2.0),
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
                const TextSpan(
                  text: '.',
                  style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: 'Montserrat'),
                ),
              ],
            ),
          ),
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
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              )
            : Text(text, style: AppTextStyles.buttonText),
      ),
    );
  }

  // =======================================================
  // ENVÍO FINAL
  // =======================================================

  Future<void> _submit() async {
    if (!_dataTreatmentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes autorizar el tratamiento de datos para continuar.')),
      );
      return;
    }

    if (_accountType == AccountType.pediatrician) {
      if (_polizaUrl == null ||
          _tarjetaProfesionalUrl == null ||
          (_documentoIdentidadFrenteUrl == null && _documentoIdentidadReversoUrl == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Puedes continuar sin subir todos los documentos, pero tu cuenta quedará pendiente de revisión.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider).register(
        RegisterData(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          birthDate: _birthDate!,
          isPediatrician: _accountType == AccountType.pediatrician,
          country: _selectedCountry,
          workAddress: _workAddressController.text.trim().isEmpty
              ? null
              : _workAddressController.text.trim(),
          startDate: _startDate,
          polizaUrl: _polizaUrl,
          tarjetaProfesionalUrl: _tarjetaProfesionalUrl,
          documentoIdentidadFrenteUrl: _documentoIdentidadFrenteUrl,
          documentoIdentidadReversoUrl: _documentoIdentidadReversoUrl,
        ),
      );

      if (!mounted) return;
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

      setState(() => _isLoading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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
        title: const Text('Registro'),
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
                constraints: BoxConstraints(maxWidth: mq.width > 500 ? 500 : mq.width),
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

                      ToggleButtons(
                        borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge),
                        borderColor: AppColors.primary,
                        selectedBorderColor: AppColors.primary,
                        fillColor: AppColors.primary,
                        selectedColor: Colors.white,
                        color: Colors.white70,
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

                      const SizedBox(height: 18),

                      if (_accountType == AccountType.user)
                        _stepPersonalData(showSubmit: true),

                      if (_accountType == AccountType.pediatrician) ...[
                        if (_step == 0) _stepPersonalData(),
                        if (_step == 1) _stepProfessionalData(),
                        if (_step == 2) _stepDocuments(),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_step > 0)
                              ElevatedButton.icon(
                                onPressed: _prevStep,
                                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                                label: const Text(
                                  'Anterior',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Montserrat', color: AppColors.primary),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textWhite,
                                  elevation: AppDimens.elevationMedium,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge),
                                  ),
                                ),
                              ),
                            if (_step < 2)
                              ElevatedButton.icon(
                                onPressed: _nextStep,
                                icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
                                label: const Text(
                                  'Siguiente',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Montserrat', color: AppColors.primary),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textWhite,
                                  elevation: AppDimens.elevationMedium,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge),
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
                                      borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                                        )
                                      : Text('Guardar', style: AppTextStyles.buttonText),
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
