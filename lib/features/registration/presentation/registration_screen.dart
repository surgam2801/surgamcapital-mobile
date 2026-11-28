import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_shell.dart';
import '../../authentication/data/authentication_providers.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _email.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authenticationRepositoryProvider)
          .register(
            username: _username.text.trim(),
            password: _password.text,
            email: _email.text.trim(),
            mobileNumber: _mobile.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. Continue by signing in.'),
        ),
      );
      context.go(AppRoutes.login);
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to create your account. Try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    return AppShell(
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
              SizedBox(height: isMobile ? 18 : 24),
              const AppPageHeader(
                eyebrow: 'Secure account access',
                title: 'Create your investor account',
                subtitle:
                    'Registration begins a guided onboarding process for identity and KYC verification.',
              ),
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: Validators.requiredUsername,
              ),
              SizedBox(height: isMobile ? 10 : 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value != null &&
                        RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(value.trim())
                    ? null
                    : 'Enter a valid email address',
              ),
              SizedBox(height: isMobile ? 10 : 12),
              TextFormField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  hintText: '+919876543210',
                ),
                validator: (value) =>
                    value != null &&
                        RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(value.trim())
                    ? null
                    : 'Use international format, for example +919876543210',
              ),
              SizedBox(height: isMobile ? 10 : 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  helperText: 'Use at least 12 characters.',
                ),
                validator: (value) => value != null && value.length >= 12
                    ? null
                    : 'Password must be at least 12 characters',
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happens next',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: isMobile ? 10 : 12),
                    Text('1. Account details'),
                    SizedBox(height: isMobile ? 5 : 6),
                    Text('2. Identity and KYC verification'),
                    SizedBox(height: isMobile ? 5 : 6),
                    Text('3. Nominee and investment profile setup'),
                    SizedBox(height: isMobile ? 10 : 12),
                    Text(
                      'No PAN, Aadhaar, bank or other sensitive identity details are collected in Phase 1.',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 18 : 24),
              if (_error != null) ...[
                SizedBox(height: isMobile ? 10 : 12),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              SizedBox(height: isMobile ? 12 : 16),
              PrimaryButton(
                label: 'Create Account',
                loading: _loading,
                onPressed: _register,
              ),
              SizedBox(height: isMobile ? 10 : 12),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Return to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
