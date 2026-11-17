import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/api_config.dart';
import '../data/demo_viewings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'update_viewing_screen.dart';

class MyViewingsScreen extends StatefulWidget {
  const MyViewingsScreen({super.key});

  @override
  State<MyViewingsScreen> createState() => _MyViewingsScreenState();
}

class _MyViewingsScreenState extends State<MyViewingsScreen> {
  List<dynamic> _viewings = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchViewings();
  }

  Future<void> _fetchViewings() async {
    if (apiUrl == 'YOUR_API_URL') {
      setState(() {
        _viewings = List<Map<String, dynamic>>.from(demoViewings);
        _isLoading = false;
        _errorMessage = '';
      });
      return;
    }

    try {
      final res = await http.get(Uri.parse('$apiUrl/viewings'));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _viewings = data is List ? data : [];
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

  Future<void> _openUpdateViewing(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdateViewingScreen(id: id)),
    );

    await _fetchViewings();
  }

  Future<void> _deleteViewing(int id, int index) async {
    if (apiUrl == 'YOUR_API_URL') {
      demoViewings.removeWhere((viewing) => viewing['id'] == id);

      setState(() {
        _viewings.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viewing cancelled successfully.')),
      );
      return;
    }

    try {
      final res = await http.delete(Uri.parse('$apiUrl/viewings/$id'));

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() {
          _viewings.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viewing cancelled successfully.')),
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
    }
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
                          'No viewing requests yet',
                          style: AppTextStyles.sectionTitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Open a room and request a viewing to get started.',
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
                      _openUpdateViewing(viewing['id']);
                    },
                    onCancel: () {
                      _deleteViewing(viewing['id'], index - 1);
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
    if (viewing['status'] == 'Approved') {
      return AppColors.successBackground;
    }
    if (viewing['status'] == 'Cancelled') {
      return AppColors.photoBackground;
    }
    return AppColors.warningBackground;
  }

  Color get _statusColor {
    if (viewing['status'] == 'Approved') {
      return AppColors.success;
    }
    if (viewing['status'] == 'Cancelled') {
      return AppColors.textSecondary;
    }
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
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
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.roofLavender,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewing['propertyName'] ?? '',
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
                              '${viewing['viewingDate']} • ${viewing['viewingTime']}',
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
                  onPressed: onCancel,
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
