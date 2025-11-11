import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
// app_text_styles import removed (not used in this file)
import '../../../../core/constants/app_dimens.dart';

class MedicalHistoryPage extends StatefulWidget {
  const MedicalHistoryPage({super.key});

  @override
  State<MedicalHistoryPage> createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _allergiesController = TextEditingController();
  final _chronicController = TextEditingController();
  final _surgeryController = TextEditingController();
  final _medsController = TextEditingController();
  final _vaccinesController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _allergiesController.dispose();
    _chronicController.dispose();
    _surgeryController.dispose();
    _medsController.dispose();
    _vaccinesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      // For now we just show a snackbar — replace with persistence later
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Antecedentes guardados')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antecedentes médicos'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _allergiesController,
                    decoration: const InputDecoration(labelText: 'Alergias (si aplica)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppDimens.paddingSmall),
                  TextFormField(
                    controller: _chronicController,
                    decoration: const InputDecoration(labelText: 'Enfermedades crónicas'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppDimens.paddingSmall),
                  TextFormField(
                    controller: _surgeryController,
                    decoration: const InputDecoration(labelText: 'Cirugías previas'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppDimens.paddingSmall),
                  TextFormField(
                    controller: _medsController,
                    decoration: const InputDecoration(labelText: 'Medicamentos actuales'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppDimens.paddingSmall),
                  TextFormField(
                    controller: _vaccinesController,
                    decoration: const InputDecoration(labelText: 'Vacunas (fecha / tipo)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppDimens.paddingSmall),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Observaciones adicionales'),
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppDimens.paddingMedium),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppDimens.buttonHeight / 2),
                        child: Text('Guardar'),
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
