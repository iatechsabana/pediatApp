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
      appBar: AppBar(
        title: const Text('Perfil del Pediatra'),
        backgroundColor: Colors.teal,
      ),
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
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.teal.shade100,
                  child: const Icon(Icons.person, size: 60, color: Colors.teal),
                ),
                const SizedBox(height: 20),
                Text(data['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(data['email'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 16),
                if (data['specialty'] != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.medical_services, color: Colors.teal),
                      const SizedBox(width: 6),
                      Text(data['specialty'], style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                if (data['clinic'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_city, color: Colors.teal),
                        const SizedBox(width: 6),
                        Text(data['clinic'], style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                if (data['license'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.badge, color: Colors.teal),
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
                        const Icon(Icons.schedule, color: Colors.teal),
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
                        const Icon(Icons.map, color: Colors.teal),
                        const SizedBox(width: 6),
                        Text(data['address'], style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
