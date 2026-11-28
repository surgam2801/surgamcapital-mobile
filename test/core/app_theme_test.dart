import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surgam_capital/core/theme/app_theme.dart';

void main() {
  test('mobile text theme reduces headings and tightens line spacing', () {
    const baseline = TextTheme(
      headlineLarge: TextStyle(fontSize: 36),
      headlineMedium: TextStyle(fontSize: 30),
      headlineSmall: TextStyle(fontSize: 24),
      titleLarge: TextStyle(fontSize: 20),
      titleMedium: TextStyle(fontSize: 16),
      bodyLarge: TextStyle(fontSize: 16, height: 1.55),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, height: 1.45),
    );
    final theme = AppTheme.textThemeForWidth(599, baseline);

    expect(theme.headlineLarge?.fontSize, 30);
    expect(theme.headlineMedium?.fontSize, 26);
    expect(theme.headlineSmall?.fontSize, 22);
    expect(theme.titleLarge?.fontSize, 18);
    expect(theme.titleMedium?.fontSize, 15);
    expect(theme.bodyLarge?.fontSize, 15);
    expect(theme.bodyMedium?.fontSize, 14);
    expect(theme.bodySmall?.fontSize, 12);
    expect(theme.bodyLarge?.height, 1.4);
    expect(theme.bodyMedium?.height, 1.4);
    expect(theme.bodySmall?.height, 1.35);
  });

  test('tablet and desktop typography stays unchanged from 600 dp', () {
    const baseline = TextTheme(headlineLarge: TextStyle(fontSize: 36));

    for (final width in [600.0, 900.0]) {
      expect(AppTheme.isMobileWidth(width), isFalse);
      expect(AppTheme.textThemeForWidth(width, baseline), same(baseline));
    }
    expect(AppTheme.isMobileWidth(599), isTrue);
  });

  testWidgets('mobile typography keeps system text scaling', (tester) async {
    const baseline = TextTheme(bodyLarge: TextStyle(fontSize: 16));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(1.3),
          ),
          child: Theme(
            data: ThemeData(
              textTheme: AppTheme.textThemeForWidth(390, baseline),
            ),
            child: Builder(
              builder: (context) => Text(
                'Readable body text',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      MediaQuery.textScalerOf(
        tester.element(find.text('Readable body text')),
      ).scale(15),
      19.5,
    );
  });
}
