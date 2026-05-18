import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../assistant/presentation/pages/assistant_page.dart';
import 'request_service_page.dart';
import 'medical_history_list_page.dart';
import 'family_core_page.dart';
import '_thread_comments_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _tab = 0;
  String _userName = 'Usuario';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name') ?? '';
    if (mounted && name.isNotEmpty) {
      setState(() => _userName = name.split(' ').first);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: IndexedStack(
        index: _tab,
        children: [
          _HomeTab(userName: _userName, onLogout: _logout),
          const MedicalHistoryListPage(),
          const FamilyCorePage(),
          const AssistantPage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.iconSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.history_edu_outlined), activeIcon: Icon(Icons.history_edu), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.family_restroom_outlined), activeIcon: Icon(Icons.family_restroom), label: 'Familia'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), activeIcon: Icon(Icons.smart_toy), label: 'Asistente'),
        ],
      ),
    );
  }
}

// ============================================================
//   TAB HOME
// ============================================================
class _HomeTab extends StatelessWidget {
  final String userName;
  final VoidCallback onLogout;

  const _HomeTab({required this.userName, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverToBoxAdapter(child: _buildHeader(context, userName)),
        SliverPadding(
          padding: const EdgeInsets.all(AppDimens.paddingLarge),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildMetricsRow(uid),
              const SizedBox(height: AppDimens.paddingLarge),
              _buildQuickActions(context),
              const SizedBox(height: AppDimens.paddingLarge),
              const Text('Publicaciones de médicos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppDimens.paddingSmall),
              _buildThreads(),
              const SizedBox(height: AppDimens.paddingHuge),
            ]),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.primary,
      pinned: true,
      toolbarHeight: 48,
      title: const Text('DoctorKids', style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: onLogout,
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hola, $name 👋', style: const TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('¿Cómo estás hoy?', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestServicePage())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.borderRadiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_circle_outline, color: AppColors.primary, size: 18),
                  SizedBox(width: 6),
                  Text('Solicitar consulta', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(String? uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: uid == null
          ? const Stream.empty()
          : FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnap) {
        return StreamBuilder<DocumentSnapshot>(
          stream: uid == null
              ? const Stream.empty()
              : FirebaseFirestore.instance.collection('family_cores').doc(uid).snapshots(),
          builder: (context, familySnap) {
            final credits = (userSnap.data?.data() as Map<String, dynamic>?)?['credits'] ?? 0;
            final children = ((familySnap.data?.data() as Map<String, dynamic>?)?['children'] as List?)?.length ?? 0;

            return Row(
              children: [
                Expanded(child: _MetricCard(icon: Icons.child_care, label: 'Hijos registrados', value: '$children', color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _MetricCard(icon: Icons.monetization_on_outlined, label: 'Créditos', value: '$credits', color: AppColors.warning)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(icon: Icons.medical_services_outlined, label: 'Historial médico', color: const Color(0xFF5C6BC0),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalHistoryListPage()))),
      _QuickAction(icon: Icons.family_restroom, label: 'Núcleo familiar', color: const Color(0xFF26A69A),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyCorePage()))),
      _QuickAction(icon: Icons.people_outline, label: 'Especialistas', color: const Color(0xFF42A5F5),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestServicePage()))),
      _QuickAction(icon: Icons.smart_toy_outlined, label: 'Asistente IA', color: const Color(0xFFEF5350),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssistantPage()))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Accesos rápidos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: AppDimens.paddingSmall),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: actions.map((a) => _buildActionTile(a)).toList(),
        ),
      ],
    );
  }

  Widget _buildActionTile(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimens.borderRadiusMedium),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreads() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('threads').orderBy('createdAt', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final threads = snapshot.data?.docs ?? [];
        if (threads.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
            ),
            child: const Center(child: Text('No hay publicaciones aún.', style: TextStyle(color: AppColors.textSecondary))),
          );
        }
        return Column(
          children: threads.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final author = data['authorName'] ?? 'Médico';
            final content = data['content'] ?? '';
            final ts = data['createdAt'];
            final date = ts is Timestamp ? ts.toDate() : null;
            final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(author.isNotEmpty ? author[0].toUpperCase() : 'M',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(dateStr, style: const TextStyle(fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(content, style: const TextStyle(fontSize: 14)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: ThreadCommentsWidget(threadId: doc.id),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimens.borderRadiusMedium),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
}
