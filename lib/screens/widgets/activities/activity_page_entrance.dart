import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';

class ActivityPageEntrance extends StatefulWidget {
  final Widget child;

  const ActivityPageEntrance({super.key, required this.child});

  @override
  State<ActivityPageEntrance> createState() => _ActivityPageEntranceState();
}

class _ActivityPageEntranceState extends State<ActivityPageEntrance> {
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
      child: FitAnimations.slide(visible: _visible, child: widget.child),
    );
  }
}
