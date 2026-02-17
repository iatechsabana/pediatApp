import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PediatricianMedicalHistoryPage extends StatefulWidget {
  final String patientId;
  final String patientName;
  const PediatricianMedicalHistoryPage({super.key, required this.patientId, required this.patientName});

  @override
  State<PediatricianMedicalHistoryPage> createState() => _PediatricianMedicalHistoryPageState();
}

class _PediatricianMedicalHistoryPageState extends State<PediatricianMedicalHistoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _anamnesisController = TextEditingController();
  final _planController = TextEditingController();
  final _analisisController = TextEditingController();
  final _evolucionController = TextEditingController();
  final _conclusionesController = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _history;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('medical_histories')
        .doc('${user.uid}_${widget.patientId}')
        .get();
    if (doc.exists) {
      _history = doc.data();
      _anamnesisController.text = _history?['anamnesis'] ?? '';
      _planController.text = _history?['plan'] ?? '';
      _analisisController.text = _history?['analisis'] ?? '';
      _evolucionController.text = _history?['evolucion'] ?? '';
      _conclusionesController.text = _history?['conclusiones'] ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _saveHistory() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('medical_histories')
        .doc('${user.uid}_${widget.patientId}')
        .set({
      'pediatricianId': user.uid,
      'patientId': widget.patientId,
      'patientName': widget.patientName,
      'anamnesis': _anamnesisController.text.trim(),
      'plan': _planController.text.trim(),
      'analisis': _analisisController.text.trim(),
      'evolucion': _evolucionController.text.trim(),
      'conclusiones': _conclusionesController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Enviar notificación al usuario (padre/madre) avisando que la historia está disponible
    await FirebaseFirestore.instance.collection('notifications').add({
      'toUserId': widget.patientId,
      'fromUserId': user.uid,
      'type': 'historia_clinica',
      'message': 'La historia clínica de ${widget.patientName} ha sido actualizada y está disponible.',
      'timestamp': FieldValue.serverTimestamp(),
      'userName': user.displayName ?? 'Pediatra',
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Historia clínica guardada y notificada al usuario')));
  }

  @override
  void dispose() {
    _anamnesisController.dispose();
    _planController.dispose();
    _analisisController.dispose();
    _evolucionController.dispose();
    _conclusionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historia clínica de ${widget.patientName}'),
        backgroundColor: Colors.teal,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Anamnesis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _anamnesisController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Describe síntomas, antecedentes, motivo de consulta...',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese la anamnesis' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _planController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'Tratamiento, exámenes, seguimiento...',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese el plan' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Análisis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _analisisController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'Interpretación clínica, hallazgos...',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese el análisis' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nota de la evolución', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _evolucionController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Progresión, respuesta al tratamiento...',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese la nota de evolución' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Conclusiones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _conclusionesController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'Resumen, recomendaciones finales...',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese las conclusiones' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saveHistory,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
