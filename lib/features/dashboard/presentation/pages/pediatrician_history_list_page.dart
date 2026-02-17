import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pediatrician_medical_history_page.dart';

class PediatricianHistoryListPage extends StatefulWidget {
  const PediatricianHistoryListPage({super.key});

  @override
  State<PediatricianHistoryListPage> createState() => _PediatricianHistoryListPageState();
}

class _PediatricianHistoryListPageState extends State<PediatricianHistoryListPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no autenticado')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historias clínicas realizadas'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre o documento',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _search = value.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('medical_histories')
                  .where('pediatricianId', isEqualTo: user.uid)
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((doc) {
                  final data = doc.data();
                  final name = (data['patientName'] ?? '').toString().toLowerCase();
                  final docId = (data['patientId'] ?? '').toString().toLowerCase();
                  return _search.isEmpty || name.contains(_search) || docId.contains(_search);
                }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No hay historias clínicas encontradas.'));
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final data = filtered[i].data();
                    return ListTile(
                      title: Text(data['patientName'] ?? 'Paciente'),
                      subtitle: Text('Documento: ${data['patientId'] ?? ''}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PediatricianMedicalHistoryPage(
                              patientId: data['patientId'] ?? '',
                              patientName: data['patientName'] ?? '',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
