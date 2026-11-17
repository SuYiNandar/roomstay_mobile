import 'package:flutter/material.dart';

import '../data/sample_properties.dart';
import '../models/property.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'request_viewing_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({
    super.key,
    required this.id,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final int id;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late Property _property;
  late bool _isFavorite;
  int _currentImage = 0;

  static const _houseRules = [
    'No smoking',
    'No parties',
    'Pets according to property rules',
  ];

  @override
  void initState() {
    super.initState();
    _property = sampleProperties.firstWhere(
      (property) => property.id == widget.id,
    );
    _isFavorite = widget.isFavorite;
  }

  void _toggleFavorite() {
    widget.onFavoriteToggle();
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _openViewingRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestViewingScreen(property: _property),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final property = _property;

    return Scaffold(
      bottomNavigationBar: _buildBottomActions(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGallery(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildOverview(),
                  const SizedBox(height: 24),
                  const Text('Description', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 10),
                  Text(
                    property.description,
                    style: AppTextStyles.secondaryBody.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Text('Facilities', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final facility in property.facilities)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            facility,
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('House Rules', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 10),
                  for (final rule in _houseRules)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rule,
                              style: AppTextStyles.secondaryBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Property Partner',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 10),
                  _buildPartnerCard(),
                  const SizedBox(height: 24),
                  const Text('Reviews', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 10),
                  _buildReviewsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery(BuildContext context) {
    return SizedBox(
      height: 290,
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              itemCount: 1,
              onPageChanged: (index) {
                setState(() {
                  _currentImage = index;
                });
              },
              itemBuilder: (context, index) {
                return Container(
                  color: AppColors.photoBackground,
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 56,
                      color: AppColors.roofLavender,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _circleButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Back',
                  onTap: () => Navigator.pop(context),
                ),
                const Spacer(),
                _circleButton(
                  icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                  iconColor: _isFavorite
                      ? AppColors.accent
                      : AppColors.brandText,
                  tooltip: _isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onTap: _toggleFavorite,
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_currentImage + 1} / 1',
                style: AppTextStyles.small.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color iconColor = AppColors.brandText,
  }) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 1,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: iconColor),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final property = _property;
    final statusColor = property.available
        ? AppColors.success
        : AppColors.warning;
    final statusBackground = property.available
        ? AppColors.successBackground
        : AppColors.warningBackground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          property.name,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.brandText,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                property.location,
                style: AppTextStyles.secondaryBody,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          property.priceLabel,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.deepIndigo,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                property.available ? 'Available' : 'Currently unavailable',
                style: AppTextStyles.small.copyWith(
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _toggleFavorite,
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 18,
              ),
              label: Text(_isFavorite ? 'Saved' : 'Save'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverview() {
    final property = _property;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _OverviewCard(
                icon: Icons.apartment,
                label: 'Property type',
                value: property.type,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewCard(
                icon: Icons.king_bed_outlined,
                label: 'Bedrooms',
                value: property.bedrooms == 0
                    ? 'Studio'
                    : '${property.bedrooms}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _OverviewCard(
                icon: Icons.bathtub_outlined,
                label: 'Bathrooms',
                value: '${property.bathrooms}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewCard(
                icon: Icons.square_foot,
                label: 'Size',
                value: '${property.sizeSqm} sqm',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPartnerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.business, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RoomStay Partner',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Member since 2025',
                  style: AppTextStyles.small.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Rating 4.8',
                      style: AppTextStyles.small.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '4.8',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandText,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.star_rounded,
                size: 20,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '“Clean room and convenient location.”',
            style: AppTextStyles.secondaryBody,
          ),
          const SizedBox(height: 8),
          Text(
            '“Good communication with the partner.”',
            style: AppTextStyles.secondaryBody,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final canRequest = _property.available;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canRequest ? _openViewingRequest : null,
              child: const Text('Request Viewing'),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coolBorder),
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
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.small.copyWith(fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
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
    );
  }
}
