import '../../../../core/navigation/app_section.dart';
import '../../../../core/navigation/navigation_controller.dart';

/// Navegação interna da Home sem conhecimento de índices da Bottom Navigation.
final class HomeNavigationController extends SectionNavigationController {
  const HomeNavigationController(NavigationController navigation)
    : super(navigation: navigation, section: AppShellSection.home);
}
