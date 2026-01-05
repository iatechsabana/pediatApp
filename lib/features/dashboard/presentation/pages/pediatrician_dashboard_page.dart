
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pediatrician_threads_page.dart';
import 'pediatrician_profile_page.dart';
import 'pediatrician_notifications_page.dart';
import '../../../chat/presentation/user_select_page.dart';
import '../../../chat/presentation/chat_pages.dart';

class PediatricianDashboardPage extends StatefulWidget {
  const PediatricianDashboardPage({super.key});

  @override
  State<PediatricianDashboardPage> createState() => _PediatricianDashboardPageState();
}

class _PediatricianDashboardPageState extends State<PediatricianDashboardPage> {
  int _selectedIndex = 1;

  Widget _buildHeader(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchPediatricianData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data;
        final String nombre = data?['name'] ?? 'Pediatra';
        final int creditos = data?['credits'] ?? 0;
        final int pendientes = data?['pending'] ?? 0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFBDEEE6), Color(0xFF1ABC9C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              (data != null && data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty)
                  ? CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(data['photoUrl']),
                      backgroundColor: Colors.white,
                    )
                  : CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: const AssetImage('assets/images/doctorkids_logo.png'),
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Pediatra',
                      style: TextStyle(fontSize: 13, color: Colors.black54, fontFamily: 'Roboto'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                        const SizedBox(width: 3),
                        Text('$creditos créditos', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        const SizedBox(width: 10),
                        Icon(Icons.pending_actions, color: Colors.orange, size: 18),
                        const SizedBox(width: 3),
                        Text('$pendientes pendientes', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat, color: Colors.teal, size: 26),
                tooltip: 'Chat entre colegas',
                onPressed: () async {
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  final dynamic result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserSelectPage()),
                  );
                  final String? selectedUserId = (result is String && result.isNotEmpty) ? result : null;
                  if (selectedUserId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Debes seleccionar un usuario válido para chatear.')),
                    );
                    return;
                  }
                  if (selectedUserId == currentUserId || currentUserId == null || currentUserId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se puede iniciar el chat: usuario inválido.')),
                    );
                    return;
                  }
                  // Buscar o crear chat y navegar
                  final chatsQuery = await FirebaseFirestore.instance
                      .collection('chats')
                      .where('participants', arrayContains: currentUserId)
                      .get();
                  String? chatId;
                  for (var doc in chatsQuery.docs) {
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
                  if (chatId == null || chatId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se pudo crear el chat.')), 
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatConversationPage(
                        chatId: chatId!,
                        currentUserId: currentUserId!,
                        otherUserId: selectedUserId!,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchPediatricianData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      PediatricianProfilePage(),
      Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: PediatricianThreadsPage(
              onTapOwnProfile: () => setState(() => _selectedIndex = 0),
            ),
          ),
        ],
      ),
      // Notificaciones
      PediatricianNotificationsPage(),
      // Historia clínica (puedes crear una página más completa luego)
      Center(
        child: Text(
          'Historia clínica',
          style: TextStyle(fontSize: 20, color: Colors.teal),
        ),
      ),
    ];
    return Scaffold(
      // AppBar eliminado para ahorrar espacio en blanco superior
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.teal,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups),
              label: 'Comunidad',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notificaciones',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu),
              label: 'Historia clínica',
            ),
          ],
        ),
      ),
    );
  }
}
