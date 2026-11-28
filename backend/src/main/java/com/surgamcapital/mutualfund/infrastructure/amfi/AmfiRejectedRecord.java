package com.surgamcapital.mutualfund.infrastructure.amfi;

public record AmfiRejectedRecord(int lineNumber, String rawRecord, String reason) {}
