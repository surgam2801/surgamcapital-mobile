import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surgam_capital/app.dart';
import 'package:surgam_capital/core/routing/app_router.dart';
import 'package:surgam_capital/core/routing/app_routes.dart';
import 'package:surgam_capital/features/authentication/data/authentication_providers.dart';
import 'package:surgam_capital/features/authentication/data/mock_authentication_repository.dart';
import 'package:surgam_capital/features/authentication/data/token_storage.dart';
import 'package:surgam_capital/features/mutual_funds/data/amfi_sample_mutual_fund_repository.dart';
import 'package:surgam_capital/features/mutual_funds/data/mock_mutual_fund_repository.dart';
import 'package:surgam_capital/features/mutual_funds/data/mutual_fund_providers.dart';
import 'package:surgam_capital/features/mutual_funds/domain/mutual_fund_scheme.dart';
import 'package:surgam_capital/features/onboarding/data/mock_onboarding_repository.dart';
import 'package:surgam_capital/features/onboarding/data/onboarding_providers.dart';
import 'package:surgam_capital/features/portfolio/data/demo_portfolio_repository.dart';
import 'package:surgam_capital/features/portfolio/presentation/demo_portfolio_screen.dart';

Widget testApp({TokenStorage? tokenStorage}) {
  return ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(
        tokenStorage ?? _TestTokenStorage(),
      ),
    ],
    child: const SurgamCapitalApp(),
  );
}

void main() {
  testWidgets('landing page renders public content', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('Invest with Clarity'), findsWidgets);
    expect(find.text('Learn Before You Invest'), findsOneWidget);
    expect(find.text('Your Investment Journey'), findsNothing);
    expect(find.text('Making Mutual Fund Investing Easier'), findsNothing);
    expect(find.text('Goals'), findsWidgets);
  });

  testWidgets('mobile app applies compact readable typography', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Learn Before You Invest'));
    expect(Theme.of(context).textTheme.headlineLarge?.fontSize, 30);
    expect(Theme.of(context).textTheme.headlineSmall?.fontSize, 22);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Goals').last);
    await tester.pumpAndSettle();
    expect(find.text('Plan Your Investments'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('calculator-retirement')));
    await tester.tap(find.byKey(const Key('calculator-retirement')));
    await tester.pumpAndSettle();
    expect(find.text('Plan a goal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile portfolio layout has no overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tokenStorage = _TestTokenStorage();
    await tokenStorage.saveTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
    );
    await tester.pumpWidget(testApp(tokenStorage: tokenStorage));
    await tester.pumpAndSettle();

    expect(
      find.text(portfolioDemoMode ? 'Priya Nair' : 'Investor profile'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('login form validates required fields', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    final login = find.text('Login');
    await tester.tap(login.last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();
    expect(find.text('Username cannot be empty'), findsOneWidget);
    expect(find.text('Password cannot be empty'), findsOneWidget);
  });

  testWidgets('password visibility toggle changes obscure state', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();
    final password = find.byKey(const Key('password-field'));
    expect(
      find.descendant(
        of: password,
        matching: find.byIcon(Icons.visibility_outlined),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('password-toggle')));
    await tester.pump();
    expect(
      find.descendant(
        of: password,
        matching: find.byIcon(Icons.visibility_off_outlined),
      ),
      findsOneWidget,
    );
  });

  testWidgets('landing navigates to registration entry', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Create your investor account'), findsOneWidget);
    expect(
      find.textContaining('Identity and KYC verification'),
      findsOneWidget,
    );
  });

  testWidgets('investor home redirects to login without a stored session', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(_TestTokenStorage())],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go(AppRoutes.dashboard);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('stored session opens the portfolio on app start', (
    tester,
  ) async {
    final tokenStorage = _TestTokenStorage();
    await tokenStorage.saveTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
    );
    final container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(tokenStorage)],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(portfolioDemoMode ? 'Priya Nair' : 'Investor profile'),
      findsOneWidget,
    );
  });

  testWidgets('public scheme discovery is accessible without a session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(_TestTokenStorage()),
        mutualFundRepositoryProvider.overrideWithValue(
          AmfiSampleMutualFundRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go(AppRoutes.schemeDiscovery);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Explore mutual funds'), findsOneWidget);
    expect(find.text('All AMCs'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('explore-filter-controls')),
      const Offset(-240, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Learn'), findsNothing);
    expect(find.text('Saved'), findsNothing);
    expect(find.text('More categories'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('category-all'))).width,
      lessThan(130),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('scheme-row-152076'))).height,
      lessThan(180),
    );
    expect(find.text('Explore mutual funds'), findsOneWidget);
    final childrenCategory = find.byKey(
      const ValueKey("category-OPEN_ENDED:Children’s Fund - Childrens' Fund"),
    );
    expect(childrenCategory, findsOneWidget);
    await tester.tap(childrenCategory);
    await tester.pumpAndSettle();
    expect(find.text("Children’s Fund - Childrens' Fund"), findsWidgets);
    expect(tester.takeException(), isNull);
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('calculators are public and have goal and investment tools', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(_TestTokenStorage())],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go(AppRoutes.calculators);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('Plan Your Investments'), findsOneWidget);
    expect(find.text('Retirement'), findsOneWidget);
    expect(find.text('SIP calculator'), findsOneWidget);
    expect(find.text('Lumpsum calculator'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('calculator-retirement'))).width,
      lessThan(160),
    );

    await tester.tap(find.text('Retirement'));
    await tester.pumpAndSettle();
    expect(find.text('Plan a goal'), findsOneWidget);
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('calculator-tool-tab-retirement')),
          )
          .properties
          .selected,
      isTrue,
    );
    expect(find.text('Expected annual inflation'), findsOneWidget);
    expect(
      find.textContaining('Past performance does not guarantee'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal calculator tabs switch tools with fresh defaults', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(_TestTokenStorage())],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go('${AppRoutes.calculator}/retirement');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Plan a goal'), findsOneWidget);
    expect(find.byKey(const ValueKey('calculator-tool-tabs')), findsOneWidget);

    final goalAmount = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller?.text == '2500000',
    );
    expect(goalAmount, findsOneWidget);
    await tester.enterText(goalAmount, '1234567');
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('calculator-tool-tabs')),
      const Offset(-1600, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calculator-tool-tab-sip')));
    await tester.pumpAndSettle();

    expect(find.text('Investment calculators'), findsOneWidget);
    expect(find.text('Monthly SIP'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is TextField && widget.controller?.text == '15000',
      ),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('calculator-tool-tabs')),
      const Offset(1600, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('calculator-tool-tab-education')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plan a goal'), findsOneWidget);
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('calculator-tool-tab-education')),
          )
          .properties
          .selected,
      isTrue,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is TextField && widget.controller?.text == '2500000',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scheme discovery errors stay visible without layout overflow', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(_TestTokenStorage()),
        mutualFundRepositoryProvider.overrideWithValue(
          _UnavailableMutualFundRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go(AppRoutes.schemeDiscovery);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Categories could not be loaded.'), findsOneWidget);
    expect(find.text('Unable to load schemes.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scheme details keep NAV and characteristics in compact tabs', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        mutualFundRepositoryProvider.overrideWithValue(
          MockMutualFundRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go('${AppRoutes.schemeDetail}/00000000-0000-4000-8000-000000000001');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('LATEST NAV'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    await tester.tap(find.text('Performance'));
    await tester.pumpAndSettle();
    expect(find.text('Historical NAV'), findsOneWidget);
    await tester.tap(find.text('Fund details & risk'));
    await tester.pumpAndSettle();
    expect(find.text('Scheme characteristics'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'portfolio navigation shows explicit unsynchronized state',
    (tester) async {
      final tokenStorage = _TestTokenStorage();
      await tokenStorage.saveTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      );
      final container = ProviderContainer(
        overrides: [tokenStorageProvider.overrideWithValue(tokenStorage)],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      router.go(AppRoutes.dashboard);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portfolio').last);
      await tester.pumpAndSettle();

      expect(find.text('Investor profile'), findsOneWidget);
      expect(find.text('NOT SYNCED'), findsOneWidget);
      expect(find.text('No synchronized holdings'), findsOneWidget);
      expect(find.text('PORTFOLIO XIRR'), findsOneWidget);
      expect(find.text('My SIPs'), findsOneWidget);
      expect(find.text('Allotment'), findsNothing);
      await tester.tap(find.text('Holdings').first);
      await tester.pumpAndSettle();
      expect(find.text('My holdings'), findsOneWidget);
      expect(find.text('No synchronized holdings'), findsOneWidget);
      await tester.tap(find.text('Overview').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('My SIPs'));
      await tester.tap(find.text('My SIPs'));
      await tester.pumpAndSettle();
      expect(find.text('SIP status'), findsOneWidget);
      expect(
        find.text('No synchronized records in any section.'),
        findsOneWidget,
      );
    },
    skip: portfolioDemoMode,
  );

  testWidgets(
    'demo portfolio overview shows sample investor, returns and advisor',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: DemoPortfolioScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Priya Nair'), findsOneWidget);
      expect(find.text('₹10,25,000'), findsOneWidget);
      expect(find.text('₹8,50,000'), findsOneWidget);
      expect(find.text('₹1,75,000'), findsOneWidget);
      expect(find.text('XIRR 14.8%'), findsOneWidget);
      expect(find.text('Absolute return'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('portfolio-return-toggle')),
          matching: find.byIcon(Icons.swap_horiz_rounded),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('portfolio-return-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('ABSOLUTE 20.59%'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('portfolio-return-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('XIRR 14.8%'), findsOneWidget);
      expect(find.text('Rahul Kumar'), findsOneWidget);
      expect(find.text('rahul.kumar@example.invalid'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'demo portfolio tabs render only when demo mode is enabled',
    (tester) async {
      final tokenStorage = _TestTokenStorage();
      await tokenStorage.saveTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      );
      final container = ProviderContainer(
        overrides: [tokenStorageProvider.overrideWithValue(tokenStorage)],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      router.go(AppRoutes.portfolio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Priya Nair'), findsOneWidget);
      await tester.ensureVisible(find.text('Holdings').first);
      await tester.tap(find.text('Holdings').first);
      await tester.pumpAndSettle();
      expect(find.text('My holdings'), findsOneWidget);
      expect(find.textContaining('[DEMO]'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
    skip: !portfolioDemoMode,
  );

  testWidgets('mock login and OTP navigate to the portfolio', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(
            MockAuthenticationRepository(),
          ),
          onboardingRepositoryProvider.overrideWithValue(
            MockOnboardingRepository(),
          ),
          mutualFundRepositoryProvider.overrideWithValue(
            MockMutualFundRepository(),
          ),
          tokenStorageProvider.overrideWithValue(_TestTokenStorage()),
        ],
        child: const SurgamCapitalApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('username-field')), 'investor');
    await tester.enterText(find.byKey(const Key('password-field')), 'example');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.textContaining('verification code sent'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('otp-field')), '123456');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(
      find.text(portfolioDemoMode ? 'Priya Nair' : 'Investor profile'),
      findsOneWidget,
    );
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Welcome to your investor home'), findsOneWidget);
    await tester.tap(find.text('Explore mutual funds'));
    await tester.pumpAndSettle();
    expect(find.text('Explore mutual funds'), findsOneWidget);
    expect(find.textContaining('DEMO DATA ONLY'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start investor onboarding'));
    await tester.pumpAndSettle();
    expect(find.text('Let’s set up your investor profile'), findsOneWidget);
    expect(find.text('Start onboarding'), findsOneWidget);
  });
}

class _TestTokenStorage implements TokenStorage {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<bool> hasTokens() async =>
      _accessToken != null && _refreshToken != null;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }
}

class _UnavailableMutualFundRepository extends MockMutualFundRepository {
  @override
  Future<List<MutualFundFilterOption>> categories() async =>
      throw StateError('Category service unavailable');

  @override
  Future<SchemePage> search({
    String? query,
    String? category,
    String? amc,
    List<String>? amcIds,
    String? schemeClass,
    String? marketCap,
    String? risk,
    String? subCategory,
    String? planType,
    String? optionType,
    double? minExpenseRatio,
    double? maxExpenseRatio,
    int page = 0,
    String sortBy = 'schemeName',
    String sortDirection = 'ASC',
  }) async => throw StateError('Scheme service unavailable');
}
