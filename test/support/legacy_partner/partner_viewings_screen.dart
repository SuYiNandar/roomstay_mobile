import 'package:flutter/material.dart';

import '../../fixtures/partner_demo_data.dart';
import 'package:roomstay_mobile/theme/app_colors.dart';
import 'package:roomstay_mobile/theme/app_text_styles.dart';

class PartnerViewingsScreen extends StatefulWidget {
  const PartnerViewingsScreen({super.key});

  @override
  State<PartnerViewingsScreen> createState() => _PartnerViewingsScreenState();
}

class _PartnerViewingsScreenState extends State<PartnerViewingsScreen> {
  final List<Map<String, dynamic>> _requests = partnerViewingRequests;

  void _approveRequest(Map<String, dynamic> request) {
    setState(() {
      request['status'] = 'Approved';
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Viewing request approved.')));
  }

  void _rejectRequest(Map<String, dynamic> request) {
    setState(() {
      request['status'] = 'Rejected';
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Viewing request rejected.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Viewing Requests')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          final status = request['status']?.toString() ?? 'Pending';
          final message = request['message']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
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
                            request['renterName'] ?? '',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandText,
                            ),
                          ),
                        ),
                        _StatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.home_work_outlined,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            request['propertyName'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.small.copyWith(
                              fontSize: 12,
                              color: AppColors.deepIndigo,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${request['viewingDate']} at ${request['viewingTime']}',
                          style: AppTextStyles.small.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        message.isEmpty ? 'No message provided.' : message,
                        style: AppTextStyles.body.copyWith(fontSize: 13),
                      ),
                    ),
                    if (status == 'Pending') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _approveRequest(request);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 40),
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _rejectRequest(request);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                minimumSize: const Size(0, 40),
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground;

    if (status == 'Approved') {
      background = AppColors.successBackground;
      foreground = AppColors.success;
    } else if (status == 'Rejected') {
      background = const Color(0xFFFDECEC);
      foreground = AppColors.error;
    } else {
      background = AppColors.warningBackground;
      foreground = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: AppTextStyles.small.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
