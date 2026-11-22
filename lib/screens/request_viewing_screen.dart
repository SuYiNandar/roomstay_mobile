import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';
import '../data/user_session.dart';
import '../data/viewing_helpers.dart';
import '../models/property.dart';
import '../theme/app_text_styles.dart';
import '../widgets/property_summary_card.dart';

class RequestViewingScreen extends StatefulWidget {
  const RequestViewingScreen({super.key, required this.property, this.now});

  final Property property;
  final DateTime Function()? now;

  @override
  State<RequestViewingScreen> createState() => _RequestViewingScreenState();
}

class _RequestViewingScreenState extends State<RequestViewingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _messageController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  DateTime _currentTime() => widget.now?.call() ?? DateTime.now();

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = _currentTime();
    final today = DateUtils.dateOnly(now);
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _selectedDate = selected;
      _dateController.text = displayViewingDate(supabaseDate(selected));
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.fromDateTime(_currentTime()),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _selectedTime = selected;
      _timeController.text = selected.format(context);
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) return;

    if (!isFutureViewingDateTime(
      _selectedDate!,
      _selectedTime!,
      now: _currentTime(),
    )) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(futureViewingTimeMessage)));
      return;
    }

    final viewingDate = supabaseDate(_selectedDate!);
    final viewingTime = supabaseTime(_selectedTime!);
    final message = _messageController.text.trim();

    if (UserSession.accessToken == null || UserSession.userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in again.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final res = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/viewings'),
        headers: {
          'apikey': supabasePublishableKey,
          'Authorization': 'Bearer ${UserSession.accessToken}',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'property_id': widget.property.id,
          'renter_id': UserSession.userId,
          'viewing_date': viewingDate,
          'viewing_time': viewingTime,
          'message': message,
          'status': 'Pending',
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viewing request submitted successfully.'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to submit viewing request.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to submit viewing request.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Viewing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Schedule a viewing', style: AppTextStyles.h2),
              const SizedBox(height: 6),
              const Text(
                'Choose a preferred date and time. The property manager will confirm the viewing later.',
                style: AppTextStyles.secondaryBody,
              ),
              const SizedBox(height: 20),
              PropertySummaryCard(property: widget.property),
              const SizedBox(height: 20),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Preferred date',
                  hintText: 'Select a date',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  suffixIcon: Icon(Icons.keyboard_arrow_down),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _timeController,
                readOnly: true,
                onTap: _pickTime,
                decoration: const InputDecoration(
                  labelText: 'Preferred time',
                  hintText: 'Select a time',
                  prefixIcon: Icon(Icons.access_time),
                  suffixIcon: Icon(Icons.keyboard_arrow_down),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _messageController,
                minLines: 3,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  hintText: 'Share anything the property manager should know',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
