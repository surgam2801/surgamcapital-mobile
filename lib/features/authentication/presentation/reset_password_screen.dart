import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_brand.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_shell.dart';
import '../data/authentication_repository.dart';
import '../data/authentication_providers.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.challenge});

  final AuthChallenge? challenge;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _otp.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final challenge = widget.challenge;
    if (challenge == null) {
      setState(() => _error = 'Reset request is missing. Please try again.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authenticationRepositoryProvider)
          .resetPassword(
            challengeId: challenge.challengeId,
            otp: _otp.text,
            newPassword: _password.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Sign in to continue.')),
      );
      context.go(AppRoutes.login);
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to reset your password.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.login),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AppPanel(
              padding: 28,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppBrand(),
                    SizedBox(height: isMobile ? 22 : 28),
                    Text(
                      'Choose a new password',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    const Text(
                      'Enter the six-digit reset code sent to your registered mobile and set a new password.',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                    SizedBox(height: isMobile ? 18 : 24),
                    TextFormField(
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Reset code',
                        counterText: '',
                      ),
                      validator: Validators.otp,
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New password',
                        helperText: 'Use at least 12 characters.',
                      ),
                      validator: (value) => value != null && value.length >= 12
                          ? null
                          : 'Password must be at least 12 characters',
                    ),
                    if (_error != null) ...[
                      SizedBox(height: isMobile ? 10 : 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                    SizedBox(height: isMobile ? 12 : 16),
                    PrimaryButton(
                      label: 'Update Password',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
