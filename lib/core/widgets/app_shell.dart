import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_brand.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.body,
    this.scroll = true,
    this.maxWidth = 1120,
    this.selectedNavigationIndex,
  });

  final Widget body;
  final bool scroll;
  final double maxWidth;
  final int? selectedNavigationIndex;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    final content = scroll
        ? SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 20 : 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: body,
              ),
            ),
          )
        : Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: body,
            ),
          );
    return Scaffold(
      appBar: AppBar(
        title: const AppBrand(compact: true),
        backgroundColor: AppColors.surface,
      ),
      body: selectedNavigationIndex == null
          ? content
          : AppAdaptiveBody(
              selectedIndex: selectedNavigationIndex!,
              child: content,
            ),
    );
  }
}

class AppAdaptiveBody extends StatelessWidget {
  const AppAdaptiveBody({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  final Widget child;
  final int selectedIndex;

  static const _routes = [
    AppRoutes.schemeDiscovery,
    AppRoutes.portfolio,
    AppRoutes.calculators,
    AppRoutes.dashboard,
  ];

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.search_rounded),
      selectedIcon: Icon(Icons.search_rounded),
      label: 'Explore',
    ),
    NavigationDestination(
      icon: Icon(Icons.business_center_outlined),
      selectedIcon: Icon(Icons.business_center_rounded),
      label: 'Portfolio',
    ),
    NavigationDestination(
      icon: Icon(Icons.calculate_outlined),
      selectedIcon: Icon(Icons.calculate_rounded),
      label: 'Goals',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  void _navigate(BuildContext context, int index) {
    if (index >= 0 && index < _routes.length && index != selectedIndex) {
      context.go(_routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= 900) {
        return Row(
          children: [
            NavigationRail(
              extended: constraints.maxWidth >= 1200,
              minExtendedWidth: 216,
              selectedIndex: selectedIndex < 0 ? null : selectedIndex,
              onDestinationSelected: (index) => _navigate(context, index),
              leading: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                child: constraints.maxWidth >= 1200
                    ? const AppBrand(compact: true)
                    : const Icon(
                        Icons.account_balance_rounded,
                        color: AppColors.navy,
                        size: 28,
                      ),
              ),
              destinations: [
                for (final destination in _destinations)
                  NavigationRailDestination(
                    icon: destination.icon,
                    selectedIcon: destination.selectedIcon,
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: child),
          ],
        );
      }
      if (selectedIndex < 0) return child;
      return Column(
        children: [
          Expanded(child: child),
          NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _navigate(context, index),
            destinations: _destinations,
          ),
        ],
      );
    },
  );
}

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      bottom: AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
          ? 12
          : 16,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.blue,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 16), trailing!],
      ],
    ),
  );
}

class AppSectionHeading extends StatelessWidget {
  const AppSectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      bottom: AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
          ? 12
          : 16,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    ),
  );
}

class AppPanel extends StatelessWidget {
  const AppPanel({super.key, required this.child, this.padding = 20});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    final effectivePadding = isMobile && padding > 20 ? 20.0 : padding;
    return Card(
      child: Padding(padding: EdgeInsets.all(effectivePadding), child: child),
    );
  }
}

class AppProgressSteps extends StatelessWidget {
  const AppProgressSteps({
    super.key,
    required this.labels,
    required this.currentStep,
    this.completed = false,
  });

  final List<String> labels;
  final int currentStep;
  final bool completed;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          SizedBox(
            width: 76,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: index + 1 <= currentStep || completed
                      ? AppColors.blue
                      : const Color(0xFFE7ECEC),
                  foregroundColor: index + 1 <= currentStep || completed
                      ? Colors.white
                      : AppColors.secondaryText,
                  child: index + 1 < currentStep || completed
                      ? const Icon(Icons.check, size: 17)
                      : Text('${index + 1}'),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: index + 1 == currentStep
                        ? AppColors.navy
                        : AppColors.secondaryText,
                    fontWeight: index + 1 == currentStep
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (index != labels.length - 1)
            Container(
              width: 12,
              height: 1,
              margin: const EdgeInsets.only(top: 13),
              color: index + 1 < currentStep || completed
                  ? AppColors.blue
                  : AppColors.border,
            ),
        ],
      ],
    ),
  );
}
