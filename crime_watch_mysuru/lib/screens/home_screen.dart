import 'package:flutter/material.dart';
import 'predict_screen.dart';
import 'alert_screen.dart';

const List<String> kAreas = [
  'Mysuru City', 'Bannur', 'Nanjangud', 'Hunsur',
  'T Narasipura', 'KRS', 'Periyapatna', 'HD Kote', 'Saragur',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _screens = [
    PredictScreen(),
    AlertScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1A1D2E),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.psychology), label: 'Predict'),
          NavigationDestination(icon: Icon(Icons.notifications_active), label: 'Alerts'),
        ],
      ),
    );
  }
}
