import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_pages.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSelectPage extends StatelessWidget {
  const UserSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona un colega'), backgroundColor: Colors.teal),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!.docs.where((u) => u.id != currentUserId).toList();
          if (users.isEmpty) return const Center(child: Text('No hay otros usuarios.'));
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final user = users[i].data();
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (user['photoUrl'] ?? '').toString().isNotEmpty
                      ? NetworkImage(user['photoUrl'])
                      : const AssetImage('assets/images/doctorkids_logo.png') as ImageProvider,
                ),
                title: Text(user['name'] ?? 'Usuario'),
                subtitle: Text(user['specialty'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.chat, color: Colors.teal),
                  onPressed: () async {
                    Navigator.pop(context, users[i].id);
                  },
                ),
                onTap: () async {
                  Navigator.pop(context, users[i].id);
                },
              );
            },
          );
        },
      ),
    );
  }
}
