import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';



class UserSelectPage extends StatefulWidget {
  const UserSelectPage({Key? key}) : super(key: key);

  @override
  _UserSelectPageState createState() => _UserSelectPageState();
}

class _UserSelectPageState extends State<UserSelectPage> {
  String _filter = 'todos';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona un colega'), backgroundColor: Colors.teal),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filter,
                      items: const [
                        DropdownMenuItem(value: 'todos', child: Text('Todos')),
                        DropdownMenuItem(value: 'online', child: Text('Solo online')),
                        DropdownMenuItem(value: 'offline', child: Text('Solo offline')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filter = value!;
                        });
                      },
                      icon: const Icon(Icons.filter_list, color: Colors.teal),
                      style: const TextStyle(fontSize: 15, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar por nombre',
                        prefixIcon: Icon(Icons.search, color: Colors.teal),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _search = value.trim();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var users = snapshot.data!.docs.where((u) => u.id != currentUserId).toList();
                if (_filter == 'online') {
                  users = users.where((u) => u.data()['online'] == true).toList();
                } else if (_filter == 'offline') {
                  users = users.where((u) => u.data()['online'] != true).toList();
                }
                if (_search.isNotEmpty) {
                  users = users.where((u) => (u.data()['name'] ?? '').toString().toLowerCase().contains(_search.toLowerCase())).toList();
                }
                if (users.isEmpty) return const Center(child: Text('No hay otros usuarios.'));
                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final user = users[i].data();
                    final isOnline = user['online'] == true;
                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundImage: (user['photoUrl'] ?? '').toString().isNotEmpty
                                ? NetworkImage(user['photoUrl'])
                                : const AssetImage('assets/images/doctorkids_logo.png') as ImageProvider,
                          ),
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
                      title: Row(
                        children: [
                          Text(user['name'] ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.w500)),
                          if (!isOnline)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                'No activo',
                                style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(user['specialty'] ?? '', style: const TextStyle(fontSize: 13)),
                      trailing: IconButton(
                        icon: const Icon(Icons.chat, color: Colors.teal),
                        onPressed: () async {
                          Navigator.pop(context, users[i].id);
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context, users[i].id);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
