import 'package:flutter/material.dart';

import '../data/sample_properties.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/property_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    required this.favoriteIds,
    required this.onFavoriteToggle,
    required this.onPropertySelected,
  });

  final List<int> favoriteIds;
  final void Function(int propertyId) onFavoriteToggle;
  final void Function(int propertyId) onPropertySelected;

  @override
  Widget build(BuildContext context) {
    final favorites = sampleProperties
        .where((property) => favoriteIds.contains(property.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isEmpty
          ? const Center(
              child: Padding(
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
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < favorites.length; index++) ...[
                    if (index > 0) const SizedBox(height: 12),
                    PropertyCard(
                      property: favorites[index],
                      isFavorite: true,
                      onFavoritePressed: () {
                        onFavoriteToggle(favorites[index].id);
                      },
                      onTap: () {
                        onPropertySelected(favorites[index].id);
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
