package com.surgamcapital.auth.presentation.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank @Size(min = 3, max = 40) @Pattern(regexp = "^[a-zA-Z0-9._-]+$") String username,
        @NotBlank @Size(min = 12, max = 128) String password,
        @NotBlank @Email @Size(max = 254) String email,
        @NotBlank @Pattern(regexp = "^\\+[1-9][0-9]{7,14}$") String mobileNumber) {
    @Override
    public String toString() {
        return "RegisterRequest[username=" + username + ", password=[REDACTED], email=[REDACTED], mobileNumber=[REDACTED]]";
    }
}
