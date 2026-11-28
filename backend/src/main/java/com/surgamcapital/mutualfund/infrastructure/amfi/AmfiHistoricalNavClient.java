package com.surgamcapital.mutualfund.infrastructure.amfi;

import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

@Component
public class AmfiHistoricalNavClient {
    private static final DateTimeFormatter DATE =
            DateTimeFormatter.ofPattern("dd-MMM-uuuu", Locale.ENGLISH);
    private final AmfiHttpClientSupport http;

    public AmfiHistoricalNavClient(AmfiHttpClientSupport http) {
        this.http = http;
    }

    public String fetch(AmfiReportType type, LocalDate from, LocalDate to) {
        if (type == null || from == null || to == null || from.isAfter(to)) {
            throw new IllegalArgumentException("Invalid AMFI historical report request.");
        }
        return http.getText(client -> client.get()
                .uri(builder -> builder.path("/DownloadNAVHistoryReport_Po.aspx")
                        .queryParam("tp", type.downloadType())
                        .queryParam("frmdt", DATE.format(from))
                        .queryParam("todt", DATE.format(to))
                        .build())
                .retrieve()
                .toEntity(String.class));
    }
}
