import 'package:flutter/material.dart';

import '../../../design_system/fit_design_system.dart';
import '../domain_showcase_scaffold.dart';

/// Catálogo visual dos componentes do domínio Premium.
class PremiumDomainShowcasePage extends StatefulWidget {
  const PremiumDomainShowcasePage({super.key});

  @override
  State<PremiumDomainShowcasePage> createState() =>
      _PremiumDomainShowcasePageState();
}

class _PremiumDomainShowcasePageState extends State<PremiumDomainShowcasePage> {
  final _coupon = TextEditingController();

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DomainShowcaseScaffold(
      title: 'Premium',
      children: [
        const FitPremiumHeroCard(
          title: 'FitIA Premium',
          description: 'Recursos avançados para sua evolução.',
          actionLabel: 'Conhecer Premium',
          onAction: _noop,
        ),
        const FitPremiumBenefitTile(
          title: 'Coach ilimitado',
          description: 'Insights personalizados',
          icon: FitIcons.coach,
        ),
        const FitPremiumComparisonRow(
          feature: 'Planos com IA',
          freeLabel: '1/mês',
          premiumLabel: 'Ilimitado',
        ),
        const FitSubscriptionPlanCard(
          name: 'Anual',
          priceLabel: 'R\$ 149,90',
          billingLabel: 'por ano',
          badgeLabel: 'Melhor valor',
          features: ['Coach ilimitado', 'Planos avançados'],
          selected: true,
          onTap: _noop,
        ),
        const FitPremiumBadge(),
        const FitFamilyMemberCard(
          name: 'Gabriel',
          email: 'gabriel@fitia.dev',
          statusLabel: 'Titular',
          onTap: _noop,
        ),
        const FitPaymentHistoryRow(
          title: 'FitIA Premium Anual',
          amountLabel: 'R\$ 149,90',
          dateLabel: '24 de julho',
          statusLabel: 'Pago',
          onTap: _noop,
        ),
        FitCouponField(
          controller: _coupon,
          hintText: 'Digite o código',
          onApply: _noop,
        ),
        const FitRestorePurchaseCard(onRestore: _noop),
        const FitSubscriptionPlanCard(
          name: 'Mensal indisponível',
          priceLabel: 'R\$ 24,90',
          enabled: false,
          onTap: _noop,
        ),
        const DomainShowcaseStates(emptyTitle: 'Sem ofertas'),
      ],
    );
  }
}

void _noop() {}
