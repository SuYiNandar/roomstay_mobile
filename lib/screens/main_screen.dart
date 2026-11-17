import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'my_viewings_screen.dart';
import 'profile_screen.dart';
import 'room_detail_screen.dart';
import 'search_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<int> _favoriteIds = [];

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _toggleFavorite(int propertyId) {
    setState(() {
      if (_favoriteIds.contains(propertyId)) {
        _favoriteIds.remove(propertyId);
      } else {
        _favoriteIds.add(propertyId);
      }
    });
  }

  void _openRoomDetail(int propertyId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomDetailScreen(
          id: propertyId,
          isFavorite: _favoriteIds.contains(propertyId),
          onFavoriteToggle: () => _toggleFavorite(propertyId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        onSearchRequested: () => _selectTab(1),
        favoriteIds: _favoriteIds,
        onFavoriteToggle: _toggleFavorite,
        onPropertySelected: _openRoomDetail,
      ),
      SearchScreen(
        favoriteIds: _favoriteIds,
        onFavoriteToggle: _toggleFavorite,
        onPropertySelected: _openRoomDetail,
      ),
      FavoritesScreen(
        favoriteIds: _favoriteIds,
        onFavoriteToggle: _toggleFavorite,
        onPropertySelected: _openRoomDetail,
      ),
      const MyViewingsScreen(),
      ProfileScreen(
        onFavoritesSelected: () => _selectTab(2),
        onViewingsSelected: () => _selectTab(3),
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
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
              NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: 'Favorites',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_available_outlined),
                selectedIcon: Icon(Icons.event_available),
                label: 'My Viewings',
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
