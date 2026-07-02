import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';
import 'historico_corridas_page.dart';

class CorridasPage extends StatelessWidget {
  final double distancia;
  final double velocidadeMedia;
  final int segundos;
  final bool corridaIniciada;
  final VoidCallback iniciarCorrida;
  final VoidCallback pararCorrida;

  const CorridasPage({
    super.key,
    required this.distancia,
    required this.velocidadeMedia,
    required this.segundos,
    required this.corridaIniciada,
    required this.iniciarCorrida,
    required this.pararCorrida,
  });

  String _formatTempo() {
    final h = segundos ~/ 3600;
    final m = (segundos % 3600) ~/ 60;
    final s = segundos % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SliverToBoxAdapter(child: _buildHeader(context)),

          // â”€â”€ ConteÃºdo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                // Metric principal â€” distÃ¢ncia
                _buildMainMetric(context),
                const SizedBox(height: 16),

                // Stats secundÃ¡rios â€” tempo e velocidade
                _buildSecondaryStats(context),
                const SizedBox(height: 32),

                // BotÃ£o principal
                _buildRunButton(context),
                const SizedBox(height: 14),

                // HistÃ³rico
                _buildHistoricoButton(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 20,
        20,
        24,
      ),
      child: AppPremiumHeader(
        eyebrow: corridaIniciada ? "Em andamento" : "Pronto para correr?",
        title: "Corridas",
        subtitle: "Controle tempo, distancia e ritmo em uma experiencia limpa.",
        icon: Icons.directions_run_rounded,
        gradient: corridaIniciada
            ? AppColors.gradientRun
            : AppColors.gradientPrimary,
        trailing: corridaIniciada ? const _LiveBadge() : null,
      ),
    );
  }

  Widget _buildMainMetric(BuildContext context) {
    return AppGradientCard(
      gradient: corridaIniciada
          ? AppColors.gradientRun
          : AppColors.gradientCard,
      child: Column(
        children: [
          Text(
            'DISTÃ‚NCIA',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: corridaIniciada ? Colors.white60 : null,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                distancia.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  color: corridaIniciada ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 6),
                child: Text(
                  'km',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: corridaIniciada
                        ? Colors.white60
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            label: 'TEMPO',
            value: _formatTempo(),
            icon: Icons.timer_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            label: 'VELOCIDADE',
            value: '${velocidadeMedia.toStringAsFixed(1)} km/h',
            icon: Icons.speed_outlined,
            iconColor: AppColors.accent2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton(BuildContext context) {
    final isRunning = corridaIniciada;
    return isRunning
        ? AppButton.danger(
            onPressed: pararCorrida,
            icon: Icons.stop_rounded,
            label: "Parar Corrida",
          )
        : AppButton.primary(
            onPressed: iniciarCorrida,
            icon: Icons.play_arrow_rounded,
            label: "Iniciar Corrida",
          );
  }

  Widget _buildHistoricoButton(BuildContext context) {
    return AppButton.secondary(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoricoCorridasPage()),
        );
      },
      icon: Icons.history_rounded,
      label: 'Ver Historico',
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(24),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFF1744),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            "AO VIVO",
            style: TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
