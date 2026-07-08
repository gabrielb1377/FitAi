import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class HomeNotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const HomeNotificationBell({super.key, required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(16)),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
