import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'user_select_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/chat_models.dart' as chat_models;

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  Future<void> _startChat(BuildContext context, String currentUserId, String otherUserId) async {
    final chatsRef = FirebaseFirestore.instance.collection('chats');
    final existing = await chatsRef
        .where('participants', arrayContains: currentUserId)
        .get();
    String? chatId;
    for (final doc in existing.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);
      if (participants.contains(otherUserId) && participants.length == 2) {
        chatId = doc.id;
        break;
      }
    }
    if (chatId == null) {
      final newChat = await chatsRef.add({
        'participants': [currentUserId, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
      });
      chatId = newChat.id;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationPage(chatId: chatId!, currentUserId: currentUserId, otherUserId: otherUserId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No autenticado')),
      );
    }
    final currentUserId = user.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Chats entre colegas'), backgroundColor: Colors.teal),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data?.docs ?? [];
          return ListView(
            children: [
              ...chats.map((doc) {
                final chat = chat_models.Chat.fromDoc(doc);
                final otherUserId = chat.participants.firstWhere((id) => id != currentUserId, orElse: () => '');
                return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData || !userSnap.data!.exists) {
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: const Text('Usuario'),
                        subtitle: const Text('Sin mensajes'),
                      );
                    }
                    final user = userSnap.data!.data()!;
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
                          Text(user['name'] ?? 'Usuario'),
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
                      subtitle: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('chats')
                            .doc(chat.id)
                            .collection('messages')
                            .orderBy('sentAt', descending: true)
                            .limit(1)
                            .snapshots(),
                        builder: (context, msgSnap) {
                          if (!msgSnap.hasData || msgSnap.data!.docs.isEmpty) return const Text('Sin mensajes');
                          final lastMsg = msgSnap.data!.docs.first.data();
                          return Text(lastMsg['text'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatConversationPage(chatId: chat.id, currentUserId: currentUserId, otherUserId: otherUserId),
                          ),
                        );
                      },
                    );
                  },
                );
              }).toList(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_comment, color: Colors.teal),
                title: const Text('Iniciar chat con colega'),
                onTap: () async {
                  final selectedUserId = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserSelectPage()),
                  );
                  if (selectedUserId != null && selectedUserId != currentUserId) {
                    _startChat(context, currentUserId, selectedUserId);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChatConversationPage extends StatefulWidget {
    static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final String chatId;
  final String currentUserId;
  final String otherUserId;
  const ChatConversationPage({super.key, required this.chatId, required this.currentUserId, required this.otherUserId});

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
    @override
    void initState() {
      super.initState();
      _initNotifications();
    }

    Future<void> _initNotifications() async {
      // Usa el logo de la app como icono de notificación
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      await ChatConversationPage._notificationsPlugin.initialize(initializationSettings);
    }

    Future<void> _showNotification(String sender, String message) async {
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'chat_channel',
        'Chat entre colegas',
        channelDescription: 'Notificaciones claras de mensajes entre pediatras',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        icon: '@mipmap/ic_launcher', // Asegura el logo de la app
      );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
      await ChatConversationPage._notificationsPlugin.show(
        0,
        'Nuevo mensaje de $sender',
        message,
        platformChannelSpecifics,
      );
    }
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'senderId': widget.currentUserId,
      'text': text,
      'sentAt': FieldValue.serverTimestamp(),
    });
    // Actualiza el campo updatedAt del chat para ordenarlo por último mensaje
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversación'), backgroundColor: Colors.teal),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('sentAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                // Detectar mensaje entrante
                if (messages.isNotEmpty) {
                  final lastMsg = chat_models.Message.fromDoc(messages.last);
                  final isMe = lastMsg.senderId == widget.currentUserId;
                  if (!isMe) {
                    // Buscar nombre del remitente
                    FirebaseFirestore.instance.collection('users').doc(lastMsg.senderId).get().then((userDoc) {
                      final senderName = userDoc.data()?['name'] ?? 'Colega';
                      _showNotification(senderName, lastMsg.text);
                    });
                  }
                }
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: messages.map((doc) {
                    final msg = chat_models.Message.fromDoc(doc);
                    final isMe = msg.senderId == widget.currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.teal.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg.text),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Escribe un mensaje...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
