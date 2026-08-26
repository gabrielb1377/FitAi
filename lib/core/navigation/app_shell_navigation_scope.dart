import 'package:flutter/widgets.dart';

import 'app_section.dart';
import 'navigation_controller.dart';

/// Expõe a navegação oficial do shell para fluxos que atravessam módulos.
///
/// Features usam este escopo em vez de instanciar telas de outra seção. Assim,
/// a pilha da seção de destino permanece dona do fluxo e do botão Voltar.
class AppShellNavigationScope extends InheritedNotifier<NavigationController> {
  const AppShellNavigationScope({
    super.key,
    required NavigationController navigationController,
    required super.child,
  }) : super(notifier: navigationController);

  static AppShellNavigationScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppShellNavigationScope>();

  Future<T?> open<T extends Object?>(
    AppShellSection section,
    String routeName, {
    Object? arguments,
  }) => notifier!.pushNamed<T>(section, routeName, arguments: arguments);

  void select(AppShellSection section) => notifier!.selectSection(section);
}
