package com.surgamcapital.auth.application.port;

public interface OtpDeliveryProvider {
    void deliver(String destination, String otp);
}
