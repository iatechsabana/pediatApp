import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../chat/presentation/user_select_page.dart';
import '../../../chat/presentation/chat_pages.dart';
import 'pediatrician_threads_page.dart';
import 'pediatrician_profile_page.dart';
import 'pediatrician_notifications_page.dart';
import 'pediatrician_history_list_page.dart';
import 'doctor_calendar_page.dart';
import 'request_service_page.dart';

class PediatricianDashboardPage extends StatefulWidget {
  const PediatricianDashboardPage({super.key});

  @override
  State<PediatricianDashboardPage> createState() => _PediatricianDashboardPageState();
}

class _PediatricianDashboardPageState extends State<PediatricianDashboardPage> {
  int _selectedIndex = 0;

  Future<void> _openChat() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserSelectPage()),
    );
    if (!mounted) return;

    final String? selectedUserId = (result is String && result.isNotEmpty) ? result : null;
    if (selectedUserId == null || selectedUserId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un usuario válido para chatear.')),
      );
      return;
    }

    final chatsQuery = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();
    if (!mounted) return;

    String? chatId;
    for (final doc in chatsQuery.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);
      if (participants.contains(selectedUserId)) {
        chatId = doc.id;
        break;
      }
    }

    if (chatId == null) {
      final newChat = await FirebaseFirestore.instance.collection('chats').add({
        'participants': [currentUserId, selectedUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      chatId = newChat.id;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationPage(
          chatId: chatId!,
          currentUserId: currentUserId,
          otherUserId: selectedUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _PediatricianHomeTab(onChatTap: _openChat),
      PediatricianThreadsPage(onTapOwnProfile: () => setState(() => _selectedIndex = 3)),
      const PediatricianNotificationsPage(),
      const PediatricianHistoryListPage(),
      PediatricianProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: IndexedStack(index: _selectedIndex, children: pages),
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
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.iconSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Comunidad'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Alertas'),
          BottomNavigationBarItem(icon: Icon(Icons.history_edu_outlined), activeIcon: Icon(Icons.history_edu), label: 'Historias'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

// ============================================================
//   TAB HOME DEL PEDIATRA
// ============================================================
class _PediatricianHomeTab extends StatelessWidget {
  final VoidCallback onChatTap;

  const _PediatricianHomeTab({required this.onChatTap});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.primary,
          pinned: true,
          toolbarHeight: 48,
          title: const Text('DoctorKids', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.chat_outlined), tooltip: 'Chat', onPressed: onChatTap),
          ],
        ),
        SliverToBoxAdapter(child: _buildHeader(uid)),
        SliverPadding(
          padding: const EdgeInsets.all(AppDimens.paddingLarge),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildQuickActions(context),
              const SizedBox(height: AppDimens.paddingLarge),
              _buildUpcomingSection(uid),
              const SizedBox(height: AppDimens.paddingHuge),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String? uid) {
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final name = data?['name'] ?? 'Pediatra';
        final firstName = name.toString().split(' ').first;
        final credits = data?['credits'] ?? 0;
        final photoUrl = data?['photoUrl']?.toString() ?? '';

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
          child: Row(
            children: [
              photoUrl.isNotEmpty
                  ? CircleAvatar(radius: 32, backgroundImage: NetworkImage(photoUrl), backgroundColor: Colors.white)
                  : CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'P',
                        style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hola, Dr. $firstName 👋', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 2),
                    const Text('Bienvenido de nuevo', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _HeaderChip(icon: Icons.monetization_on, label: '$credits créditos', color: Colors.amber),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(icon: Icons.calendar_month_outlined, label: 'Calendario', color: AppColors.primary,
          onTap: () async {
            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
            if (uid.isEmpty || !context.mounted) return;
            final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
            final name = (doc.data()?['name'] ?? 'Pediatra') as String;
            if (!context.mounted) return;
            Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorCalendarPage(doctorId: uid, doctorName: name, mode: 'consultorio')));
          }),
      _QuickAction(icon: Icons.add_circle_outline, label: 'Nueva consulta', color: const Color(0xFF5C6BC0),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestServicePage()))),
      _QuickAction(icon: Icons.history_edu_outlined, label: 'Historias', color: const Color(0xFF26A69A),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PediatricianHistoryListPage()))),
      _QuickAction(icon: Icons.chat_outlined, label: 'Chat', color: const Color(0xFF42A5F5),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserSelectPage()))),
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
            Text(action.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(String? uid) {
    if (uid == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Solicitudes recientes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: AppDimens.paddingSmall),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('consultations')
              .where('doctorId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
                ),
                child: const Center(
                  child: Text('No hay solicitudes recientes.', style: TextStyle(color: AppColors.textSecondary)),
                ),
              );
            }
            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final patientName = data['patientName'] ?? 'Paciente';
                final status = data['status'] ?? 'pendiente';
                final ts = data['createdAt'];
                final date = ts is Timestamp ? ts.toDate() : null;
                final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: const Icon(Icons.person, color: AppColors.primary),
                    ),
                    title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(dateStr, style: const TextStyle(fontSize: 12)),
                    trailing: _StatusChip(status: status),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'activo' || status == 'confirmado';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusFull),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.warning,
        ),
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
