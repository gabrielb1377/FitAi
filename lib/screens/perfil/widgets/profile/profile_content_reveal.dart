import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

/// Aplica uma entrada curta ao conteudo carregado sem controlar dados ou rotas.
class ProfileContentReveal extends StatefulWidget {
  final Widget child;

  const ProfileContentReveal({super.key, required this.child});

  @override
  State<ProfileContentReveal> createState() => _ProfileContentRevealState();
}

class _ProfileContentRevealState extends State<ProfileContentReveal> {
  var _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FitAnimations.fade(
      visible: _visible,
      child: FitAnimations.slide(
        visible: _visible,
        child: FitAnimations.scale(visible: _visible, child: widget.child),
      ),
    );
  }
}
