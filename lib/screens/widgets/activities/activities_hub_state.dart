import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';

class ActivitiesHubState extends StatelessWidget {
  final Widget content;

  const ActivitiesHubState({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const FitHeader(
              title: 'Atividades',
              subtitle: 'Acompanhe sua movimentacao.',
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}
