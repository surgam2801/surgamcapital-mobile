package com.surgamcapital.mutualfund.infrastructure.amfi;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class AmfiNavScheduler {
    private static final Logger LOGGER =
            LoggerFactory.getLogger(AmfiNavScheduler.class);
    private final AmfiDataSyncService sync;

    public AmfiNavScheduler(AmfiDataSyncService sync) {
        this.sync = sync;
    }

    @Scheduled(cron = "${surgam.mutual-fund.amfi.sync-cron:-}")
    public void synchronize() {
        try {
            sync.synchronizeLatest();
        } catch (RuntimeException exception) {
            LOGGER.error("Scheduled AMFI NAV synchronization failed.", exception);
        }
    }
}
