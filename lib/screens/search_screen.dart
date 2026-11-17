import 'package:flutter/material.dart';

import '../data/sample_properties.dart';
import '../models/property.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/property_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.favoriteIds,
    required this.onFavoriteToggle,
    required this.onPropertySelected,
  });

  final List<int> favoriteIds;
  final void Function(int propertyId) onFavoriteToggle;
  final void Function(int propertyId) onPropertySelected;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _quickFilterOptions = [
    'Apartment',
    'Condo',
    'House',
    'Dormitory',
    'Pet friendly',
    'Near University',
    'Near BTS/MRT',
  ];

  static const _quickTypeOptions = {'Apartment', 'Condo', 'House', 'Dormitory'};

  static const _sortOptions = [
    'Default',
    'Price: Low to High',
    'Price: High to Low',
  ];

  final _searchController = TextEditingController();

  final Set<String> _quickFilters = {};
  String _sortOption = 'Default';

  String _propertyType = 'All';
  int? _minRent;
  int? _maxRent;
  String _bedrooms = 'Any';
  bool _availableOnly = false;
  Set<String> _facilities = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  void _resetAllFilters() {
    setState(() {
      _searchController.clear();
      _quickFilters.clear();
      _sortOption = 'Default';
      _propertyType = 'All';
      _minRent = null;
      _maxRent = null;
      _bedrooms = 'Any';
      _availableOnly = false;
      _facilities = {};
    });
  }

  List<Property> _filteredProperties() {
    final query = _searchController.text.trim().toLowerCase();

    final results = sampleProperties.where((property) {
      final matchesKeyword =
          query.isEmpty ||
          property.name.toLowerCase().contains(query) ||
          property.location.toLowerCase().contains(query) ||
          property.type.toLowerCase().contains(query);

      if (!matchesKeyword) return false;

      if (_quickFilters.isNotEmpty) {
        final selectedTypes = _quickFilters
            .where(_quickTypeOptions.contains)
            .toSet();

        if (selectedTypes.isNotEmpty &&
            !selectedTypes.contains(property.type)) {
          return false;
        }
        if (_quickFilters.contains('Pet friendly') && !property.petFriendly) {
          return false;
        }
        if (_quickFilters.contains('Near University') &&
            !property.nearUniversity) {
          return false;
        }
        if (_quickFilters.contains('Near BTS/MRT') && !property.nearTransit) {
          return false;
        }
      }

      if (_propertyType != 'All' && property.type != _propertyType) {
        return false;
      }
      if (_minRent != null && property.monthlyRent < _minRent!) {
        return false;
      }
      if (_maxRent != null && property.monthlyRent > _maxRent!) {
        return false;
      }

      switch (_bedrooms) {
        case 'Studio':
          if (property.bedrooms != 0) return false;
        case '1':
          if (property.bedrooms != 1) return false;
        case '2':
          if (property.bedrooms != 2) return false;
        case '3+':
          if (property.bedrooms < 3) return false;
      }

      if (_availableOnly && !property.available) {
        return false;
      }
      if (_facilities.isNotEmpty &&
          !_facilities.every(property.facilities.contains)) {
        return false;
      }

      return true;
    }).toList();

    if (_sortOption == 'Price: Low to High') {
      results.sort((a, b) => a.monthlyRent.compareTo(b.monthlyRent));
    } else if (_sortOption == 'Price: High to Low') {
      results.sort((a, b) => b.monthlyRent.compareTo(a.monthlyRent));
    }

    return results;
  }

  Future<void> _openMoreFilters() async {
    final result = await showModalBottomSheet<_MoreFiltersResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.85,
          child: _MoreFiltersSheet(
            initialPropertyType: _propertyType,
            initialMinRent: _minRent,
            initialMaxRent: _maxRent,
            initialBedrooms: _bedrooms,
            initialAvailableOnly: _availableOnly,
            initialFacilities: _facilities,
          ),
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      _propertyType = result.propertyType;
      _minRent = result.minRent;
      _maxRent = result.maxRent;
      _bedrooms = result.bedrooms;
      _availableOnly = result.availableOnly;
      _facilities = result.facilities;
    });
  }

  void _openRoomDetail(Property property) {
    widget.onPropertySelected(property.id);
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredProperties();

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Search rooms', style: AppTextStyles.h2),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by location, university, or keyword',
                hintStyle: AppTextStyles.secondaryBody.copyWith(fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 22,
                  color: AppColors.primary,
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.coolBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in _quickFilterOptions)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: _quickFilters.contains(filter),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _quickFilters.add(filter);
                            } else {
                              _quickFilters.remove(filter);
                            }
                          });
                        },
                        showCheckmark: false,
                        selectedColor: AppColors.primaryTint,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: _quickFilters.contains(filter)
                              ? AppColors.primary
                              : AppColors.coolBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        labelStyle: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _quickFilters.contains(filter)
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.coolBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortOption,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        items: [
                          for (final option in _sortOptions)
                            DropdownMenuItem<String>(
                              value: option,
                              child: Text(
                                option,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _sortOption = value;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _openMoreFilters,
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('More Filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: const BorderSide(color: AppColors.coolBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: AppTextStyles.button.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    results.length == 1
                        ? '1 room found'
                        : '${results.length} rooms found',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandText,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _resetAllFilters,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (results.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.search_off,
                      size: 40,
                      color: AppColors.roofLavender,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No rooms found',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Try changing your search or filters.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.secondaryBody,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _resetAllFilters,
                      child: const Text('Reset Filters'),
                    ),
                  ],
                ),
              )
            else
              for (var index = 0; index < results.length; index++) ...[
                if (index > 0) const SizedBox(height: 12),
                PropertyCard(
                  property: results[index],
                  isFavorite: widget.favoriteIds.contains(results[index].id),
                  onFavoritePressed: () {
                    widget.onFavoriteToggle(results[index].id);
                  },
                  onTap: () => _openRoomDetail(results[index]),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _MoreFiltersSheet extends StatefulWidget {
  const _MoreFiltersSheet({
    required this.initialPropertyType,
    required this.initialMinRent,
    required this.initialMaxRent,
    required this.initialBedrooms,
    required this.initialAvailableOnly,
    required this.initialFacilities,
  });

  final String initialPropertyType;
  final int? initialMinRent;
  final int? initialMaxRent;
  final String initialBedrooms;
  final bool initialAvailableOnly;
  final Set<String> initialFacilities;

  @override
  State<_MoreFiltersSheet> createState() => _MoreFiltersSheetState();
}

class _MoreFiltersSheetState extends State<_MoreFiltersSheet> {
  static const _propertyTypes = [
    'All',
    'Condo',
    'Apartment',
    'Dormitory',
    'House',
    'Townhouse',
    'Duplex / Loft',
  ];

  static const _minRentOptions = <int?>[
    null,
    5000,
    8000,
    10000,
    15000,
    20000,
    30000,
  ];

  static const _maxRentOptions = <int?>[
    null,
    10000,
    15000,
    20000,
    30000,
    50000,
  ];

  static const _bedroomOptions = ['Any', 'Studio', '1', '2', '3+'];

  static const _facilityOptions = [
    'Wi-Fi',
    'Air Conditioner',
    'Furnished',
    'Parking',
    'Elevator',
    'Security / CCTV',
    'Swimming Pool',
    'Fitness / Gym',
    'Washing Machine',
    'Balcony',
    'Pet friendly',
  ];

  late String _propertyType;
  late int? _minRent;
  late int? _maxRent;
  late String _bedrooms;
  late bool _availableOnly;
  late Set<String> _facilities;

  @override
  void initState() {
    super.initState();
    _propertyType = widget.initialPropertyType;
    _minRent = widget.initialMinRent;
    _maxRent = widget.initialMaxRent;
    _bedrooms = widget.initialBedrooms;
    _availableOnly = widget.initialAvailableOnly;
    _facilities = Set.of(widget.initialFacilities);
  }

  void _reset() {
    setState(() {
      _propertyType = 'All';
      _minRent = null;
      _maxRent = null;
      _bedrooms = 'Any';
      _availableOnly = false;
      _facilities = {};
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      _MoreFiltersResult(
        propertyType: _propertyType,
        minRent: _minRent,
        maxRent: _maxRent,
        bedrooms: _bedrooms,
        availableOnly: _availableOnly,
        facilities: _facilities,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.brandText,
        ),
      ),
    );
  }

  Widget _choiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppColors.primaryTint,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.coolBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.coolBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 12, 4),
          child: Row(
            children: [
              const Expanded(
                child: Text('More Filters', style: AppTextStyles.h2),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Property Type'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in _propertyTypes)
                      _choiceChip(
                        label: type,
                        selected: _propertyType == type,
                        onTap: () {
                          setState(() {
                            _propertyType = type;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                _sectionTitle('Minimum rent'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final rent in _minRentOptions)
                      _choiceChip(
                        label: rent == null ? 'No minimum' : formatBaht(rent),
                        selected: _minRent == rent,
                        onTap: () {
                          setState(() {
                            _minRent = rent;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                _sectionTitle('Maximum rent'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final rent in _maxRentOptions)
                      _choiceChip(
                        label: rent == null ? 'No limit' : formatBaht(rent),
                        selected: _maxRent == rent,
                        onTap: () {
                          setState(() {
                            _maxRent = rent;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                _sectionTitle('Bedrooms'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final bedrooms in _bedroomOptions)
                      _choiceChip(
                        label: bedrooms,
                        selected: _bedrooms == bedrooms,
                        onTap: () {
                          setState(() {
                            _bedrooms = bedrooms;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                _sectionTitle('Availability'),
                FilterChip(
                  label: const Text('Available now'),
                  selected: _availableOnly,
                  onSelected: (selected) {
                    setState(() {
                      _availableOnly = selected;
                    });
                  },
                  showCheckmark: false,
                  selectedColor: AppColors.primaryTint,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: _availableOnly
                        ? AppColors.primary
                        : AppColors.coolBorder,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  labelStyle: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _availableOnly
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                _sectionTitle('Facilities'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final facility in _facilityOptions)
                      _choiceChip(
                        label: facility,
                        selected: _facilities.contains(facility),
                        onTap: () {
                          setState(() {
                            if (_facilities.contains(facility)) {
                              _facilities.remove(facility);
                            } else {
                              _facilities.add(facility);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: AppColors.coolBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _apply,
                    child: const Text('Show Results'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MoreFiltersResult {
  const _MoreFiltersResult({
    required this.propertyType,
    required this.minRent,
    required this.maxRent,
    required this.bedrooms,
    required this.availableOnly,
    required this.facilities,
  });

  final String propertyType;
  final int? minRent;
  final int? maxRent;
  final String bedrooms;
  final bool availableOnly;
  final Set<String> facilities;
}
