import 'package:flutter/material.dart';
import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';

class VideoCallPage extends StatefulWidget {
  final String roomCode;
  final String userName;
  final String videocallId;
  const VideoCallPage({
    super.key,
    required this.roomCode,
    required this.userName,
    required this.videocallId,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  bool _joining = false;
  bool _callEnded = false;

  @override
  void initState() {
    super.initState();
    _joinCall();
  }

  Future<void> _joinCall() async {
    if (_joining) return;
    setState(() => _joining = true);
    try {
      await JitsiMeetWrapper.joinMeeting(
        options: JitsiMeetingOptions(
          roomNameOrUrl: widget.roomCode,
          userDisplayName: widget.userName,
          subject: 'Consulta médica — DoctorKids',
          isAudioMuted: false,
          isVideoMuted: false,
        ),
      );
      // joinMeeting resuelve cuando el usuario sale de Jitsi
      await _finalizeCall();
    } catch (_) {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _finalizeCall() async {
    try {
      await FirebaseFirestore.instance
          .collection('videocalls')
          .doc(widget.videocallId)
          .update({'status': 'finalizada'});
    } catch (_) {}
    if (mounted) {
      setState(() {
        _joining = false;
        _callEnded = true;
      });
    }
  }

  Future<void> _leaveEarly() async {
    await _finalizeCall();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _callEnded ? _buildEndedScreen() : _buildConnectingScreen();
  }

  Widget _buildConnectingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        automaticallyImplyLeading: false,
        title: const Text(
          'Videollamada',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.video_call, color: AppColors.primary, size: 60),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Abriendo videollamada...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Jitsi Meet se abrirá en unos segundos.\nNo cierres esta pantalla.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.6),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _joining ? null : _joinCall,
                    icon: const Icon(Icons.refresh),
                    label: const Text('No se abrió — Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _leaveEarly,
                    icon: const Icon(Icons.call_end, color: AppColors.error),
                    label: const Text(
                      'Salir de la llamada',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndedScreen() {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 56),
              ),
              const SizedBox(height: 24),
              const Text(
                'Consulta finalizada',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'La videollamada ha terminado correctamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Ir al inicio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
