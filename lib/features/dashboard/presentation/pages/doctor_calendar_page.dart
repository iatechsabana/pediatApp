import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorCalendarPage extends StatelessWidget {
  final String doctorId;
  final String doctorName;
  final String mode; // 'consultorio' o 'domicilio'
  const DoctorCalendarPage({super.key, required this.doctorId, required this.doctorName, required this.mode});

  Future<Map<String, dynamic>> _fetchSchedule() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(doctorId).get();
    if (!doc.exists) return {};
    final data = doc.data() ?? {};
    if (mode == 'consultorio') {
      return Map<String, dynamic>.from(data['consultorioSchedule'] ?? {});
    } else {
      return Map<String, dynamic>.from(data['domicilioSchedule'] ?? {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda de $doctorName'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchSchedule(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final schedule = snapshot.data!;
          if (schedule.isEmpty) {
            return const Center(child: Text('El médico no tiene horarios configurados.'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Selecciona un día y hora disponible:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...schedule.entries.map((entry) {
                final day = entry.key;
                final from = entry.value['from'] ?? '--:--';
                final to = entry.value['to'] ?? '--:--';
                return ListTile(
                  title: Text(day),
                  subtitle: Text('De $from a $to'),
                  trailing: ElevatedButton(
                    child: const Text('Agendar'),
                    onPressed: from == '--:--' || to == '--:--'
                        ? null
                        : () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(hour: int.parse(from.split(':')[0]), minute: int.parse(from.split(':')[1])),
                            );
                            if (picked != null) {
                              // Aquí puedes crear la cita y notificar al médico
                              await FirebaseFirestore.instance.collection('appointments').add({
                                'doctorId': doctorId,
                                'doctorName': doctorName,
                                'mode': mode,
                                'day': day,
                                'hour': picked.format(context),
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Cita solicitada para $day a las ${picked.format(context)}.')),
                              );
                              // Aquí puedes agregar la notificación al médico
                              await FirebaseFirestore.instance.collection('notifications').add({
                                'toUserId': doctorId,
                                'type': 'cita',
                                'timestamp': FieldValue.serverTimestamp(),
                                'message': 'Tienes una nueva solicitud de cita para $day a las ${picked.format(context)}.',
                              });
                            }
                          },
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
