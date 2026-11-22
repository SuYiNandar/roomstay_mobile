import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'manager_properties_screen.dart';
import 'manager_viewings_screen.dart';
import 'profile_screen.dart';

class PropertyManagerMainScreen extends StatefulWidget {
  const PropertyManagerMainScreen({super.key});

  @override
  State<PropertyManagerMainScreen> createState() =>
      _PropertyManagerMainScreenState();
}

class _PropertyManagerMainScreenState extends State<PropertyManagerMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      ManagerPropertiesScreen(),
      ManagerViewingsScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        color: AppColors.surface,
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.apartment_outlined),
                label: 'Properties',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_available_outlined),
                label: 'Viewing Requests',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
