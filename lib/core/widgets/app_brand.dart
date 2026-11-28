import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBrand extends StatelessWidget {
  const AppBrand({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final showName = !compact || constraints.maxWidth >= 280;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 36 : 44,
            height: compact ? 36 : 44,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text(
              'S',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (showName) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Surgam Capital',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: compact ? 16 : 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}
