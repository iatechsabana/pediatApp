import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'video_call_waiting_page.dart';
import 'public_profile_page.dart';
import '../../../chat/presentation/chat_pages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_calendar_page.dart'; // <-- Import agregado


class SpecialistListPage extends StatelessWidget {
  final String service;
  const SpecialistListPage({super.key, required this.service});

  String _serviceLabel(String service) {
    switch (service) {
      case 'telemedicina':
        return 'Telemedicina';
      case 'consultorio':
        return 'Consultorio';
      case 'domicilio':
        return 'Domicilio';
      default:
        return service;
    }
  }

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
              return Container(
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withAlpha(33),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.teal.shade200, width: 2),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: (data['photoUrl'] ?? '').toString().isNotEmpty
                          ? NetworkImage(data['photoUrl'])
                          : const AssetImage('assets/images/doctorkids_logo.png') as ImageProvider,
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.teal.shade800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (specialty.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 6),
                              child: Text(
                                specialty,
                                style: TextStyle(fontSize: 15, color: Colors.teal.shade900, fontWeight: FontWeight.w500),
                              ),
                            ),
                          if (service == 'telemedicina')
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  SizedBox(
                                    width: 140,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.chat),
                                      label: const Text('Chat', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(40, 36),
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                      onPressed: () async {
                                        final user = FirebaseAuth.instance.currentUser;
                                        final toUserId = docs[i].id;
                                        if (toUserId == null || toUserId.toString().isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Error: No se pudo identificar al médico.')),
                                          );
                                          return;
                                        }
                                        if (user != null) {
                                          // Buscar o crear chat
                                          final chatsQuery = await FirebaseFirestore.instance
                                              .collection('chats')
                                              .where('participants', arrayContains: user.uid)
                                              .get();
                                          String? chatId;
                                          for (var doc in chatsQuery.docs) {
                                            final participants = List<String>.from(doc['participants'] ?? []);
                                            if (participants.contains(toUserId)) {
                                              chatId = doc.id;
                                              break;
                                            }
                                          }
                                          if (chatId == null) {
                                            final newChat = await FirebaseFirestore.instance.collection('chats').add({
                                              'participants': [user.uid, toUserId],
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
                                                currentUserId: user.uid,
                                                otherUserId: toUserId,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 140,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.video_call),
                                      label: const Text('Videollamada', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(40, 36),
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Confirmar solicitud'),
                                            content: const Text('¿Deseas solicitar una videollamada con este médico?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Cancelar'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('Solicitar'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm != true) return;
                                        final user = FirebaseAuth.instance.currentUser;
                                        if (user == null) return;
                                        final toUserId = docs[i].id;
                                        if (toUserId == null || toUserId.toString().isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Error: No se pudo identificar al médico.')),
                                          );
                                          return;
                                        }
                                        // Generar un roomId único
                                        final roomId = 'room_${user.uid}_${toUserId}_${DateTime.now().millisecondsSinceEpoch}';
                                        // Crear registro de videollamada en Firestore
                                        final videocallDoc = await FirebaseFirestore.instance.collection('videocalls').add({
                                          'roomId': roomId,
                                          'fromUserId': user.uid,
                                          'toUserId': toUserId,
                                          'status': 'pendiente', // pendiente, aceptada, rechazada
                                          'timestamp': FieldValue.serverTimestamp(),
                                        });
                                        // Crear notificación en Firestore para el médico
                                        await FirebaseFirestore.instance.collection('notifications').add({
                                          'toUserId': toUserId,
                                          'fromUserId': user.uid,
                                          'type': 'videollamada',
                                          'title': 'Solicitud de videollamada',
                                          'message': 'Tienes una nueva solicitud de videollamada de un paciente.',
                                          'timestamp': FieldValue.serverTimestamp(),
                                          'userName': user.displayName ?? '',
                                          'videocallId': videocallDoc.id,
                                          'roomId': roomId,
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Se notificó al médico para la videollamada.')),
                                        );
                                        // Navegar a la sala de videollamada y escuchar el estado
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => VideoCallWaitingPage(
                                              roomId: roomId,
                                              videocallId: videocallDoc.id,
                                              toUserId: toUserId,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (service == 'consultorio' || service == 'domicilio')
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: SizedBox(
                                width: 180,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.calendar_month),
                                  label: const Text('Agendar cita', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(40, 36),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DoctorCalendarPage(
                                          doctorId: docs[i].id,
                                          doctorName: name,
                                          mode: service,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.info_outline, color: Colors.teal.shade700),
                      onPressed: () {
                        final toUserId = docs[i].id;
                        if (toUserId == null || toUserId.toString().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error: No se pudo identificar al médico.')),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PublicProfilePage(
                              userId: toUserId,
                              userName: name,
                              userAvatar: data['photoUrl'],
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
        },
      ),
    );
  }
}
