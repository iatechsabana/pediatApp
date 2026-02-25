import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart'; // Descomenta si usas Jitsi

class VideoCallWaitingPage extends StatefulWidget {
  final String roomId;
  final String videocallId;
  final String toUserId;
  const VideoCallWaitingPage({required this.roomId, required this.videocallId, required this.toUserId});

  @override
  State<VideoCallWaitingPage> createState() => _VideoCallWaitingPageState();
}

class _VideoCallWaitingPageState extends State<VideoCallWaitingPage> {
  bool _callStarted = false;
  bool _callRejected = false;
  String? _rejectReason;

  @override
  void initState() {
    super.initState();
    _listenVideocallStatus();
  }

  void _listenVideocallStatus() {
    FirebaseFirestore.instance
        .collection('videocalls')
        .doc(widget.videocallId)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      if (data == null) return;
      final status = data['status'] ?? 'pendiente';
      if (status == 'aceptada' && !_callStarted) {
        setState(() {
          _callStarted = true;
        });
        // Aquí inicia la videollamada (Jitsi, etc.)
        // JitsiMeetWrapper.joinMeeting(JitsiMeetingOptions(roomNameOrUrl: widget.roomId));
      } else if (status == 'rechazada' && !_callRejected) {
        setState(() {
          _callRejected = true;
          _rejectReason = data['rejectReason'] ?? 'El médico rechazó la videollamada.';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_callRejected) {
      return Scaffold(
        appBar: AppBar(title: const Text('Videollamada')),
        body: Center(child: Text(_rejectReason ?? 'Videollamada rechazada')),
      );
    }
    if (_callStarted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Videollamada')),
        body: const Center(child: Text('Videollamada iniciada (aquí va Jitsi Meet)')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Videollamada')),
      body: const Center(child: Text('Esperando que el médico acepte la videollamada...')),
    );
  }
}