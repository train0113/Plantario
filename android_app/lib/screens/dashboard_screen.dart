import 'package:flutter/material.dart';
import 'package:khuthon/screens/dashboard/plant_screen.dart';
import 'package:khuthon/screens/dashboard/bluetooth_screen.dart';
import 'package:khuthon/screens/dashboard/ble_data_screen.dart';
import 'package:khuthon/screens/dashboard/plant_reg_screen.dart';
import 'package:khuthon/screens/profile_screen.dart';
import 'package:khuthon/screens/community/community_screen.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Dashboard extends StatefulWidget {
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      PlantScreen(),
      PlantRegistrationScreen(onRegistrationComplete: () {
        setState(() {
          _selectedIndex = 0; // 등록 완료 후 식물 화면으로 이동
        });
      }),
      const CommunityScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.eco), label: '내 식물'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: '식물 등록'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: '커뮤니티'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
      ),
    );
  }
}
