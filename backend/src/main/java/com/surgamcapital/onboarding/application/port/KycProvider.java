package com.surgamcapital.onboarding.application.port;

public interface KycProvider {
    KycResult checkExisting(String pan);

    record KycResult(String providerStatus, String providerReference) {}
}
