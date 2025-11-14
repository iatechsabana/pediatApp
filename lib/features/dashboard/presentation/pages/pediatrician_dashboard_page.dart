
import 'package:flutter/material.dart';
import 'pediatrician_threads_page.dart';
import 'pediatrician_profile_page.dart';

class PediatricianDashboardPage extends StatefulWidget {
  const PediatricianDashboardPage({super.key});

  @override
  State<PediatricianDashboardPage> createState() => _PediatricianDashboardPageState();
}

class _PediatricianDashboardPageState extends State<PediatricianDashboardPage> {
  int _selectedIndex = 1;

  static final List<Widget> _pages = <Widget>[
    PediatricianProfilePage(),
    PediatricianThreadsPage(),
    Center(
      child: Text(
        'Citas programadas',
        style: TextStyle(fontSize: 20, color: Colors.teal),
      ),
    ),
  ];

  static final List<String> _titles = [
    'Perfil',
    'Red Social',
    'Citas',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.teal,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.public),
              label: 'Red Social',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Citas',
            ),
          ],
        ),
      ),
    );
  }
}
