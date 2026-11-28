package com.surgamcapital.mutualfund.infrastructure.provider;

import com.surgamcapital.mutualfund.application.port.MutualFundDataProvider;
import com.surgamcapital.mutualfund.application.service.MutualFundSyncService;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

@Configuration
@Profile({"local", "test"})
public class MockMutualFundSeedConfiguration {
    @Bean
    @ConditionalOnProperty(name = "surgam.mutual-fund.seed-mock-data", havingValue = "true")
    ApplicationRunner seedMockMutualFundData(MutualFundSyncService sync,
                                             MutualFundDataProvider provider) {
        return args -> {
            if (!provider.providerCode().equals("MOCK_DEMO")) {
                throw new IllegalStateException(
                        "Mock fixture seeding requires the MOCK_DEMO provider.");
            }
            sync.synchronize();
        };
    }
}
