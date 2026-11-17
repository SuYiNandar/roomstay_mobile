import 'package:flutter/material.dart';

import '../models/property.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PropertySummaryCard extends StatelessWidget {
  const PropertySummaryCard({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.photoBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.meeting_room_outlined,
              color: AppColors.roofLavender,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  property.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  property.priceLabel,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepIndigo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
