import 'package:flutter/material.dart';

import '../../data/partner_demo_data.dart';
import '../../models/property.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'add_property_screen.dart';
import 'update_property_screen.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  final List<Map<String, dynamic>> _properties = partnerProperties;

  Future<void> _openAddProperty() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
    );

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openUpdateProperty(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdatePropertyScreen(id: id)),
    );

    if (!mounted) return;
    setState(() {});
  }

  void _deleteProperty(int index) {
    setState(() {
      _properties.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Property deleted successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Properties')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openAddProperty,
                child: const Text('+ Add Property'),
              ),
            ),
          ),
          Expanded(
            child: _properties.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.home_work_outlined,
                            size: 48,
                            color: AppColors.roofLavender,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No properties yet',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap + Add Property to create your first listing.',
                            style: AppTextStyles.secondaryBody,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                    itemCount: _properties.length,
                    itemBuilder: (context, index) {
                      final property = _properties[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PropertyCard(
                          property: property,
                          onEdit: () {
                            _openUpdateProperty(property['id']);
                          },
                          onDelete: () {
                            _deleteProperty(index);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> property;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isAvailable = property['available'] == true;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    property['name'] ?? '',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandText,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppColors.successBackground
                        : AppColors.warningBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'Unavailable',
                    style: AppTextStyles.small.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isAvailable
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    property['location'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${formatBaht(property['monthlyRent'])} / month',
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.deepIndigo,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${property['type']} • ${property['bedrooms']} bedrooms',
              style: AppTextStyles.small.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
