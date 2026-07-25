import 'package:flutter/material.dart';

import 'planos_official_root_page.dart';

/// Raiz oficial do modulo Planos dentro do App Shell.
class PlansRootPage extends StatelessWidget {
  const PlansRootPage({super.key, this.onXpUpdated, this.onBack});

  final Future<void> Function()? onXpUpdated;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return PlanosOfficialRootPage(onXpUpdated: onXpUpdated, onBack: onBack);
  }
}
