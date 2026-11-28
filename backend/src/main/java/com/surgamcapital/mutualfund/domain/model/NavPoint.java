package com.surgamcapital.mutualfund.domain.model;

import java.math.BigDecimal;
import java.time.LocalDate;

public record NavPoint(LocalDate date, BigDecimal nav) {}
