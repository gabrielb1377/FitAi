import '../../../../core/navigation/app_section.dart';
import '../../../../core/navigation/navigation_controller.dart';

/// Navegação interna da Biblioteca e seus conteúdos subordinados.
final class LibraryNavigationController extends SectionNavigationController {
  const LibraryNavigationController(NavigationController navigation)
    : super(navigation: navigation, section: AppShellSection.library);
}
