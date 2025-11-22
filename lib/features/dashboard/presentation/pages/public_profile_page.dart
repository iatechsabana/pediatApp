import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicProfilePage extends StatelessWidget {
  final String userId;
  final String userName;
  final String? userAvatar;

  const PublicProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal.shade600,
        title: Text(
          userName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),

      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userSnapshot.hasError) {
            return const Center(child: Text("Error al cargar el perfil"));
          }
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text("Perfil no encontrado"));
          }

          final data = userSnapshot.data!.data()!;
          final about = data['about'] ?? '';
          final avatar = data['photoUrl'] ?? userAvatar ?? '';
          final specialty = data['specialty'] ?? '';
          final clinic = data['clinic'] ?? '';
          final story = data['story'] ?? '';

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _buildProfileCard(
                avatar: avatar,
                userName: userName,
                specialty: specialty,
                clinic: clinic,
                story: story,
                about: about,
              ),

              const SizedBox(height: 25),

              const Text(
                "Publicaciones",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 10),

              _UserThreads(userId: userId),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileCard({
    required String avatar,
    required String userName,
    required String specialty,
    required String clinic,
    required String story,
    required String about,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white,
            backgroundImage: avatar.isNotEmpty
                ? NetworkImage(avatar)
                : const AssetImage("assets/images/doctorkids_logo.png")
                    as ImageProvider,
          ),
          const SizedBox(height: 12),

          Text(
            userName,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          if (specialty.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                specialty,
                style: TextStyle(
                  color: Colors.white.withOpacity(.9),
                  fontSize: 15,
                ),
              ),
            ),

          if (clinic.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                clinic,
                style: TextStyle(
                  color: Colors.white.withOpacity(.8),
                  fontSize: 13,
                ),
              ),
            ),

          if (story.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade200, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                      SizedBox(width: 6),
                      Text(
                        '¿Qué piensa hoy?',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    story,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, height: 1.35, color: Colors.black87),
                  ),
                ],
              ),
            ),

          if (about.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.92),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                about,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ***********************************
// PUBLICACIONES DEL USUARIO (sin índice)
// ***********************************
class _UserThreads extends StatelessWidget {
  final String userId;

  const _UserThreads({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('threads')
          .where("authorId", isEqualTo: userId)
          .snapshots(), // <-- SIN orderBy (NO DA ERROR)
      builder: (context, threadsSnapshot) {
        if (threadsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!threadsSnapshot.hasData || threadsSnapshot.data!.docs.isEmpty) {
          return const Text(
            "Este usuario no tiene publicaciones.",
            style: TextStyle(color: Colors.grey),
          );
        }

        // Ordenamos manualmente sin Firestore
        final threads = threadsSnapshot.data!.docs;
        threads.sort((a, b) {
          final aa = a['createdAt'] ?? Timestamp.now();
          final bb = b['createdAt'] ?? Timestamp.now();
          return (bb as Timestamp).compareTo(aa as Timestamp);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: threads.map((doc) {
            final tData = doc.data();
            final content = tData["content"] ?? "";
            final createdAt = tData['createdAt'] is Timestamp
                ? (tData['createdAt'] as Timestamp).toDate()
                : DateTime.now();

            return Card(
              elevation: 3,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${createdAt.day}/${createdAt.month}/${createdAt.year} "
                      "${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      content,
                      style: const TextStyle(fontSize: 16, height: 1.35),
                    ),

                    const SizedBox(height: 10),

                    _ThreadComments(threadId: doc.id),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ***********************************
// COMENTARIOS POR PUBLICACIÓN
// ***********************************
class _ThreadComments extends StatelessWidget {
  final String threadId;

  const _ThreadComments({required this.threadId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("threads")
          .doc(threadId)
          .collection("comments")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final comments = snapshot.data!.docs;

        if (comments.isEmpty) {
          return const Text(
            "Sin comentarios.",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Comentarios:",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),

            ...comments.map((c) {
              final data = c.data();
              final author = data["authorName"] ?? "Usuario";
              final content = data["content"] ?? "";

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.comment, size: 16, color: Colors.teal),
                    const SizedBox(width: 4),

                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: Colors.black),
                          children: [
                            TextSpan(
                              text: "$author: ",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: content),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
