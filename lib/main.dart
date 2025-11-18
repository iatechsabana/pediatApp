
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/pages/pediatrician_dashboard_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Puedes personalizar la notificación aquí si lo deseas
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar notificaciones locales
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Solicitar permisos para notificaciones push
  await FirebaseMessaging.instance.requestPermission();

  // Configurar handler para mensajes en background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Mostrar notificaciones locales cuando llega un mensaje en foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_channel',
            'Chat entre colegas',
            channelDescription: 'Notificaciones claras de mensajes entre pediatras',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
// Handler para eventos de ciclo de vida
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnlineStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnlineStatus(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
      _setOnlineStatus(false);
    }
  }

  Future<void> _setOnlineStatus(bool online) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'online': online,
        'lastActive': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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