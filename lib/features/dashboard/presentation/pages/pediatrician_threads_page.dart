import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PediatricianThreadsPage extends StatefulWidget {
  const PediatricianThreadsPage({super.key});

  @override
  State<PediatricianThreadsPage> createState() => _PediatricianThreadsPageState();
}

class _PediatricianThreadsPageState extends State<PediatricianThreadsPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isCreating = false;

  Future<void> _createThread() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) return;
    setState(() => _isCreating = true);
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('threads').add({
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'authorId': user?.uid,
      'authorName': user?.displayName ?? user?.email ?? 'Pediatra',
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
            const Text('Nuevo hilo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título del tema'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Contenido'),
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
                  : const Text('Publicar hilo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hilos de Pediatras'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            tooltip: 'Crear nuevo hilo',
            onPressed: _showCreateThreadDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('threads').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay hilos aún. ¡Crea el primero!'));
          }
          final threads = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: threads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final t = threads[i].data() as Map<String, dynamic>;
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  title: Text(t['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(t['content'] ?? '', maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 18, color: Colors.teal),
                          const SizedBox(width: 4),
                          Text(t['authorName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                          const Spacer(),
                          const Icon(Icons.comment, size: 18, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${t['commentsCount'] ?? 0}'),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    // Aquí puedes navegar a la pantalla de comentarios del hilo
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
