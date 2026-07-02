import '../core/app_router.dart';
import '../core/app_shell.dart';

typedef AppNavigationDestination = AppRouteDestination;

@Deprecated('Use AppShell from lib/core/app_shell.dart.')
class AppAdaptiveNavigationScaffold extends AppShell {
  const AppAdaptiveNavigationScaffold({
    super.key,
    required super.selectedIndex,
    required super.onDestinationSelected,
    required super.destinations,
    required super.pages,
  });
}
