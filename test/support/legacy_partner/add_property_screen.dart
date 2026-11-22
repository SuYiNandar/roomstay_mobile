import 'package:flutter/material.dart';

import '../../fixtures/partner_demo_data.dart';
import 'package:roomstay_mobile/theme/app_colors.dart';
import 'package:roomstay_mobile/theme/app_text_styles.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _typeController = TextEditingController();
  final _rentController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isAvailable = true;

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

  void _saveProperty() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    partnerProperties.add({
      'id': nextPartnerPropertyId,
      'name': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      'type': _typeController.text.trim(),
      'monthlyRent': int.parse(_rentController.text.trim()),
      'bedrooms': int.parse(_bedroomsController.text.trim()),
      'description': _descriptionController.text.trim(),
      'available': _isAvailable,
    });

    nextPartnerPropertyId++;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Property added successfully.')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
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
                'Add a new room or property for renters to discover.',
                style: AppTextStyles.secondaryBody,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Property Name',
                  hintText: 'e.g. Cozy Studio near RSU',
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g. Rangsit, Pathum Thani',
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Property Type',
                  hintText: 'e.g. Condo, Apartment, House',
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Monthly Rent',
                  hintText: 'e.g. 6500',
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Bedrooms',
                  hintText: 'e.g. 1',
                ),
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
                  hintText: 'Describe the property and nearby facilities.',
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
                onPressed: _saveProperty,
                child: const Text('Add Property'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
