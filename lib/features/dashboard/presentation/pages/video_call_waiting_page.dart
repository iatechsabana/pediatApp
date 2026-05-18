import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import 'video_call_page.dart';

class VideoCallWaitingPage extends StatefulWidget {
  final String roomId;
  final String videocallId;
  final String toUserId;
  const VideoCallWaitingPage({
    super.key,
    required this.roomId,
    required this.videocallId,
    required this.toUserId,
  });

  @override
  State<VideoCallWaitingPage> createState() => _VideoCallWaitingPageState();
}

class _VideoCallWaitingPageState extends State<VideoCallWaitingPage>
    with SingleTickerProviderStateMixin {
  StreamSubscription<DocumentSnapshot>? _sub;
  bool _navigated = false;
  bool _callRejected = false;
  String _rejectReason = '';
  Map<String, dynamic>? _doctorData;
  Map<String, dynamic>? _childData;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadDoctor();
    _loadChildData();
    _listenStatus();
  }

  Future<void> _loadDoctor() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.toUserId)
        .get();
    if (mounted && doc.exists) {
      setState(() => _doctorData = doc.data());
    }
  }

  Future<void> _loadChildData() async {
    final doc = await FirebaseFirestore.instance
        .collection('videocalls')
        .doc(widget.videocallId)
        .get();
    if (mounted && doc.exists) {
      final child = doc.data()?['child'];
      if (child is Map<String, dynamic>) {
        setState(() => _childData = child);
      }
    }
  }

  void _listenStatus() {
    _sub = FirebaseFirestore.instance
        .collection('videocalls')
        .doc(widget.videocallId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists || !mounted) return;
      final status = (doc.data()?['status'] ?? 'pendiente') as String;
      if (status == 'aceptada' && !_navigated) {
        _navigated = true;
        final user = FirebaseAuth.instance.currentUser;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VideoCallPage(
              roomCode: widget.roomId,
              userName: user?.displayName ?? 'Paciente',
              videocallId: widget.videocallId,
            ),
          ),
        );
      } else if (status == 'rechazada' && !_callRejected) {
        setState(() {
          _callRejected = true;
          _rejectReason = (doc.data()?['rejectReason'] as String?) ??
              'El médico no está disponible en este momento.';
        });
      }
    });
  }

  Future<void> _cancelCall() async {
    await FirebaseFirestore.instance
        .collection('videocalls')
        .doc(widget.videocallId)
        .update({'status': 'cancelada'});
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _callRejected ? _buildRejected() : _buildWaiting();
  }

  Widget _buildWaiting() {
    final name = (_doctorData?['name'] as String?) ?? '';
    final photo = (_doctorData?['photoUrl'] as String?) ?? '';
    final displayName = name.isNotEmpty ? name : 'el médico';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 48,
        automaticallyImplyLeading: false,
        title: const Text('Videollamada', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header con avatar pulsante
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryLight, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: photo.isNotEmpty
                          ? CircleAvatar(
                              radius: 46,
                              backgroundImage: NetworkImage(photo),
                              backgroundColor: Colors.white,
                            )
                          : CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.white,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'M',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name.isNotEmpty ? 'Dr. $name' : 'Médico',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Esperando que acepte la llamada...',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                if (_childData != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.child_care, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Paciente: ${(_childData!['name'] as String?) ?? 'Hijo'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          // Estado de la llamada
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingLarge),
            child: Container(
              padding: const EdgeInsets.all(AppDimens.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.borderRadiusXLarge),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Llamando a $displayName',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La videollamada iniciará automáticamente\ncuando el médico acepte.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimens.paddingLarge),

          // Botón cancelar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cancelCall,
                icon: const Icon(Icons.call_end, color: AppColors.error),
                label: const Text(
                  'Cancelar llamada',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejected() {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 48,
        title: const Text('Videollamada', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call_end, color: AppColors.error, size: 52),
              ),
              const SizedBox(height: 24),
              const Text(
                'Llamada no aceptada',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                _rejectReason,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
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
