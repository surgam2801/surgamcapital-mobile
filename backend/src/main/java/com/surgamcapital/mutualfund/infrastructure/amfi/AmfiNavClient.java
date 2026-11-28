package com.surgamcapital.mutualfund.infrastructure.amfi;

import org.springframework.stereotype.Component;

@Component
public class AmfiNavClient {
    private final AmfiHttpClientSupport http;

    public AmfiNavClient(AmfiHttpClientSupport http) {
        this.http = http;
    }

    public String fetchLatestReport() {
        return http.getText(client -> client.get()
                .uri("/spages/NAVAll.txt")
                .retrieve()
                .toEntity(String.class));
    }
}
