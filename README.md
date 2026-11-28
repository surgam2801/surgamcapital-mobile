# Surgam Capital

Flutter investor application and an in-progress Spring Boot backend. Public
landing and education remain unauthenticated. The backend is a modular
monolith under `backend/`; it implements authentication and an initial,
provider-neutral onboarding/KYC foundation. It does not implement investment,
portfolio, KYC provider integrations, or account activation.

## Flutter app

After sign-in, the app opens the Portfolio destination. In the local demo
preview, the investor, portfolio figures and advisor contact are fictional
sample data; live portfolio and profile details are not yet connected.

```bash
flutter pub get
flutter run
```

To launch the web app and open desktop plus phone-sized browser windows, run
this executable from the repository root:

```bash
./run-app
```

It uses the Flutter web-server target (no emulator), mock authentication, and
the bundled AMFI sample preview. The default local URL is `http://localhost:8083`.
The preview does not require the backend, PostgreSQL, or Redis. Build and
runtime logs remain visible in the launching terminal; `--no-dds` avoids the
Dart Development Service WebSocket startup failure that can leave the browser
page unloaded. The launcher stops rather than reuses an existing listener so
that it can show logs for the server it starts. Press `Ctrl+C` in the launching
terminal to stop it. Override the Flutter executable or port if needed with
`FLUTTER_BIN=/path/to/flutter` or `PORT=8084 ./run-app`. To start only the
server without opening browser windows, run `OPEN_WINDOWS=false ./run-app`.

The launcher also enables a visibly labeled, fictional portfolio preview with
`PORTFOLIO_DEMO_MODE=true`. It is still behind the normal authenticated
Portfolio route and never calls investment or order APIs. The application
default is off; live portfolio data and integrations remain unavailable.

## Calculators and demo portfolio

The public **Calculators** section is available from the landing page and the
shared responsive navigation without login. It includes goal projections,
monthly SIP (including target and annual step-up modes), and lumpsum
calculations. SIPs use a nominal annual return divided by 12 with end-of-month
contributions; lumpsum projections compound annually. Calculator results are
illustrative, not promises.

When `PORTFOLIO_DEMO_MODE=true` is explicitly enabled, Portfolio screens use a
separate typed sample repository. Its fictional holdings reconcile to
₹8,50,000 invested and ₹10,25,000 current value. The demo mode does not modify
authentication, live repositories, or backend records. Do not enable it for a
production build.

For a UI preview without the backend, opt into mock authentication:

```bash
flutter run -d web-server --web-port 8082 --dart-define=AUTH_MODE=mock
```

In mock mode, use any non-empty username and password, then any six-digit OTP.
Onboarding screens also use local mock storage/provider responses in this mode.
It is for local previews only; the default remains the real API.
Mock onboarding data lives only in memory and resets when the app restarts.

For a no-login mutual-fund preview using a small, saved sample fetched from
AMFI's official daily NAV report, use the bundled snapshot. It is the default
Explore data source for builds, so Explore works without a backend or a live
AMFI request. To build an installable APK with this offline data:

```bash
flutter build apk --dart-define=AMFI_SAMPLE_MODE=true
```

The APK includes `assets/data/amfi_nav_sample.json`: one captured scheme for
each of the 103 AMFI category sections. Explore, scheme details and comparison
read this local asset; its NAV dates and source are shown in the app. It is a
snapshot, not live data, and does not include NAV history or performance.
Some categories may have older NAV dates. The snapshot must be refreshed and
rebuilt to distribute newer local data. To explicitly use the configured API
repository instead, build with `--dart-define=AMFI_SAMPLE_MODE=false`; that
mode requires the API service to be reachable.

## Design system and responsive UX

The Flutter app uses a shared Surgam Capital visual system: Inter typography,
navy (`#142B45`) and emerald (`#168568`) brand colours, neutral surfaces,
consistent form/button/card treatments, and responsive navigation. Compact
layouts use bottom navigation; wide layouts use a left navigation rail.
Landing, authentication, investor home, onboarding, education, and mutual-fund
research screens share these styles and reusable financial metrics, source
notes, and status treatments. Authentication and onboarding use focused,
single-task layouts rather than the primary research navigation. This is a
presentation-layer change; it does not add account balances, KYC verification,
scheme attributes, or performance data that the configured sources do not
provide.

## Portfolio status

The authenticated Portfolio destination and its SIP, transaction, order,
allocation, and holding-detail entry screens are present, but portfolio figures
are intentionally unavailable until investor-specific data services are
implemented. The current backend provides mutual-fund research, AMFI NAV and
history, and watchlists; it does not provide folios, confirmed allotments,
adjusted units, investor transactions, SIP mandates/installments, or order
lifecycle records. No BSE StAR MF, CAMS, or KFintech portfolio synchronization
is currently present.

Do not treat an exchange order acknowledgement as an allotment. Production
portfolio integration must reconcile confirmed allotments and RTA folio
records, redemptions, switches, corporate actions, and applicable NAVs before
calculating holdings, cost basis, returns, XIRR, allocation, or performance.
The required valuation is adjusted confirmed units multiplied by the latest
applicable NAV; unrealized return is current value less the cost basis of
current holdings. XIRR requires dated net investor cash flows with switches,
redemptions, and corporate actions reconciled. These calculations are not
implemented without those source records. The Portfolio UI displays
unavailable/synchronization states rather than sample balances or fabricated
charts until those inputs are available.

Default API address is `http://localhost:8081`. Override it for the target
environment:

```bash
# Android emulator talking to a backend on the host machine
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081

# iOS simulator or local web development
flutter run --dart-define=API_BASE_URL=http://localhost:8081
```

Physical devices need a reachable host/LAN address and an HTTPS endpoint for
production. Android cleartext access is enabled only in the debug manifest;
iOS allows local networking only. Never use an HTTP URL in a production build.
For a release APK, provide the deployed HTTPS API origin at build time:

```bash
flutter build apk --dart-define=API_BASE_URL=https://api.example.com
```

The APK needs a reachable backend that implements the authentication endpoints;
the bundled AMFI sample only makes fund discovery available offline.

## Backend local development

Requirements: Java 21, Maven 3.9+, Docker Compose.

1. Copy `backend/.env.example` to the repository-root `.env`.
2. Replace placeholders with local-only values. Generate independent secrets:

   ```bash
   openssl rand -base64 32
   ```

   Use separate generated values for all signing and lookup secrets. Set
   `PAN_ENCRYPTION_KEY` to exactly 32 random bytes encoded as Base64; use a
   KMS-backed key in a production deployment.
3. Start the stack:

   ```bash
   docker compose up --build
   ```

Flyway applies migrations at backend startup. Swagger UI is at
`http://localhost:8081/swagger-ui/index.html`; health is at
`http://localhost:8081/actuator/health`.

The local `MockOtpDeliveryProvider` prints the OTP to backend logs. Mock PAN
and KYC providers are restricted to `local` and `test` profiles; they return
pending/unknown and never claim verification. Production fails closed until
authorised providers are configured.

## Implemented authentication API

All endpoints use `/api/v1/auth` and standardized response envelopes:

- `POST /register`
- `POST /login`
- `POST /otp/verify`
- `POST /otp/resend`
- `POST /refresh`
- `POST /logout` (bearer token required)
- `POST /forgot-password`
- `POST /reset-password`

See [backend/README.md](./backend/README.md) for boundaries, local run details,
security decisions and limitations.

## Onboarding and KYC foundation

After sign-in, choose **Start investor onboarding** on Investor home. The
resumable flow currently saves personal information, PAN, address and a
versioned tax-residency declaration, checks existing KYC through a provider
port, and supports submission/status tracking. PAN is encrypted at rest and
responses expose only its masked form. Local PAN/KYC providers return
`PENDING`/`UNKNOWN`; this is not a real KRA/CKYC verification or account
activation.

The onboarding APIs are under `/api/v1/onboarding`; details, data model, ERD,
security decisions and production gaps are in [docs/onboarding.md](./docs/onboarding.md).
Bank verification, nominees, secure document storage/upload, consent evidence,
notifications, and operations/manual-review APIs are not implemented yet.

## Mutual fund discovery and research

Read-only scheme discovery, scheme details and comparison are public and do
not require login. Personal watchlists and investor account functions still
require login. The AMFI sample preview includes a small dated snapshot only;
the full API-backed discovery needs the configured backend and AMFI sync.
This is informational research only; no purchase, redemption, SIP
registration, or transaction flow is implemented.

Do not treat the bundled snapshot as live or as a production data feed.
Mock/demo scheme and NAV fixtures are synthetic and must not be treated as
real market data. See [docs/mutual-fund-discovery.md](./docs/mutual-fund-discovery.md)
for routes, APIs, data model, performance methodology, and provider limitations.

Explore classifies AMFI category labels into scheme groups and market-cap
styles; displayed counts are counts of matching AMFI categories, not individual
funds. Market-cap styles reflect the category name only, not current portfolio
holdings or constituent exposure. AMC selection supports multiple fund houses.

## Tests and checks

```bash
dart format lib test
flutter analyze
flutter test
cd backend && mvn test
```

The Flutter code uses a feature-first layout under `lib/features/`. The backend
uses `com.surgamcapital.auth` and `shared` packages. Phase 1 education and public
content remain local mock data.

## Current limitations

- Backend uses configurable HMAC JWT signing, not asymmetric key rotation.
- Mock OTP delivery is local-only; a production SMS/email adapter and operational
  key rotation are required before deployment.
- Auth rate limiting uses Redis counters; distributed edge/IP controls still
  need deployment-specific configuration.
- Java/Maven/Docker are not installed in the current environment, so backend
  compilation, migrations and container tests have not been run here.
- No production readiness/security audit is implied. Review and test before use
  with real investors or personal data.
