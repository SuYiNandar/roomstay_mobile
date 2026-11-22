import 'package:flutter/material.dart';

import '../../fixtures/partner_demo_data.dart';
import 'package:roomstay_mobile/theme/app_colors.dart';
import 'package:roomstay_mobile/theme/app_text_styles.dart';
import 'package:roomstay_mobile/widgets/roomstay_logo.dart';
import 'add_property_screen.dart';

class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({
    super.key,
    required this.onViewProperties,
    required this.onViewRequests,
  });

  final VoidCallback onViewProperties;
  final VoidCallback onViewRequests;

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  Future<void> _openAddProperty() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
    );

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final availableCount = partnerProperties
        .where((property) => property['available'] == true)
        .length;
    final pendingCount = partnerViewingRequests
        .where((viewing) => viewing['status'] == 'Pending')
        .length;
    final recentCount = partnerProperties.length < 3
        ? partnerProperties.length
        : 3;

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
            const Text('Partner Dashboard', style: AppTextStyles.h2),
            const SizedBox(height: 6),
            const Text(
              'Welcome back, Partner',
              style: AppTextStyles.secondaryBody,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.apartment,
                    label: 'My Properties',
                    value: '${partnerProperties.length}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.check_circle_outline,
                    label: 'Available Rooms',
                    value: '$availableCount',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.pending_actions,
                    label: 'Pending Viewings',
                    value: '$pendingCount',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.event_note,
                    label: 'Total Viewing Requests',
                    value: '${partnerViewingRequests.length}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text('Quick Actions', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _openAddProperty,
                    child: const Text('Add Property'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onViewRequests,
                    child: const Text('View Requests'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent Properties',
                    style: AppTextStyles.sectionTitle,
                  ),
                ),
                TextButton(
                  onPressed: widget.onViewProperties,
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentCount,
              itemBuilder: (context, index) {
                final property = partnerProperties[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primaryTint,
                        child: Icon(
                          Icons.home_work_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        property['name'] ?? '',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandText,
                        ),
                      ),
                      subtitle: Text(
                        '${property['location']} • ฿${property['monthlyRent']} / month',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        property['available'] == true
                            ? 'Available'
                            : 'Unavailable',
                        style: AppTextStyles.small.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: property['available'] == true
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 19, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.deepIndigo,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            style: AppTextStyles.small.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
