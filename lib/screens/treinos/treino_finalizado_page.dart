import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class TreinoFinalizadoPage extends StatelessWidget {
  final String tempo;
  final String volume;
  final int xp;
  final int recordes;
  final int conquistas;
  final String resumoIa;
  final VoidCallback? onVoltar;
  final VoidCallback? onCompartilhar;

  const TreinoFinalizadoPage({
    super.key,
    required this.tempo,
    required this.volume,
    required this.xp,
    this.recordes = 0,
    this.conquistas = 0,
    this.resumoIa =
        'Treino concluido com sucesso. Mantenha a consistencia para evoluir nas proximas sessoes.',
    this.onVoltar,
    this.onCompartilhar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _hero(context)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              _horizontalPadding(context),
              0,
              _horizontalPadding(context),
              120,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: _metricsGrid(context),
                ),
                const SizedBox(height: 2),
                _resumoIaCard(),
                const SizedBox(height: 18),
                _statusCard(),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(
          _horizontalPadding(context),
          10,
          _horizontalPadding(context),
          18,
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onVoltar ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Voltar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    onCompartilhar ?? () => _mostrarCompartilhar(context),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Compartilhar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return SizedBox(
      height: 340,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.gradientPrimary),
          ),
          Positioned(
            right: -42,
            top: 78,
            child: Icon(
              Icons.emoji_events_rounded,
              color: Colors.black.withAlpha(42),
              size: 220,
            ),
          ),
          Positioned(
            left: -70,
            bottom: -90,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withAlpha(18),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withAlpha(28),
                  AppColors.background.withAlpha(246),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _horizontalPadding(context),
                20,
                _horizontalPadding(context),
                34,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filledTonal(
                      onPressed:
                          onVoltar ?? () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'TREINO FINALIZADO',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Excelente trabalho',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      height: .98,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Seu treino foi salvo e sua evolucao acabou de ganhar mais um ponto.',
                    style: TextStyle(
                      color: Colors.black87,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        final spacing = columns == 4 ? 12.0 : 10.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.timer_rounded,
                label: 'Tempo',
                value: tempo,
                color: AppColors.primary,
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.monitor_weight_rounded,
                label: 'Volume',
                value: volume,
                color: AppColors.accent1,
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.bolt_rounded,
                label: 'XP',
                value: '+$xp',
                color: AppColors.accent3,
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.emoji_events_rounded,
                label: 'Recordes',
                value: '$recordes',
                color: AppColors.rankOuro,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _resumoIaCard() {
    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(28),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumo IA',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  resumoIa,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _StatusRow(
            icon: Icons.workspace_premium_rounded,
            label: 'Conquistas desbloqueadas',
            value: '$conquistas',
          ),
          const SizedBox(height: 12),
          _StatusRow(
            icon: Icons.trending_up_rounded,
            label: 'Proximo passo',
            value: recordes > 0 ? 'Manter evolucao' : 'Nova sessao',
          ),
        ],
      ),
    );
  }

  void _mostrarCompartilhar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resumo pronto para compartilhar.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1080) return 72;
    if (width >= 720) return 36;
    return 20;
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withAlpha(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(42),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
