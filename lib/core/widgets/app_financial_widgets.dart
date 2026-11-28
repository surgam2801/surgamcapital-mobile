import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class AppSpotlightPanel extends StatelessWidget {
  const AppSpotlightPanel({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    this.trailing,
    this.compact = false,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    final showIllustration = !compact && !isMobile;
    return Container(
      padding: EdgeInsets.all(
        isMobile
            ? compact
                  ? 14
                  : 18
            : compact
            ? 18
            : 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF29435B)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14142B45),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon, size: 16, color: AppColors.teal),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      eyebrow.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFB5D9CE),
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: isMobile
                      ? compact
                            ? 10
                            : 12
                      : compact
                      ? 12
                      : 16,
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontSize: isMobile || compact ? 22 : 26,
                    height: isMobile ? 1.2 : 1.2,
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFD1DDE6),
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(height: isMobile ? 12 : 16),
                  trailing!,
                ],
              ],
            ),
          ),
          if (showIllustration) ...[
            const SizedBox(width: 16),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: AppColors.teal, size: 30),
            ),
          ],
        ],
      ),
    );
  }
}

class AppMetricTile extends StatelessWidget {
  const AppMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.accent = false,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    final background = accent ? AppColors.navy : AppColors.surface;
    final foreground = accent ? Colors.white : AppColors.navy;
    final secondary = accent
        ? const Color(0xFFCAD7E1)
        : AppColors.secondaryText;
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent ? AppColors.navy : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: secondary,
                    letterSpacing: .7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (icon != null) Icon(icon, size: 16, color: AppColors.teal),
            ],
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (caption != null) ...[
            SizedBox(height: isMobile ? 4 : 5),
            Text(
              caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: secondary),
            ),
          ],
        ],
      ),
    );
  }
}

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = AppStatusTone.neutral,
  });

  final String label;
  final IconData? icon;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    final color = switch (tone) {
      AppStatusTone.success => AppColors.success,
      AppStatusTone.warning => AppColors.warning,
      AppStatusTone.error => AppColors.error,
      AppStatusTone.info => AppColors.info,
      AppStatusTone.neutral => AppColors.secondaryText,
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: isMobile ? 5 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum AppStatusTone { neutral, success, warning, error, info }

class AppSourceNote extends StatelessWidget {
  const AppSourceNote({
    super.key,
    required this.source,
    required this.caption,
    this.tone = AppStatusTone.info,
  });

  final String source;
  final String caption;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    final color = tone == AppStatusTone.warning
        ? AppColors.warning
        : AppColors.info;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: '$source  ',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
