import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';
import '../data/user_session.dart';
import '../data/viewing_helpers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ManagerViewingsScreen extends StatefulWidget {
  const ManagerViewingsScreen({super.key});

  @override
  State<ManagerViewingsScreen> createState() => _ManagerViewingsScreenState();
}

class _ManagerViewingsScreenState extends State<ManagerViewingsScreen> {
  List<Map<String, dynamic>> _viewings = [];
  final Set<int> _propertyIds = {};
  final Map<String, String> _renterLabels = {};
  final Set<String> _updatingIds = {};
  bool _isLoading = true;
  String _error = '';

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
    _fetchViewings();
  }

  Future<void> _fetchViewings() async {
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
      final propertyResponse = await http.get(
        Uri.parse(
          '$supabaseUrl/rest/v1/properties?partner_id=eq.${UserSession.userId}&select=id,partner_id&order=id.desc',
        ),
        headers: _headers,
      );
      if (!mounted) return;
      if (propertyResponse.statusCode != 200) {
        throw const FormatException('Properties request failed');
      }
      final properties = jsonDecode(propertyResponse.body);
      if (properties is! List) {
        throw const FormatException('Expected property list');
      }
      _propertyIds.clear();
      for (final property in properties) {
        if (property['partner_id'] == UserSession.userId) {
          final id = int.tryParse(property['id'].toString());
          if (id != null) _propertyIds.add(id);
        }
      }
      _renterLabels.clear();
      if (_propertyIds.isEmpty) {
        setState(() {
          _viewings = [];
          _isLoading = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/viewings').replace(
          queryParameters: {
            'property_id': 'in.(${_propertyIds.join(',')})',
            'select':
                'id,property_id,renter_id,viewing_date,viewing_time,message,status,created_at,properties(name)',
            'order': 'created_at.desc',
          },
        ),
        headers: _headers,
      );
      if (!mounted) return;
      if (response.statusCode != 200) {
        throw const FormatException('Viewings request failed');
      }
      final data = jsonDecode(response.body);
      if (data is! List) throw const FormatException('Expected viewings list');
      final viewings = <Map<String, dynamic>>[];
      final renterIds = <String>{};
      for (final row in data) {
        final viewing = Map<String, dynamic>.from(row as Map);
        final propertyId = int.tryParse(viewing['property_id'].toString());
        if (!_propertyIds.contains(propertyId)) continue;
        viewings.add(viewing);
        final renterId = viewing['renter_id']?.toString();
        if (renterId != null && renterId.isNotEmpty) renterIds.add(renterId);
      }
      await _fetchRenterLabels(renterIds);
      if (!mounted) return;
      setState(() {
        _viewings = viewings;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load viewing requests.';
      });
    }
  }

  Future<void> _fetchRenterLabels(Set<String> renterIds) async {
    if (renterIds.isEmpty) return;
    // Only request profiles belonging to this manager's filtered viewings.
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/profiles').replace(
          queryParameters: {
            'id': 'in.(${renterIds.join(',')})',
            'select': 'id,full_name,email',
          },
        ),
        headers: _headers,
      );
      if (!mounted || response.statusCode != 200) return;
      final data = jsonDecode(response.body);
      if (data is! List) return;
      for (final profile in data) {
        final id = profile['id']?.toString();
        if (!renterIds.contains(id)) continue;
        final name = profile['full_name']?.toString().trim() ?? '';
        final email = profile['email']?.toString().trim() ?? '';
        if (name.isNotEmpty || email.isNotEmpty) {
          _renterLabels[id!] = name.isNotEmpty ? name : email;
        }
      }
    } catch (_) {
      // Profiles may be hidden by RLS; requests still work without contact details.
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _updateStatus(
    Map<String, dynamic> viewing,
    String status,
  ) async {
    final id = viewing['id'].toString();
    final propertyId = int.tryParse(viewing['property_id'].toString());
    if (!_hasAccess ||
        !_propertyIds.contains(propertyId) ||
        viewing['status'] != 'Pending' ||
        _updatingIds.contains(id) ||
        !['Approved', 'Rejected'].contains(status)) {
      return;
    }
    setState(() => _updatingIds.add(id));
    try {
      // Recheck ownership in case it changed since the list was loaded.
      // The database RLS policy must also enforce ownership on the PATCH itself.
      final ownership = await http.get(
        Uri.parse(
          '$supabaseUrl/rest/v1/properties?id=eq.$propertyId&partner_id=eq.${UserSession.userId}&select=id,partner_id',
        ),
        headers: _headers,
      );
      if (!mounted) return;
      final properties = jsonDecode(ownership.body);
      if (!_hasAccess ||
          ownership.statusCode != 200 ||
          properties is! List ||
          properties.isEmpty ||
          properties.first['partner_id'] != UserSession.userId ||
          properties.first['id'].toString() != propertyId.toString()) {
        _showMessage(
          'Unable to update this viewing request. You may no longer own the property.',
        );
        return;
      }
      final response = await http.patch(
        Uri.parse(
          '$supabaseUrl/rest/v1/viewings?id=eq.$id&property_id=eq.$propertyId&status=eq.Pending',
        ),
        headers: {..._headers, 'Prefer': 'return=representation'},
        body: jsonEncode({'status': status}),
      );
      if (!mounted) return;
      final rows = jsonDecode(response.body);
      if (response.statusCode == 200 &&
          rows is List &&
          rows.isNotEmpty &&
          rows.first['id'].toString() == id &&
          rows.first['status'] == status) {
        setState(() => viewing['status'] = status);
        _showMessage(
          status == 'Approved'
              ? 'Viewing request approved.'
              : 'Viewing request rejected.',
        );
      } else {
        _showMessage(
          'Unable to update viewing request. Check your access or refresh the list.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to update viewing request.');
    } finally {
      if (mounted) setState(() => _updatingIds.remove(id));
    }
  }

  Widget _buildViewing(Map<String, dynamic> viewing) {
    final status = viewing['status']?.toString() ?? 'Pending';
    final message = viewing['message']?.toString() ?? '';
    final updating = _updatingIds.contains(viewing['id'].toString());
    final color = status == 'Approved'
        ? AppColors.success
        : status == 'Rejected'
        ? AppColors.error
        : status == 'Cancelled'
        ? AppColors.textSecondary
        : AppColors.warning;
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
            Text(
              viewingPropertyName(viewing),
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 6),
            Text(
              _renterLabels[viewing['renter_id']?.toString()] ??
                  'Renter information unavailable',
              style: AppTextStyles.secondaryBody,
            ),
            const SizedBox(height: 6),
            Text(
              '${displayViewingDate(viewing['viewing_date'])} at ${displayViewingTime(viewing['viewing_time'])}',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 8),
            Text(
              message.isEmpty ? 'No message provided.' : message,
              style: AppTextStyles.secondaryBody,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.small.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (status == 'Pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: updating
                          ? null
                          : () => _updateStatus(viewing, 'Approved'),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: updating
                          ? null
                          : () => _updateStatus(viewing, 'Rejected'),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

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
                onPressed: _fetchViewings,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_viewings.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.event_busy_outlined,
                size: 56,
                color: AppColors.roofLavender,
              ),
              const SizedBox(height: 16),
              const Text(
                'No viewing requests yet',
                style: AppTextStyles.sectionTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'New requests from renters will appear here.',
                style: AppTextStyles.secondaryBody,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
      itemCount: _viewings.length,
      itemBuilder: (context, index) => _buildViewing(_viewings[index]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Viewing Requests'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _isLoading || _updatingIds.isNotEmpty
              ? null
              : _fetchViewings,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _buildBody(),
  );
}
