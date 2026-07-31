import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_shell.dart';
import '../features/core_journey/presentation/core_journey_controller.dart';
import '../services/running_session_service.dart';
import '../services/sync_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.initialDeepLink});

  final Uri? initialDeepLink;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final CoreJourneyController _coreJourney;

  @override
  void initState() {
    super.initState();
    _coreJourney = CoreJourneyController();
    unawaited(_coreJourney.initialize());
    SyncService.instance.startAutoSync();
    unawaited(RunningSessionService.instance.initialize());
  }

  @override
  void dispose() {
    _coreJourney.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      initialDeepLink: widget.initialDeepLink,
      coreJourney: _coreJourney,
    );
  }
}
