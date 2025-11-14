import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PediatricianProfilePage extends StatelessWidget {
  const PediatricianProfilePage({super.key});

  Future<Map<String, dynamic>?> _getProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No se encontró información.'));
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFBDEEE6), Color(0xFF1ABC9C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.person, size: 60, color: Colors.teal),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        data['name'] ?? '',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal, fontFamily: 'Roboto'),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data['email'] ?? '',
                        style: const TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (data['specialty'] != null) ...[
                            const Icon(Icons.medical_services, color: Colors.teal, size: 20),
                            const SizedBox(width: 6),
                            Text(data['specialty'], style: const TextStyle(fontSize: 16)),
                          ],
                          if (data['clinic'] != null) ...[
                            const SizedBox(width: 16),
                            const Icon(Icons.location_city, color: Colors.teal, size: 20),
                            const SizedBox(width: 6),
                            Text(data['clinic'], style: const TextStyle(fontSize: 16)),
                          ],
                        ],
                      ),
                      if (data['license'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.badge, color: Colors.teal, size: 20),
                              const SizedBox(width: 6),
                              Text('Licencia: ${data['license']}', style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      if (data['experience'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.schedule, color: Colors.teal, size: 20),
                              const SizedBox(width: 6),
                              Text('${data['experience']} años de experiencia', style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      if (data['address'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.map, color: Colors.teal, size: 20),
                              const SizedBox(width: 6),
                              Text(data['address'], style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatBox(Icons.groups, 'Comunidad', '12'),
                      _buildStatBox(Icons.comment, 'Comentarios', '34'),
                      _buildStatBox(Icons.monetization_on, 'Créditos', '12'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sobre mí', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                      const SizedBox(height: 10),
                      Text(
                        data['about'] ?? 'Pediatra comprometido con la salud infantil.',
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.edit, color: Colors.white),
                            label: const Text('Editar perfil'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await FirebaseAuth.instance.signOut();
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.clear();
                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const LoginPage()),
                                    (route) => false,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error al cerrar sesión: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.logout, color: Colors.teal),
                            label: const Text('Cerrar sesión', style: TextStyle(color: Colors.teal)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.teal),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatBox(IconData icon, String label, String value) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.teal.shade50,
          child: Icon(icon, color: Colors.teal, size: 26),
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ],
    );
  }
}
