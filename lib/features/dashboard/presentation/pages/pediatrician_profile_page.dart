import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PediatricianProfilePage extends StatefulWidget {
  const PediatricianProfilePage({super.key});

  @override
  State<PediatricianProfilePage> createState() => _PediatricianProfilePageState();
}

class _PediatricianProfilePageState extends State<PediatricianProfilePage> {
    Future<int> _getThreadsCount() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;
      final snap = await FirebaseFirestore.instance.collection('threads').where('authorId', isEqualTo: user.uid).get();
      return snap.docs.length;
    }

    Future<int> _getCommentsCount() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;
      int total = 0;
      final threads = await FirebaseFirestore.instance.collection('threads').get();
      for (final thread in threads.docs) {
        final comments = await FirebaseFirestore.instance.collection('threads').doc(thread.id).collection('comments').where('authorId', isEqualTo: user.uid).get();
        total += comments.docs.length;
      }
      return total;
    }

    Future<int> _getCredits() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return (doc.data()?['credits'] ?? 0) as int;
    }
  bool isEditingAbout = false;
  final aboutController = TextEditingController();

  Future<Map<String, dynamic>?> _getProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data();
  }

  Future<void> _saveAbout(String about) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'about': about});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
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
                const SizedBox(height: 24),
                _buildStatsSection(),
                const SizedBox(height: 30),
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

  // 🔹 HEADER LIMPIO Y MODERNO
  Widget _buildHeader(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFBDEEE6), Color(0xFF1ABC9C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty
                  ? CircleAvatar(
                      radius: 44,
                      backgroundImage: NetworkImage(data['photoUrl']),
                      backgroundColor: Colors.white,
                    )
                  : CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white,
                      backgroundImage: const AssetImage('assets/images/doctorkids_logo.png'),
                    ),
              _editAvatarButton(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data['name'] ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Montserrat',
              shadows: [
                Shadow(
                  color: Colors.black38,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data['email'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontFamily: 'Montserrat',
              letterSpacing: 0.2,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildHeaderInfoIcons(data),
        ],
      ),
    );
  }

  Widget _editAvatarButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: IconButton(
        icon: const Icon(Icons.edit, color: Colors.teal),
        onPressed: () {},
      ),
    );
  }

  Widget _buildHeaderInfoIcons(Map<String, dynamic> data) {
    final infoItems = <Widget>[];

    void addItem(IconData icon, String text) {
      infoItems.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ));
    }

    if (data['specialty'] != null) addItem(Icons.medical_services, data['specialty']);
    if (data['clinic'] != null) addItem(Icons.location_city, data['clinic']);
    if (data['license'] != null) addItem(Icons.badge, "Licencia: ${data['license']}");
    if (data['experience'] != null) addItem(Icons.schedule, "${data['experience']} años");
    if (data['address'] != null) addItem(Icons.map, data['address']);

    return Column(
      children: infoItems
          .map((item) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: item,
              ))
          .toList(),
    );
  }

  // 🔹 SECCIÓN DE ESTADÍSTICAS
  Widget _buildStatsSection() {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        _getThreadsCount(),
        _getCommentsCount(),
        _getCredits(),
      ]),
      builder: (context, snapshot) {
        final values = snapshot.data ?? [0, 0, 0];
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statBox(Icons.groups, "Comunidad", values[0].toString()),
            _statBox(Icons.comment, "Comentarios", values[1].toString()),
            _statBox(Icons.monetization_on, "Créditos", values[2].toString()),
          ],
        );
      },
    );
  }

  Widget _statBox(IconData icon, String label, String value) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.teal.shade50,
          child: Icon(icon, color: Colors.teal),
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ],
    );
  }

  // 🔹 SOBRE MÍ
  Widget _buildAboutSection(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Sobre mí", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
              IconButton(
                icon: Icon(isEditingAbout ? Icons.close : Icons.edit, color: Colors.teal),
                onPressed: () => setState(() => isEditingAbout = !isEditingAbout),
              ),
            ],
          ),
          const SizedBox(height: 10),
          isEditingAbout ? _editAboutField() : _aboutText(data),
        ],
      ),
    );
  }

  Widget _editAboutField() {
    return Column(
      children: [
        TextField(
          controller: aboutController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Escribe algo sobre ti...",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await _saveAbout(aboutController.text.trim());
                setState(() => isEditingAbout = false);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Actualizado")));
              },
              icon: const Icon(Icons.save),
              label: const Text("Guardar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () => setState(() => isEditingAbout = false),
              child: const Text("Cancelar"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _aboutText(Map<String, dynamic> data) {
    return Text(
      data['about'] ?? "Pediatra comprometido con la salud infantil.",
      style: const TextStyle(fontSize: 15, height: 1.4),
    );
  }

  // 🔹 BOTONES DE ACCIÓN
  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text("Editar perfil"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.teal),
            label: const Text("Cerrar sesión", style: TextStyle(color: Colors.teal)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.teal),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
