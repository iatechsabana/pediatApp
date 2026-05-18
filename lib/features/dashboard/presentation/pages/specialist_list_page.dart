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
        toolbarHeight: 44,
        title: Text('Especialistas: ${_serviceLabel(service)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.teal,
        centerTitle: true,
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
                                        final user = FirebaseAuth.instance.currentUser;
                                        if (user == null) return;
                                        final toUserId = docs[i].id;
                                        if (toUserId == null || toUserId.toString().isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Error: No se pudo identificar al médico.')),
                                          );
                                          return;
                                        }
                                        // Obtener hijos del usuario desde family_cores
                                        final familyDoc = await FirebaseFirestore.instance.collection('family_cores').doc(user.uid).get();
                                        final children = (familyDoc.data()?['children'] ?? []) as List<dynamic>;
                                        if (!context.mounted) return;
                                        if (children.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Debes registrar un hijo en "Núcleo familiar" antes de solicitar una consulta.'),
                                              duration: Duration(seconds: 4),
                                            ),
                                          );
                                          return;
                                        }
                                        // Selección de hijo con UI de tarjetas
                                        int selectedIndex = 0;
                                        const avatarColors = [
                                          Color(0xFF5C6BC0), Color(0xFF26A69A), Color(0xFF42A5F5),
                                          Color(0xFFEF5350), Color(0xFFF57C00), Color(0xFF1ABC9C),
                                        ];
                                        final confirm = await showDialog<Map<String, dynamic>>(
                                          context: context,
                                          builder: (dlgCtx) => StatefulBuilder(
                                            builder: (dlgCtx, setDlgState) {
                                              return AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                title: const Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('¿Para cuál hijo es la consulta?',
                                                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                                    SizedBox(height: 4),
                                                    Text('Selecciona al paciente',
                                                        style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.normal)),
                                                  ],
                                                ),
                                                content: SizedBox(
                                                  width: double.maxFinite,
                                                  child: ListView.separated(
                                                    shrinkWrap: true,
                                                    itemCount: children.length,
                                                    separatorBuilder: (_, i) => const SizedBox(height: 8),
                                                    itemBuilder: (_, idx) {
                                                      final child = children[idx] as Map<String, dynamic>;
                                                      final childName = (child['name'] as String?) ?? 'Hijo ${idx + 1}';
                                                      final dob = (child['dob'] as String?) ?? '';
                                                      final color = avatarColors[idx % avatarColors.length];
                                                      final initial = childName.isNotEmpty ? childName[0].toUpperCase() : '?';
                                                      final isSelected = selectedIndex == idx;

                                                      // Calcular edad desde dob (dd/MM/yyyy)
                                                      String age = '';
                                                      if (dob.isNotEmpty) {
                                                        try {
                                                          final parts = dob.split('/');
                                                          if (parts.length == 3) {
                                                            final birth = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                                                            final now = DateTime.now();
                                                            int years = now.year - birth.year;
                                                            if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) years--;
                                                            if (years < 1) {
                                                              int months = (now.year - birth.year) * 12 + now.month - birth.month;
                                                              if (now.day < birth.day) months--;
                                                              age = '$months ${months == 1 ? 'mes' : 'meses'}';
                                                            } else {
                                                              age = '$years ${years == 1 ? 'año' : 'años'}';
                                                            }
                                                          }
                                                        } catch (_) {}
                                                      }

                                                      return GestureDetector(
                                                        onTap: () => setDlgState(() => selectedIndex = idx),
                                                        child: AnimatedContainer(
                                                          duration: const Duration(milliseconds: 150),
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                          decoration: BoxDecoration(
                                                            color: isSelected ? color.withAlpha(25) : Colors.grey.shade50,
                                                            borderRadius: BorderRadius.circular(14),
                                                            border: Border.all(
                                                              color: isSelected ? color : Colors.grey.shade200,
                                                              width: isSelected ? 2 : 1,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              CircleAvatar(
                                                                radius: 22,
                                                                backgroundColor: color,
                                                                child: Text(initial,
                                                                    style: const TextStyle(
                                                                        color: Colors.white,
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: 16)),
                                                              ),
                                                              const SizedBox(width: 12),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(childName,
                                                                        style: TextStyle(
                                                                          fontWeight: FontWeight.w700,
                                                                          fontSize: 15,
                                                                          color: isSelected ? color : Colors.black87,
                                                                        )),
                                                                    if (age.isNotEmpty)
                                                                      Text(age,
                                                                          style: const TextStyle(
                                                                              fontSize: 12, color: Colors.black54)),
                                                                  ],
                                                                ),
                                                              ),
                                                              if (isSelected)
                                                                Icon(Icons.check_circle, color: color, size: 22),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(dlgCtx, null),
                                                    child: const Text('Cancelar'),
                                                  ),
                                                  ElevatedButton.icon(
                                                    onPressed: () => Navigator.pop(dlgCtx, {'child': children[selectedIndex]}),
                                                    icon: const Icon(Icons.video_call, size: 18),
                                                    label: const Text('Solicitar consulta'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.blue,
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        );
                                        if (confirm == null || confirm['child'] == null) return;
                                        final selectedChild = confirm['child'] as Map<String, dynamic>;
                                        // Generar un roomId único
                                        final roomId = 'room_${user.uid}_${toUserId}_${DateTime.now().millisecondsSinceEpoch}';
                                        // Crear registro de videollamada en Firestore
                                        final videocallDoc = await FirebaseFirestore.instance.collection('videocalls').add({
                                          'roomId': roomId,
                                          'fromUserId': user.uid,
                                          'toUserId': toUserId,
                                          'status': 'pendiente', // pendiente, aceptada, rechazada
                                          'timestamp': FieldValue.serverTimestamp(),
                                          'child': selectedChild,
                                        });
                                        // Crear notificación en Firestore para el médico
                                        final childName = (selectedChild['name'] as String?) ?? 'un paciente';
                                        await FirebaseFirestore.instance.collection('notifications').add({
                                          'toUserId': toUserId,
                                          'fromUserId': user.uid,
                                          'type': 'videollamada',
                                          'title': 'Solicitud de videollamada',
                                          'message': 'Nueva videollamada para atender a $childName.',
                                          'timestamp': FieldValue.serverTimestamp(),
                                          'userName': user.displayName ?? '',
                                          'videocallId': videocallDoc.id,
                                          'roomId': roomId,
                                          'child': selectedChild,
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
