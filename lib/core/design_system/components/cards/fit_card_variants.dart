import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_card.dart';

/// Card com elevação sutil para conteúdo que precisa se destacar do fundo.
class FitElevatedCard extends FitCard {
  const FitElevatedCard({
    super.key,
    required super.child,
    super.title,
    super.subtitle,
    super.header,
    super.footer,
    super.leading,
    super.trailing,
    super.padding,
    super.onTap,
    super.elevation = 1,
    super.color,
    super.borderColor,
    super.selected,
    super.semanticLabel,
  }) : super(variant: FitCardVariant.elevated);
}

/// Card delimitado por borda para agrupamentos de baixa elevação.
class FitOutlinedCard extends FitCard {
  const FitOutlinedCard({
    super.key,
    required super.child,
    super.title,
    super.subtitle,
    super.header,
    super.footer,
    super.leading,
    super.trailing,
    super.padding,
    super.onTap,
    super.color,
    super.borderColor,
    super.selected,
    super.semanticLabel,
  }) : super(variant: FitCardVariant.outlined);
}

/// Card de seção com título obrigatório e ação contextual opcional.
class FitSectionCard extends FitCard {
  const FitSectionCard({
    super.key,
    required super.title,
    required super.child,
    super.subtitle,
    Widget? action,
    super.footer,
    super.padding,
    super.onTap,
    super.color,
    super.semanticLabel,
  }) : super(
         trailing: action,
         variant: onTap == null
             ? FitCardVariant.standard
             : FitCardVariant.clickable,
       );
}
