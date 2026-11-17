import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class RoomStayLogo extends StatelessWidget {
  const RoomStayLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 40.0 : 52.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/images/roomstay_mark.svg',
          width: markSize,
          height: markSize,
        ),
        SizedBox(width: compact ? 10 : 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RoomStay',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: compact ? 22 : 26,
                fontWeight: FontWeight.bold,
                color: AppColors.brandText,
                letterSpacing: -0.5,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 2),
              const Text(
                'Find. Rent. Belong.',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  color: AppColors.tagline,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
