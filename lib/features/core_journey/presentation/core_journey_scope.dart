import 'package:flutter/widgets.dart';

import 'core_journey_controller.dart';

/// Dependencias de navegacao do Core V1 compartilhadas pelo App Shell.
///
/// Evita acoplar as paginas da jornada a indices da Bottom Navigation.
class CoreJourneyScope extends InheritedNotifier<CoreJourneyController> {
  const CoreJourneyScope({
    super.key,
    required CoreJourneyController controller,
    required this.onOpenHome,
    required this.onOpenWorkoutHistory,
    required super.child,
  }) : super(notifier: controller);

  final VoidCallback onOpenHome;
  final Future<void> Function(String sessionId) onOpenWorkoutHistory;

  static CoreJourneyScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CoreJourneyScope>();
}
