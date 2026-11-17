import 'package:flutter/material.dart';

import '../../data/partner_demo_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class UpdatePropertyScreen extends StatefulWidget {
  const UpdatePropertyScreen({super.key, required this.id});

  final int id;

  @override
  State<UpdatePropertyScreen> createState() => _UpdatePropertyScreenState();
}

class _UpdatePropertyScreenState extends State<UpdatePropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _typeController = TextEditingController();
  final _rentController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _descriptionController = TextEditingController();

  Map<String, dynamic>? _property;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();

    for (final property in partnerProperties) {
      if (property['id'] == widget.id) {
        _property = property;
        _nameController.text = property['name']?.toString() ?? '';
        _locationController.text = property['location']?.toString() ?? '';
        _typeController.text = property['type']?.toString() ?? '';
        _rentController.text = property['monthlyRent']?.toString() ?? '';
        _bedroomsController.text = property['bedrooms']?.toString() ?? '';
        _descriptionController.text = property['description']?.toString() ?? '';
        _isAvailable = property['available'] == true;
        break;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _typeController.dispose();
    _rentController.dispose();
    _bedroomsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateProperty() {
    if (_property == null) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    _property!['name'] = _nameController.text.trim();
    _property!['location'] = _locationController.text.trim();
    _property!['type'] = _typeController.text.trim();
    _property!['monthlyRent'] = int.parse(_rentController.text.trim());
    _property!['bedrooms'] = int.parse(_bedroomsController.text.trim());
    _property!['description'] = _descriptionController.text.trim();
    _property!['available'] = _isAvailable;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Property updated successfully.')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_property == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Property')),
        body: const Center(
          child: Text('Property not found.', style: AppTextStyles.body),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Property')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Property details', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 6),
              const Text(
                'Update the listing information below.',
                style: AppTextStyles.secondaryBody,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Property Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Property name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _typeController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Property Type'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Property type is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _rentController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Monthly Rent'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Monthly rent is required';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Monthly rent must be a number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _bedroomsController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Bedrooms'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bedrooms are required';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Bedrooms must be a number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _isAvailable,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      setState(() {
                        _isAvailable = value ?? true;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Available for rent',
                      style: AppTextStyles.body,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProperty,
                child: const Text('Update Property'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
