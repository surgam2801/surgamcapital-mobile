package com.surgamcapital.auth.infrastructure.otp;

import com.surgamcapital.auth.application.port.OtpDeliveryProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile({"local", "test"})
public class LocalMockOtpDeliveryProvider implements OtpDeliveryProvider {
    private static final Logger log = LoggerFactory.getLogger(LocalMockOtpDeliveryProvider.class);

    @Override
    public void deliver(String destination, String otp) {
        log.info("LOCAL MOCK OTP delivery to masked destination {}. OTP is for local/test use only: {}",
                mask(destination), otp);
    }

    private String mask(String destination) {
        if (destination.length() < 4) return "****";
        return "******" + destination.substring(destination.length() - 4);
    }
}
