import '../../../../core/navigation/app_section.dart';
import '../../../../core/navigation/navigation_controller.dart';

/// Navegação interna de Atividades e seus módulos subordinados.
final class ActivitiesNavigationController extends SectionNavigationController {
  const ActivitiesNavigationController(NavigationController navigation)
    : super(navigation: navigation, section: AppShellSection.activities);
}
