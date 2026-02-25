import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import './_medical_history_list_for_doctor.dart';

class MedicalHistoryPage extends StatefulWidget {
  final bool readOnly;
  const MedicalHistoryPage({super.key, this.readOnly = true});

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
    if (_user == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    final doc = await FirebaseFirestore.instance
        .collection('medical_history')
        .doc(_user!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data() ?? <String, dynamic>{};
      _allergiesController.text = (data['allergies'] ?? '').toString();
      _chronicController.text = (data['chronic'] ?? '').toString();
      _surgeryController.text = (data['surgery'] ?? '').toString();
      _medsController.text = (data['meds'] ?? '').toString();
      _vaccinesController.text = (data['vaccines'] ?? '').toString();
      _notesController.text = (data['notes'] ?? '').toString();
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (widget.readOnly) return;

    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    await FirebaseFirestore.instance
        .collection('medical_history')
        .doc(_user!.uid)
        .set({
      'allergies': _allergiesController.text.trim(),
      'chronic': _chronicController.text.trim(),
      'surgery': _surgeryController.text.trim(),
      'meds': _medsController.text.trim(),
      'vaccines': _vaccinesController.text.trim(),
      'notes': _notesController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Antecedentes guardados correctamente')),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final uid = _user?.uid;

    return Scaffold(
          appBar: AppBar(
            toolbarHeight: 44,
            title: const Text(
              'Antecedentes médicos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
            centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingLarge),
              child: Column(
                children: [
                  // Lista de historias SOLO si es doctor
                  if (uid != null)
                    FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        if (snapshot.hasError) {
                          return const SizedBox.shrink();
                        }

                        final data = snapshot.data?.data();
                        final isDoctor = data != null &&
                            (data['role'] == 'doctor' ||
                                data['isDoctor'] == true);

                        if (isDoctor) {
                          // Si tu widget no tiene constructor const, quita el const
                          return MedicalHistoryListForDoctor();
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                  Form(
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
                            enabled: !widget.readOnly,
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
                            enabled: !widget.readOnly,
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
                            enabled: !widget.readOnly,
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
                            enabled: !widget.readOnly,
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
                            enabled: !widget.readOnly,
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
                            enabled: !widget.readOnly,
                          ),
                        ),
                        const SizedBox(height: AppDimens.paddingLarge),
                        if (!widget.readOnly)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _save,
                              icon: const Icon(Icons.save),
                              label: const Text(
                                'Guardar antecedentes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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
                ],
              ),
            ),
    );
  }
}
