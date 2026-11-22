import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';
import '../data/user_session.dart';
import '../models/property.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'property_form_screen.dart';

class ManagerPropertiesScreen extends StatefulWidget {
  const ManagerPropertiesScreen({super.key});

  @override
  State<ManagerPropertiesScreen> createState() =>
      _ManagerPropertiesScreenState();
}

class _ManagerPropertiesScreenState extends State<ManagerPropertiesScreen> {
  List<Property> _properties = [];
  bool _isLoading = true;
  String _error = '';
  final Set<int> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  bool get _hasAccess =>
      UserSession.isPropertyManager &&
      UserSession.userId != null &&
      UserSession.accessToken != null;

  Map<String, String> get _headers => {
    'apikey': supabasePublishableKey,
    'Authorization': 'Bearer ${UserSession.accessToken}',
    'Content-Type': 'application/json',
  };

  Future<void> _fetchProperties() async {
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
          '$supabaseUrl/rest/v1/properties?partner_id=eq.${UserSession.userId}&select=*&order=id.desc',
        ),
        headers: _headers,
      );
      if (!mounted) return;
      if (response.statusCode != 200) {
        throw const FormatException('Properties request failed');
      }
      final data = jsonDecode(response.body);
      if (data is! List) {
        throw const FormatException('Expected properties list');
      }
      final properties = <Property>[];
      for (final row in data) {
        final property = Property.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        );
        if (property.partnerId == UserSession.userId) properties.add(property);
      }
      setState(() {
        _properties = properties;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load properties.';
      });
    }
  }

  Future<void> _openForm([int? propertyId]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyFormScreen(propertyId: propertyId),
      ),
    );
    if (!mounted) return;
    if (saved == true) await _fetchProperties();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteProperty(Property property) async {
    if (_deletingIds.contains(property.id) ||
        !_hasAccess ||
        property.partnerId != UserSession.userId) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property?'),
        content: const Text('Are you sure you want to delete this property?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted ||
        confirmed != true ||
        !_hasAccess ||
        property.partnerId != UserSession.userId) {
      return;
    }
    setState(() => _deletingIds.add(property.id));
    try {
      final response = await http.delete(
        Uri.parse(
          '$supabaseUrl/rest/v1/properties?id=eq.${property.id}&partner_id=eq.${UserSession.userId}',
        ),
        headers: {..._headers, 'Prefer': 'return=representation'},
      );
      if (!mounted) return;
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data is List && data.isNotEmpty) {
        setState(
          () => _properties.removeWhere((item) => item.id == property.id),
        );
        _showMessage('Property deleted successfully.');
      } else if (data is Map && data['code'] == '23503') {
        _showMessage(
          'Unable to delete this property because it has related records.',
        );
      } else {
        _showMessage('Unable to delete property.');
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to delete property.');
    } finally {
      if (mounted) setState(() => _deletingIds.remove(property.id));
    }
  }

  Widget _buildProperty(Property property) {
    final deleting = _deletingIds.contains(property.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 140,
                child: property.image.isEmpty
                    ? _imagePlaceholder()
                    : Image.network(
                        property.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            _imagePlaceholder(),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(property.name, style: AppTextStyles.sectionTitle),
            const SizedBox(height: 4),
            Text(property.location, style: AppTextStyles.secondaryBody),
            const SizedBox(height: 8),
            Text(
              property.priceLabel,
              style: AppTextStyles.body.copyWith(
                color: AppColors.deepIndigo,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              property.available ? 'Available' : 'Unavailable',
              style: AppTextStyles.small.copyWith(
                color: property.available
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: deleting ? null : () => _openForm(property.id),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: deleting ? null : () => _deleteProperty(property),
                  icon: const Icon(Icons.delete_outline),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  label: Text(deleting ? 'Deleting…' : 'Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: AppColors.photoBackground,
    child: const Center(
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: AppColors.roofLavender,
      ),
    ),
  );

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) {
      return Center(
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
                onPressed: _fetchProperties,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_properties.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.apartment_outlined,
                size: 56,
                color: AppColors.roofLavender,
              ),
              const SizedBox(height: 16),
              const Text(
                'No properties yet',
                style: AppTextStyles.sectionTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first property to start receiving viewing requests.',
                style: AppTextStyles.secondaryBody,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
      itemCount: _properties.length,
      itemBuilder: (context, index) => _buildProperty(_properties[index]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Properties')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _hasAccess ? () => _openForm() : null,
              child: const Text('Add Property'),
            ),
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    ),
  );
}
