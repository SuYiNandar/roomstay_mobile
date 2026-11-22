import 'package:flutter/material.dart';

import 'package:roomstay_mobile/theme/app_colors.dart';
import 'my_properties_screen.dart';
import 'partner_dashboard_screen.dart';
import 'partner_profile_screen.dart';
import 'partner_viewings_screen.dart';

class PartnerMainScreen extends StatefulWidget {
  const PartnerMainScreen({super.key});

  @override
  State<PartnerMainScreen> createState() => _PartnerMainScreenState();
}

class _PartnerMainScreenState extends State<PartnerMainScreen> {
  int _currentIndex = 0;

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      PartnerDashboardScreen(
        onViewProperties: () => _selectTab(1),
        onViewRequests: () => _selectTab(2),
      ),
      const MyPropertiesScreen(),
      const PartnerViewingsScreen(),
      PartnerProfileScreen(
        onPropertiesSelected: () => _selectTab(1),
        onViewingsSelected: () => _selectTab(2),
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        color: AppColors.surface,
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _selectTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.apartment_outlined),
                selectedIcon: Icon(Icons.apartment),
                label: 'My Properties',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_available_outlined),
                selectedIcon: Icon(Icons.event_available),
                label: 'Viewings',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
