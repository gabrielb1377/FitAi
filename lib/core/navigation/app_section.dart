import 'package:flutter/material.dart';

import '../../design_system/tokens/fit_icons.dart';

/// Destinos raiz oficiais do FitIA, na mesma ordem da barra inferior.
enum AppShellSection {
  home(
    label: 'Home',
    slug: 'home',
    rootRoute: '/home',
    icon: FitIcons.homeOutlined,
    selectedIcon: FitIcons.home,
  ),
  plans(
    label: 'Planos',
    slug: 'planos',
    rootRoute: '/plans',
    icon: FitIcons.plansOutlined,
    selectedIcon: FitIcons.plans,
  ),
  activities(
    label: 'Atividades',
    slug: 'atividades',
    rootRoute: '/activities',
    icon: FitIcons.activitiesOutlined,
    selectedIcon: FitIcons.activities,
  ),
  library(
    label: 'Biblioteca',
    slug: 'biblioteca',
    rootRoute: '/library',
    icon: FitIcons.libraryOutlined,
    selectedIcon: FitIcons.library,
  ),
  profile(
    label: 'Perfil',
    slug: 'perfil',
    rootRoute: '/profile',
    icon: FitIcons.profileOutlined,
    selectedIcon: FitIcons.profile,
  );

  const AppShellSection({
    required this.label,
    required this.slug,
    required this.rootRoute,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final String slug;
  final String rootRoute;
  final IconData icon;
  final IconData selectedIcon;

  /// Resolve índices externos sem permitir acesso inválido à lista.
  static AppShellSection? fromIndex(int index) {
    if (index < 0 || index >= values.length) return null;
    return values[index];
  }

  /// Aceita os nomes públicos em português e os paths internos em inglês.
  static AppShellSection? fromSlug(String value) {
    final normalized = value.trim().toLowerCase();
    for (final section in values) {
      if (normalized == section.slug ||
          normalized == section.name ||
          normalized == section.rootRoute.substring(1)) {
        return section;
      }
    }
    return null;
  }
}
