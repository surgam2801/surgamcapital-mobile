package com.surgamcapital.shared.security;

import com.surgamcapital.auth.infrastructure.persistence.UserSessionRepository;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.oauth2.server.resource.InvalidBearerTokenException;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

@Component
public class ActiveSessionJwtConverter
        implements org.springframework.core.convert.converter.Converter<Jwt, AbstractAuthenticationToken> {
    private final UserSessionRepository sessions;

    public ActiveSessionJwtConverter(UserSessionRepository sessions) {
        this.sessions = sessions;
    }

    @Override
    public AbstractAuthenticationToken convert(Jwt jwt) {
        try {
            UUID sessionId = UUID.fromString(jwt.getClaimAsString("sid"));
            boolean active = sessions.findById(sessionId).map(session -> session.isActive()
                    && session.getUserId().toString().equals(jwt.getSubject())).orElse(false);
            if (!active) throw new InvalidBearerTokenException("The session is inactive.");
            return new JwtAuthenticationToken(jwt, List.of(),
                    jwt.getSubject());
        } catch (IllegalArgumentException exception) {
            throw new InvalidBearerTokenException("The token is invalid.");
        }
    }
}
