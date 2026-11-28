package com.surgamcapital.onboarding.infrastructure.provider;

import com.surgamcapital.onboarding.application.port.PanVerificationProvider;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile("!local & !test")
public class UnavailablePanVerificationProvider implements PanVerificationProvider {
    @Override
    public PanResult verify(String pan) {
        throw new IllegalStateException("An authorised PAN verification provider is not configured.");
    }
}
