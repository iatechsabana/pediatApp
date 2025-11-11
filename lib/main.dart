import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
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
      home: const LoginPage(),
    );
  }
}