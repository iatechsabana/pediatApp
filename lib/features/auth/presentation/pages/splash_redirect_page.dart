import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../../dashboard/presentation/pages/pediatrician_dashboard_page.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart' as dashboard;

class SplashRedirectPage extends StatefulWidget {
  const SplashRedirectPage({Key? key}) : super(key: key);

  @override
  State<SplashRedirectPage> createState() => _SplashRedirectPageState();
}

class _SplashRedirectPageState extends State<SplashRedirectPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    String type = '';
    if (data != null && data['type'] != null) {
      type = (data['type'] as String).toLowerCase().trim();
      type = type
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll(RegExp(r'[^a-z]'), '');
    }
    Widget next;
    if (type == 'admin') {
      next = const AdminDashboardPage();
    } else if (type.startsWith('pediatra')) {
      next = const PediatricianDashboardPage();
    } else {
      next = const dashboard.DashboardPage();
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
