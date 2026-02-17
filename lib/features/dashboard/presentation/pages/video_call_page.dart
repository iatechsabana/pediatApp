import 'package:flutter/material.dart';
import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';

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
            await JitsiMeetWrapper.joinMeeting(
              options: JitsiMeetingOptions(
                roomNameOrUrl: roomCode,
                userDisplayName: userName,
                subject: 'Videollamada',
                isAudioMuted: false,
                isVideoMuted: false,
              ),
            );
          },
        ),
      ),
    );
  }
}
