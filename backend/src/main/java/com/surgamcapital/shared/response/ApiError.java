package com.surgamcapital.shared.response;

import java.time.Instant;

public record ApiError(boolean success, ErrorBody error, Instant timestamp) {
    public static ApiError of(String code, String message) {
        return new ApiError(false, new ErrorBody(code, message), Instant.now());
    }

    public record ErrorBody(String code, String message) {}
}
