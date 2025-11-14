
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/pages/pediatrician_dashboard_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'App Pediatría',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          titleTextStyle: AppTextStyles.heading3,
          iconTheme: const IconThemeData(color: AppColors.textWhite),
          actionsIconTheme: const IconThemeData(color: AppColors.textWhite),
          elevation: 0,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
      ),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, check type and route accordingly
          return _DashboardRouter();
        } else {
          // Not logged in
          return const LoginPage();
        }
      },
    );
  }
}

class _DashboardRouter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final userData = snapshot.data;
        if (userData == null) {
          // Fallback to login if user data is missing
          return const LoginPage();
        }
        final tipo = userData['type'] ?? 'usuario';
        if (tipo == 'pediatra') {
          return const PediatricianDashboardPage();
        } else {
          return const DashboardPage();
        }
      },
    );
  }
}

Future<Map<String, dynamic>?> _getUserData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  return doc.data();
}