package com.surgamcapital.auth.infrastructure.otp;

import com.surgamcapital.auth.application.port.OtpDeliveryProvider;
import com.surgamcapital.shared.exception.AuthException;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

@Component
@Profile("!local & !test")
public class UnavailableOtpDeliveryProvider implements OtpDeliveryProvider {
    @Override
    public void deliver(String destination, String otp) {
        throw new AuthException(HttpStatus.SERVICE_UNAVAILABLE, "OTP_DELIVERY_UNAVAILABLE",
                "OTP delivery is not configured.");
    }
}
