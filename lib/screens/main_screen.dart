import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';
import '../data/favorite_helpers.dart';
import '../data/user_session.dart';
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
  String? _homeSearchFilter;
  final Set<int> _favoriteIds = {};
  final Set<int> _pendingFavoriteIds = {};
  late final Future<void> _initialFavoritesLoad;
  int _favoritesRevision = 0;

  @override
  void initState() {
    super.initState();
    _initialFavoritesLoad = _fetchFavoriteIds();
  }

  Future<void> _fetchFavoriteIds() async {
    final revision = _favoritesRevision;

    if (UserSession.accessToken == null || UserSession.userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please log in again.')));
      });
      return;
    }

    try {
      final res = await http.get(
        Uri.parse(
          '$supabaseUrl/rest/v1/favorites'
          '?user_id=eq.${UserSession.userId}&select=id,property_id,properties(*)',
        ),
        headers: {
          'apikey': supabasePublishableKey,
          'Authorization': 'Bearer ${UserSession.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted || revision != _favoritesRevision) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is! List) {
          throw const FormatException('Expected favorites list');
        }
        setState(() {
          _favoriteIds
            ..clear()
            ..addAll(parseFavoritePropertyIds(data));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load favorites.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load favorites.')),
      );
    }
  }

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _homeSearchFilter = null;
      _currentIndex = index;
    });
  }

  void _openSearch([String? filter]) {
    setState(() {
      _homeSearchFilter = filter;
      _currentIndex = 1;
    });
  }

  Future<bool> _toggleFavorite(int propertyId) async {
    if (!_pendingFavoriteIds.add(propertyId)) return false;
    try {
      await _initialFavoritesLoad;
      if (!mounted) return false;
      if (UserSession.accessToken == null || UserSession.userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please log in again.')));
        return false;
      }
      if (_favoriteIds.contains(propertyId)) {
        return await _removeFavorite(propertyId);
      }
      return await _addFavorite(propertyId);
    } finally {
      _pendingFavoriteIds.remove(propertyId);
    }
  }

  Future<bool> _addFavorite(int propertyId) async {
    if (_favoriteIds.contains(propertyId)) return true;

    try {
      final res = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/favorites'),
        headers: {
          'apikey': supabasePublishableKey,
          'Authorization': 'Bearer ${UserSession.accessToken}',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'user_id': UserSession.userId,
          'property_id': propertyId,
        }),
      );

      if (!mounted) return false;

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          _favoriteIds.add(propertyId);
        });
        return true;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to save favorite.')));
      return false;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to save favorite.')));
      return false;
    }
  }

  Future<bool> _removeFavorite(int propertyId) async {
    try {
      final res = await http.delete(
        Uri.parse(
          '$supabaseUrl/rest/v1/favorites'
          '?user_id=eq.${UserSession.userId}&property_id=eq.$propertyId',
        ),
        headers: {
          'apikey': supabasePublishableKey,
          'Authorization': 'Bearer ${UserSession.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return false;

      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() {
          _favoriteIds.remove(propertyId);
        });
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to remove favorite.')),
      );
      return false;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to remove favorite.')),
      );
      return false;
    }
  }

  Future<void> _openRoomDetail(int propertyId) async {
    await _initialFavoritesLoad;
    if (!mounted) return;
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
        onSearchRequested: _openSearch,
        onCategorySelected: _openSearch,
        favoriteIds: Set<int>.of(_favoriteIds),
        onFavoriteToggle: _toggleFavorite,
        onPropertySelected: _openRoomDetail,
      ),
      SearchScreen(
        initialQuickFilter: _homeSearchFilter,
        favoriteIds: Set<int>.of(_favoriteIds),
        onFavoriteToggle: _toggleFavorite,
        onPropertySelected: _openRoomDetail,
      ),
      FavoritesScreen(
        onFavoritesLoaded: (ids) {
          setState(() {
            _favoritesRevision++;
            _favoriteIds
              ..clear()
              ..addAll(ids);
          });
        },
        favoriteIds: Set<int>.of(_favoriteIds),
        onFavoriteToggle: _toggleFavorite,
        onPropertySelected: _openRoomDetail,
      ),
      const MyViewingsScreen(),
      ProfileScreen(
        onFavoritesSelected: () => _selectTab(2),
        onViewingsSelected: () => _selectTab(3),
      ),
    ];

    return PopScope(
      canPop: !(_currentIndex == 1 && _homeSearchFilter != null),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex == 1 && _homeSearchFilter != null) {
          _selectTab(0);
        }
      },
      child: Scaffold(
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
                NavigationDestination(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
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
      ),
    );
  }
}
