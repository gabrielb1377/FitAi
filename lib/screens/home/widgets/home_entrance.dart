import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';

/// Entrada curta para blocos principais da Home, sem timers ou estado global.
class HomeEntrance extends StatefulWidget {
  final Widget child;
  final bool useScale;

  const HomeEntrance({super.key, required this.child, this.useScale = false});

  @override
  State<HomeEntrance> createState() => _HomeEntranceState();
}

class _HomeEntranceState extends State<HomeEntrance> {
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
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    final animated = FitAnimations.slide(
      visible: _visible,
      child: FitAnimations.fade(visible: _visible, child: widget.child),
    );
    return widget.useScale
        ? FitAnimations.scale(visible: _visible, child: animated)
        : animated;
  }
}
