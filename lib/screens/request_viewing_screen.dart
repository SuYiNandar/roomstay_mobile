import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/api_config.dart';
import '../data/demo_viewings.dart';
import '../models/property.dart';
import '../theme/app_text_styles.dart';
import '../widgets/property_summary_card.dart';

class RequestViewingScreen extends StatefulWidget {
  const RequestViewingScreen({super.key, required this.property});

  final Property property;

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

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _selectedDate = selected;
      _dateController.text =
          '${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}';
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _selectedTime = selected;
      _timeController.text = selected.format(context);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    if (apiUrl == 'YOUR_API_URL') {
      demoViewings.add({
        'id': nextDemoViewingId,
        'propertyId': widget.property.id,
        'propertyName': widget.property.name,
        'userId': 1,
        'viewingDate': _dateController.text,
        'viewingTime': _timeController.text,
        'message': _messageController.text,
        'status': 'Pending',
      });
      nextDemoViewingId++;

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viewing request submitted successfully.'),
        ),
      );
      Navigator.pop(context);
      return;
    }

    try {
      final headers = {'Content-Type': 'application/json'};

      final body = jsonEncode({
        'propertyId': widget.property.id,
        'propertyName': widget.property.name,
        'userId': 1,
        'viewingDate': _dateController.text,
        'viewingTime': _timeController.text,
        'message': _messageController.text,
        'status': 'Pending',
      });

      final res = await http.post(
        Uri.parse('$apiUrl/viewings'),
        headers: headers,
        body: body,
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
        Navigator.pop(context);
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
                'Choose a preferred date and time. The partner will confirm the viewing later.',
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
                  hintText: 'Share anything the partner should know',
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
                        child: CircularProgressIndicator(strokeWidth: 2),
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
