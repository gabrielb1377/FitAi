import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_icon_button.dart';

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FitIconButton(
        icon: Icons.arrow_back_rounded,
        tooltip: 'Voltar',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
