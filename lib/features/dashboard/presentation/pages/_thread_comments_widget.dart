import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ThreadCommentsWidget extends StatefulWidget {
  final String threadId;
  const ThreadCommentsWidget({required this.threadId});

  @override
  State<ThreadCommentsWidget> createState() => _ThreadCommentsWidgetState();
}

class _ThreadCommentsWidgetState extends State<ThreadCommentsWidget> {
  final TextEditingController _controller = TextEditingController();
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
      _userName = doc.data()?['name'] ?? user.email ?? 'Usuario';
    });
  }

  Future<void> _addComment() async {
    if (_controller.text.trim().isEmpty || _userId == null) return;
    setState(() => _isSending = true);
    final threadRef = FirebaseFirestore.instance.collection('threads').doc(widget.threadId);
    await threadRef.collection('comments').add({
      'content': _controller.text.trim(),
      'authorId': _userId,
      'authorName': _userName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() => _isSending = false);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Comentarios:", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        SizedBox(
          height: 70,
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('threads')
                .doc(widget.threadId)
                .collection('comments')
                .orderBy('createdAt', descending: false)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 1));
              }
              final comentarios = snapshot.data?.docs ?? [];
              if (comentarios.isEmpty) {
                return const Text('Sin comentarios aún.', style: TextStyle(fontSize: 13, color: Colors.grey));
              }
              return ListView.builder(
                itemCount: comentarios.length,
                itemBuilder: (context, i) {
                  final c = comentarios[i].data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.comment, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(c['content'] ?? '', style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Escribe un comentario o pregunta...",
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
              IconButton(
                icon: _isSending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.teal),
                onPressed: _isSending ? null : _addComment,
              ),
            ],
          ),
        ),
      ],
    );
  }
}