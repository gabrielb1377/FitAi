import 'package:flutter/material.dart';

import '../../design_system/tokens/fit_breakpoints.dart';
import 'app_section.dart';
import 'navigation_controller.dart';
import 'section_router.dart';
import 'shell_navigation.dart';

/// Shell oficial das cinco áreas raiz do FitIA.
///
/// Cada destino mantém seu próprio Navigator dentro de um IndexedStack.
class MainScaffold extends StatelessWidget {
  const MainScaffold({
    super.key,
    required this.navigationController,
    required this.sectionRouters,
  }) : assert(sectionRouters.length == AppShellSection.values.length);

  final NavigationController navigationController;
  final List<SectionRouter> sectionRouters;

  @override
  Widget build(BuildContext context) {
    final routersBySection = {
      for (final router in sectionRouters) router.section: router,
    };
    assert(
      AppShellSection.values.every(routersBySection.containsKey),
      'MainScaffold exige um SectionRouter para cada seção oficial.',
    );

    return ListenableBuilder(
      listenable: navigationController,
      builder: (context, _) {
        final section = navigationController.currentSection;
        final canPopSection = navigationController.canPop(section);
        if (navigationController.hasPendingDeepLink) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigationController.flushPendingDeepLink();
          });
        }

        return PopScope<void>(
          canPop: section == AppShellSection.home && !canPopSection,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (await navigationController.maybePopCurrent()) return;
            navigationController.selectSection(AppShellSection.home);
          },
          child: Scaffold(
            body: IndexedStack(
              index: section.index,
              children: [
                for (final item in AppShellSection.values)
                  SectionNavigator(
                    router: routersBySection[item]!,
                    controller: navigationController,
                  ),
              ],
            ),
            bottomNavigationBar: canPopSection
                ? null
                : Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: FitBreakpoints.tablet,
                      ),
                      child: ShellNavigation(
                        selectedSection: section,
                        onSelected: navigationController.selectSection,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
