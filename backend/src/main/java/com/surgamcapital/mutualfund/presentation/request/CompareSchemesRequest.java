package com.surgamcapital.mutualfund.presentation.request;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

public record CompareSchemesRequest(
        @NotEmpty @Size(max = 4) List<UUID> schemeIds) {}
