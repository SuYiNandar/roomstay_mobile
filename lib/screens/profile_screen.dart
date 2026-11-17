import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.onFavoritesSelected,
    required this.onViewingsSelected,
  });

  final VoidCallback onFavoritesSelected;
  final VoidCallback onViewingsSelected;

  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Su Yi Nandar',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Renter', style: AppTextStyles.secondaryBody),
                  const SizedBox(height: 4),
                  Text(
                    'suyinandar@example.com',
                    style: AppTextStyles.small.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Material(
              color: AppColors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.favorite_border,
                      color: AppColors.primary,
                    ),
                    title: const Text('My Favorites'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onFavoritesSelected,
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  ListTile(
                    leading: const Icon(
                      Icons.event_available_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('My Viewings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onViewingsSelected,
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: const Text('Logout'),
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
