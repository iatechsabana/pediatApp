
import 'package:flutter/material.dart';
import 'pediatrician_threads_page.dart';

class PediatricianDashboardPage extends StatelessWidget {
  const PediatricianDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Red Social Pediatras'),
        backgroundColor: Colors.teal,
      ),
      body: const PediatricianThreadsPage(),
    );
  }
}
