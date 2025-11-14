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

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadUserData();
  }

  Future<void> _editThread(String threadId, String oldTitle, String oldContent) async {
    final titleController = TextEditingController(text: oldTitle);
    final contentController = TextEditingController(text: oldContent);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar publicación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Contenido'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('threads')
                  .doc(threadId)
                  .update({
                'title': titleController.text.trim(),
                'content': contentController.text.trim(),
              });
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteThread(String threadId) async {
    await FirebaseFirestore.instance.collection('threads').doc(threadId).delete();
  }

  void _showCreateThreadDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Crear publicación', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '¿Sobre qué quieres compartir?'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Comparte tu experiencia, pregunta o tema...'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isCreating ? null : _createThread,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isCreating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Publicar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildCommunityHeader() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1ABC9C),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.groups, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Comunidad Pediátrica',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
    }
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isCreating = false;
  String? _userName;
  String? _userAvatar;


  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    setState(() {
      _userName = data?['name'] ?? user.email ?? 'Pediatra';
      _userAvatar = null; // Si tienes campo de avatar, asígnalo aquí
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('threads').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        final threads = snapshot.hasData ? snapshot.data!.docs : [];
        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 90),
              itemCount: 1 + threads.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildCommunityHeader(),
                  );
                }
                if (threads.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No hay publicaciones aún. ¡Crea la primera!')),
                  );
                }
                final t = threads[index - 1].data() as Map<String, dynamic>;
                final threadId = threads[index - 1].id;
                final isOwner = t['authorId'] == _currentUserId;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.teal.shade100,
                                child: const Icon(Icons.person, color: Colors.teal),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                t['authorName'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Spacer(),
                              Text(
                                t['createdAt'] != null && t['createdAt'] is Timestamp
                                    ? _formatDate((t['createdAt'] as Timestamp).toDate())
                                    : '',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              if (isOwner)
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _editThread(threadId, t['title'] ?? '', t['content'] ?? '');
                                    } else if (value == 'delete') {
                                      _deleteThread(threadId);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                    const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t['title'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t['content'] ?? '',
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Icon(Icons.comment, size: 18, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('threads')
                                    .doc(threadId)
                                    .collection('comments')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                  return Text('$count comentarios', style: const TextStyle(fontSize: 13));
                                },
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline, color: Colors.teal),
                                tooltip: 'Comentar',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ThreadCommentsPage(
                                        threadId: threadId,
                                        threadTitle: t['title'] ?? '',
                                        threadContent: t['content'] ?? '',
                                        threadAuthorId: t['authorId'] ?? '',
                                        threadAuthorName: t['authorName'] ?? '',
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
                  ),
                );
              },
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.extended(
                onPressed: _showCreateThreadDialog,
                backgroundColor: Colors.teal,
                icon: _userAvatar != null
                    ? CircleAvatar(backgroundImage: NetworkImage(_userAvatar!), radius: 14)
                    : const Icon(Icons.edit),
                label: Text(_userName != null ? 'Publicar como $_userName' : 'Crear publicación'),
                elevation: 6,
              ),
            ),
          ],
        );
      },
    );
  }
// Código duplicado eliminado

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (now.difference(date).inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} hoy';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
