import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';

class FamilyCorePage extends StatefulWidget {
  const FamilyCorePage({super.key});

  @override
  State<FamilyCorePage> createState() => _FamilyCorePageState();
}

class _FamilyCorePageState extends State<FamilyCorePage> {
  final _formKey = GlobalKey<FormState>();

  final _fatherController = TextEditingController();
  final _motherController = TextEditingController();
  final _caregiverController = TextEditingController();
  final _siblingsController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  final List<_ChildInfo> _children = [];

  @override
  void dispose() {
    _fatherController.dispose();
    _motherController.dispose();
    _caregiverController.dispose();
    _siblingsController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();

    for (final c in _children) {
      c.dispose();
    }
    super.dispose();
  }

  // ============================================================
  //   GUARDAR
  // ============================================================
  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Núcleo familiar guardado correctamente")),
      );
    }
  }

  // ============================================================
  //   AGREGAR / ELIMINAR HIJO
  // ============================================================
  void _addChild() {
    setState(() => _children.add(_ChildInfo()));
  }

  void _removeChild(int index) {
    setState(() {
      _children[index].dispose();
      _children.removeAt(index);
    });
  }

  // ============================================================
  //   UI: TARJETA DE HIJO
  // ============================================================
  Widget _buildChildCard(int index) {
    final child = _children[index];

    return Card(
      elevation: 3,
      shadowColor: AppColors.overlayLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: AppDimens.paddingMedium),
      child: ExpansionTile(
        key: ValueKey(index),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.child_care, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                child.nameController.text.isEmpty
                    ? "Hijo ${index + 1}"
                    : child.nameController.text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),

        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _removeChild(index),
        ),

        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            child: Column(
              children: [
                TextFormField(
                  controller: child.nameController,
                  decoration: const InputDecoration(
                    labelText: "Nombre del hijo",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppDimens.paddingSmall),

                TextFormField(
                  controller: child.ageController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Fecha de nacimiento",
                    border: OutlineInputBorder(),
                  ),
                  onTap: () => _pickChildDob(index),
                ),
                const SizedBox(height: AppDimens.paddingSmall),

                TextFormField(
                  controller: child.notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Antecedentes del hijo",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //   SELECTOR DE FECHA PARA HIJOS
  // ============================================================
  Future<void> _pickChildDob(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2018),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      helpText: "Seleccione fecha de nacimiento",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _children[index].ageController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // ============================================================
  //   PÁGINA PRINCIPAL
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Núcleo familiar"),
        backgroundColor: AppColors.primary,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // TÍTULO + BOTÓN AGREGAR HIJO
              Row(
                children: [
                  const Icon(Icons.family_restroom, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    "Hijos",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _addChild,
                    icon: const Icon(Icons.add),
                    label: const Text("Agregar hijo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimens.paddingMedium),
              ..._children.asMap().entries.map((e) => _buildChildCard(e.key)),

              const SizedBox(height: AppDimens.paddingLarge),

              // =====================================================
              //   INFORMACIÓN FAMILIAR GENERAL
              // =====================================================
              _buildSectionTitle("Información familiar"),

              TextFormField(
                controller: _fatherController,
                decoration: const InputDecoration(
                  labelText: "Nombre del padre",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppDimens.paddingMedium),

              TextFormField(
                controller: _motherController,
                decoration: const InputDecoration(
                  labelText: "Nombre de la madre",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppDimens.paddingMedium),

              TextFormField(
                controller: _caregiverController,
                decoration: const InputDecoration(
                  labelText: "Cuidador principal",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppDimens.paddingMedium),

              TextFormField(
                controller: _siblingsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Número de hermanos",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppDimens.paddingMedium),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Dirección",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppDimens.paddingMedium),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Teléfono de contacto",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: AppDimens.paddingLarge),
              const Divider(),
              const SizedBox(height: AppDimens.paddingLarge),

              // =====================================================
              //   EMERGENCIA
              // =====================================================
              _buildSectionTitle("Contacto de emergencia"),

              TextFormField(
                controller: _emergencyNameController,
                decoration: const InputDecoration(
                  labelText: "Nombre",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Ingrese un nombre" : null,
              ),
              const SizedBox(height: AppDimens.paddingMedium),

              TextFormField(
                controller: _emergencyPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Teléfono",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Ingrese un teléfono" : null,
              ),

              const SizedBox(height: AppDimens.paddingLarge),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.buttonHeight / 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Guardar núcleo familiar",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //   TITULOS DE SECCIÓN UNIFORMES
  // ============================================================
  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingSmall),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}

// ============================================================
//   MODELO HIJO
// ============================================================
class _ChildInfo {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  void dispose() {
    nameController.dispose();
    ageController.dispose();
    notesController.dispose();
  }
}
