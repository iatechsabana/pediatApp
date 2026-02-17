import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'video_call_page.dart';

class PediatricianNotificationsPage extends StatefulWidget {
  const PediatricianNotificationsPage({super.key});

  @override
  State<PediatricianNotificationsPage> createState() =>
      _PediatricianNotificationsPageState();
}

class _PediatricianNotificationsPageState
    extends State<PediatricianNotificationsPage> {
  /// Caché local de notificaciones
  final Map<String, Map<String, dynamic>> _localNotifications = {};

  bool _loggedUid = false;

  @override
  void initState() {
    super.initState();
    // Muestra UID una sola vez (evita spam en cada rebuild)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (!mounted || user == null || _loggedUid) return;
      _loggedUid = true;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('UID autenticado: ${user.uid}')));
      debugPrint('UID autenticado: ${user.uid}');
    });
  }

  Future<void> _deleteNotification({
    required String notificationId,
    required AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
  }) async {
    // Eliminar del caché local primero (UI inmediata)
    setState(() {
      _localNotifications.remove(notificationId);
    });

    // Eliminar del backend
    final docs = snapshot.data?.docs ?? [];
    QueryDocumentSnapshot<Map<String, dynamic>>? docToDelete;
    try {
      docToDelete = docs.firstWhere((doc) => doc.id == notificationId);
    } catch (_) {
      docToDelete = null;
    }
    if (docToDelete != null) {
      await docToDelete.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Usuario no autenticado', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUserId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Actualizar caché local
          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              _localNotifications[doc.id] = doc.data();
            }
          }

          // Ordenar desde caché
          final notifications = _localNotifications.entries.toList()
            ..sort((a, b) {
              final ta =
                  (a.value['timestamp'] as Timestamp?)?.toDate() ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final tb =
                  (b.value['timestamp'] as Timestamp?)?.toDate() ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return tb.compareTo(ta);
            });

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'No tienes notificaciones.',
                style: TextStyle(fontSize: 15),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final id = notifications[i].key;
              final data = notifications[i].value;

              final type = (data['type'] ?? '').toString();
              final message = (data['message'] ?? '').toString();
              final userName = (data['userName'] ?? '').toString();
              final toUserId = (data['toUserId'] ?? '').toString();

              // ✅ Ajusta estos campos según tu estructura real:
              final patientId = (data['patientId'] ?? data['fromUserId'] ?? '')
                  .toString();
              final patientName = userName;

              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              IconData icon = Icons.notifications;
              Color color = Colors.teal;

              if (type == 'videollamada') {
                icon = Icons.video_call;
                color = Colors.blue;
              } else if (type == 'chat') {
                icon = Icons.chat;
                color = Colors.teal;
              } else if (type == 'consulta') {
                icon = Icons.medical_services;
                color = Colors.green;
              }

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: Icon(icon, color: color, size: 32),
                  title: Text(
                    message,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.black87,
                      letterSpacing: 0.2,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (userName.isNotEmpty)
                        Text(
                          'De: $userName',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.teal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Text(
                        'ID destino: $toUserId',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: timestamp != null
                      ? Text(
                          '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        )
                      : null,
                  onTap: () async {
                    // Validación rápida
                    if (toUserId != user.uid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Esta notificación no corresponde a tu usuario.',
                          ),
                        ),
                      );
                      return;
                    }

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Detalle de la notificación'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (userName.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Enviado por: $userName',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cerrar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: type == 'videollamada'
                                ? const Text('Iniciar videollamada')
                                : const Text('Ir a historia clínica'),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    if (type == 'videollamada') {
                      if (patientId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No se encontró el patientId en la notificación.',
                            ),
                          ),
                        );
                        return;
                      }

                      // Room único y consistente (médico + paciente)
                      final roomCode = '${user.uid}_$patientId';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoCallPage(
                            roomCode: roomCode,
                            userName: user.displayName ?? 'Médico',
                          ),
                        ),
                      );

                      await _deleteNotification(
                        notificationId: id,
                        snapshot: snapshot,
                      );
                      return;
                    }

                    // Otros tipos: crear/actualizar historia clínica
                    if (patientId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No se encontró el patientId en la notificación.',
                          ),
                        ),
                      );
                      return;
                    }

                    final docRef = FirebaseFirestore.instance
                        .collection('medical_histories')
                        .doc('${user.uid}_$patientId');

                    await docRef.set({
                      'pediatricianId': user.uid,
                      'patientId': patientId,
                      'patientName': patientName.isNotEmpty
                          ? patientName
                          : 'Paciente',
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                    await _deleteNotification(
                      notificationId: id,
                      snapshot: snapshot,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Historia actualizada.')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
