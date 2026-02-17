import 'package:flutter/material.dart';
import 'package:jitsi_meet/jitsi_meet.dart';

class VideoCallPage extends StatelessWidget {
  final String roomCode;
  final String userName;
  const VideoCallPage({super.key, required this.roomCode, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Videollamada'), backgroundColor: Colors.teal),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.video_call),
          label: const Text('Unirse a la videollamada'),
          onPressed: () async {
            await JitsiMeet.joinMeeting(
              JitsiMeetingOptions(room: roomCode)
                ..userDisplayName = userName,
            );
          },
        ),
      ),
    );
  }
}
