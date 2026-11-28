package com.surgamcapital.onboarding.application.port;

public interface PanVerificationProvider {
    PanResult verify(String pan);

    record PanResult(String status, String providerReference) {}
}
