import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_financial_widgets.dart';
import '../../../core/widgets/app_shell.dart';
import '../data/onboarding_providers.dart';
import '../domain/onboarding_application.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _dateOfBirth = TextEditingController();
  final _pan = TextEditingController();
  final _addressLine1 = TextEditingController();
  final _addressLine2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postalCode = TextEditingController();
  final _countryCode = TextEditingController(text: 'IN');
  final _taxCountry = TextEditingController(text: 'IN');
  OnboardingApplication? _application;
  String _gender = 'PREFER_NOT_TO_SAY';
  bool _taxResidentInIndia = true;
  bool _taxConfirmed = false;
  bool _loading = false;
  String? _error;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _dateOfBirth.dispose();
    _pan.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _city.dispose();
    _state.dispose();
    _postalCode.dispose();
    _countryCode.dispose();
    _taxCountry.dispose();
    super.dispose();
  }

  Future<void> _loadApplication() async {
    setState(() => _loading = true);
    try {
      final application = await ref
          .read(onboardingRepositoryProvider)
          .startOrResume();
      if (!mounted) return;
      _application = application;
      _firstName.text = _value(application.personal, 'firstName');
      _middleName.text = _value(application.personal, 'middleName');
      _lastName.text = _value(application.personal, 'lastName');
      _dateOfBirth.text = _value(application.personal, 'dateOfBirth');
      _gender = _value(application.personal, 'gender', 'PREFER_NOT_TO_SAY');
      _addressLine1.text = _value(application.address, 'addressLine1');
      _addressLine2.text = _value(application.address, 'addressLine2');
      _city.text = _value(application.address, 'city');
      _state.text = _value(application.address, 'state');
      _postalCode.text = _value(application.address, 'postalCode');
      _countryCode.text = _value(application.address, 'countryCode', 'IN');
      _taxResidentInIndia =
          application.taxResidency['taxResidentInIndia'] as bool? ?? true;
      _taxCountry.text = _value(application.taxResidency, 'countryCode', 'IN');
      _taxConfirmed = application.taxResidency['declarationVersion'] is String;
      if (application.onboardingStatus == 'PENDING_VERIFICATION' ||
          application.onboardingStatus == 'APPROVED' ||
          application.onboardingStatus == 'PENDING_MANUAL_REVIEW') {
        _step = 6;
      } else if (_hasPersonal(application) &&
          _hasAddress(application) &&
          _hasTax(application)) {
        _step = 6;
      } else if (_hasAddress(application)) {
        _step = 5;
      } else if (application.maskedPan != null) {
        _step = 3;
      } else if (_hasPersonal(application)) {
        _step = 2;
      }
      setState(() => _loading = false);
    } on AppException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load your onboarding application.';
          _loading = false;
        });
      }
    }
  }

  String _value(Map<String, dynamic> map, String key, [String fallback = '']) =>
      map[key] is String ? map[key] as String : fallback;

  bool _hasPersonal(OnboardingApplication application) =>
      application.personal['firstName'] is String &&
      application.personal['lastName'] is String;
  bool _hasAddress(OnboardingApplication application) =>
      application.address['addressLine1'] is String;
  bool _hasTax(OnboardingApplication application) =>
      application.taxResidency['taxResidentInIndia'] is bool;

  Future<void> _run(
    Future<OnboardingApplication> Function() action, {
    int? nextStep,
  }) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await action();
      if (!mounted) return;
      setState(() {
        _application = result;
        _loading = false;
        if (nextStep != null) _step = nextStep;
      });
    } on AppException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'We could not save that step. Please retry.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _savePersonal() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final application = _application!;
    await _run(
      () => ref
          .read(onboardingRepositoryProvider)
          .savePersonal(
            application: application,
            firstName: _firstName.text.trim(),
            middleName: _middleName.text.trim(),
            lastName: _lastName.text.trim(),
            dateOfBirth: _dateOfBirth.text,
            gender: _gender,
          ),
      nextStep: 2,
    );
  }

  Future<void> _verifyPan() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final application = _application!;
    await _run(
      () => ref
          .read(onboardingRepositoryProvider)
          .verifyPan(application: application, pan: _pan.text.trim()),
      nextStep: 3,
    );
    _pan.clear();
  }

  Future<void> _saveAddress() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final application = _application!;
    await _run(
      () => ref
          .read(onboardingRepositoryProvider)
          .saveAddress(
            application: application,
            addressLine1: _addressLine1.text.trim(),
            addressLine2: _addressLine2.text.trim(),
            city: _city.text.trim(),
            state: _state.text.trim(),
            postalCode: _postalCode.text.trim(),
            countryCode: _countryCode.text.trim().toUpperCase(),
          ),
      nextStep: 5,
    );
  }

  Future<void> _saveTaxResidency() async {
    final application = _application!;
    await _run(
      () => ref
          .read(onboardingRepositoryProvider)
          .saveTaxResidency(
            application: application,
            taxResidentInIndia: _taxResidentInIndia,
            countryCode: _taxCountry.text.trim().toUpperCase(),
          ),
      nextStep: 6,
    );
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: DateTime(1990),
    );
    if (selected != null) {
      _dateOfBirth.text =
          '${selected.year.toString().padLeft(4, '0')}-'
          '${selected.month.toString().padLeft(2, '0')}-'
          '${selected.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final application = _application;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
        title: const Text('Investor onboarding'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _loading && application == null
              ? const Center(child: CircularProgressIndicator())
              : application == null
              ? _loadError()
              : _content(application),
        ),
      ),
    );
  }

  Widget _loadError() => Padding(
    padding: EdgeInsets.all(
      AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width) ? 18 : 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_error ?? 'Unable to load onboarding.'),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: _loadApplication, child: const Text('Retry')),
      ],
    ),
  );

  Widget _content(OnboardingApplication application) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    final completed =
        application.onboardingStatus == 'PENDING_VERIFICATION' ||
        application.onboardingStatus == 'PENDING_MANUAL_REVIEW' ||
        application.onboardingStatus == 'APPROVED';
    final activeStep = switch (_step) {
      0 => _introduction(application),
      1 => _personalForm(),
      2 => _panStep(application),
      3 => _kycStep(application),
      4 => _addressForm(),
      5 => _taxForm(),
      _ => _review(application),
    };
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 20,
        isMobile ? 8 : 12,
        isMobile ? 16 : 20,
        isMobile ? 18 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeader(
            eyebrow: 'Investor onboarding',
            title: completed
                ? 'Application tracking'
                : _step == 0
                ? 'A guided setup, at your pace'
                : 'Step $_step of 6',
            subtitle: completed
                ? 'Review your saved application status and reference.'
                : 'Your progress is saved as you move through each step.',
          ),
          if (_step == 0 && !completed) ...[
            const AppSpotlightPanel(
              compact: true,
              eyebrow: 'A few guided steps',
              title: 'Start with the essentials',
              description:
                  'Add your details, verify your PAN and review your application before submitting.',
              icon: Icons.verified_user_outlined,
            ),
            SizedBox(height: isMobile ? 10 : 12),
          ],
          if (_step > 0 || completed) ...[
            AppProgressSteps(
              labels: const [
                'Personal',
                'PAN',
                'KYC',
                'Address',
                'Tax',
                'Review',
              ],
              currentStep: _step.clamp(1, 6).toInt(),
              completed: completed,
            ),
            SizedBox(height: isMobile ? 8 : 10),
          ],
          if (_step == 0 && !completed) ...[
            const AppStatusBadge(
              label: 'YOUR PROGRESS IS SAVED AS YOU GO',
              icon: Icons.bookmark_added_outlined,
              tone: AppStatusTone.info,
            ),
            SizedBox(height: isMobile ? 10 : 12),
          ],
          if (_error != null) ...[
            _notice(_error!, AppColors.error),
            SizedBox(height: isMobile ? 10 : 12),
          ],
          if (_step > 0 && !completed)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _loading
                    ? null
                    : () => setState(() => _step = (_step - 1).clamp(0, 6)),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous step'),
              ),
            ),
          AppPanel(padding: 14, child: activeStep),
        ],
      ),
    );
  }

  Widget _introduction(OnboardingApplication application) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Let’s set up your investor profile',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      const Text(
        'You can save your progress and come back later. Verification status '
        'comes from authorised providers and is never assumed from a form entry.',
      ),
      const SizedBox(height: 20),
      const _StepSummary(
        title: 'Personal information',
        subtitle: 'Basic identity details',
      ),
      const _StepSummary(
        title: 'PAN and existing KYC',
        subtitle: 'Provider checks; PAN format alone is not verification',
      ),
      const _StepSummary(
        title: 'Address and tax residency',
        subtitle: 'Save your declared information',
      ),
      const _StepSummary(
        title: 'Review and submit',
        subtitle: 'Submit for verification and track progress',
      ),
      const SizedBox(height: 20),
      PrimaryButton(
        label: _hasPersonal(application)
            ? 'Continue onboarding'
            : 'Start onboarding',
        loading: _loading,
        onPressed: () => setState(() => _step = _nextIncomplete(application)),
      ),
      const SizedBox(height: 8),
      Text('Application reference: ${application.applicationReference}'),
    ],
  );

  int _nextIncomplete(OnboardingApplication application) {
    if (!_hasPersonal(application)) return 1;
    if (application.maskedPan == null) return 2;
    if (application.kycProviderStatus == 'UNKNOWN' &&
        application.kycWorkflowStatus == 'NOT_STARTED') {
      return 3;
    }
    if (!_hasAddress(application)) return 4;
    if (!_hasTax(application)) return 5;
    return 6;
  }

  Widget _personalForm() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'Personal information',
          'Enter your name as it appears on your identity documents.',
        ),
        _field(_firstName, 'First name', required: true),
        _field(_middleName, 'Middle name'),
        _field(_lastName, 'Last name', required: true),
        TextFormField(
          controller: _dateOfBirth,
          readOnly: true,
          onTap: _chooseDate,
          decoration: const InputDecoration(
            labelText: 'Date of birth',
            hintText: 'YYYY-MM-DD',
            suffixIcon: Icon(Icons.calendar_today_outlined),
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Date of birth is required'
              : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _gender,
          decoration: const InputDecoration(labelText: 'Gender'),
          items: const [
            DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
            DropdownMenuItem(value: 'MALE', child: Text('Male')),
            DropdownMenuItem(value: 'OTHER', child: Text('Other')),
            DropdownMenuItem(
              value: 'PREFER_NOT_TO_SAY',
              child: Text('Prefer not to say'),
            ),
          ],
          onChanged: (value) => setState(() => _gender = value!),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Save and continue',
          loading: _loading,
          onPressed: _savePersonal,
        ),
      ],
    ),
  );

  Widget _panStep(OnboardingApplication application) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'PAN verification',
          'Your PAN is encrypted on the server and only a masked value is shown here.',
        ),
        TextFormField(
          controller: _pan,
          textCapitalization: TextCapitalization.characters,
          maxLength: 10,
          decoration: const InputDecoration(labelText: 'PAN'),
          validator: (value) {
            if (application.maskedPan != null) return null;
            if (value == null ||
                !RegExp(
                  r'^[A-Za-z]{5}[0-9]{4}[A-Za-z]$',
                ).hasMatch(value.trim())) {
              return 'Enter a valid PAN format';
            }
            return null;
          },
        ),
        if (application.maskedPan != null) ...[
          Text('Saved PAN: ${application.maskedPan}'),
          const SizedBox(height: 8),
          _status(
            application.panVerificationStatus,
            'PAN provider status: ${application.panVerificationStatus}. A valid format is not proof of verification.',
          ),
        ],
        const SizedBox(height: 12),
        PrimaryButton(
          label: application.maskedPan == null ? 'Verify PAN' : 'Continue',
          loading: _loading,
          onPressed: application.maskedPan == null
              ? _verifyPan
              : () => setState(() => _step = 3),
        ),
      ],
    ),
  );

  Widget _kycStep(OnboardingApplication application) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(
        'Existing KYC status',
        'We check for an existing record before asking you to repeat KYC.',
      ),
      _status(
        application.kycProviderStatus,
        'Provider-reported status: ${application.kycProviderStatus}. This is separate from Surgam’s KYC workflow status (${application.kycWorkflowStatus}).',
      ),
      if (application.kycProviderStatus == 'UNKNOWN') ...[
        const SizedBox(height: 12),
        const Text(
          'The local mock provider reports UNKNOWN. No real KRA/CKYC lookup is connected.',
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _loading
              ? null
              : () => _run(
                  () => ref
                      .read(onboardingRepositoryProvider)
                      .checkKyc(application),
                ),
          child: const Text('Check existing KYC status'),
        ),
      ],
      const SizedBox(height: 20),
      PrimaryButton(
        label: 'Continue to address',
        loading: _loading,
        onPressed: () => setState(() => _step = 4),
      ),
    ],
  );

  Widget _addressForm() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'Residential address',
          'Your details are saved securely with your application.',
        ),
        _field(_addressLine1, 'Address line 1', required: true),
        _field(_addressLine2, 'Address line 2'),
        _field(_city, 'City', required: true),
        _field(_state, 'State', required: true),
        TextFormField(
          controller: _postalCode,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'PIN code'),
          validator: (value) =>
              value == null || !RegExp(r'^[0-9]{6}$').hasMatch(value)
              ? 'Enter a six-digit PIN code'
              : null,
        ),
        TextFormField(
          controller: _countryCode,
          maxLength: 2,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Country code'),
          validator: (value) =>
              value == null || !RegExp(r'^[A-Za-z]{2}$').hasMatch(value)
              ? 'Enter a two-letter country code'
              : null,
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Save and continue',
          loading: _loading,
          onPressed: _saveAddress,
        ),
      ],
    ),
  );

  Widget _taxForm() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'Tax residency',
          'Tax-residency wording and required declarations need compliance approval before production.',
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('I am an Indian tax resident'),
          value: _taxResidentInIndia,
          onChanged: (value) => setState(() {
            _taxResidentInIndia = value;
            if (value) _taxCountry.text = 'IN';
          }),
        ),
        TextFormField(
          controller: _taxCountry,
          maxLength: 2,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Country of tax residence (2-letter code)',
          ),
          validator: (value) =>
              value == null || !RegExp(r'^[A-Za-z]{2}$').hasMatch(value)
              ? 'Enter a two-letter country code'
              : null,
        ),
        const SizedBox(height: 8),
        const Text(
          'I confirm that this tax residency declaration is accurate to the best of my knowledge.',
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _taxConfirmed,
          onChanged: (value) => setState(() => _taxConfirmed = value ?? false),
          title: const Text('I confirm this declaration'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Save and review',
          loading: _loading,
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            if (!_taxConfirmed) {
              setState(
                () => _error =
                    'Confirm the tax residency declaration to continue.',
              );
              return;
            }
            _saveTaxResidency();
          },
        ),
      ],
    ),
  );

  Widget _review(OnboardingApplication application) {
    final submitted = application.submittedAt != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          submitted ? 'Application tracking' : 'Review your application',
          submitted
              ? 'Your application was submitted for verification.'
              : 'Review the saved details before submitting.',
        ),
        _summaryCard('Application reference', application.applicationReference),
        _summaryCard('Onboarding status', application.onboardingStatus),
        _summaryCard(
          'PAN verification',
          '${application.panVerificationStatus}${application.maskedPan == null ? '' : ' · ${application.maskedPan}'}',
        ),
        _summaryCard('Provider-reported KYC', application.kycProviderStatus),
        _summaryCard('Surgam KYC workflow', application.kycWorkflowStatus),
        _summaryCard(
          'Personal information',
          '${_value(application.personal, 'firstName')} ${_value(application.personal, 'lastName')} · ${_value(application.personal, 'dateOfBirth')}',
        ),
        _summaryCard(
          'Address',
          '${_value(application.address, 'addressLine1')}, ${_value(application.address, 'city')} ${_value(application.address, 'postalCode')}',
        ),
        _summaryCard(
          'Tax residency',
          '${application.taxResidency['taxResidentInIndia'] == true ? 'India' : 'Other'} · ${_value(application.taxResidency, 'countryCode')}',
        ),
        _summaryCard(
          'Last updated',
          application.updatedAt.toLocal().toString().substring(0, 16),
        ),
        const SizedBox(height: 8),
        _notice(
          submitted
              ? 'Verification is not complete. This preview does not connect to KRA/CKYC or a PAN provider.'
              : 'Submitting starts verification; it does not mark your KYC or account as verified or active.',
          AppColors.warning,
        ),
        if (!submitted) ...[
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Submit for verification',
            loading: _loading,
            onPressed: () => _run(
              () => ref.read(onboardingRepositoryProvider).submit(application),
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _loadApplication,
            child: const Text('Refresh status'),
          ),
        ],
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    validator: required
        ? (value) => value == null || value.trim().isEmpty
              ? '$label is required'
              : null
        : null,
  );

  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: AppColors.secondaryText)),
      ],
    ),
  );

  Widget _status(String status, String description) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.replaceAll('_', ' '),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _summaryCard(String title, String value) => Card(
    child: ListTile(
      title: Text(title, style: Theme.of(context).textTheme.labelLarge),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(value.trim().isEmpty ? 'Not provided' : value),
      ),
    ),
  );

  Widget _notice(String text, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: TextStyle(color: color)),
  );
}

class _StepSummary extends StatelessWidget {
  const _StepSummary({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.check_circle_outline, color: AppColors.teal),
    title: Text(title),
    subtitle: Text(subtitle),
  );
}
