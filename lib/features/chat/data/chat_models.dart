import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participants; // userIds
  final DateTime createdAt;

  Chat({required this.id, required this.participants, required this.createdAt});

  factory Chat.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Chat(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;

  Message({required this.id, required this.senderId, required this.text, required this.sentAt});

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    DateTime sentAt;
    if (data['sentAt'] is Timestamp) {
      sentAt = (data['sentAt'] as Timestamp).toDate();
    } else if (data['sentAt'] is DateTime) {
      sentAt = data['sentAt'] as DateTime;
    } else {
      sentAt = DateTime.now();
    }
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      sentAt: sentAt,
    );
  }
}
