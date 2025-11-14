
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pediatrician_threads_page.dart';
import 'pediatrician_profile_page.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFBDEEE6), Color(0xFF1ABC9C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: const Icon(Icons.person, size: 38, color: Colors.teal),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pediatra',
                      style: TextStyle(fontSize: 15, color: Colors.black54, fontFamily: 'Roboto'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text('$creditos créditos', style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(width: 16),
                        Icon(Icons.pending_actions, color: Colors.orange, size: 20),
                        const SizedBox(width: 4),
                        Text('$pendientes pendientes', style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat, color: Colors.teal, size: 30),
                tooltip: 'Chat entre colegas',
                onPressed: () {},
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
    final List<Widget> _pages = [
      PediatricianProfilePage(),
      Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          const Expanded(child: PediatricianThreadsPage()),
        ],
      ),
      Center(
        child: Text(
          'Citas programadas',
          style: TextStyle(fontSize: 20, color: Colors.teal),
        ),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.teal,
        automaticallyImplyLeading: false,
      ),
      body: _pages[_selectedIndex],
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
              icon: Icon(Icons.calendar_month),
              label: 'Citas',
            ),
          ],
        ),
      ),
    );
  }
}
