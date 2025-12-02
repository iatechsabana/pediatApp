import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString('type') ?? '';
    Widget next;
    if (type == 'admin') {
      next = const AdminDashboardPage();
    } else if (type == 'pediatra') {
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
