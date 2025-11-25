import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/utils/document_picker_stub.dart';
import '../../../../core/constants/app_text_styles.dart';

// =======================================================
// MÉTODOS GLOBALES PARA SUBIDA DE DOCUMENTOS
// =======================================================

Future<void> _pickAndUploadPoliza(
    BuildContext context, Function(String) setPolizaUrl) async {
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

  final storageRef = FirebaseStorage.instance
      .ref()
      .child('polizas/${DateTime.now().millisecondsSinceEpoch}_$fileName');

  await storageRef.putData(fileBytes);
  final url = await storageRef.getDownloadURL();
  setPolizaUrl(url);
}

Future<void> _pickAndUploadTarjetaProfesional(
    BuildContext context, Function(String) setTarjetaProfesionalUrl) async {
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
      'tarjetas_profesional/${DateTime.now().millisecondsSinceEpoch}_$fileName');

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
  int _step = 0;
  bool _obscure = true;
  bool _isLoading = false;

  // CONTROLADORES
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _experienceController = TextEditingController();

  // ESTADO
  AccountType _accountType = AccountType.user;

  List<String> _documents = [];
  String? _polizaUrl;
  String? _tarjetaProfesionalUrl;

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
    'Otro'
  ];

  // =======================================================
  // NAVEGACIÓN STEPS
  // =======================================================

  void _nextStep() {
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
          vertical: AppDimens.verticalPadding),
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
            hintStyle: TextStyle(
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
    return Column(
      children: [
        _sectionTitle("Póliza de responsabilidad única"),
        if (_polizaUrl != null)
          _fileUploadedCard("Póliza subida", () {
            setState(() => _polizaUrl = null);
          })
        else
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file, color: AppColors.inputIcon),
            label: Text("Subir póliza", style: AppTextStyles.buttonText),
            onPressed: () => _pickAndUploadPoliza(
              context,
              (url) => setState(() => _polizaUrl = url),
            ),
          ),
        const SizedBox(height: AppDimens.paddingMedium),

        _sectionTitle("Tarjeta profesional"),
        if (_tarjetaProfesionalUrl != null)
          _fileUploadedCard("Tarjeta profesional subida", () {
            setState(() => _tarjetaProfesionalUrl = null);
          })
        else
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file, color: AppColors.inputIcon),
            label: Text("Subir tarjeta profesional", style: AppTextStyles.buttonText),
            onPressed: () => _pickAndUploadTarjetaProfesional(
              context,
              (url) => setState(() => _tarjetaProfesionalUrl = url),
            ),
          ),
        const SizedBox(height: AppDimens.paddingMedium),

        _sectionTitle("Otros documentos"),
        if (_selectedFileName != null)
          _fileTemporaryCard()
        else
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file, color: AppColors.inputIcon),
            label: Text("Seleccionar documento", style: AppTextStyles.buttonText),
            onPressed: _pickAndUploadDocument,
          ),
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
        // El botón de guardar y validar se moverá al Row de navegación
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

  Widget _fileUploadedCard(String title, VoidCallback onDelete) {
    return Card(
      color: AppColors.inputFill,
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file, color: AppColors.inputIcon),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
            fontFamily: 'Montserrat',
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }

  Widget _fileTemporaryCard() {
    return Card(
      color: AppColors.inputFill,
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file, color: AppColors.inputIcon),
        title: Text(
          _selectedFileName!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
            fontFamily: 'Montserrat',
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () {
            setState(() {
              _selectedFileName = null;
              _selectedFileBytes = null;
            });
          },
        ),
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

  Widget _submitButton(String text) => SizedBox(
        height: AppDimens.buttonHeight,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textWhite,
            foregroundColor: AppColors.primary,
            elevation: AppDimens.elevationLarge,
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

  // =======================================================
  // ENVÍO FINAL (LÓGICA A COMPLETAR)
  // =======================================================

  Future<void> _submit() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enviar formulario')),
    );
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
                constraints:
                    BoxConstraints(maxWidth: mq.width > 500 ? 500 : mq.width),
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
                            _accountType = index == 0
                                ? AccountType.user
                                : AccountType.pediatrician;
                            _step = 0;
                          });
                        },
                        children: const [
                          Text('Usuario',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat',
                                  fontSize: 16)),
                          Text('Pediatra',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat',
                                  fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // ========== FORMULARIOS ========== 
                      if (_accountType == AccountType.user) ...[
                        _stepUser(),
                      ],
                      if (_accountType == AccountType.pediatrician) ...[
                        if (_step == 0) ...[_stepP1()],
                        if (_step == 1) ...[_pediatricianFields()],
                        if (_step == 2) ...[_stepP3()],
                        const SizedBox(height: 20),
                        // NAVEGACIÓN
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_step > 0)
                              ElevatedButton.icon(
                                onPressed: _prevStep,
                                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                                label: const Text("Anterior",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Montserrat',
                                        color: AppColors.primary)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textWhite,
                                  foregroundColor: AppColors.primary,
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
                                label: const Text("Siguiente",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Montserrat',
                                        color: AppColors.primary)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textWhite,
                                  foregroundColor: AppColors.primary,
                                  elevation: AppDimens.elevationMedium,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge),
                                  ),
                                ),
                              ),
                            if (_step == 2)
                              SizedBox(
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
                                      : Text("Guardar y validar", style: AppTextStyles.buttonText),
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
