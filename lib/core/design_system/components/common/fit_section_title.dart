import '../../../../design_system/components/fit_section_header.dart';

/// Título de seção com subtítulo, badge ou ação opcional.
class FitSectionTitle extends FitSectionHeader {
  const FitSectionTitle({
    super.key,
    required super.title,
    super.subtitle,
    super.action,
    super.badge,
    super.onViewAll,
    super.viewAllLabel,
  });
}
