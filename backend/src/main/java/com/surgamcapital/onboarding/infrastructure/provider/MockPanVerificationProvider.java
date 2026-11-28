package com.surgamcapital.onboarding.infrastructure.provider;

import com.surgamcapital.onboarding.application.port.PanVerificationProvider;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
@Profile({"local", "test"})
public class MockPanVerificationProvider implements PanVerificationProvider {
    @Override
    public PanResult verify(String pan) {
        return new PanResult("PENDING", "mock-pan-" + UUID.randomUUID());
    }
}
