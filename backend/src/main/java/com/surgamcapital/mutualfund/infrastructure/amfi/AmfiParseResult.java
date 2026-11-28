package com.surgamcapital.mutualfund.infrastructure.amfi;

import java.util.List;

public record AmfiParseResult(
        List<AmfiNavRecord> records,
        List<AmfiRejectedRecord> rejectedRecords) {
    public AmfiParseResult {
        records = List.copyOf(records);
        rejectedRecords = List.copyOf(rejectedRecords);
    }
}
