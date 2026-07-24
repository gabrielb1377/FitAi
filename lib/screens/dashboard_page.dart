import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_shell.dart';
import '../services/running_session_service.dart';
import '../services/sync_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.initialDeepLink});

  final Uri? initialDeepLink;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    SyncService.instance.startAutoSync();
    unawaited(RunningSessionService.instance.initialize());
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(initialDeepLink: widget.initialDeepLink);
  }
}
