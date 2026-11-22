import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';
import '../data/user_session.dart';
import '../data/viewing_helpers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'login_screen.dart';
import 'update_viewing_screen.dart';

class MyViewingsScreen extends StatefulWidget {
  const MyViewingsScreen({super.key});

  @override
  State<MyViewingsScreen> createState() => _MyViewingsScreenState();
}

class _MyViewingsScreenState extends State<MyViewingsScreen> {
  List<Map<String, dynamic>> _viewings = [];
  final Set<String> _cancellingIds = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchViewings();
  }

  Future<void> _fetchViewings() async {
    if (UserSession.accessToken == null || UserSession.userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please log in again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final res = await http.get(
        Uri.parse(
          '$supabaseUrl/rest/v1/viewings'
          '?renter_id=eq.${UserSession.userId}'
          '&select=id,property_id,renter_id,viewing_date,viewing_time,message,status,created_at,properties(name,location,image_url)'
          '&order=created_at.desc',
        ),
        headers: {
          'apikey': supabasePublishableKey,
          'Authorization': 'Bearer ${UserSession.accessToken}',
        },
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is! List) {
          throw const FormatException('Expected viewings list');
        }
        final viewings = <Map<String, dynamic>>[];
        for (final row in data) {
          viewings.add(Map<String, dynamic>.from(row as Map));
        }
        setState(() {
          _viewings = viewings;
          _isLoading = false;
          _errorMessage = '';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load viewings.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load viewings.';
      });
    }
  }

  Future<void> _openUpdateViewing(Map<String, dynamic> viewing) async {
    if (!isPendingViewingStatus(viewing['status'])) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(pendingViewingModificationMessage)),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => UpdateViewingScreen(id: viewing['id']),
      ),
    );

    if (!mounted) return;
    if (result == true) {
      await _fetchViewings();
    }
  }

  Future<void> _cancelViewing(Map<String, dynamic> viewing) async {
    if (!isPendingViewingStatus(viewing['status'])) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(pendingViewingModificationMessage)),
      );
      return;
    }

    final id = viewing['id'];
    if (_cancellingIds.contains(id.toString())) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel viewing?'),
          content: const Text('Are you sure you want to cancel this viewing?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    if (UserSession.accessToken == null || UserSession.userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in again.')));
      return;
    }

    _cancellingIds.add(id.toString());
    try {
      final res = await http.delete(
        Uri.parse(
          '$supabaseUrl/rest/v1/viewings?id=eq.$id'
          '&renter_id=eq.${UserSession.userId}'
          '&status=eq.Pending',
        ),
        headers: {
          'apikey': supabasePublishableKey,
          'Authorization': 'Bearer ${UserSession.accessToken}',
          'Prefer': 'return=representation',
        },
      );

      if (!mounted) return;

      final rows = res.statusCode == 200 ? jsonDecode(res.body) : null;
      if (rows is List && rows.isNotEmpty) {
        setState(() {
          _viewings.removeWhere(
            (item) => item['id'].toString() == id.toString(),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viewing cancelled successfully.')),
        );
      } else if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(pendingViewingModificationMessage)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to cancel viewing.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to cancel viewing.')),
      );
    } finally {
      _cancellingIds.remove(id.toString());
    }
  }

  void _goToLogin() {
    UserSession.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Viewings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _errorMessage,
                      style: AppTextStyles.secondaryBody,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (_errorMessage == 'Please log in again.')
                      ElevatedButton(
                        onPressed: _goToLogin,
                        child: const Text('Log In'),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = '';
                          });
                          _fetchViewings();
                        },
                        child: const Text('Try Again'),
                      ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
              itemCount: _viewings.isEmpty ? 2 : _viewings.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('Viewing requests', style: AppTextStyles.h2),
                  );
                }

                if (_viewings.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.event_busy_outlined,
                          size: 40,
                          color: AppColors.roofLavender,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No viewing requests yet.',
                          style: AppTextStyles.sectionTitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choose a room and request a viewing.',
                          style: AppTextStyles.secondaryBody,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final viewing = _viewings[index - 1];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ViewingCard(
                    viewing: viewing,
                    onEdit: () {
                      _openUpdateViewing(viewing);
                    },
                    onCancel: () {
                      _cancelViewing(viewing);
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _ViewingCard extends StatelessWidget {
  const _ViewingCard({
    required this.viewing,
    required this.onEdit,
    required this.onCancel,
  });

  final Map<String, dynamic> viewing;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  Color get _statusBackground {
    if (viewing['status'] == 'Rejected') {
      return AppColors.error.withValues(alpha: 0.1);
    }
    if (viewing['status'] == 'Approved') {
      return AppColors.successBackground;
    }
    if (viewing['status'] == 'Cancelled') {
      return AppColors.photoBackground;
    }
    return AppColors.warningBackground;
  }

  Color get _statusColor {
    if (viewing['status'] == 'Rejected') return AppColors.error;
    if (viewing['status'] == 'Approved') {
      return AppColors.success;
    }
    if (viewing['status'] == 'Cancelled') {
      return AppColors.textSecondary;
    }
    return AppColors.warning;
  }

  Widget _buildImage() {
    final imageUrl = viewingPropertyImage(viewing);

    if (imageUrl.isEmpty) {
      return const Center(
        child: Icon(Icons.image_outlined, color: AppColors.roofLavender),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.image_outlined, color: AppColors.roofLavender),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final message = viewing['message']?.toString() ?? '';
    final canModify = isPendingViewingStatus(viewing['status']);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.photoBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _buildImage(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewingPropertyName(viewing),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandText,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${displayViewingDate(viewing['viewing_date'])} • ${displayViewingTime(viewing['viewing_time'])}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.small.copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          viewing['status'] ?? 'Pending',
                          style: AppTextStyles.small.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(fontSize: 12),
                ),
              ),
            ],
            if (canModify) ...[
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
