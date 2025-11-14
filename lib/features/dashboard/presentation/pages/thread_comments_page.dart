import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThreadCommentsPage extends StatefulWidget {
  final String threadId;
  final String threadTitle;
  final String threadContent;
  final String threadAuthorId;
  final String threadAuthorName;

  const ThreadCommentsPage({
    super.key,
    required this.threadId,
    required this.threadTitle,
    required this.threadContent,
    required this.threadAuthorId,
    required this.threadAuthorName,
  });

  @override
  State<ThreadCommentsPage> createState() => _ThreadCommentsPageState();
}

class _ThreadCommentsPageState extends State<ThreadCommentsPage> {
  final _commentController = TextEditingController();
  bool _isSending = false;
  String? _userId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    setState(() {
      _userName = doc.data()?['name'] ?? user.email ?? 'Pediatra';
    });
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || _userId == null) return;
    setState(() => _isSending = true);
    final threadRef = FirebaseFirestore.instance.collection('threads').doc(widget.threadId);
    await threadRef.collection('comments').add({
      'content': _commentController.text.trim(),
      'authorId': _userId,
      'authorName': _userName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Incrementar el contador de comentarios de forma atómica
    await threadRef.update({'commentsCount': FieldValue.increment(1)});
    setState(() => _isSending = false);
    _commentController.clear();
  }

  Future<void> _editComment(String commentId, String oldContent) async {
    final controller = TextEditingController(text: oldContent);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar comentario'),
        content: TextField(
          controller: controller,
          minLines: 1,
          maxLines: 4,
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
                  .doc(widget.threadId)
                  .collection('comments')
                  .doc(commentId)
                  .update({'content': controller.text.trim()});
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(String commentId) async {
    await FirebaseFirestore.instance
        .collection('threads')
        .doc(widget.threadId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  Future<void> _editThread() async {
    final controller = TextEditingController(text: widget.threadContent);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar publicación'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 6,
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
                  .doc(widget.threadId)
                  .update({'content': controller.text.trim()});
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteThread() async {
    await FirebaseFirestore.instance.collection('threads').doc(widget.threadId).delete();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isThreadOwner = _userId == widget.threadAuthorId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comentarios'),
        backgroundColor: Colors.teal,
        actions: isThreadOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar publicación',
                  onPressed: _editThread,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Eliminar publicación',
                  onPressed: _deleteThread,
                ),
              ]
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.threadAuthorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(widget.threadTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(widget.threadContent),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('threads')
                  .doc(widget.threadId)
                  .collection('comments')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay comentarios aún.'));
                }
                final comments = snapshot.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = comments[i].data() as Map<String, dynamic>;
                    final isOwner = c['authorId'] == _userId;
                    return ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: Colors.teal.shade50,
                      title: Text(c['authorName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(c['content'] ?? ''),
                      trailing: isOwner
                          ? PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editComment(comments[i].id, c['content'] ?? '');
                                } else if (value == 'delete') {
                                  _deleteComment(comments[i].id);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                              ],
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un comentario...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.teal),
                  onPressed: _isSending ? null : _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
