package com.surgamcapital.onboarding.infrastructure.provider;

import com.surgamcapital.onboarding.application.port.KycProvider;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
@Profile({"local", "test"})
public class MockKycProvider implements KycProvider {
    @Override
    public KycResult checkExisting(String pan) {
        return new KycResult("UNKNOWN", "mock-kyc-" + UUID.randomUUID());
    }
}
