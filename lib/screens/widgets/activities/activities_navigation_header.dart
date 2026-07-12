import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';

class ActivitiesNavigationHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const ActivitiesNavigationHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return FitHeader(
      title: title,
      subtitle: subtitle,
      showBackButton: true,
      onBack: () => Navigator.maybePop(context),
      actions: trailing == null ? const [] : [trailing!],
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
    );
  }
}
