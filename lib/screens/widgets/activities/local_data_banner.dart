import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';

class LocalDataBanner extends StatelessWidget {
  const LocalDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Dados locais ativos',
      child: Row(
        children: [
          const FitBadge.offline(),
          const SizedBox(width: FitSpacing.s8),
          Expanded(
            child: Text(
              'Mostrando dados salvos no dispositivo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
