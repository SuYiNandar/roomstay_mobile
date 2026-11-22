import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';
import '../data/user_session.dart';
import '../data/viewing_helpers.dart';
import '../theme/app_text_styles.dart';

class UpdateViewingScreen extends StatefulWidget {
  const UpdateViewingScreen({super.key, required this.id, this.now});

  final dynamic id;
  final DateTime Function()? now;

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
  String _viewingStatus = '';
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

  DateTime _currentTime() => widget.now?.call() ?? DateTime.now();

  void _loadViewing(Map<String, dynamic> viewing) {
    final status = viewing['status']?.toString() ?? '';
    if (!isPendingViewingStatus(status)) {
      setState(() {
        _viewingStatus = status;
        _isLoading = false;
        _errorMessage = pendingViewingModificationMessage;
      });
      return;
    }

    _selectedDate = parseViewingDate(viewing['viewing_date']);
    _selectedTime = parseViewingTime(viewing['viewing_time']);

    _dateController.text = displayViewingDate(viewing['viewing_date']);
    _timeController.text = displayViewingTime(viewing['viewing_time']);
    _messageController.text = viewing['message']?.toString() ?? '';

    setState(() {
      _propertyName = viewingPropertyName(viewing);
      _viewingStatus = status;
      _isLoading = false;
      _errorMessage = '';
    });
  }

  Future<void> _fetchViewing() async {
    if (UserSession.accessToken == null || UserSession.userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please log in again.';
      });
      return;
    }

    try {
      final res = await http.get(
        Uri.parse(
          '$supabaseUrl/rest/v1/viewings?id=eq.${widget.id}'
          '&renter_id=eq.${UserSession.userId}'
          '&select=*,properties(name,location,image_url)',
        ),
        headers: {
          'apikey': supabasePublishableKey,
          'Authorization': 'Bearer ${UserSession.accessToken}',
        },
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data is List && data.isNotEmpty) {
          _loadViewing(Map<String, dynamic>.from(data[0] as Map));
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Viewing not found.';
          });
        }
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
    final today = DateUtils.dateOnly(_currentTime());
    final lastDate = today.add(const Duration(days: 365));
    var initialDate = _selectedDate ?? today.add(const Duration(days: 1));
    if (initialDate.isBefore(today)) initialDate = today;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: lastDate,
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

  Future<void> _updateViewing() async {
    if (_isSaving) return;
    if (!isPendingViewingStatus(_viewingStatus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(pendingViewingModificationMessage)),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time.')),
      );
      return;
    }

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

    final updatedDate = supabaseDate(_selectedDate!);
    final updatedTime = supabaseTime(_selectedTime!);
    final message = _messageController.text.trim();

    if (UserSession.accessToken == null || UserSession.userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in again.')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final res = await http.patch(
        Uri.parse(
          '$supabaseUrl/rest/v1/viewings?id=eq.${widget.id}'
          '&renter_id=eq.${UserSession.userId}&status=eq.Pending',
        ),
        headers: {
          'apikey': supabasePublishableKey,
          'Authorization': 'Bearer ${UserSession.accessToken}',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'viewing_date': updatedDate,
          'viewing_time': updatedTime,
          'message': message,
        }),
      );

      if (!mounted) return;

      final rows = res.statusCode == 200 ? jsonDecode(res.body) : null;
      setState(() {
        _isSaving = false;
      });
      if (rows is List && rows.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viewing updated successfully.')),
        );
        Navigator.pop(context, true);
      } else if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(pendingViewingModificationMessage)),
        );
      } else {
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
                        hintText:
                            'Share anything the property manager should know',
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
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
