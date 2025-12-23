import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'public_profile_page.dart';

class SpecialistListPage extends StatelessWidget {
  final String service;
  const SpecialistListPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Especialistas: ${_serviceLabel(service)}'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('type', isEqualTo: 'pediatra')
            .where('servicio_ofrecidos', arrayContains: service)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay especialistas disponibles para este servicio.'));
          }
          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 18),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final name = data['name'] ?? 'Sin nombre';
              final specialty = data['specialty'] ?? '';
              final city = data['city'] ?? '';
              final experience = data['experience'] != null && data['experience'].toString().isNotEmpty
                  ? '${data['experience']} años de experiencia'
                  : null;
              final phone = data['phone'] ?? '';
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicProfilePage(
                        userId: docs[i].id,
                        userName: name,
                        userAvatar: data['photoUrl'],
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.teal.withOpacity(0.18), width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: (data['photoUrl'] ?? '').toString().isNotEmpty
                            ? NetworkImage(data['photoUrl'])
                            : const AssetImage('assets/images/doctorkids_logo.png') as ImageProvider,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Colors.teal,
                              ),
                            ),
                            if (specialty.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  specialty,
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              ),
                            if (city.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_city, size: 15, color: Colors.teal),
                                    SizedBox(width: 4),
                                    Text(city, style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            if (experience != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.school, size: 15, color: Colors.teal),
                                    SizedBox(width: 4),
                                    Text(experience, style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            if (phone.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone, size: 15, color: Colors.teal),
                                    SizedBox(width: 4),
                                    Text(phone, style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.teal),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _serviceLabel(String value) {
    switch (value) {
      case 'telemedicina':
        return 'Telemedicina';
      case 'consultorio':
        return 'Consultorio';
      case 'domicilio':
        return 'Domicilio';
      default:
        return value;
    }
  }
}
