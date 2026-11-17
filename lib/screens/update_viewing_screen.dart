import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/api_config.dart';
import '../data/demo_viewings.dart';
import '../theme/app_text_styles.dart';

class UpdateViewingScreen extends StatefulWidget {
  const UpdateViewingScreen({super.key, required this.id});

  final int id;

  @override
  State<UpdateViewingScreen> createState() => _UpdateViewingScreenState();
}

class _UpdateViewingScreenState extends State<UpdateViewingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _messageController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _propertyName = '';
  int _propertyId = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchViewing();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _findDemoViewing() {
    for (final viewing in demoViewings) {
      if (viewing['id'] == widget.id) {
        return viewing;
      }
    }
    return null;
  }

  Future<void> _fetchViewing() async {
    if (apiUrl == 'YOUR_API_URL') {
      final viewing = _findDemoViewing();

      if (viewing == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Viewing not found.';
        });
        return;
      }

      _dateController.text = viewing['viewingDate'] ?? '';
      _timeController.text = viewing['viewingTime'] ?? '';
      _messageController.text = viewing['message'] ?? '';

      setState(() {
        _propertyName = viewing['propertyName'] ?? '';
        _propertyId = viewing['propertyId'] ?? 0;
        _isLoading = false;
        _errorMessage = '';
      });
      return;
    }

    try {
      final res = await http.get(Uri.parse('$apiUrl/viewings/${widget.id}'));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        _dateController.text = data['viewingDate'] ?? '';
        _timeController.text = data['viewingTime'] ?? '';
        _messageController.text = data['message'] ?? '';

        setState(() {
          _propertyName = data['propertyName'] ?? '';
          _propertyId = data['propertyId'] ?? 0;
          _isLoading = false;
          _errorMessage = '';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load viewing.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load viewing.';
      });
    }
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

  Future<void> _updateViewing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    if (apiUrl == 'YOUR_API_URL') {
      final viewing = _findDemoViewing();

      if (viewing == null) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Viewing not found.';
        });
        return;
      }

      viewing['viewingDate'] = _dateController.text;
      viewing['viewingTime'] = _timeController.text;
      viewing['message'] = _messageController.text;

      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viewing updated successfully.')),
      );
      Navigator.pop(context);
      return;
    }

    try {
      final headers = {'Content-Type': 'application/json'};

      final body = jsonEncode({
        'propertyId': _propertyId,
        'propertyName': _propertyName,
        'viewingDate': _dateController.text,
        'viewingTime': _timeController.text,
        'message': _messageController.text,
      });

      final res = await http.put(
        Uri.parse('$apiUrl/viewings/${widget.id}'),
        headers: headers,
        body: body,
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viewing updated successfully.')),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update viewing.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update viewing.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Viewing')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _errorMessage,
                  style: AppTextStyles.secondaryBody,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Update viewing', style: AppTextStyles.h2),
                    const SizedBox(height: 6),
                    Text(_propertyName, style: AppTextStyles.secondaryBody),
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
                      onPressed: _isSaving ? null : _updateViewing,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update Viewing'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
