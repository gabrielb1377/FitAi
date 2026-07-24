import '../../../../core/navigation/app_section.dart';
import '../../../../core/navigation/navigation_controller.dart';

/// Navegação interna de Perfil, Premium e Configurações.
final class ProfileNavigationController extends SectionNavigationController {
  const ProfileNavigationController(NavigationController navigation)
    : super(navigation: navigation, section: AppShellSection.profile);
}
