import 'package:flutter/material.dart';
import '../../models/achievement_model.dart';
import '../../services/achievement_service.dart';
import '../../theme/app_theme.dart';
import 'agenda_treinos_page.dart';
import 'calendario_treinos_page.dart';
import 'edit_profile_page.dart';
import 'conquistas_page.dart';
import 'evolucao_page.dart';
import 'metas_page.dart';
import 'perfil_ia_page.dart';
import 'recordes_page.dart';
import '../../services/storage_service.dart';

class PerfilPage extends StatelessWidget {
  final String nome;
  final String peso;
  final String altura;
  final String idade;
  final int nivel;
  final bool conquistaPrimeiraCorrida;
  final bool conquista10Km;
  final Future<void> Function()? onPerfilAtualizado;

  const PerfilPage({
    super.key,
    required this.nome,
    required this.peso,
    required this.altura,
    required this.idade,
    required this.nivel,
    required this.conquistaPrimeiraCorrida,
    required this.conquista10Km,
    this.onPerfilAtualizado,
  });

  String rankAtual() {
    if (nivel >= 50) return '💎 Diamante';
    if (nivel >= 30) return '🏆 Platina';
    if (nivel >= 20) return '🥇 Ouro';
    if (nivel >= 10) return '🥈 Prata';
    return '🥉 Bronze';
  }

  int get conquistasDesbloqueadas {
    int count = 0;
    if (conquistaPrimeiraCorrida) count++;
    if (conquista10Km) count++;
    if (nivel >= 5) count++;
    if (nivel >= 10) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHero(context)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              _horizontalPadding(context),
              0,
              _horizontalPadding(context),
              100,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                // Stats rápidos
                _buildStatsRow(context),
                const SizedBox(height: 20),

                // Informações
                AppSection(
                  title: 'Informações',
                  child: _buildInfoCard(context),
                ),
                const SizedBox(height: 20),

                // Ações
                AppSection(title: 'Conta', child: _buildAcoesCard(context)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        _horizontalPadding(context),
        MediaQuery.of(context).padding.top + 20,
        _horizontalPadding(context),
        28,
      ),
      child: AppGradientCard(
        gradient: AppColors.gradientPrimary,
        child: Row(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(22),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  nome.isNotEmpty ? nome[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "PERFIL FITIA",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(24),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      rankAtual(),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }

  Widget _buildStatsRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 680
            ? (constraints.maxWidth - 24) / 3
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildStatItem(
                context,
                label: 'Nível',
                value: '$nivel',
                icon: Icons.bolt,
                color: AppColors.primary,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: FutureBuilder<List<AchievementModel>>(
                future: const AchievementService().carregarConquistas(),
                builder: (context, snapshot) {
                  final conquistas =
                      snapshot.data ?? const <AchievementModel>[];
                  final desbloqueadas = conquistas
                      .where((conquista) => conquista.desbloqueada)
                      .length;

                  return _buildStatItem(
                    context,
                    label: 'Conquistas',
                    value: snapshot.connectionState == ConnectionState.done
                        ? '$desbloqueadas'
                        : '$conquistasDesbloqueadas',
                    icon: Icons.emoji_events_outlined,
                    color: const Color(0xFFFFD700),
                  );
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildStatItem(
                context,
                label: 'Idade',
                value: idade,
                icon: Icons.calendar_today_outlined,
                color: AppColors.accent1,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return AppGradientCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildInfoTile(
            context,
            icon: Icons.monitor_weight_outlined,
            label: 'Peso',
            value: peso,
            isFirst: true,
          ),
          const Divider(height: 1, indent: 56),
          _buildInfoTile(
            context,
            icon: Icons.height_rounded,
            label: 'Altura',
            value: altura,
          ),
          const Divider(height: 1, indent: 56),
          _buildInfoTile(
            context,
            icon: Icons.cake_outlined,
            label: 'Idade',
            value: '$idade anos',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcoesCard(BuildContext context) {
    return AppGradientCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildAcaoTile(
            context,
            icon: Icons.edit_outlined,
            label: 'Editar Perfil',
            color: AppColors.primary,
            isFirst: true,
            onTap: () async {
              final resultado = await Navigator.push<Map<String, String>>(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );

              if (resultado == null) return;

              await StorageService.salvarPerfilUsuario(
                nome: resultado['nome'] ?? nome,
                peso: resultado['peso'] ?? peso,
                altura: resultado['altura'] ?? altura,
                idade: resultado['idade'] ?? idade,
              );

              await onPerfilAtualizado?.call();

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Perfil salvo com sucesso!')),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildAcaoTile(
            context,
            icon: Icons.psychology_rounded,
            label: 'Meu Perfil IA',
            color: AppColors.accent3,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PerfilIAPage(
                    nome: nome,
                    idade: idade,
                    peso: peso,
                    altura: altura,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildAcaoTile(
            context,
            icon: Icons.emoji_events_outlined,
            label: 'Ver Conquistas',
            color: const Color(0xFFFFD700),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConquistasPage()),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildAcaoTile(
            context,
            icon: Icons.military_tech_rounded,
            label: 'Recordes Pessoais',
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecordesPage()),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildAcaoTile(
            context,
            icon: Icons.auto_graph_rounded,
            label: 'Evolução',
            color: AppColors.accent1,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EvolucaoPage()),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildAcaoTile(
            context,
            icon: Icons.flag_rounded,
            label: 'Metas',
            color: Colors.greenAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MetasPage()),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildAcaoTile(
            context,
            icon: Icons.calendar_month_rounded,
            label: 'Agenda de Treinos',
            color: AppColors.accent2,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AgendaTreinosPage()),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildAcaoTile(
            context,
            icon: Icons.event_available_rounded,
            label: 'Calendário de Treinos',
            color: AppColors.primary,
            isLast: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CalendarioTreinosPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAcaoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
