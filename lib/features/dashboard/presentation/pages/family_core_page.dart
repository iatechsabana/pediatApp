import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'medical_history_list_page.dart';

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

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<QuerySnapshot<Map<String, dynamic>>> _medicalHistoriesStream(String childName) {
    final uid = _currentUserId;
    if (childName.trim().isEmpty || uid.isEmpty) {
      // Stream vacío para evitar queries inútiles
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('medical_histories')
        .where('patientName', isEqualTo: childName.trim())
        .where('patientId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Núcleo familiar guardado correctamente")),
      );
    }
  }

  void _addChild() {
    final child = _ChildInfo();

    // Para que el título y la sección de historias se refresquen al escribir el nombre
    child.nameController.addListener(() {
      if (mounted) setState(() {});
    });

    setState(() => _children.add(child));
  }

  void _removeChild(int index) {
    setState(() {
      _children[index].dispose();
      _children.removeAt(index);
    });
  }

  Widget _buildChildCard(int index) {
    final child = _children[index];
    final childName = child.nameController.text.trim();

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
                childName.isEmpty ? "Hijo ${index + 1}" : childName,
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
                const SizedBox(height: AppDimens.paddingMedium),

                // Historias clínicas (en vivo)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Historias clínicas previas:",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),

                if (_currentUserId.isEmpty)
                  const Text(
                    "Inicia sesión para ver historias clínicas.",
                    style: TextStyle(color: Colors.grey),
                  )
                else if (childName.isEmpty)
                  const Text(
                    "Escribe el nombre del hijo para buscar historias clínicas.",
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _medicalHistoriesStream(childName),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                          "Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Text(
                          "Sin historias clínicas registradas.",
                          style: TextStyle(color: Colors.grey),
                        );
                      }

                      return Column(
                        children: docs.map((d) {
                          final data = d.data();
                          final updatedAt = data['updatedAt'];
                          final date = (updatedAt is Timestamp)
                              ? updatedAt.toDate()
                              : (updatedAt is DateTime ? updatedAt : null);

                          final dateText = date != null
                              ? "${date.toLocal()}".split(' ')[0]
                              : "";

                          return ListTile(
                            title: Text(data['patientName'] ?? 'Paciente'),
                            subtitle: Text(
                              "Médico: ${data['pediatricianId'] ?? ''}\nFecha: $dateText",
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(data['patientName'] ?? 'Paciente'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Médico: ${data['pediatricianId'] ?? ''}"),
                                      Text("Fecha: $dateText"),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Cerrar"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
            colorScheme: const ColorScheme.light(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 44,
        title: const Text(
          "Núcleo familiar",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.medical_services),
            tooltip: "Historias clínicas",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicalHistoryListPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimens.paddingMedium),
              ..._children.asMap().entries.map((e) => _buildChildCard(e.key)),

              const SizedBox(height: AppDimens.paddingLarge),

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

              _buildSectionTitle("Contacto de emergencia"),

              TextFormField(
                controller: _emergencyNameController,
                decoration: const InputDecoration(
                  labelText: "Nombre",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? "Ingrese un nombre" : null,
              ),
              const SizedBox(height: AppDimens.paddingMedium),

              TextFormField(
                controller: _emergencyPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Teléfono",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? "Ingrese un teléfono" : null,
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