import 'package:flutter/material.dart';

import '../../../../../design_system/extensions/context_extensions.dart';
import '../../../../../design_system/tokens/fit_icons.dart';
import '../../../../../design_system/tokens/fit_layout.dart';
import '../../../../../design_system/tokens/fit_opacity.dart';
import '../../../../../design_system/tokens/fit_spacing.dart';
import '../../buttons/buttons.dart';
import '../../cards/cards.dart';
import '../../common/common.dart';
import '../../inputs/inputs.dart';
import '../shared/fit_domain_models.dart';
import '../shared/fit_domain_primitives.dart';

/// Destaque principal de uma oferta Premium.
class FitPremiumHeroCard extends StatelessWidget {
  const FitPremiumHeroCard({
    super.key,
    required this.title,
    required this.description,
    this.media,
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null));

  final String title;
  final String description;
  final Widget? media;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return FitDomainContentCard(
      title: title,
      subtitle: description,
      icon: FitIcons.premium,
      accent: context.fitColors.premium,
      media: media,
      tags: const [FitPremiumBadge()],
      footer: onAction == null
          ? null
          : FitPrimaryButton(
              label: actionLabel!,
              icon: FitIcons.premium,
              onPressed: onAction,
              fullWidth: true,
            ),
    );
  }
}

/// Benefício incluído em uma oferta Premium.
class FitPremiumBenefitTile extends StatelessWidget {
  const FitPremiumBenefitTile({
    super.key,
    required this.title,
    required this.icon,
    this.description,
    this.included = true,
  });

  final String title;
  final String? description;
  final IconData icon;
  final bool included;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: title,
      subtitle: description,
      leading: Icon(
        icon,
        color: included
            ? context.fitColors.premium
            : context.colors.onSurfaceVariant,
      ),
      trailing: Icon(
        included ? FitIcons.check : FitIcons.remove,
        color: included ? context.colors.primary : context.colors.error,
      ),
      semanticLabel: '$title, ${included ? 'incluído' : 'não incluído'}',
    );
  }
}

/// Linha comparativa entre modalidades.
class FitPremiumComparisonRow extends StatelessWidget {
  const FitPremiumComparisonRow({
    super.key,
    required this.feature,
    required this.freeLabel,
    required this.premiumLabel,
  });

  final String feature;
  final String freeLabel;
  final String premiumLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$feature, gratuito: $freeLabel, premium: $premiumLabel',
      child: Row(
        children: [
          Expanded(child: Text(feature)),
          Expanded(
            child: Text(
              freeLabel,
              textAlign: TextAlign.center,
              style: context.textTheme.labelMedium,
            ),
          ),
          Expanded(
            child: Text(
              premiumLabel,
              textAlign: TextAlign.end,
              style: context.textTheme.labelMedium?.copyWith(
                color: context.fitColors.premium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plano de assinatura; compra e seleção pertencem ao chamador.
class FitSubscriptionPlanCard extends StatelessWidget {
  const FitSubscriptionPlanCard({
    super.key,
    required this.name,
    required this.priceLabel,
    this.description,
    this.billingLabel,
    this.badgeLabel,
    this.features = const [],
    this.selected = false,
    this.enabled = true,
    this.onTap,
  });

  final String name;
  final String priceLabel;
  final String? description;
  final String? billingLabel;
  final String? badgeLabel;
  final List<String> features;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled
          ? FitLayout.navigationSelectedScale
          : FitOpacity.disabled,
      child: FitCard(
        title: name,
        subtitle: description,
        selected: selected,
        onTap: enabled ? onTap : null,
        trailing: badgeLabel == null
            ? null
            : FitPremiumBadge(label: badgeLabel!),
        semanticLabel: '$name, $priceLabel${selected ? ', selecionado' : ''}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              priceLabel,
              style: context.textTheme.headlineSmall?.copyWith(
                color: context.fitColors.premium,
              ),
            ),
            if (billingLabel != null)
              Text(billingLabel!, style: context.textTheme.bodySmall),
            if (features.isNotEmpty) ...[
              const SizedBox(height: FitSpacing.s12),
              for (final feature in features)
                Padding(
                  padding: const EdgeInsets.only(bottom: FitSpacing.s8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(FitIcons.check, color: context.colors.primary),
                      const SizedBox(width: FitSpacing.s8),
                      Expanded(child: Text(feature)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Badge visual de acesso Premium.
class FitPremiumBadge extends StatelessWidget {
  const FitPremiumBadge({super.key, this.label = 'Premium'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return FitDomainStatusBadge(
      label: label,
      tone: FitDomainTone.premium,
      icon: FitIcons.premium,
    );
  }
}

/// Membro de um grupo ou plano familiar.
class FitFamilyMemberCard extends StatelessWidget {
  const FitFamilyMemberCard({
    super.key,
    required this.name,
    this.email,
    this.avatar,
    this.statusLabel,
    this.trailing,
    this.onTap,
  });

  final String name;
  final String? email;
  final Widget? avatar;
  final String? statusLabel;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: name,
      subtitle: email,
      leading: avatar ?? FitAvatar(name: name),
      trailing:
          trailing ??
          (statusLabel == null
              ? const Icon(FitIcons.forward)
              : FitDomainStatusBadge(
                  label: statusLabel!,
                  tone: FitDomainTone.neutral,
                )),
      onTap: onTap,
    );
  }
}

/// Registro visual de cobrança; nenhum pagamento é iniciado aqui.
class FitPaymentHistoryRow extends StatelessWidget {
  const FitPaymentHistoryRow({
    super.key,
    required this.title,
    required this.amountLabel,
    this.dateLabel,
    this.statusLabel,
    this.onTap,
  });

  final String title;
  final String amountLabel;
  final String? dateLabel;
  final String? statusLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitListTile(
      title: title,
      subtitle: dateLabel,
      leading: Icon(FitIcons.payment, color: context.fitColors.premium),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(amountLabel, style: context.textTheme.titleSmall),
          if (statusLabel != null)
            Text(statusLabel!, style: context.textTheme.labelSmall),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Campo de cupom controlado externamente.
class FitCouponField extends StatelessWidget {
  const FitCouponField({
    super.key,
    required this.controller,
    this.label = 'Cupom',
    this.hintText,
    this.errorText,
    this.loading = false,
    this.enabled = true,
    this.onChanged,
    this.onApply,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? errorText;
  final bool loading;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    return FitTextField(
      controller: controller,
      label: label,
      hintText: hintText,
      errorText: errorText,
      isLoading: loading,
      enabled: enabled,
      onChanged: onChanged,
      prefixIcon: const Icon(FitIcons.coupon),
      suffixIcon: FitIconButton(
        icon: FitIcons.check,
        tooltip: 'Aplicar cupom',
        onPressed: onApply,
        enabled: enabled,
      ),
    );
  }
}

/// Ação visual para restaurar compra; integração pertence ao chamador.
class FitRestorePurchaseCard extends StatelessWidget {
  const FitRestorePurchaseCard({
    super.key,
    this.title = 'Restaurar compra',
    this.description = 'Recupere uma assinatura vinculada à sua conta.',
    this.loading = false,
    this.onRestore,
  });

  final String title;
  final String description;
  final bool loading;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return FitInfoCard(
      title: title,
      description: description,
      icon: FitIcons.retry,
      action: FitLoadingButton(
        label: 'Restaurar',
        loading: loading,
        onPressed: onRestore,
      ),
    );
  }
}
