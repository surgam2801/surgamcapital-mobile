package com.surgamcapital.onboarding.infrastructure.provider;

import com.surgamcapital.onboarding.application.port.KycProvider;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile("!local & !test")
public class UnavailableKycProvider implements KycProvider {
    @Override
    public KycResult checkExisting(String pan) {
        throw new IllegalStateException("An authorised KRA/CKYC provider is not configured.");
    }
}
