import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';
import '../data/user_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/roomstay_logo.dart';
import 'main_screen.dart';
import 'property_manager_main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'Renter';
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _login() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    UserSession.clear();
    setState(() {
      _isLoading = true;
    });

    if (!isSupabaseConfigured) {
      _showLoginError(
        'Supabase is not configured. Add your project URL and publishable key.',
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password'),
        headers: {
          'apikey': supabasePublishableKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! Map) {
          _showLoginError('Unable to read the login session.');
          return;
        }
        final user = data['user'];
        final accessToken = data['access_token'];

        if (accessToken is! String ||
            accessToken.isEmpty ||
            user is! Map ||
            user['id'] is! String ||
            user['id'].isEmpty) {
          _showLoginError('Unable to read the login session.');
          return;
        }

        UserSession.accessToken = accessToken;
        UserSession.refreshToken = data['refresh_token']?.toString();
        UserSession.userId = user['id'] as String;
        UserSession.email =
            user['email']?.toString() ?? _emailController.text.trim();

        await _fetchProfileAndOpenApp();
      } else {
        _showLoginError(
          _readAuthError(
            response.body,
            'Login failed. Please check your email and password.',
          ),
        );
      }
    } catch (error) {
      _showLoginError('Unable to connect. Please check your network.');
    }
  }

  Future<void> _fetchProfileAndOpenApp() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$supabaseUrl/rest/v1/profiles?id=eq.${UserSession.userId}&select=*',
        ),
        headers: {
          'apikey': supabasePublishableKey,
          'Authorization': 'Bearer ${UserSession.accessToken}',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          final profile = Map<String, dynamic>.from(data[0] as Map);
          UserSession.fullName = profile['full_name']?.toString();
          UserSession.email = profile['email']?.toString() ?? UserSession.email;
          final role = profile['role']?.toString().trim().toLowerCase() ?? '';
          UserSession.role = role;

          setState(() {
            _isLoading = false;
          });

          if (role == 'renter') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false,
            );
          } else if (UserSession.isPropertyManager) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const PropertyManagerMainScreen(),
              ),
              (route) => false,
            );
          } else {
            _showLoginError('This account role is not supported.');
          }
        } else {
          _showLoginError('Unable to load your profile.');
        }
      } else {
        _showLoginError('Unable to load your profile.');
      }
    } catch (error) {
      _showLoginError('Unable to connect. Please check your network.');
    }
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

  void _showLoginError(String message) {
    if (!mounted) return;
    UserSession.clear();

    setState(() {
      _isLoading = false;
    });

    _showMessage(message);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _showForgotPasswordMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset is coming soon.')),
    );
  }

  Widget _roleButton(String role) {
    final isSelected = _selectedRole == role;

    return Expanded(
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () {
                setState(() {
                  _selectedRole = role;
                });
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
          foregroundColor: isSelected ? Colors.white : AppColors.primary,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.coolBorder,
          ),
        ),
        child: Text(role),
      ),
    );
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
                const SizedBox(height: 36),
                const Text('Welcome back', style: AppTextStyles.h1),
                const SizedBox(height: 8),
                const Text(
                  'Log in to browse rooms, save favorites, and track your viewing requests.',
                  style: AppTextStyles.secondaryBody,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Login as',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _roleButton('Renter'),
                    const SizedBox(width: 10),
                    _roleButton('Property Manager'),
                  ],
                ),
                const SizedBox(height: 20),
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
                  textInputAction: TextInputAction.done,
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordMessage,
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'New to RoomStay?',
                      style: AppTextStyles.secondaryBody,
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _openRegister,
                      child: const Text('Create an account'),
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
