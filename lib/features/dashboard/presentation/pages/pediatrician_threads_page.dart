import '../../../chat/presentation/chat_pages.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'thread_comments_page.dart';
import 'public_profile_page.dart';


typedef OnTapOwnProfile = void Function();

class PediatricianThreadsPage extends StatefulWidget {
  final OnTapOwnProfile? onTapOwnProfile;
  const PediatricianThreadsPage({Key? key, this.onTapOwnProfile}) : super(key: key);

  @override
  State<PediatricianThreadsPage> createState() => _PediatricianThreadsPageState();
}

class _PediatricianThreadsPageState extends State<PediatricianThreadsPage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal.shade600,
        icon: const Icon(Icons.add),
        label: const Text("Publicar"),
        onPressed: () async {
          if (user == null) return;

          final controller = TextEditingController();

          final result = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Nueva publicación',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: TextField(
                controller: controller,
                autofocus: true,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '¿Qué quieres compartir?',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text('Publicar'),
                  onPressed: () => Navigator.pop(context, controller.text),
                ),
              ],
            ),
          );

          if (result != null && result.trim().isNotEmpty) {
            await FirebaseFirestore.instance.collection('threads').add({
              'content': result.trim(),
              'createdAt': FieldValue.serverTimestamp(),
              'authorId': user.uid,
              'authorName': user.displayName ?? 'Usuario',
              'authorAvatar': user.photoURL ?? '',
            });
          }
        },
      ),

      body: Column(
        children: [
          // ⭐ STORY PERSONAL (SE MANTIENE)
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: user != null
                ? FirebaseFirestore.instance
                    .collection('stories')
                    .doc(user.uid)
                    .snapshots()
                : null,
            builder: (context, snapshot) {
              String storyText = '';
              if (snapshot.hasData && snapshot.data!.data() != null) {
                storyText = snapshot.data!.data()!['text'] ?? '';
              }
              return _StoryBoxEditable(initialText: storyText);
            },
          ),

          const SizedBox(height: 8),

          // ⭐ LISTA DE POSTS
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('threads')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay publicaciones aún.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                final threads = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  itemCount: threads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),

                  itemBuilder: (context, index) {
                    final doc = threads[index];
                    final data = doc.data();

                    final String author = data['authorName'] ?? 'Usuario';
                    final String content = data['content'] ?? '';
                    final avatarUrl = data['authorAvatar'] as String?;
                    DateTime createdAt;
                    if (data['createdAt'] is Timestamp) {
                      createdAt = (data['createdAt'] as Timestamp).toDate();
                    } else if (data['createdAt'] is DateTime) {
                      createdAt = data['createdAt'] as DateTime;
                    } else {
                      createdAt = DateTime.now();
                    }


                    final bool isOwn = user != null && data['authorId'] == user.uid;

                    return Card(
                      elevation: 3,
                      shadowColor: Colors.black12,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ---------- HEADER ----------
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (user != null && data['authorId'] == user.uid) {
                                      if (widget.onTapOwnProfile != null) {
                                        widget.onTapOwnProfile!();
                                      }
                                    } else {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PublicProfilePage(userId: data['authorId'], userName: author, userAvatar: avatarUrl),
                                        ),
                                      );
                                    }
                                  },
                                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                    stream: FirebaseFirestore.instance.collection('users').doc(data['authorId']).snapshots(),
                                    builder: (context, userSnap) {
                                      final isOnline = userSnap.hasData && userSnap.data != null && userSnap.data!.data()?['online'] == true;
                                      final isCurrentUser = user != null && data['authorId'] == user.uid;
                                      return Row(
                                        children: [
                                          Stack(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundColor: Colors.grey.shade300,
                                                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                                    ? NetworkImage(avatarUrl)
                                                    : const AssetImage('assets/images/doctorkids_logo.png') as ImageProvider,
                                              ),
                                              if (!isCurrentUser)
                                                Positioned(
                                                  bottom: 0,
                                                  right: 0,
                                                  child: Container(
                                                    width: 14,
                                                    height: 14,
                                                    decoration: BoxDecoration(
                                                      color: isOnline ? Colors.green : Colors.grey,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: Colors.white, width: 2),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                author,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 17,
                                                ),
                                              ),
                                              Text(
                                                "${createdAt.day}/${createdAt.month}/${createdAt.year} "
                                                "${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                const Spacer(),
                                if (isOwn)
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        final controller = TextEditingController(text: content);
                                        final result = await showDialog<String>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            title: const Text('Editar publicación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                            content: TextField(
                                              controller: controller,
                                              autofocus: true,
                                              maxLines: 4,
                                              decoration: const InputDecoration(
                                                hintText: 'Edita tu publicación',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                child: const Text('Cancelar'),
                                                onPressed: () => Navigator.pop(context),
                                              ),
                                              ElevatedButton(
                                                child: const Text('Guardar'),
                                                onPressed: () => Navigator.pop(context, controller.text),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (result != null && result.trim().isNotEmpty) {
                                          await FirebaseFirestore.instance.collection('threads').doc(doc.id).update({
                                            'content': result.trim(),
                                            'updatedAt': FieldValue.serverTimestamp(),
                                          });
                                        }
                                      } else if (value == 'delete') {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            title: const Text('Eliminar publicación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                                            content: const Text('¿Estás seguro de que deseas eliminar esta publicación? Esta acción no se puede deshacer.'),
                                            actions: [
                                              TextButton(
                                                child: const Text('Cancelar'),
                                                onPressed: () => Navigator.pop(context, false),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                                child: const Text('Eliminar'),
                                                onPressed: () => Navigator.pop(context, true),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await FirebaseFirestore.instance.collection('threads').doc(doc.id).delete();
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Editar'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                            SizedBox(width: 8),
                                            Text('Eliminar'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // ---------- CONTENIDO ----------
                            Text(
                              content,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.35,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // ---------- PIE / COMENTARIOS ----------
                            Row(
                              children: [
                                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                  stream: FirebaseFirestore.instance
                                      .collection('threads')
                                      .doc(doc.id)
                                      .collection('comments')
                                      .snapshots(),
                                  builder: (context, snapComments) {
                                    final count = snapComments.hasData
                                        ? snapComments.data!.docs.length
                                        : 0;

                                    return Row(
                                      children: [
                                        const Icon(Icons.chat_bubble_outline,
                                            size: 19, color: Colors.teal),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$count comentarios',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.teal.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                const Spacer(),

                                IconButton(
                                  icon: const Icon(Icons.add_comment_outlined, color: Colors.teal),
                                  tooltip: 'Ver comentarios',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ThreadCommentsPage(
                                          threadId: doc.id,
                                          threadTitle: '',
                                          threadContent: content,
                                          threadAuthorId: data['authorId'],
                                          threadAuthorName: author,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (!isOwn)
                                  IconButton(
                                    icon: const Icon(Icons.chat, color: Colors.teal),
                                    tooltip: 'Chatear con el autor',
                                    onPressed: () async {
                                      final currentUserId = user?.uid;
                                      final authorId = data['authorId'];
                                      if (currentUserId != null && authorId != null && currentUserId != authorId) {
                                        // Importar ChatListPage y lógica de chat
                                        // Buscar o crear chat y navegar
                                        final chatsRef = FirebaseFirestore.instance.collection('chats');
                                        final existing = await chatsRef
                                            .where('participants', arrayContains: currentUserId)
                                            .get();
                                        String? chatId;
                                        for (final doc in existing.docs) {
                                          final participants = List<String>.from(doc['participants'] ?? []);
                                          if (participants.contains(authorId) && participants.length == 2) {
                                            chatId = doc.id;
                                            break;
                                          }
                                        }
                                        if (chatId == null) {
                                          final newChat = await chatsRef.add({
                                            'participants': [currentUserId, authorId],
                                            'createdAt': FieldValue.serverTimestamp(),
                                          });
                                          chatId = newChat.id;
                                        }
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatConversationPage(
                                              chatId: chatId!,
                                              currentUserId: currentUserId,
                                              otherUserId: authorId,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

//
// --------------------------------------------------
//         STORY BOX (MEJOR ESTILO RED SOCIAL)
// --------------------------------------------------
//
class _StoryBoxEditable extends StatefulWidget {
  final String initialText;
  const _StoryBoxEditable({required this.initialText});

  @override
  State<_StoryBoxEditable> createState() => _StoryBoxEditableState();
}

class _StoryBoxEditableState extends State<_StoryBoxEditable> {
  late TextEditingController _controller;
  String? storyText;

  @override
  void initState() {
    super.initState();
    storyText = widget.initialText;
    _controller = TextEditingController(text: storyText);
  }

  @override
  void didUpdateWidget(covariant _StoryBoxEditable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText) {
      storyText = widget.initialText;
      _controller.text = storyText ?? '';
    }
  }

  Future<void> _saveStory(String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No puedes guardar una historia vacía')));
      return;
    }
    final docRef = FirebaseFirestore.instance.collection('stories').doc(user.uid);
    final now = FieldValue.serverTimestamp();
    await docRef.set({
      'text': text,
      'updatedAt': now,
      'createdAt': now,
      'uid': user.uid,
      'authorName': user.displayName ?? '',
    }, SetOptions(merge: true));
    setState(() => storyText = text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Historia guardada!')));
  }

  Future<void> _deleteStory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('stories').doc(user.uid).delete();
    setState(() => storyText = '');
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.edit, color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: 3,
              style: const TextStyle(fontSize: 15.5),
              decoration: const InputDecoration(
                hintText: '¿Qué piensas hoy?',
                border: InputBorder.none,
              ),
              onChanged: (val) {
                setState(() => storyText = val);
              },
            ),
          ),
          const SizedBox(width: 8),
          if (user != null && storyText != null && storyText!.isNotEmpty)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.save_alt, color: Colors.teal, size: 26),
                  tooltip: 'Guardar historia',
                  onPressed: () async {
                    await _saveStory(_controller.text.trim());
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey, size: 24),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      // Permitir edición directa en el TextField
                      FocusScope.of(context).requestFocus(FocusNode());
                    } else if (value == 'delete') {
                      await _deleteStory();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
