import 'package:flutter/material.dart';

import '../../design_system/components/fit_empty_state.dart';
import '../../design_system/components/fit_error_state.dart';
import '../../design_system/components/fit_header.dart';
import '../../design_system/tokens/fit_icons.dart';
import '../../design_system/tokens/fit_spacing.dart';
import 'app_section.dart';
import 'navigation_controller.dart';

typedef SectionRouteBuilder =
    Widget Function(BuildContext context, RouteSettings settings);

/// Registro de rotas de uma seção raiz.
class SectionRouter {
  const SectionRouter({
    required this.section,
    required this.rootBuilder,
    this.routes = const {},
    this.declaredRoutes = const {},
  });

  final AppShellSection section;
  final WidgetBuilder rootBuilder;
  final Map<String, SectionRouteBuilder> routes;
  final Set<String> declaredRoutes;

  String get initialRoute => section.rootRoute;

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute<dynamic>(
        settings: settings,
        builder: (context) => builder(context, settings),
      );
    }

    final isPlanned = declaredRoutes.contains(settings.name);
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => SectionPlaceholderPage(
        section: section,
        routeName: settings.name,
        isPlanned: isPlanned,
      ),
    );
  }
}

/// Navigator independente que preserva a pilha de uma seção.
class SectionNavigator extends StatefulWidget {
  const SectionNavigator({
    super.key,
    required this.router,
    required this.controller,
  });

  final SectionRouter router;
  final NavigationController controller;

  @override
  State<SectionNavigator> createState() => _SectionNavigatorState();
}

class _SectionNavigatorState extends State<SectionNavigator> {
  late final HeroController _heroController;
  late final _SectionNavigatorObserver _routeObserver;

  @override
  void initState() {
    super.initState();
    _heroController = HeroController();
    _routeObserver = _SectionNavigatorObserver(_notifyRouteChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: widget.controller.navigatorKeyFor(widget.router.section),
      pages: [
        MaterialPage<void>(
          key: ValueKey(widget.router.section),
          name: widget.router.initialRoute,
          child: Builder(builder: widget.router.rootBuilder),
        ),
      ],
      onGenerateRoute: widget.router.onGenerateRoute,
      onDidRemovePage: (_) => _notifyRouteChanged(),
      observers: [_heroController, _routeObserver],
    );
  }

  void _notifyRouteChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.notifyRouteStackChanged(widget.router.section);
    });
  }
}

class _SectionNavigatorObserver extends NavigatorObserver {
  _SectionNavigatorObserver(this.onChanged);

  final VoidCallback onChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onChanged();
  }
}

/// Fallback oficial para rotas reservadas ainda sem implementação.
class SectionPlaceholderPage extends StatelessWidget {
  const SectionPlaceholderPage({
    super.key,
    required this.section,
    required this.routeName,
    required this.isPlanned,
  });

  final AppShellSection section;
  final String? routeName;
  final bool isPlanned;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            FitHeader(
              title: section.label,
              subtitle: isPlanned ? 'Próxima etapa do módulo' : 'Navegação',
              showBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: isPlanned
                  ? FitEmptyState(
                      icon: FitIcons.progress,
                      title: 'Em desenvolvimento',
                      description:
                          'Esta rota já está reservada na arquitetura oficial.',
                      actionLabel: 'Voltar',
                      onAction: () => Navigator.of(context).maybePop(),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(FitSpacing.s20),
                      child: FitErrorState(
                        error: 'A rota ${routeName ?? ''} não foi encontrada.',
                        onRetry: () => Navigator.of(context).maybePop(),
                        retryLabel: 'Voltar',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
