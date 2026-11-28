package com.surgamcapital.mutualfund.infrastructure.amfi;

public enum AmfiReportType {
    OPEN_ENDED(1, "OPEN_ENDED"),
    CLOSE_ENDED(2, "CLOSE_ENDED"),
    INTERVAL(3, "INTERVAL");

    private final int downloadType;
    private final String schemeType;

    AmfiReportType(int downloadType, String schemeType) {
        this.downloadType = downloadType;
        this.schemeType = schemeType;
    }

    public int downloadType() {
        return downloadType;
    }

    public String schemeType() {
        return schemeType;
    }

    public String latestReportType() {
        return "LATEST_" + schemeType;
    }

    public static AmfiReportType fromDownloadType(int downloadType) {
        for (AmfiReportType type : values()) {
            if (type.downloadType == downloadType) return type;
        }
        throw new IllegalArgumentException("Unsupported AMFI historical report type.");
    }
}
