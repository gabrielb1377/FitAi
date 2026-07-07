import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_shell.dart';
import 'corridas/corridas_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    unawaited(CorridaAtivaController.instance.inicializar());
  }

  @override
  Widget build(BuildContext context) {
    return const AppShell();
  }
}
