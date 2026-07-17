import 'package:flutter/material.dart';

import '../../../screens/dashboard_page.dart';

abstract final class AuthNavigation {
  static void replaceWithApp(BuildContext context) {
    replaceAll(context, const DashboardPage());
  }

  static void replaceAll(BuildContext context, Widget destination) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (_) => false,
    );
  }
}
