import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';
import '../data/favorite_helpers.dart';
import '../data/user_session.dart';
import '../models/property.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/property_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
    required this.favoriteIds,
    required this.onFavoriteToggle,
    required this.onPropertySelected,
    this.onFavoritesLoaded,
  });

  final Set<int> favoriteIds;
  final ValueChanged<Set<int>>? onFavoritesLoaded;
  final void Function(int propertyId) onFavoriteToggle;
  final void Function(int propertyId) onPropertySelected;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Property> _favorites = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  @override
  void didUpdateWidget(covariant FavoritesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final removedIds = oldWidget.favoriteIds.difference(widget.favoriteIds);
    final addedIds = widget.favoriteIds.difference(oldWidget.favoriteIds);
    if (removedIds.isEmpty && addedIds.isEmpty) return;

    // A response started before a successful heart change is now out of date.
    _requestId++;
    _favorites.removeWhere((property) => removedIds.contains(property.id));
    final displayedIds = <int>{};
    for (final property in _favorites) {
      displayedIds.add(property.id);
    }
    for (final id in addedIds) {
      if (!displayedIds.contains(id)) {
        _fetchFavorites();
        return;
      }
    }
    if (_isLoading) _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    final requestId = ++_requestId;
    if (UserSession.accessToken == null || UserSession.userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please log in again.';
      });
      return;
    }

    try {
      final res = await http.get(
        Uri.parse(
          '$supabaseUrl/rest/v1/favorites'
          '?user_id=eq.${UserSession.userId}'
          '&select=id,property_id,properties(*)',
        ),
        headers: {
          'apikey': supabasePublishableKey,
          'Authorization': 'Bearer ${UserSession.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted || requestId != _requestId) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is! List) {
          throw const FormatException('Expected favorites list');
        }
        final favorites = <Property>[];

        for (final row in data) {
          final property = favoritePropertyMap(row);

          if (property != null) {
            favorites.add(Property.fromSupabase(property));
          }
        }

        widget.onFavoritesLoaded?.call(parseFavoritePropertyIds(data));
        setState(() {
          _favorites = favorites;
          _isLoading = false;
          _errorMessage = '';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load favorites.';
        });
      }
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load favorites.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _errorMessage,
                      style: AppTextStyles.secondaryBody,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = '';
                        });
                        _fetchFavorites();
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          : _favorites.isEmpty
          ? const Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 48,
                      color: AppColors.roofLavender,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No saved rooms yet',
                      style: AppTextStyles.sectionTitle,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tap the heart on a room to save it here.',
                      style: AppTextStyles.secondaryBody,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final property = _favorites[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PropertyCard(
                    property: property,
                    isFavorite: widget.favoriteIds.contains(property.id),
                    onFavoritePressed: () {
                      widget.onFavoriteToggle(property.id);
                    },
                    onTap: () {
                      widget.onPropertySelected(property.id);
                    },
                  ),
                );
              },
            ),
    );
  }
}
