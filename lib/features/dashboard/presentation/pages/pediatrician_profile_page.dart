import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/presentation/pages/login_page.dart';

class PediatricianProfilePage extends StatefulWidget {
  const PediatricianProfilePage({super.key});

  @override
  State<PediatricianProfilePage> createState() =>
      _PediatricianProfilePageState();
}
class _PediatricianProfilePageState extends State<PediatricianProfilePage> {
  bool isEditingAbout = false;
  late TextEditingController aboutController;
  Map<String, Map<String, TimeOfDay?>> consultorioSchedule = {};
  final List<String> weekDays = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    aboutController = TextEditingController();
    _loadConsultorioSchedule();
  }

  @override
  void dispose() {
    aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadConsultorioSchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null && data['consultorioSchedule'] != null) {
      final sched = Map<String, dynamic>.from(data['consultorioSchedule']);
      final Map<String, Map<String, TimeOfDay?>> tempSchedule = {};
      sched.forEach((day, times) {
        final t = Map<String, dynamic>.from(times);
        tempSchedule[day] = {
          'from': t['from'] != null ? _parseTimeOfDay(t['from']) : null,
          'to': t['to'] != null ? _parseTimeOfDay(t['to']) : null,
        };
      });
      consultorioSchedule = tempSchedule;
      setState(() {});
    }
  }

  TimeOfDay? _parseTimeOfDay(String? s) {
    if (s == null) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay? t) {
    if (t == null) return '--:--';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}' ;
  }

  Future<void> _saveConsultorioSchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final sched = consultorioSchedule.map((day, times) => MapEntry(day, {
      'from': times['from'] != null ? _formatTimeOfDay(times['from']) : null,
      'to': times['to'] != null ? _formatTimeOfDay(times['to']) : null,
    }));
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'consultorioSchedule': sched,
    });
    setState(() {});
  }

  // ===================== FIRESTORE =====================

  Future<Map<String, dynamic>?> _getProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data();
  }

  Future<int> _getThreadsCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    final snap = await FirebaseFirestore.instance
        .collection('threads')
        .where('authorId', isEqualTo: user.uid)
        .get();
    return snap.docs.length;
  }

  Future<int> _getCommentsCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    int total = 0;
    final threads = await FirebaseFirestore.instance
        .collection('threads')
        .get();

    for (final thread in threads.docs) {
      final comments = await FirebaseFirestore.instance
          .collection('threads')
          .doc(thread.id)
          .collection('comments')
          .where('authorId', isEqualTo: user.uid)
          .get();
      total += comments.docs.length;
    }
    return total;
  }

  Future<int> _getCredits() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return (doc.data()?['credits'] ?? 0) as int;
  }

  Future<void> _saveAbout(String about) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'about': about,
    });
  }

  // ===================== SERVICIOS =====================

  List<String> _getSelectedServicios(Map<String, dynamic> data, User? user) {
    return List<String>.from(data['servicio_ofrecidos'] ?? []);
  }

  Future<void> _updateServicios(
    List<String> selected,
    String value,
    bool checked,
    User? user,
  ) async {
    if (user == null) return;
    final newList = List<String>.from(selected);
    checked ? newList.add(value) : newList.remove(value);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'servicio_ofrecidos': newList,
    });

    setState(() {});
  }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F7),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getProfile(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          aboutController.text = data['about'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              children: [
                _buildHeader(data),
                const SizedBox(height: 16),
                _buildStatsSection(),
                const SizedBox(height: 16),
                _buildServiceChecks(data),
                const SizedBox(height: 16),
                _buildAboutSection(data),
                const SizedBox(height: 20),
                _buildActions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1ABC9C), Color(0xFF16A085)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage:
                data['photoUrl'] != null &&
                        data['photoUrl'].toString().isNotEmpty
                    ? NetworkImage(data['photoUrl'])
                    : const AssetImage('assets/images/doctorkids_logo.png')
                        as ImageProvider,
          ),
          const SizedBox(height: 12),
          Text(
            data['name'] ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.medical_services,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                data['specialty'] ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                data['email'] ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          if ((data['phone'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  data['phone'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
          if ((data['country'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flag, size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  data['country'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
          if ((data['city'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_city, size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  data['city'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
          if ((data['experience'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school, size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  '${data['experience']} años de experiencia',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===================== STATS =====================

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder<List<int>>(
        future: Future.wait([
          _getThreadsCount(),
          _getCommentsCount(),
          _getCredits(),
        ]),
        builder: (context, snapshot) {
          final values = snapshot.data ?? [0, 0, 0];
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat(Icons.forum, "Posts", values[0]),
              _stat(Icons.comment, "Comentarios", values[1]),
              _stat(Icons.monetization_on, "Créditos", values[2]),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(IconData icon, String label, int value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.teal),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== SERVICIOS =====================

  Widget _buildServiceChecks(Map<String, dynamic> data) {
    final user = FirebaseAuth.instance.currentUser;
    final selected = _getSelectedServicios(data, user);

    final servicios = [
      {
        'icon': Icons.video_call,
        'label': 'Telemedicina',
        'value': 'telemedicina',
      },
      {
        'icon': Icons.local_hospital,
        'label': 'Consultorio',
        'value': 'consultorio',
      },
      {'icon': Icons.home, 'label': 'Domicilio', 'value': 'domicilio'},
    ];

    final showConsultorioSchedule = selected.contains('consultorio');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Servicios",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: servicios.map((serv) {
                final isChecked = selected.contains(serv['value']);
                return GestureDetector(
                  onTap: () => _updateServicios(
                    selected,
                    serv['value'] as String,
                    !isChecked,
                    user,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isChecked
                            ? Colors.teal.shade100
                            : Colors.grey.shade200,
                        child: Icon(
                          serv['icon'] as IconData,
                          color: isChecked ? Colors.teal : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        serv['label'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
          if (showConsultorioSchedule) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Horario de atención en consultorio',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...weekDays.map((day) {
                    final times = consultorioSchedule[day] ?? {'from': null, 'to': null};
                    return Row(
                      children: [
                        Expanded(child: Text(day)),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: times['from'] ?? TimeOfDay(hour: 8, minute: 0),
                            );
                            if (picked != null) {
                              setState(() {
                                consultorioSchedule[day] = {
                                  'from': picked,
                                  'to': times['to']
                                };
                              });
                            }
                          },
                          child: Text('Desde: ' + _formatTimeOfDay(times['from'])),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: times['to'] ?? TimeOfDay(hour: 17, minute: 0),
                            );
                            if (picked != null) {
                              setState(() {
                                consultorioSchedule[day] = {
                                  'from': times['from'],
                                  'to': picked
                                };
                              });
                            }
                          },
                          child: Text('Hasta: ' + _formatTimeOfDay(times['to'])),
                        ),
                      ],
                    );
                  }).toList(),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _saveConsultorioSchedule,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar horario'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===================== ABOUT =====================

  Widget _buildAboutSection(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Sobre mí",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(
                    isEditingAbout ? Icons.close : Icons.edit,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => isEditingAbout = !isEditingAbout),
                ),
              ],
            ),
            isEditingAbout
                ? Column(
                    children: [
                      TextField(
                        controller: aboutController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "Describe tu experiencia…",
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await _saveAbout(aboutController.text.trim());
                          setState(() => isEditingAbout = false);
                        },
                        child: const Text("Guardar"),
                      ),
                    ],
                  )
                : Text(
                    data['about'] ??
                        "Pediatra comprometido con la salud infantil.",
                  ),
          ],
        ),
      ),
    );
  }

  // ===================== ACTIONS =====================

  Widget _buildActions(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Estás seguro que deseas cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await _logout(context);
        }
      },
      icon: const Icon(Icons.logout),
      label: const Text("Cerrar sesión"),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }
}
