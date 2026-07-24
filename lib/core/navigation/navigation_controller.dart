import 'dart:async';

import 'package:flutter/material.dart';

import 'app_section.dart';
import 'deep_link.dart';

/// Estado único da navegação do shell e das pilhas aninhadas.
class NavigationController extends ChangeNotifier {
  NavigationController({AppShellSection initialSection = AppShellSection.home})
    : _currentSection = initialSection,
      _navigatorKeys = {
        for (final section in AppShellSection.values)
          section: GlobalKey<NavigatorState>(
            debugLabel: '${section.name}-navigator',
          ),
      };

  AppShellSection _currentSection;
  final Map<AppShellSection, GlobalKey<NavigatorState>> _navigatorKeys;
  AppDeepLinkTarget? _pendingDeepLink;

  AppShellSection get currentSection => _currentSection;
  int get selectedIndex => _currentSection.index;
  bool get hasPendingDeepLink => _pendingDeepLink != null;

  GlobalKey<NavigatorState> navigatorKeyFor(AppShellSection section) =>
      _navigatorKeys[section]!;

  NavigatorState? navigatorFor(AppShellSection section) =>
      navigatorKeyFor(section).currentState;

  bool selectIndex(int index) {
    final section = AppShellSection.fromIndex(index);
    if (section == null) return false;
    return selectSection(section);
  }

  bool selectSection(AppShellSection section) {
    if (_currentSection == section) return false;
    _currentSection = section;
    notifyListeners();
    return true;
  }

  bool canPop(AppShellSection section) =>
      navigatorFor(section)?.canPop() ?? false;

  Future<bool> maybePopCurrent<T extends Object?>([T? result]) async {
    final navigator = navigatorFor(_currentSection);
    if (navigator == null || !navigator.canPop()) return false;
    return navigator.maybePop<T>(result);
  }

  void popToRoot(AppShellSection section) {
    navigatorFor(section)?.popUntil((route) => route.isFirst);
    notifyRouteStackChanged(section);
  }

  Future<T?> pushNamed<T extends Object?>(
    AppShellSection section,
    String routeName, {
    Object? arguments,
  }) async {
    selectSection(section);
    final navigator = navigatorFor(section);
    if (navigator == null) return null;
    return navigator.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Seleciona a seção e agenda a rota até o Navigator correspondente existir.
  Future<bool> openDeepLink(Uri uri) async {
    final target = AppDeepLinkParser.parse(uri);
    if (target == null) return false;

    selectSection(target.section);
    if (target.opensSectionRoot) {
      popToRoot(target.section);
      return true;
    }

    final navigator = navigatorFor(target.section);
    if (navigator == null) {
      _pendingDeepLink = target;
      notifyListeners();
      return true;
    }

    unawaited(navigator.pushNamed<void>(target.routeName, arguments: target));
    return true;
  }

  Future<void> flushPendingDeepLink() async {
    final target = _pendingDeepLink;
    if (target == null) return;
    final navigator = navigatorFor(target.section);
    if (navigator == null) return;

    _pendingDeepLink = null;
    unawaited(navigator.pushNamed<void>(target.routeName, arguments: target));
  }

  /// Chamado pelos observers das pilhas para atualizar o tratamento de voltar.
  void notifyRouteStackChanged(AppShellSection section) {
    if (section == _currentSection) notifyListeners();
  }
}

/// Fachada de navegação limitada a uma única feature.
///
/// Controllers de apresentação podem depender desta API sem conhecer índices
/// da Bottom Navigation ou chaves globais.
class SectionNavigationController {
  const SectionNavigationController({
    required this.navigation,
    required this.section,
  });

  final NavigationController navigation;
  final AppShellSection section;

  void show() => navigation.selectSection(section);

  Future<T?> open<T extends Object?>(String routeName, {Object? arguments}) =>
      navigation.pushNamed<T>(section, routeName, arguments: arguments);

  void closeToRoot() => navigation.popToRoot(section);
}
