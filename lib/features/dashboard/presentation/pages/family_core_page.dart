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
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  final List<_ChildInfo> _children = [];
  bool _saving = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _load();
    _fatherController.addListener(() { if (mounted) setState(() {}); });
    _motherController.addListener(() { if (mounted) setState(() {}); });
  }

  Future<void> _load() async {
    if (_uid.isEmpty) return;
    final doc = await FirebaseFirestore.instance.collection('family_cores').doc(_uid).get();
    if (!doc.exists || !mounted) return;
    final data = doc.data()!;
    _fatherController.text = data['father'] ?? '';
    _motherController.text = data['mother'] ?? '';
    _caregiverController.text = data['caregiver'] ?? '';
    _addressController.text = data['address'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _emergencyNameController.text = data['emergencyName'] ?? '';
    _emergencyPhoneController.text = data['emergencyPhone'] ?? '';
    final children = (data['children'] as List?) ?? [];
    _children.clear();
    for (final c in children) {
      final child = _ChildInfo();
      child.nameController.text = c['name'] ?? '';
      child.dobController.text = c['dob'] ?? '';
      child.notesController.text = c['notes'] ?? '';
      child.nameController.addListener(() { if (mounted) setState(() {}); });
      _children.add(child);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _fatherController.dispose();
    _motherController.dispose();
    _caregiverController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    for (final c in _children) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_uid.isEmpty) return;
    setState(() => _saving = true);
    final childrenData = _children.map((c) => {
      'name': c.nameController.text.trim(),
      'dob': c.dobController.text.trim(),
      'notes': c.notesController.text.trim(),
    }).toList();
    await FirebaseFirestore.instance.collection('family_cores').doc(_uid).set({
      'father': _fatherController.text.trim(),
      'mother': _motherController.text.trim(),
      'caregiver': _caregiverController.text.trim(),
      'address': _addressController.text.trim(),
      'phone': _phoneController.text.trim(),
      'emergencyName': _emergencyNameController.text.trim(),
      'emergencyPhone': _emergencyPhoneController.text.trim(),
      'children': childrenData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Núcleo familiar guardado'), backgroundColor: AppColors.success),
    );
  }

  void _addChild() {
    final child = _ChildInfo();
    child.nameController.addListener(() { if (mounted) setState(() {}); });
    setState(() => _children.add(child));
  }

  Future<void> _removeChild(int index) async {
    final name = _children[index].nameController.text.trim();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge)),
        title: const Text('Eliminar hijo'),
        content: Text('¿Eliminar a ${name.isEmpty ? 'este hijo' : name} del núcleo familiar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() {
      _children[index].dispose();
      _children.removeAt(index);
    });
  }

  Future<void> _pickDob(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2018),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _children[index].dobController.text = '${picked.day}/${picked.month}/${picked.year}');
    }
  }

  String _computeAge(String dob) {
    if (dob.isEmpty) return '';
    try {
      final parts = dob.split('/');
      if (parts.length != 3) return '';
      final birth = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      final now = DateTime.now();
      int years = now.year - birth.year;
      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) years--;
      if (years < 1) {
        int months = (now.year - birth.year) * 12 + now.month - birth.month;
        if (now.day < birth.day) months--;
        return '$months ${months == 1 ? 'mes' : 'meses'}';
      }
      return '$years ${years == 1 ? 'año' : 'años'}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.primary,
              pinned: true,
              toolbarHeight: 48,
              title: const Text('Núcleo familiar', style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
              actions: [
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.save_outlined),
                    tooltip: 'Guardar',
                    onPressed: _save,
                  ),
              ],
            ),
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.all(AppDimens.paddingLarge),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildChildrenSection(),
                  const SizedBox(height: AppDimens.paddingLarge),
                  _buildFamilyInfoSection(),
                  const SizedBox(height: AppDimens.paddingLarge),
                  _buildEmergencySection(),
                  const SizedBox(height: AppDimens.paddingLarge),
                  _buildSaveButton(),
                  const SizedBox(height: AppDimens.paddingHuge),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final father = _fatherController.text.trim();
    final mother = _motherController.text.trim();
    final count = _children.length;
    final parents = [if (father.isNotEmpty) father, if (mother.isNotEmpty) mother].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge),
            ),
            child: const Icon(Icons.family_restroom, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 0
                      ? 'Sin hijos registrados'
                      : '$count ${count == 1 ? 'hijo registrado' : 'hijos registrados'}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (parents.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    parents,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.child_care, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Hijos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: _addChild,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Agregar'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        if (_children.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
                SizedBox(width: 10),
                Text('No hay hijos registrados aún', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ...List.generate(_children.length, _buildChildCard),
      ],
    );
  }

  Widget _buildChildCard(int index) {
    final child = _children[index];
    final name = child.nameController.text.trim();
    final dob = child.dobController.text.trim();
    final age = _computeAge(dob);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    const avatarColors = [
      Color(0xFF5C6BC0), Color(0xFF26A69A), Color(0xFF42A5F5),
      Color(0xFFEF5350), Color(0xFFF57C00), AppColors.primary,
    ];
    final cardColor = avatarColors[index % avatarColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge)),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: cardColor,
          child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        title: Text(
          name.isEmpty ? 'Hijo ${index + 1}' : name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: age.isNotEmpty
            ? Text(age, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
            : (dob.isNotEmpty ? Text(dob, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)) : null),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.history_edu_outlined, color: AppColors.primary, size: 20),
              tooltip: 'Historial médico',
              onPressed: name.isNotEmpty
                  ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalHistoryListPage()))
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              tooltip: 'Eliminar',
              onPressed: () => _removeChild(index),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 8),
                _inputField(
                  controller: child.nameController,
                  label: 'Nombre completo',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: AppDimens.paddingSmall),
                _inputField(
                  controller: child.dobController,
                  label: 'Fecha de nacimiento',
                  icon: Icons.cake_outlined,
                  readOnly: true,
                  onTap: () => _pickDob(index),
                ),
                const SizedBox(height: AppDimens.paddingSmall),
                _inputField(
                  controller: child.notesController,
                  label: 'Antecedentes médicos',
                  icon: Icons.note_outlined,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyInfoSection() {
    return _sectionCard(
      icon: Icons.people_outline,
      title: 'Información familiar',
      children: [
        _inputField(controller: _fatherController, label: 'Nombre del padre', icon: Icons.man_outlined),
        const SizedBox(height: AppDimens.paddingSmall),
        _inputField(controller: _motherController, label: 'Nombre de la madre', icon: Icons.woman_outlined),
        const SizedBox(height: AppDimens.paddingSmall),
        _inputField(controller: _caregiverController, label: 'Cuidador principal', icon: Icons.supervisor_account_outlined),
        const SizedBox(height: AppDimens.paddingSmall),
        _inputField(controller: _addressController, label: 'Dirección del hogar', icon: Icons.home_outlined),
        const SizedBox(height: AppDimens.paddingSmall),
        _inputField(
          controller: _phoneController,
          label: 'Teléfono familiar',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildEmergencySection() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emergency_outlined, color: AppColors.error, size: 20),
              SizedBox(width: 8),
              Text(
                'Contacto de emergencia',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingMedium),
          const Divider(color: Color(0x22D32F2F)),
          const SizedBox(height: AppDimens.paddingMedium),
          _inputField(
            controller: _emergencyNameController,
            label: 'Nombre del contacto',
            icon: Icons.person_pin_outlined,
            validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: AppDimens.paddingSmall),
          _inputField(
            controller: _emergencyPhoneController,
            label: 'Teléfono de emergencia',
            icon: Icons.phone_in_talk_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: Text(_saving ? 'Guardando...' : 'Guardar núcleo familiar'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppDimens.paddingMedium),
          const Divider(height: 1),
          const SizedBox(height: AppDimens.paddingMedium),
          ...children,
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.scaffoldBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}

class _ChildInfo {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  void dispose() {
    nameController.dispose();
    dobController.dispose();
    notesController.dispose();
  }
}
