import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';

class MedicalHistoryPage extends StatefulWidget {
  const MedicalHistoryPage({super.key});

  @override
  State<MedicalHistoryPage> createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage> {
  User? _user;
  bool _loading = true;
  final _formKey = GlobalKey<FormState>();

  final _allergiesController = TextEditingController();
  final _chronicController = TextEditingController();
  final _surgeryController = TextEditingController();
  final _medsController = TextEditingController();
  final _vaccinesController = TextEditingController();
  final _notesController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadMedicalHistory();
  }

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

  Future<void> _loadMedicalHistory() async {
    if (_user == null) return;
    setState(() => _loading = true);
    final doc = await FirebaseFirestore.instance.collection('medical_history').doc(_user!.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _allergiesController.text = data['allergies'] ?? '';
      _chronicController.text = data['chronic'] ?? '';
      _surgeryController.text = data['surgery'] ?? '';
      _medsController.text = data['meds'] ?? '';
      _vaccinesController.text = data['vaccines'] ?? '';
      _notesController.text = data['notes'] ?? '';
    }
    setState(() => _loading = false);
  }

  // ============================================================
  //   GUARDAR FORMULARIO
  // ============================================================
  Future<void> _save() async {
    if (_formKey.currentState?.validate() ?? false && _user != null) {
      await FirebaseFirestore.instance.collection('medical_history').doc(_user!.uid).set({
        'allergies': _allergiesController.text.trim(),
        'chronic': _chronicController.text.trim(),
        'surgery': _surgeryController.text.trim(),
        'meds': _medsController.text.trim(),
        'vaccines': _vaccinesController.text.trim(),
        'notes': _notesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Antecedentes guardados correctamente')),
      );
    }
  }

  // ============================================================
  //   WIDGET TARJETA DE SECCIÓN (con colores de la app)
  // ============================================================
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 3,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: AppColors.overlayLight,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  // ============================================================
  //   PANTALLA PRINCIPAL
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antecedentes médicos'),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _sectionCard(
                      icon: Icons.warning_amber_outlined,
                      title: 'Alergias',
                      child: TextFormField(
                        controller: _allergiesController,
                        decoration: const InputDecoration(
                          labelText: 'Alergias (si aplica)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingMedium),
                    _sectionCard(
                      icon: Icons.healing_outlined,
                      title: 'Enfermedades crónicas',
                      child: TextFormField(
                        controller: _chronicController,
                        decoration: const InputDecoration(
                          labelText: 'Enfermedades crónicas',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingMedium),
                    _sectionCard(
                      icon: Icons.local_hospital_outlined,
                      title: 'Cirugías previas',
                      child: TextFormField(
                        controller: _surgeryController,
                        decoration: const InputDecoration(
                          labelText: 'Cirugías previas',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingMedium),
                    _sectionCard(
                      icon: Icons.medication_outlined,
                      title: 'Medicamentos actuales',
                      child: TextFormField(
                        controller: _medsController,
                        decoration: const InputDecoration(
                          labelText: 'Medicamentos actuales',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingMedium),
                    _sectionCard(
                      icon: Icons.vaccines_outlined,
                      title: 'Vacunas',
                      child: TextFormField(
                        controller: _vaccinesController,
                        decoration: const InputDecoration(
                          labelText: 'Vacunas (fecha / tipo)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingMedium),
                    _sectionCard(
                      icon: Icons.notes_outlined,
                      title: 'Observaciones adicionales',
                      child: TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones adicionales',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingLarge),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Guardar antecedentes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppDimens.buttonHeight / 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
