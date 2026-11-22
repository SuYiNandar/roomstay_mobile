import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/roomstay_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _showTermsError = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    final fullName = value?.trim() ?? '';

    if (fullName.isEmpty) {
      return 'Full name is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email is required';
    }
    if (!email.contains('@')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must include an uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must include a lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must include a number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _toggleTerms() {
    setState(() {
      _agreedToTerms = !_agreedToTerms;
      if (_agreedToTerms) {
        _showTermsError = false;
      }
    });
  }

  Future<void> _register() async {
    if (_isLoading) return;
    setState(() {
      _showTermsError = false;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      setState(() {
        _showTermsError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (!isSupabaseConfigured) {
      _finishRegistrationError(
        'Supabase is not configured. Add your project URL and publishable key.',
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/auth/v1/signup'),
        headers: {
          'apikey': supabasePublishableKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'data': {'full_name': _fullNameController.text.trim()},
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final requiresEmailConfirmation =
            data is Map &&
            data['access_token'] == null &&
            data['session'] == null;

        if (requiresEmailConfirmation) {
          _finishRegistration(
            'Account created. Please check your email to confirm your account.',
          );
        } else {
          _finishRegistration('Account created successfully.');
        }
      } else {
        _finishRegistrationError(
          _readAuthError(
            response.body,
            'Unable to create your account. Please try again.',
          ),
        );
      }
    } catch (error) {
      _finishRegistrationError('Unable to connect. Please check your network.');
    }
  }

  void _finishRegistration(String message) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    Navigator.pop(context);
  }

  void _finishRegistrationError(String message) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _readAuthError(String body, String fallback) {
    try {
      final data = jsonDecode(body);

      if (data is Map) {
        final message =
            data['error_description'] ??
            data['msg'] ??
            data['message'] ??
            data['error'];

        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (error) {
      return fallback;
    }

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RoomStayLogo(compact: true),
                const SizedBox(height: 32),
                const Text('Create your account', style: AppTextStyles.h1),
                const SizedBox(height: 8),
                const Text(
                  'Sign up to find your next home and manage your rental journey.',
                  style: AppTextStyles.secondaryBody,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: _validateFullName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Minimum 8 characters\n'
                  'At least 1 uppercase letter\n'
                  'At least 1 lowercase letter\n'
                  'At least 1 number',
                  style: AppTextStyles.small,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      tooltip: _obscureConfirmPassword
                          ? 'Show password'
                          : 'Hide password',
                    ),
                  ),
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (value) {
                        _toggleTerms();
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _toggleTerms,
                        child: const Text(
                          'I agree to the Terms of Service and Privacy Policy.',
                          style: AppTextStyles.secondaryBody,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showTermsError)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      'Please accept the Terms of Service and Privacy Policy.',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign Up'),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: AppTextStyles.secondaryBody,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
