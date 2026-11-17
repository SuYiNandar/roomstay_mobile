import 'package:flutter/material.dart';

import '../data/sample_properties.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/property_card.dart';
import '../widgets/roomstay_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onSearchRequested,
    required this.favoriteIds,
    required this.onFavoriteToggle,
    required this.onPropertySelected,
  });

  final VoidCallback onSearchRequested;
  final List<int> favoriteIds;
  final void Function(int propertyId) onFavoriteToggle;
  final void Function(int propertyId) onPropertySelected;

  static const _popularSearches = [
    'Sukhumvit',
    'Near BTS',
    'Pet friendly',
    'Chulalongkorn University',
  ];

  static const _categories = [
    _CategoryItem(label: 'Apartments', icon: Icons.apartment),
    _CategoryItem(label: 'Condos', icon: Icons.domain),
    _CategoryItem(label: 'Houses', icon: Icons.home_outlined),
    _CategoryItem(label: 'Dormitories', icon: Icons.meeting_room_outlined),
    _CategoryItem(label: 'Pet friendly', icon: Icons.favorite_border),
    _CategoryItem(label: 'Near University', icon: Icons.school_outlined),
    _CategoryItem(
      label: 'Near BTS/MRT',
      icon: Icons.directions_subway_outlined,
    ),
  ];

  static const _steps = [
    _HowItWorksStep(title: 'Search', icon: Icons.search),
    _HowItWorksStep(title: 'View', icon: Icons.visibility_outlined),
    _HowItWorksStep(title: 'Save', icon: Icons.favorite_border),
    _HowItWorksStep(title: 'Request', icon: Icons.event_available_outlined),
  ];

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
              Text(
                'Ari, Bangkok',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandText,
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
                onPressed: onSearchRequested,
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
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final category in _categories)
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.coolBorder),
                ),
                child: InkWell(
                  onTap: onSearchRequested,
                  borderRadius: BorderRadius.circular(12),
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
          ],
        ),
      ],
    );
  }

  Widget _buildRecentlyAdded() {
    final properties = sampleProperties.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Recently added', style: AppTextStyles.sectionTitle),
            ),
            TextButton(
              onPressed: onSearchRequested,
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
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'New listings available on RoomStay',
          style: AppTextStyles.secondaryBody,
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < properties.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          PropertyCard(
            property: properties[index],
            isFavorite: favoriteIds.contains(properties[index].id),
            onFavoritePressed: () {
              onFavoriteToggle(properties[index].id);
            },
            onTap: () {
              onPropertySelected(properties[index].id);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How RoomStay Works', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var index = 0; index < _steps.length; index++)
              Container(
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
                        _steps[index].icon,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '0${index + 1}',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.roofLavender,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            _steps[index].title,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CategoryItem {
  const _CategoryItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _HowItWorksStep {
  const _HowItWorksStep({required this.title, required this.icon});

  final String title;
  final IconData icon;
}
