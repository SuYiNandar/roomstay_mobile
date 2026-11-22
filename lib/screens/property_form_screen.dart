import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/supabase_config.dart';
import '../data/user_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// Add and Edit share the same fields; a property ID selects edit mode.
class PropertyFormScreen extends StatefulWidget {
  const PropertyFormScreen({super.key, this.propertyId});

  final int? propertyId;

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _rentController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _facilityOptions = [
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
  ];
  final Set<String> _selectedFacilities = {};
  Uint8List? _photoBytes;
  String? _photoFormat;
  String? _imageUrl;
  bool _isPickingPhoto = false;

  final _types = ['Apartment', 'Condo', 'Dormitory', 'House'];
  String? _type;
  bool _available = true;
  bool _petFriendly = false;
  bool _nearUniversity = false;
  bool _nearTransit = false;
  bool _isLoading = false;
  bool _isSaving = false;
  String _error = '';

  bool get _isEditing => widget.propertyId != null;
  bool get _hasAccess =>
      UserSession.isPropertyManager &&
      UserSession.userId != null &&
      UserSession.accessToken != null;

  Map<String, String> get _headers => {
    'apikey': supabasePublishableKey,
    'Authorization': 'Bearer ${UserSession.accessToken}',
    'Content-Type': 'application/json',
  };

  @override
  void initState() {
    super.initState();
    if (_isEditing) _fetchProperty();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _rentController.dispose();
    _bedroomsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchProperty() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    if (!_hasAccess) {
      setState(() {
        _isLoading = false;
        _error = 'Please log in as a property manager.';
      });
      return;
    }
    try {
      final response = await http.get(
        Uri.parse(
          '$supabaseUrl/rest/v1/properties?id=eq.${widget.propertyId}&partner_id=eq.${UserSession.userId}&select=*',
        ),
        headers: _headers,
      );
      if (!mounted) return;
      if (response.statusCode != 200) {
        throw const FormatException('Property request failed');
      }
      final data = jsonDecode(response.body);
      if (data is! List) throw const FormatException('Expected property list');
      if (data.isEmpty || data.first['partner_id'] != UserSession.userId) {
        setState(() {
          _isLoading = false;
          _error = 'Property not found or you do not have access.';
        });
        return;
      }
      final property = data.first;
      _nameController.text = property['name']?.toString() ?? '';
      _locationController.text = property['location']?.toString() ?? '';
      _rentController.text = property['monthly_rent']?.toString() ?? '';
      _bedroomsController.text = property['bedrooms']?.toString() ?? '';
      _descriptionController.text = property['description']?.toString() ?? '';
      _imageUrl = property['image_url']?.toString();
      final facilities = property['facilities'];
      _selectedFacilities.clear();
      if (facilities is List) {
        _selectedFacilities.addAll(facilities.whereType<String>());
        for (final facility in _selectedFacilities) {
          if (!_facilityOptions.contains(facility) &&
              facility != 'Pet friendly') {
            _facilityOptions.add(facility);
          }
        }
      }
      _type = property['type']?.toString();
      if (_type != null && !_types.contains(_type)) _types.add(_type!);
      _available = property['available'] == true;
      _petFriendly = property['pet_friendly'] == true;
      _nearUniversity = property['near_university'] == true;
      _nearTransit = property['near_transit'] == true;
      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load property.';
      });
    }
  }

  Future<void> _saveProperty() async {
    if (_isSaving || _isPickingPhoto || !_formKey.currentState!.validate()) {
      return;
    }
    if (!_hasAccess) {
      _showMessage('Please log in as a property manager.');
      return;
    }
    final managerId = UserSession.userId;
    final values = <String, dynamic>{
      'name': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      'type': _type,
      'monthly_rent': int.parse(_rentController.text.trim()),
      'bedrooms': int.parse(_bedroomsController.text.trim()),
      'description': _descriptionController.text.trim(),
      'facilities': _selectedFacilities.toList(),
      'image_url': _imageUrl,
      'available': _available,
      'pet_friendly': _petFriendly,
      'near_university': _nearUniversity,
      'near_transit': _nearTransit,
    };
    setState(() => _isSaving = true);
    try {
      if (_photoBytes != null) {
        try {
          final imageUrl = await _uploadPhoto();
          if (!mounted) return;
          // Keep the successful upload on a property-save retry.
          setState(() {
            _imageUrl = imageUrl;
            _photoBytes = null;
            _photoFormat = null;
          });
          values['image_url'] = imageUrl;
        } catch (_) {
          if (mounted) _showMessage('Unable to upload property photo.');
          return;
        }
      }
      if (!_hasAccess || UserSession.userId != managerId) {
        _showMessage('Please log in as a property manager.');
        return;
      }
      final http.Response response;
      final headers = {..._headers, 'Prefer': 'return=representation'};
      if (_isEditing) {
        response = await http.patch(
          Uri.parse(
            '$supabaseUrl/rest/v1/properties?id=eq.${widget.propertyId}&partner_id=eq.${UserSession.userId}',
          ),
          headers: headers,
          body: jsonEncode(values),
        );
      } else {
        values['partner_id'] = UserSession.userId;
        response = await http.post(
          Uri.parse('$supabaseUrl/rest/v1/properties'),
          headers: headers,
          body: jsonEncode(values),
        );
      }
      if (!mounted) return;
      final data = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data is List &&
          data.isNotEmpty) {
        _showMessage(
          _isEditing
              ? 'Property updated successfully.'
              : 'Property added successfully.',
        );
        Navigator.pop(context, true);
      } else {
        _showMessage(
          _isEditing ? 'Unable to update property.' : 'Unable to add property.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        _isEditing ? 'Unable to update property.' : 'Unable to add property.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _choosePhoto() async {
    if (_isSaving || _isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (photo == null || !mounted) return;
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      final format = _readPhotoFormat(bytes);
      if (format == null) {
        _showMessage('Please choose a JPEG, PNG, WebP, or GIF photo.');
        return;
      }
      setState(() {
        _photoBytes = bytes;
        _photoFormat = format;
      });
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Unable to choose photo. Check your gallery permission and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  // Use file signatures, not the gallery filename, for the upload content type.
  String? _readPhotoFormat(Uint8List bytes) {
    if (bytes.length < 12) return null;
    if (bytes[0] == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff) return 'jpeg';
    if (bytes[0] == 0x89 && ascii.decode(bytes.sublist(1, 4)) == 'PNG') {
      return 'png';
    }
    final header = ascii.decode(bytes.sublist(0, 12), allowInvalid: true);
    if (header.startsWith('GIF87a') || header.startsWith('GIF89a')) {
      return 'gif';
    }
    if (header.startsWith('RIFF') && header.substring(8) == 'WEBP') {
      return 'webp';
    }
    return null;
  }

  Future<String> _uploadPhoto() async {
    final path =
        '${UserSession.userId}/${DateTime.now().microsecondsSinceEpoch}.$_photoFormat';
    final response = await http.post(
      Uri.parse('$supabaseUrl/storage/v1/object/property-images/$path'),
      headers: {
        ..._headers,
        'Content-Type': 'image/$_photoFormat',
        'x-upsert': 'false',
      },
      body: _photoBytes!,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw const FormatException('Photo upload failed');
    }
    return '$supabaseUrl/storage/v1/object/public/property-images/$path';
  }

  Widget _photoPlaceholder() => const Center(
    child: Icon(Icons.image_outlined, size: 48, color: AppColors.textSecondary),
  );

  Widget _buildPhoto() {
    final hasPhoto = _photoBytes != null || (_imageUrl?.isNotEmpty ?? false);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Property Photo', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          if (hasPhoto) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 180,
                child: _photoBytes != null
                    ? Image.memory(
                        _photoBytes!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _photoPlaceholder(),
                      )
                    : Image.network(
                        _imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _photoPlaceholder(),
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_isPickingPhoto) const Center(child: CircularProgressIndicator()),
          Wrap(
            spacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _isSaving || _isPickingPhoto ? null : _choosePhoto,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(hasPhoto ? 'Change Photo' : 'Add Photo'),
              ),
              if (hasPhoto)
                TextButton(
                  onPressed: _isSaving || _isPickingPhoto
                      ? null
                      : () => setState(() {
                          _photoBytes = null;
                          _photoFormat = null;
                          _imageUrl = null;
                        }),
                  child: const Text('Remove'),
                ),
            ],
          ),
          if (!hasPhoto)
            const Text(
              'Choose from gallery',
              style: AppTextStyles.secondaryBody,
            ),
        ],
      ),
    );
  }

  Widget _buildForm() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Property details', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Property Name'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Property name is required'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Location'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Location is required'
                : null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _type,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Property Type'),
            items: [
              for (final type in _types)
                DropdownMenuItem(value: type, child: Text(type)),
            ],
            onChanged: (value) => setState(() => _type = value),
            validator: (value) => value == null || value.isEmpty
                ? 'Property type is required'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _rentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Monthly Rent'),
            validator: (value) {
              final rent = int.tryParse(value?.trim() ?? '');
              if (rent == null || rent <= 0) {
                return 'Monthly rent must be a positive whole number';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            // Legacy values outside the MVP range require an explicit choice.
            initialValue:
                List.generate(
                  6,
                  (i) => i,
                ).contains(int.tryParse(_bedroomsController.text))
                ? int.tryParse(_bedroomsController.text)
                : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Bedrooms'),
            hint: const Text('Select bedrooms'),
            items: List.generate(
              6,
              (index) => DropdownMenuItem<int>(
                value: index,
                child: Text(
                  index == 0
                      ? 'Studio (0 Bedroom)'
                      : '$index Bedroom${index > 1 ? 's' : ''}',
                ),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _bedroomsController.text = value?.toString() ?? '';
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select bedrooms';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          const Text('Facilities', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              // Keep legacy facility labels editable without rewriting their values.
              for (final facility in _facilityOptions)
                if (facility != 'Pet friendly')
                  FilterChip(
                    label: Text(facility),
                    selected: _selectedFacilities.contains(facility),
                    selectedColor: AppColors.primaryTint,
                    checkmarkColor: AppColors.primary,
                    labelStyle: AppTextStyles.small.copyWith(
                      color: _selectedFacilities.contains(facility)
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _selectedFacilities.add(facility);
                      } else {
                        _selectedFacilities.remove(facility);
                      }
                    }),
                  ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPhoto(),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Available'),
            value: _available,
            onChanged: (value) => setState(() => _available = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pet friendly'),
            value: _petFriendly,
            onChanged: (value) => setState(() => _petFriendly = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Near university'),
            value: _nearUniversity,
            onChanged: (value) => setState(() => _nearUniversity = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Near transit'),
            value: _nearTransit,
            onChanged: (value) => setState(() => _nearTransit = value),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSaving || _isPickingPhoto ? null : _saveProperty,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_isEditing ? 'Update Property' : 'Add Property'),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_isEditing ? 'Edit Property' : 'Add Property')),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error.isNotEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _error,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.secondaryBody,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _fetchProperty,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        : AbsorbPointer(absorbing: _isSaving, child: _buildForm()),
  );
}
