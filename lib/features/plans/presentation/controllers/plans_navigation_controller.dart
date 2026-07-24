import '../../../../core/navigation/app_section.dart';
import '../../../../core/navigation/navigation_controller.dart';

/// Navegação interna de Planos sem strings ou índices espalhados.
final class PlansNavigationController extends SectionNavigationController {
  const PlansNavigationController(NavigationController navigation)
    : super(navigation: navigation, section: AppShellSection.plans);
}
