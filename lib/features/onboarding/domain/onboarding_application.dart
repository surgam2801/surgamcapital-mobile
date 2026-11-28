class OnboardingApplication {
  const OnboardingApplication({
    required this.applicationId,
    required this.applicationReference,
    required this.onboardingStatus,
    required this.kycWorkflowStatus,
    required this.kycProviderStatus,
    required this.panVerificationStatus,
    required this.maskedPan,
    required this.personal,
    required this.address,
    required this.taxResidency,
    required this.submittedAt,
    required this.updatedAt,
  });

  final String applicationId;
  final String applicationReference;
  final String onboardingStatus;
  final String kycWorkflowStatus;
  final String kycProviderStatus;
  final String panVerificationStatus;
  final String? maskedPan;
  final Map<String, dynamic> personal;
  final Map<String, dynamic> address;
  final Map<String, dynamic> taxResidency;
  final DateTime? submittedAt;
  final DateTime updatedAt;

  factory OnboardingApplication.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> mapField(String key) {
      final value = json[key];
      return value is Map<String, dynamic> ? value : const <String, dynamic>{};
    }

    return OnboardingApplication(
      applicationId: json['applicationId'] as String,
      applicationReference: json['applicationReference'] as String,
      onboardingStatus: json['onboardingStatus'] as String,
      kycWorkflowStatus: json['kycWorkflowStatus'] as String,
      kycProviderStatus: json['kycProviderStatus'] as String,
      panVerificationStatus: json['panVerificationStatus'] as String,
      maskedPan: json['maskedPan'] as String?,
      personal: mapField('personal'),
      address: mapField('address'),
      taxResidency: mapField('taxResidency'),
      submittedAt: json['submittedAt'] == null
          ? null
          : DateTime.parse(json['submittedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
