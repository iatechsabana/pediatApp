import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pediatrician_medical_history_page.dart';

class MedicalHistoryListForDoctor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historias clínicas realizadas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
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
              if (docs.isEmpty) {
                return const Center(child: Text('No hay historias clínicas encontradas.'));
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final data = docs[i].data();
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PediatricianMedicalHistoryPage(
                            patientId: data['patientId'] ?? '',
                            patientName: data['patientName'] ?? '',
                            pediatricianId: data['pediatricianId'],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Container(
                        width: 180,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              data['patientName'] ?? 'Paciente',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text('Documento: ${data['patientId'] ?? ''}', style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(
                              data['updatedAt'] != null && data['updatedAt'] is Timestamp
                                  ? 'Actualizado: ' + (data['updatedAt'] as Timestamp).toDate().toString().substring(0, 16)
                                  : '',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
