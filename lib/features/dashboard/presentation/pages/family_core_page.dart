import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
// app_text_styles import removed (not used in this file)
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

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Núcleo familiar guardado')));
    }
  }

  void _addChild() {
    setState(() {
      _children.add(_ChildInfo());
    });
  }

  void _removeChild(int index) {
    setState(() {
      _children[index].dispose();
      _children.removeAt(index);
    });
  }

  List<Widget> _buildChildrenForms() {
    if (_children.isEmpty) return [];
    final List<Widget> widgets = [];
    for (var i = 0; i < _children.length; i++) {
      final child = _children[i];
      widgets.add(Card(
        margin: const EdgeInsets.only(bottom: AppDimens.paddingSmall),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Hijo ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  IconButton(onPressed: () => _removeChild(i), icon: const Icon(Icons.delete_outline)),
                ],
              ),
              TextFormField(controller: child.nameController, decoration: const InputDecoration(labelText: 'Nombre del hijo')),
              const SizedBox(height: AppDimens.paddingSmall),
              // Use a read-only field with a DatePicker for the child's date of birth
              TextFormField(
                controller: child.ageController,
                decoration: const InputDecoration(labelText: 'Fecha de nacimiento'),
                readOnly: true,
                onTap: () => _pickChildDob(i),
              ),
              const SizedBox(height: AppDimens.paddingSmall),
              TextFormField(controller: child.notesController, decoration: const InputDecoration(labelText: 'Antecedentes del hijo (alergias, condiciones)'), maxLines: 2),
            ],
          ),
        ),
      ));
    }
    return widgets;
  }

  Future<void> _pickChildDob(int index) async {
    final initialDate = DateTime.now().subtract(const Duration(days: 365 * 5));
    final firstDate = DateTime(1900);
    final lastDate = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      final formatted = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        _children[index].ageController.text = formatted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Núcleo familiar'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Removed duplicate white heading (AppBar already shows the title)
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Dynamic list of children with their own antecedentes
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Hijos', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(width: AppDimens.paddingSmall),
                        ElevatedButton.icon(
                          onPressed: _addChild,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar hijo'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.paddingSmall),
                  ..._buildChildrenForms(),
                  const SizedBox(height: AppDimens.paddingSmall),
                  TextFormField(
                    controller: _fatherController,
                    decoration: const InputDecoration(labelText: 'Nombre del padre'),
                    validator: (v) => null,
                  ),
                  const SizedBox(height: AppDimens.paddingSmall),
                  TextFormField(
                    controller: _motherController,
                    decoration: const InputDecoration(labelText: 'Nombre de la madre'),
                    validator: (v) => null,
                  ),
                  const SizedBox(height: AppDimens.paddingSmall),
                  TextFormField(
                    controller: _caregiverController,
                    decoration: const InputDecoration(labelText: 'Cuidador principal'),
                  ),
                  const SizedBox(height: AppDimens.paddingSmall),
                  TextFormField(
                    controller: _siblingsController,
                    decoration: const InputDecoration(labelText: 'Número de hermanos'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppDimens.paddingSmall),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                  ),
                  const SizedBox(height: AppDimens.paddingSmall),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Teléfono de contacto'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppDimens.paddingSmall),
                  const Divider(),
                  const SizedBox(height: AppDimens.paddingSmall),
                  const Align(alignment: Alignment.centerLeft, child: Text('Contacto de emergencia', style: TextStyle(fontWeight: FontWeight.w700))),
                  const SizedBox(height: AppDimens.paddingSmall),
                  TextFormField(
                    controller: _emergencyNameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Ingrese un nombre' : null,
                  ),
                  const SizedBox(height: AppDimens.paddingSmall),
                  TextFormField(
                    controller: _emergencyPhoneController,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.isEmpty) ? 'Ingrese teléfono' : null,
                  ),
                  const SizedBox(height: AppDimens.paddingMedium),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppDimens.buttonHeight / 2),
                        child: Text('Guardar núcleo familiar'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
