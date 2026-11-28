package com.surgamcapital.mutualfund.infrastructure.amfi;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.net.http.HttpClient;
import java.time.Duration;
import java.util.function.Function;

@Component
public class AmfiHttpClientSupport {
    private static final String AMFI_BASE_URL = "https://portal.amfiindia.com";
    private static final Logger LOGGER =
            LoggerFactory.getLogger(AmfiHttpClientSupport.class);
    private final RestClient client;
    private final int attempts;
    private final long initialBackoffMillis;

    public AmfiHttpClientSupport(
            RestClient.Builder builder,
            @Value("${surgam.mutual-fund.amfi.connect-timeout:PT5S}")
            Duration connectTimeout,
            @Value("${surgam.mutual-fund.amfi.read-timeout:PT45S}")
            Duration readTimeout,
            @Value("${surgam.mutual-fund.amfi.retry-attempts:4}") int attempts,
            @Value("${surgam.mutual-fund.amfi.retry-backoff:PT1S}")
            Duration initialBackoff) {
        if (attempts < 1 || attempts > 8 || initialBackoff.isNegative()) {
            throw new IllegalArgumentException("Invalid AMFI retry configuration.");
        }
        HttpClient httpClient = HttpClient.newBuilder()
                .connectTimeout(connectTimeout).build();
        JdkClientHttpRequestFactory requestFactory =
                new JdkClientHttpRequestFactory(httpClient);
        requestFactory.setReadTimeout(readTimeout);
        this.client = builder.baseUrl(AMFI_BASE_URL)
                .requestFactory(requestFactory)
                .defaultHeader("Accept", MediaType.TEXT_PLAIN_VALUE)
                .defaultHeader("User-Agent", "SurgamCapital-AMFI-DataClient/1.0")
                .build();
        this.attempts = attempts;
        this.initialBackoffMillis = initialBackoff.toMillis();
    }

    public String getText(Function<RestClient, ResponseEntity<String>> request) {
        long backoff = initialBackoffMillis;
        RuntimeException lastError = null;
        for (int attempt = 1; attempt <= attempts; attempt++) {
            try {
                var response = request.apply(client);
                if (!response.getStatusCode().is2xxSuccessful()) {
                    throw new IllegalStateException(
                            "AMFI returned HTTP " + response.getStatusCode().value() + ".");
                }
                String body = response.getBody();
                MediaType contentType = response.getHeaders().getContentType();
                if (body == null || body.isBlank() || body.length() < 64) {
                    throw new IllegalStateException("AMFI returned an empty or truncated report.");
                }
                if (contentType != null && !contentType.isCompatibleWith(MediaType.TEXT_PLAIN)
                        && !contentType.isCompatibleWith(MediaType.TEXT_HTML)
                        && !contentType.isCompatibleWith(MediaType.APPLICATION_OCTET_STREAM)) {
                    throw new IllegalStateException("AMFI returned an unexpected content type.");
                }
                return body;
            } catch (RestClientException exception) {
                if (exception instanceof HttpStatusCodeException status
                        && status.getStatusCode().is4xxClientError()
                        && status.getStatusCode().value() != 408
                        && status.getStatusCode().value() != 429) {
                    throw new IllegalStateException(
                            "AMFI rejected the report request with HTTP "
                                    + status.getStatusCode().value(), exception);
                }
                lastError = exception;
            } catch (IllegalStateException exception) {
                lastError = exception;
            }
            if (attempt < attempts) {
                LOGGER.warn("AMFI request failed on attempt {}/{}; retrying.",
                        attempt, attempts);
                sleep(backoff);
                backoff = Math.min(backoff * 2, Duration.ofMinutes(1).toMillis());
            }
        }
        throw new IllegalStateException("AMFI source is unavailable after retries.",
                lastError);
    }

    private void sleep(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Interrupted while waiting to retry AMFI.", exception);
        }
    }
}
