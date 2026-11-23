import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';
import '../models/property.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/property_card.dart';
import '../widgets/roomstay_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onSearchRequested,
    this.onCategorySelected,
    required this.favoriteIds,
    required this.onFavoriteToggle,
    required this.onPropertySelected,
  });

  final VoidCallback onSearchRequested;
  final ValueChanged<String>? onCategorySelected;
  final Set<int> favoriteIds;
  final void Function(int propertyId) onFavoriteToggle;
  final void Function(int propertyId) onPropertySelected;

  static const _popularSearches = [
    'Sukhumvit',
    'Near Transit',
    'Pet friendly',
    'Chulalongkorn University',
  ];

  static const _categories = [
    _CategoryItem(
      label: 'Apartments',
      filter: 'Apartment',
      icon: Icons.apartment,
    ),
    _CategoryItem(label: 'Condos', filter: 'Condo', icon: Icons.domain),
    _CategoryItem(label: 'Houses', filter: 'House', icon: Icons.home_outlined),
    _CategoryItem(
      label: 'Dormitories',
      filter: 'Dormitory',
      icon: Icons.meeting_room_outlined,
    ),
    _CategoryItem(
      label: 'Pet friendly',
      filter: 'Pet friendly',
      icon: Icons.favorite_border,
    ),
    _CategoryItem(
      label: 'Near University',
      filter: 'Near University',
      icon: Icons.school_outlined,
    ),
    _CategoryItem(
      label: 'Near Transit',
      filter: 'Near Transit',
      icon: Icons.directions_subway_outlined,
    ),
  ];

  static const _steps = [
    _HowItWorksStep(title: 'Find a Room', icon: Icons.search),
    _HowItWorksStep(title: 'View Details', icon: Icons.visibility_outlined),
    _HowItWorksStep(title: 'Save Favorite', icon: Icons.favorite_border),
    _HowItWorksStep(
      title: 'Request a Viewing',
      icon: Icons.event_available_outlined,
    ),
  ];

  void _openCategory(String filter) {
    if (onCategorySelected != null) {
      onCategorySelected!(filter);
    } else {
      onSearchRequested();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 68,
        titleSpacing: 22,
        title: const RoomStayLogo(compact: true),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHero(),
            const SizedBox(height: 20),
            _buildSearchField(),
            _buildLocationSelector(context),
            const SizedBox(height: 20),
            _buildPopularSearches(),
            const SizedBox(height: 28),
            _buildCategories(),
            const SizedBox(height: 28),
            _buildRecentlyAdded(),
            const SizedBox(height: 28),
            _buildHowItWorks(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "A PLACE FOR WHAT'S NEXT",
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Find your next home,\n'),
              TextSpan(
                text: 'simply.',
                style: TextStyle(color: AppColors.searchAccent),
              ),
            ],
          ),
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.brandText,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Search condos, apartments, houses, and dormitories, then request a viewing with RoomStay.',
          style: AppTextStyles.secondaryBody,
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coolBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSearchRequested,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.search, size: 22, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search by location, university, or keyword',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.secondaryBody.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location selection will be available soon.'),
            ),
          );
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Ari, Bangkok',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandText,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular searches:',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.navigationText,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final search in _popularSearches)
              ActionChip(
                onPressed: () {
                  if (search == 'Pet friendly' || search == 'Near Transit') {
                    _openCategory(search);
                  } else {
                    onSearchRequested();
                  }
                },
                label: Text(search),
                backgroundColor: AppColors.primaryTint,
                side: const BorderSide(color: AppColors.coolBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                labelStyle: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Popular categories', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final category in _categories)
                  SizedBox(
                    width: itemWidth,
                    child: Material(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.coolBorder),
                      ),
                      child: InkWell(
                        onTap: () => _openCategory(category.filter),
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 52),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTint,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(
                                    category.icon,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    category.label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.brandText,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentlyAdded() {
    return _RecentlyAddedSection(
      favoriteIds: favoriteIds,
      onFavoriteToggle: onFavoriteToggle,
      onPropertySelected: onPropertySelected,
      onSearchRequested: onSearchRequested,
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How RoomStay Works', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final step in _steps)
                  SizedBox(
                    width: itemWidth,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 64),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.coolBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryTint,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              step.icon,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              step.title,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brandText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RecentlyAddedSection extends StatefulWidget {
  const _RecentlyAddedSection({
    required this.favoriteIds,
    required this.onFavoriteToggle,
    required this.onPropertySelected,
    required this.onSearchRequested,
  });

  final Set<int> favoriteIds;
  final void Function(int propertyId) onFavoriteToggle;
  final void Function(int propertyId) onPropertySelected;
  final VoidCallback onSearchRequested;
  @override
  State<_RecentlyAddedSection> createState() => _RecentlyAddedSectionState();
}

class _RecentlyAddedSectionState extends State<_RecentlyAddedSection> {
  List<Property> _properties = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/properties?select=*&order=id.desc'),
        headers: {'apikey': supabasePublishableKey},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! List) {
          throw const FormatException('Expected properties list');
        }
        final properties = <Property>[];
        for (final row in data) {
          properties.add(
            Property.fromSupabase(Map<String, dynamic>.from(row as Map)),
          );
        }
        setState(() {
          _properties = properties;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load properties.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load properties.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final title = const Text(
              'Recently added',
              style: AppTextStyles.sectionTitle,
            );
            final action = TextButton(
              onPressed: widget.onSearchRequested,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View all listings →',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
            if (MediaQuery.textScalerOf(context).scale(12) > 18) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: title),
                action,
              ],
            );
          },
        ),
        const SizedBox(height: 2),
        const Text(
          'New listings available on RoomStay',
          style: AppTextStyles.secondaryBody,
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorMessage.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  _errorMessage,
                  style: AppTextStyles.secondaryBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _fetchProperties,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (_properties.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'No properties are available yet.',
              style: AppTextStyles.secondaryBody,
              textAlign: TextAlign.center,
            ),
          )
        else
          for (
            var index = 0;
            index < _properties.length && index < 3;
            index++
          ) ...[
            if (index > 0) const SizedBox(height: 12),
            _buildPropertyCard(_properties[index]),
          ],
      ],
    );
  }

  Widget _buildPropertyCard(Property property) {
    return PropertyCard(
      property: property,
      isFavorite: widget.favoriteIds.contains(property.id),
      onFavoritePressed: () {
        widget.onFavoriteToggle(property.id);
      },
      onTap: () {
        widget.onPropertySelected(property.id);
      },
    );
  }
}

class _CategoryItem {
  const _CategoryItem({
    required this.label,
    required this.filter,
    required this.icon,
  });

  final String label;
  final String filter;
  final IconData icon;
}

class _HowItWorksStep {
  const _HowItWorksStep({required this.title, required this.icon});

  final String title;
  final IconData icon;
}
