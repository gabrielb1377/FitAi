import 'package:flutter/material.dart';

import '../config/dev_config.dart';

class DevModeBanner extends StatelessWidget {
  const DevModeBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!DevConfig.enabled || !DevConfig.showDevBanner) return child;
    return Stack(
      children: [
        child,
        const Positioned(
          top: 10,
          right: 10,
          child: SafeArea(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF1B5E20),
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    'DEV MODE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
