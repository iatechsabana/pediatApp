import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'thread_comments_page.dart';

class PediatricianThreadsPage extends StatefulWidget {
  const PediatricianThreadsPage({super.key});

  @override
  State<PediatricianThreadsPage> createState() => _PediatricianThreadsPageState();
}

class _PediatricianThreadsPageState extends State<PediatricianThreadsPage> {
  String? _currentUserId;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isCreating = false;

  String? _userName;
  String? _userAvatar;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();

    setState(() {
      _userName = data?['name'] ?? user.email ?? 'Pediatra';
      _userAvatar = null;
    });
  }

  // ---------------------
  //   CREAR PUBLICACIÓN
  // ---------------------
  Future<void> _createThread() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) return;

    setState(() => _isCreating = true);

    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection('threads').add({
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'authorId': user?.uid,
      'authorName': _userName ?? user?.email ?? 'Pediatra',
      'createdAt': FieldValue.serverTimestamp(),
      'commentsCount': 0,
    });

    setState(() => _isCreating = false);
    _titleController.clear();
    _contentController.clear();
    Navigator.of(context).pop();
  }

  void _showCreateThreadDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Crear publicación',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Contenido'),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _isCreating ? null : _createThread,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Publicar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------
  //   EDITAR
  // ---------------------
  Future<void> _editThread(String id, String oldTitle, String oldContent) async {
    final titleCtrl = TextEditingController(text: oldTitle);
    final contentCtrl = TextEditingController(text: oldContent);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar publicación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Título")),
            const SizedBox(height: 10),
            TextField(controller: contentCtrl, maxLines: 5, decoration: const InputDecoration(labelText: "Contenido")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('threads').doc(id).update({
                'title': titleCtrl.text.trim(),
                'content': contentCtrl.text.trim(),
              });
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }

  Future<void> _deleteThread(String id) async {
    await FirebaseFirestore.instance.collection('threads').doc(id).delete();
  }

  // ---------------------
  //   HISTORIAS 24h
  // ---------------------
  Widget _buildStoryBox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.teal.shade200,
            child: const Icon(Icons.edit_note, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _showCreateStoryDialog,
              child: const Text(
                '¿Qué piensas hoy? (24h)',
                style: TextStyle(fontSize: 14, color: Colors.teal),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showCreateStoryDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nueva historia"),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(hintText: "Escribe algo que durará 24h..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (controller.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection("stories").add({
                  'content': controller.text.trim(),
                  'authorId': user?.uid,
                  'authorName': _userName,
                  'createdAt': FieldValue.serverTimestamp(),
                  'expiresAt': DateTime.now().add(const Duration(hours: 24)),
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Publicar"),
          )
        ],
      ),
    );
  }

  // ---------------------
  //   FORMATO FECHA
  // ---------------------
  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (now.difference(d).inDays == 0) {
      return "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} hoy";
    }
    return "${d.day}/${d.month}/${d.year}";
  }

  // ---------------------
  //   MAIN UI
  // ---------------------
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
          floatingActionButton: FloatingActionButton(
            onPressed: _showCreateThreadDialog,
            backgroundColor: Colors.teal,
            child: const Icon(Icons.add, color: Colors.white),
          ),

          body: CustomScrollView(
            slivers: [
              // ------------------- APPBAR COMPACTO -------------------
              SliverAppBar(
                backgroundColor: Colors.teal,
                pinned: true,
                expandedHeight: 55,
                centerTitle: true,
                title: const Text(
                  "Comunidad Pediátrica",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildStoryBox(),
                ),
              ),

              if (threads.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      "No hay publicaciones aún.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final t = threads[index].data() as Map<String, dynamic>;
                    final id = threads[index].id;
                    final isOwner = t['authorId'] == _currentUserId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ------------- HEADER AUTOR -------------
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.teal.shade200,
                                  child: const Icon(Icons.person, color: Colors.white),
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
                                            color: Colors.teal),
                                      ),
                                      Text(
                                        t['createdAt'] != null
                                            ? _formatDate((t['createdAt'] as Timestamp).toDate())
                                            : '',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOwner)
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                        onPressed: () => _editThread(id, t['title'], t['content']),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                        onPressed: () => _deleteThread(id),
                                      ),
                                    ],
                                  )
                              ],
                            ),

                            const SizedBox(height: 10),

                            // ------------- TÍTULO / CONTENIDO -------------
                            Text(
                              t['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              t['content'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ------------- COMENTARIOS -------------
                            Row(
                              children: [
                                const Icon(Icons.comment, size: 18, color: Colors.grey),
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
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    );
                                  },
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.teal, size: 20),
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
                  }, childCount: threads.length),
                ),
            ],
          ),
        );
      },
    );
  }
}
