import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';

class PlansEntrance extends StatefulWidget {
  final Widget child;

  const PlansEntrance({super.key, required this.child});

  @override
  State<PlansEntrance> createState() => _PlansEntranceState();
}

class _PlansEntranceState extends State<PlansEntrance> {
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
