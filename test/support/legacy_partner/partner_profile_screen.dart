import 'package:flutter/material.dart';

import 'package:roomstay_mobile/theme/app_colors.dart';
import 'package:roomstay_mobile/theme/app_text_styles.dart';
import 'package:roomstay_mobile/screens/login_screen.dart';

class PartnerProfileScreen extends StatelessWidget {
  const PartnerProfileScreen({
    super.key,
    required this.onPropertiesSelected,
    required this.onViewingsSelected,
  });

  final VoidCallback onPropertiesSelected;
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
      appBar: AppBar(title: const Text('Partner Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.primaryTint,
                  child: Icon(
                    Icons.storefront_outlined,
                    size: 34,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'RoomStay Partner',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandText,
                  ),
                ),
                SizedBox(height: 4),
                Text('Role: Partner', style: AppTextStyles.secondaryBody),
                SizedBox(height: 2),
                Text('partner@example.com', style: AppTextStyles.small),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.apartment_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('My Properties'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onPropertiesSelected,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(
                    Icons.event_note_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Viewing Requests'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onViewingsSelected,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    _logout(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
