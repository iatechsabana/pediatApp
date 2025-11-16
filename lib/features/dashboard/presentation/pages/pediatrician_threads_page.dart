import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'thread_comments_page.dart';

class PediatricianThreadsPage extends StatefulWidget {
  const PediatricianThreadsPage({super.key});

  @override
  State<PediatricianThreadsPage> createState() =>
      _PediatricianThreadsPageState();
}

class _PediatricianThreadsPageState extends State<PediatricianThreadsPage> {
    Future<Map<String, dynamic>?> _getTodayStory() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final doc = await FirebaseFirestore.instance.collection('stories').doc(user.uid).get();
      final data = doc.data();
      if (data == null) return null;
      final ts = data['createdAt'];
      if (ts == null) return null;
      final date = (ts as Timestamp).toDate();
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return data;
      }
      return null;
    }

    Future<void> _saveTodayStory(String text) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('stories').doc(user.uid).set({
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Usuario',
      });
    }
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  // -----------------------------------------------------
  // CREAR PUBLICACIÓN (FUNCIONANDO)
  // -----------------------------------------------------
  void _showCreateThreadDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          title: const Text(
            "Crear publicación",
            style: TextStyle(fontFamily: "Montserrat"),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Título",
                ),
              ),
              TextField(
                controller: contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Contenido",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Publicar"),
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    contentController.text.trim().isEmpty) return;

                final user = FirebaseAuth.instance.currentUser;

                await FirebaseFirestore.instance.collection('threads').add({
                  "title": titleController.text.trim(),
                  "content": contentController.text.trim(),
                  "authorId": user?.uid,
                  "authorName": user?.displayName ?? "Usuario",
                  "createdAt": FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStoryBox() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getTodayStory(),
      builder: (context, storySnap) {
        if (storySnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final story = storySnap.data;
        final controller = TextEditingController(text: story?['text'] ?? '');
        bool isEditing = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¿Qué piensas hoy?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                const SizedBox(height: 8),
                if (story != null && !isEditing)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(story['text'] ?? '', style: const TextStyle(fontSize: 15))),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Editar historia',
                          onPressed: () => setState(() => isEditing = true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Eliminar historia',
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;
                            await FirebaseFirestore.instance.collection('stories').doc(user.uid).delete();
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Historia eliminada.')));
                            setState(() => isEditing = false);
                            (context as Element).markNeedsBuild();
                          },
                        ),
                      ],
                    ),
                  )
                else ...[
                  TextField(
                    controller: controller,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Comparte algo que solo dure 24h...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (controller.text.trim().isEmpty) return;
                          await _saveTodayStory(controller.text.trim());
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Historia publicada!')));
                          setState(() => isEditing = false);
                          (context as Element).markNeedsBuild();
                        },
                        icon: const Icon(Icons.send),
                        label: Text(story != null ? 'Actualizar' : 'Publicar historia 24h'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      if (story != null)
                        TextButton(
                          onPressed: () => setState(() => isEditing = false),
                          child: const Text('Cancelar'),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _editThread(String id, String? title, String? content) {}

  void _deleteThread(String id) {}

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('threads')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final threads = snapshot.data?.docs ?? [];

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.teal,
            elevation: 4,
            centerTitle: true,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.groups, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  "Comunidad Pediátrica",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------
          // BOTÓN FLOTANTE (CREAR POST) FUNCIONANDO
          // ------------------------------------------
          floatingActionButton: FloatingActionButton(
            onPressed: _showCreateThreadDialog,
            backgroundColor: Colors.teal,
            child: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Crear publicación',
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          // ------------------------------------------
          // CUERPO DE LA PANTALLA
          // Orden corregido: encabezado primero
          // ------------------------------------------
          body: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: _buildStoryBox(),
              ),

              if (threads.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      "No hay publicaciones aún.",
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          fontFamily: 'Montserrat'),
                    ),
                  ),
                )
              else ...threads.map((doc) {
                final t = doc.data() as Map<String, dynamic>;
                final id = doc.id;
                final isOwner = t['authorId'] == _currentUserId;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.teal.shade200,
                              child: const Icon(Icons.person,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t['authorName'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.teal,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                  Text(
                                    t['createdAt'] != null
                                        ? _formatDate(
                                            (t['createdAt'] as Timestamp)
                                                .toDate())
                                        : '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isOwner)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        size: 18, color: Colors.blue),
                                    onPressed: () => _editThread(
                                      id,
                                      t['title'],
                                      t['content'],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 18, color: Colors.red),
                                    onPressed: () => _deleteThread(id),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          t['content'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: Colors.black87,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.comment,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 5),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('threads')
                                  .doc(id)
                                  .collection('comments')
                                  .snapshots(),
                              builder: (context, snap) {
                                final c = snap.data?.docs.length ?? 0;
                                return Text(
                                  "$c comentarios",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontFamily: 'Montserrat',
                                  ),
                                );
                              },
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline,
                                  color: Colors.teal, size: 20),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ThreadCommentsPage(
                                      threadId: id,
                                      threadTitle: t['title'],
                                      threadContent: t['content'],
                                      threadAuthorId: t['authorId'],
                                      threadAuthorName: t['authorName'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
