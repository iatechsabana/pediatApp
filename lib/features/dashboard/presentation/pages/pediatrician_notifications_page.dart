import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:collection';
import 'pediatrician_medical_history_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Usuario no autenticado',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    /// Log visual del UID del usuario autenticado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('UID autenticado: ${user.uid}'),
        ),
      );
      debugPrint('UID autenticado: ${user.uid}');
    });

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

          /// Actualizar el caché local con las notificaciones recibidas
          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              _localNotifications[doc.id] = doc.data();
            }
          }

          /// Obtener y ordenar notificaciones desde el caché local
          final notifications = _localNotifications.entries.toList()
            ..sort((a, b) {
              final ta =
                  (a.value['timestamp'] as Timestamp?)?.toDate() ??
                      DateTime.now();
              final tb =
                  (b.value['timestamp'] as Timestamp?)?.toDate() ??
                      DateTime.now();
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

              final type = data['type'] ?? '';
              final message = data['message'] ?? '';
              final userName = data['userName'] ?? '';
              final toUserId = data['toUserId'] ?? '';
              final timestamp =
                  (data['timestamp'] as Timestamp?)?.toDate();

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
                    /// Mostrar el mensaje completo y confirmar acción
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
                                style: const TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(ctx, false),
                            child: const Text('Cerrar'),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(ctx, true),
                            child:
                                const Text('Ir a historia clínica'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final user =
                          FirebaseAuth.instance.currentUser;
                      final patientId =
                          data['fromUserId'] ?? '';
                      final patientName =
                          data['userName'] ?? '';
                      final toUserId =
                          data['toUserId'] ?? '';

                      if (user != null &&
                          patientId.isNotEmpty &&
                          toUserId == user.uid) {
                        final docRef = FirebaseFirestore
                            .instance
                            .collection('medical_histories')
                            .doc(
                                '${user.uid}_$patientId');

                        await docRef.set(
                          {
                            'pediatricianId': user.uid,
                            'patientId': patientId,
                            'patientName': patientName,
                            'updatedAt': FieldValue
                                .serverTimestamp(),
                          },
                          SetOptions(merge: true),
                        );

                        /// Eliminar notificación del caché local
                        setState(() {
                          _localNotifications.remove(id);
                        });

                        /// Eliminar notificación de Firestore
                        final docs =
                            snapshot.data?.docs ?? [];
                        QueryDocumentSnapshot<
                                Map<String, dynamic>>?
                            docToDelete;

                        try {
                          docToDelete = docs.firstWhere(
                              (doc) => doc.id == id);
                        } catch (_) {
                          docToDelete = null;
                        }

                        if (docToDelete != null) {
                          await docToDelete.reference.delete();
                        }

                        /// Navegar a la historia clínica
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PediatricianMedicalHistoryPage(
                              patientId: patientId,
                              patientName:
                                  patientName.isNotEmpty
                                      ? patientName
                                      : 'Paciente',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Esta notificación no corresponde a tu usuario.',
                            ),
                          ),
                        );
                      }
                    }
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
