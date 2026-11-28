import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_brand.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_shell.dart';
import '../application/auth_state.dart';
import '../data/authentication_repository.dart';
import '../data/authentication_providers.dart';
import '../../../core/errors/app_exception.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.challenge});

  final AuthChallenge? challenge;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  Timer? _timer;
  late int _seconds;
  bool _loading = false;
  bool _resending = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _activeChallenge = widget.challenge;
    _seconds = _activeChallenge?.expiresInSeconds ?? 0;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (mounted) {
      setState(() => _seconds = _activeChallenge?.expiresInSeconds ?? 0);
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final challenge = _activeChallenge;
    if (challenge == null) {
      setState(
        () => _error = 'Login challenge is missing. Please sign in again.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authenticationRepositoryProvider)
          .verifyOtp(challengeId: challenge.challengeId, otp: _otp.text);
      if (!mounted) return;
      ref.read(authenticatedProvider.notifier).authenticated();
      context.go(AppRoutes.portfolio);
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'The OTP could not be verified.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    final challenge = _activeChallenge;
    if (_seconds > 0 || challenge == null) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      final renewed = await ref
          .read(authenticationRepositoryProvider)
          .resendOtp(challengeId: challenge.challengeId);
      if (!mounted) return;
      setState(() {
        _resending = false;
        _activeChallenge = renewed;
      });
      _startTimer();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _resending = false;
        _error = error is AppException
            ? error.message
            : 'Unable to resend OTP.';
      });
    }
  }

  AuthChallenge? _activeChallenge;

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
                      'Verify your identity',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    Text(
                      _activeChallenge == null
                          ? 'Your login challenge is missing. Return to login and try again.'
                          : 'Enter the six-digit verification code sent to ${_activeChallenge!.maskedDestination}.',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                    SizedBox(height: isMobile ? 18 : 24),
                    TextFormField(
                      key: const Key('otp-field'),
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        letterSpacing: 10,
                        fontWeight: FontWeight.w800,
                        fontSize: isMobile ? 18 : 20,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Six-digit OTP',
                        counterText: '',
                      ),
                      validator: Validators.otp,
                    ),
                    if (_error != null) ...[
                      SizedBox(height: isMobile ? 6 : 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                    SizedBox(height: isMobile ? 12 : 16),
                    PrimaryButton(
                      label: 'Verify',
                      loading: _loading,
                      onPressed: _verify,
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Center(
                      child: _seconds > 0
                          ? Text('Resend available in $_seconds seconds')
                          : TextButton(
                              onPressed: _resending ? null : _resend,
                              child: _resending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Resend OTP'),
                            ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text('Back to login'),
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
