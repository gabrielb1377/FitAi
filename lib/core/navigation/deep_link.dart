import 'package:flutter/foundation.dart';

import 'app_section.dart';

/// Destino validado de um deep link, ainda sem executar navegação.
@immutable
class AppDeepLinkTarget {
  const AppDeepLinkTarget({
    required this.uri,
    required this.section,
    required this.routeName,
  });

  final Uri uri;
  final AppShellSection section;
  final String routeName;

  bool get opensSectionRoot => routeName == section.rootRoute;
}

/// Parser puro para links `fitia://` e caminhos web.
///
/// A autenticação continua responsável por decidir quando um link pode ser
/// entregue ao shell.
abstract final class AppDeepLinkParser {
  static AppDeepLinkTarget? parse(Uri uri) {
    final segments = <String>[
      if (uri.scheme == 'fitia' && uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments,
    ].where((segment) => segment.trim().isNotEmpty).toList();
    if (segments.isEmpty) return null;

    final section = AppShellSection.fromSlug(segments.first);
    if (section == null) return null;

    final suffix = segments.skip(1).map(Uri.decodeComponent).join('/');
    final routeName = suffix.isEmpty
        ? section.rootRoute
        : '${section.rootRoute}/$suffix';
    return AppDeepLinkTarget(uri: uri, section: section, routeName: routeName);
  }
}
