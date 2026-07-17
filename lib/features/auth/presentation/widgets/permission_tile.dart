import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_badge.dart';
import '../../../../design_system/components/fit_icon_button.dart';
import '../../../../design_system/tokens/fit_colors.dart';
import '../../../../design_system/tokens/fit_radius.dart';
import '../../../../design_system/tokens/fit_spacing.dart';
import '../../data/auth_permissions_service.dart';

class PermissionTile extends StatelessWidget {
  const PermissionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.onRequest,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final AuthPermissionStatus status;
  final VoidCallback onRequest;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    final canRequest =
        status == AuthPermissionStatus.pending ||
        status == AuthPermissionStatus.denied;
    return Semantics(
      label: '$title. ${status.label}. $description',
      child: Container(
        padding: const EdgeInsets.all(FitSpacing.s16),
        decoration: BoxDecoration(
          color: FitColors.surface,
          borderRadius: FitRadius.largeBorder,
          border: Border.all(color: FitColors.outlineSoft),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(24),
                borderRadius: FitRadius.mediumBorder,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: FitSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: FitSpacing.s4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: FitSpacing.s8),
                  FitBadge.custom(
                    label: status.label,
                    tone: _badgeToneFor(status),
                  ),
                ],
              ),
            ),
            if (canRequest)
              FitIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Configurar $title',
                onPressed: onRequest,
                isLoading: isLoading,
                variant: FitIconButtonVariant.subtle,
              )
            else
              Icon(
                status == AuthPermissionStatus.granted
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: color,
              ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(AuthPermissionStatus value) => switch (value) {
    AuthPermissionStatus.granted => FitColors.success,
    AuthPermissionStatus.denied => FitColors.warning,
    AuthPermissionStatus.unavailable => FitColors.textHint,
    AuthPermissionStatus.pending => FitColors.primary,
  };

  FitBadgeTone _badgeToneFor(AuthPermissionStatus value) => switch (value) {
    AuthPermissionStatus.granted => FitBadgeTone.success,
    AuthPermissionStatus.denied => FitBadgeTone.warning,
    AuthPermissionStatus.unavailable => FitBadgeTone.neutral,
    AuthPermissionStatus.pending => FitBadgeTone.info,
  };
}
