import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_brand.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_shell.dart';
import '../data/authentication_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _submitted = false;
    });
    try {
      final challenge = await ref
          .read(authenticationRepositoryProvider)
          .forgotPassword(identifier: _identifier.text.trim());
      if (!mounted) return;
      setState(() => _submitted = true);
      context.push(AppRoutes.resetPassword, extra: challenge);
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
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
                      'Reset your password',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    const Text(
                      'Enter your username, registered mobile number or email.',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                    SizedBox(height: isMobile ? 18 : 24),
                    TextFormField(
                      controller: _identifier,
                      decoration: const InputDecoration(
                        labelText: 'Username or registered mobile/email',
                      ),
                      validator: Validators.requiredUsername,
                    ),
                    if (_submitted) ...[
                      SizedBox(height: isMobile ? 10 : 12),
                      const Text(
                        'If the account exists, password reset instructions have been sent.',
                        style: TextStyle(color: AppColors.success),
                      ),
                    ],
                    SizedBox(height: isMobile ? 12 : 16),
                    PrimaryButton(
                      label: 'Continue',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    SizedBox(height: isMobile ? 10 : 12),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text('Back to Login'),
                      ),
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
