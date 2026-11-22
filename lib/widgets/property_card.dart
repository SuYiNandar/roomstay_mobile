import 'package:flutter/material.dart';

import '../models/property.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.property,
    required this.isFavorite,
    required this.onFavoritePressed,
    this.onTap,
  });

  final Property property;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final VoidCallback? onTap;

  Widget _buildImage() {
    if (property.image.isEmpty) {
      return _buildImagePlaceholder();
    }

    return Image.network(
      property.image,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 140,
      errorBuilder: (context, error, stackTrace) {
        return _buildImagePlaceholder();
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.photoBackground,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: AppColors.roofLavender,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 140,
                      child: _buildImage(),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 64,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          property.type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.small.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tagline,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Tooltip(
                      message: isFavorite
                          ? 'Remove from favorites'
                          : 'Save to favorites',
                      child: Material(
                        color: AppColors.surface,
                        shape: const CircleBorder(),
                        elevation: 1,
                        child: InkWell(
                          onTap: onFavoritePressed,
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            key: const Key('favorite-property-button'),
                            width: 48,
                            height: 48,
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                property.name,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandText,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      property.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      property.priceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepIndigo,
                      ),
                    ),
                  ),
                  if (property.rating > 0) ...[
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      property.rating.toStringAsFixed(1),
                      style: AppTextStyles.small.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      property.available ? 'Available' : 'Unavailable',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.small.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: property.available
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
