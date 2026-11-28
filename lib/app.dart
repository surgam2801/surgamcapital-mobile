import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class SurgamCapitalApp extends ConsumerWidget {
  const SurgamCapitalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Surgam Capital',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) {
        final width = MediaQuery.sizeOf(context).width;
        return Theme(
          data: AppTheme.forWidth(width),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
