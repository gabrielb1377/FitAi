import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';

/// Agrupamento simples usado somente nas páginas de demonstração.
class ShowcaseSection extends StatelessWidget {
  const ShowcaseSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FitSectionTitle(title: title),
        const SizedBox(height: FitSpacing.s12),
        child,
      ],
    );
  }
}
