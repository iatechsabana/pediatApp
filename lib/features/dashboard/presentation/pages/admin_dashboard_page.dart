import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import 'document_viewer_page.dart';
import '../../../auth/presentation/pages/login_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return true;
    return (data['name']?.toLowerCase().contains(q) ?? false) ||
        (data['email']?.toLowerCase().contains(q) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: AppColors.primary,
            pinned: true,
            toolbarHeight: 48,
            title: const Text('Panel Administrador', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
              IconButton(icon: const Icon(Icons.logout), tooltip: 'Cerrar sesión', onPressed: _logout),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(96),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Buscar pediatra...',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimens.borderRadiusFull),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: const [
                      Tab(text: 'Pendientes'),
                      Tab(text: 'Habilitados'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildStatsBar()),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPendingList(),
            _buildEnabledList(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //   BARRA DE ESTADÍSTICAS
  // ============================================================
  Widget _buildStatsBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('type', isEqualTo: 'pediatra').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final pending = docs.where((d) => (d.data() as Map)['estado'] == 'pendiente').length;
        final enabled = docs.where((d) => (d.data() as Map)['estado'] == 'habilitado').length;

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _StatChip(label: 'Total', value: '${docs.length}', color: AppColors.info),
              const SizedBox(width: 12),
              _StatChip(label: 'Pendientes', value: '$pending', color: AppColors.warning),
              const SizedBox(width: 12),
              _StatChip(label: 'Habilitados', value: '$enabled', color: AppColors.success),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  //   LISTA PENDIENTES
  // ============================================================
  Widget _buildPendingList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('type', isEqualTo: 'pediatra')
          .where('estado', isEqualTo: 'pendiente')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs.where((d) => _matchesSearch(d.data() as Map<String, dynamic>)).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle_outline, size: 56, color: AppColors.success),
                SizedBox(height: 12),
                Text('No hay solicitudes pendientes', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimens.paddingLarge),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _PendingCard(
            doc: docs[i],
            onApprove: () => _approveUser(docs[i].id, docs[i].data() as Map<String, dynamic>),
            onReject: () => _rejectUser(docs[i].id, docs[i].data() as Map<String, dynamic>),
            onViewDocs: () => _openDocumentsDialog(docs[i].data() as Map<String, dynamic>),
          ),
        );
      },
    );
  }

  // ============================================================
  //   LISTA HABILITADOS
  // ============================================================
  Widget _buildEnabledList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('type', isEqualTo: 'pediatra')
          .where('estado', isEqualTo: 'habilitado')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs.where((d) => _matchesSearch(d.data() as Map<String, dynamic>)).toList();

        if (docs.isEmpty) {
          return const Center(
            child: Text('No hay pediatras habilitados.', style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimens.paddingLarge),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.success.withValues(alpha: 0.12),
                  child: const Icon(Icons.check_circle, color: AppColors.success),
                ),
                title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['email'] ?? '', style: const TextStyle(fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.block, color: AppColors.error),
                  tooltip: 'Deshabilitar',
                  onPressed: () => _disableUser(docs[i].id, data),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  //   ACCIONES
  // ============================================================
  Future<void> _approveUser(String id, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('users').doc(id).update({'estado': 'habilitado'});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pediatra aprobado exitosamente'), backgroundColor: AppColors.success),
    );
  }

  Future<void> _rejectUser(String id, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge)),
        title: const Text('Rechazar registro'),
        content: const Text('¿Eliminar el registro y todos sus archivos? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final urls = <String>[];
    void addUrl(String? url) { if (url != null && url.isNotEmpty) urls.add(url); }
    addUrl(data['polizaUrl']);
    addUrl(data['tarjetaProfesionalUrl']);
    addUrl(data['documentoIdentidadFrenteUrl']);
    addUrl(data['documentoIdentidadReversoUrl']);

    for (final url in urls) {
      try { await FirebaseStorage.instance.refFromURL(url).delete(); } catch (_) {}
    }

    await FirebaseFirestore.instance.collection('users').doc(id).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro eliminado'), backgroundColor: AppColors.error),
    );
  }

  Future<void> _disableUser(String id, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge)),
        title: const Text('Deshabilitar pediatra'),
        content: Text('¿Deshabilitar la cuenta de ${data['name'] ?? 'este pediatra'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deshabilitar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await FirebaseFirestore.instance.collection('users').doc(id).update({'estado': 'deshabilitado'});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pediatra deshabilitado')),
    );
  }

  void _openDocumentsDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge)),
        title: Text('Documentos — ${data['name'] ?? ''}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _docTile(data['polizaUrl'], 'Póliza de responsabilidad', Icons.shield_outlined),
              _docTile(data['tarjetaProfesionalUrl'], 'Tarjeta profesional', Icons.credit_card_outlined),
              _docTile(data['documentoIdentidadFrenteUrl'], 'Documento identidad (frente)', Icons.badge_outlined),
              _docTile(data['documentoIdentidadReversoUrl'], 'Documento identidad (reverso)', Icons.badge_outlined),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _docTile(String? url, String label, IconData icon) {
    if (url == null || url.isEmpty) {
      return ListTile(
        leading: Icon(icon, color: Colors.grey.shade400),
        title: Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        trailing: const Icon(Icons.close, color: Colors.grey, size: 16),
        dense: true,
      );
    }
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.open_in_new, color: AppColors.primary, size: 16),
      dense: true,
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentViewerPage(url: url, title: label)));
      },
    );
  }
}

// ============================================================
//   WIDGET — TARJETA PENDIENTE
// ============================================================
class _PendingCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewDocs;

  const _PendingCard({
    required this.doc,
    required this.onApprove,
    required this.onReject,
    required this.onViewDocs,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final polizaOk = (data['polizaUrl'] ?? '').toString().isNotEmpty;
    final tarjetaOk = (data['tarjetaProfesionalUrl'] ?? '').toString().isNotEmpty;
    final canApprove = polizaOk && tarjetaOk;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        border: Border.all(
          color: canApprove ? Colors.transparent : AppColors.warning.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(
                (data['name'] ?? 'P').toString().isNotEmpty ? data['name'][0].toUpperCase() : 'P',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['email'] ?? '', style: const TextStyle(fontSize: 12)),
                if (data['phone'] != null && data['phone'].toString().isNotEmpty)
                  Text(data['phone'], style: const TextStyle(fontSize: 12)),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.folder_open_outlined, color: AppColors.info),
                  tooltip: 'Ver documentos',
                  onPressed: onViewDocs,
                ),
                IconButton(
                  icon: Icon(Icons.check_circle, color: canApprove ? AppColors.success : Colors.grey.shade400),
                  tooltip: canApprove ? 'Aprobar' : 'Faltan documentos',
                  onPressed: canApprove ? onApprove : null,
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: AppColors.error),
                  tooltip: 'Rechazar',
                  onPressed: onReject,
                ),
              ],
            ),
          ),
          if (!canApprove)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    _missingDocsText(polizaOk, tarjetaOk),
                    style: const TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _missingDocsText(bool poliza, bool tarjeta) {
    if (!poliza && !tarjeta) return 'Faltan: póliza y tarjeta profesional';
    if (!poliza) return 'Falta: póliza de responsabilidad';
    return 'Falta: tarjeta profesional';
  }
}

// ============================================================
//   WIDGET — CHIP DE ESTADÍSTICA
// ============================================================
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
