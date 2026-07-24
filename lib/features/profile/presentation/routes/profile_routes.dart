import 'package:flutter/widgets.dart';

import '../../../../core/navigation/app_section.dart';
import '../../../../core/navigation/section_router.dart';

/// Rotas oficiais e reservadas de Perfil.
abstract final class ProfileRoutes {
  static const root = '/profile';
  static const edit = '/profile/edit';
  static const evolution = '/profile/evolution';
  static const measurements = '/profile/measurements';
  static const records = '/profile/records';
  static const statistics = '/profile/statistics';
  static const healthConnect = '/profile/health-connect';
  static const premium = '/profile/premium';
  static const settings = '/profile/settings';
  static const account = '/profile/account';
  static const privacy = '/profile/privacy';

  static const declared = <String>{
    root,
    edit,
    evolution,
    measurements,
    records,
    statistics,
    healthConnect,
    premium,
    settings,
    account,
    privacy,
  };

  static SectionRouter createRouter({required WidgetBuilder rootBuilder}) {
    return SectionRouter(
      section: AppShellSection.profile,
      rootBuilder: rootBuilder,
      declaredRoutes: declared,
    );
  }
}
