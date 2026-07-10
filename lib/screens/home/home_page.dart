import 'package:flutter/material.dart';

import '../../core/xp/xp_config.dart';
import '../../models/coach_insight_model.dart';
import '../../models/fitai_notification_model.dart';
import '../../models/historico_treino_model.dart';
import '../../models/treino_model.dart';
import '../../services/coach_insight_service.dart';
import '../../services/ia_evolutiva_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../services/streak_service.dart';
import '../../services/treino_do_dia_service.dart';
import '../../services/treino_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';
import '../ai_workout_page.dart';
import '../perfil/agenda_treinos_page.dart';
import '../perfil/evolucao_page.dart';
import '../perfil/notificacoes_page.dart';
import '../perfil/widgets/coach_insights_card.dart';
import '../treinos/criar_treino_page.dart';
import '../treinos/treino_profissional_page.dart';
import 'widgets/fitia_recomendacao_card.dart';
import 'widgets/header_home.dart';
import 'widgets/home_stats_row.dart';
import 'widgets/missoes_hoje_card.dart';
import 'widgets/treino_do_dia_card.dart';

class HomePage extends StatefulWidget {
  final String nome;
  final double distancia;
  final int passos;
  final int xp;
  final int nivel;
  final Future<void> Function()? onXpAtualizado;

  const HomePage({
    super.key,
    required this.nome,
    required this.distancia,
    required this.passos,
    required this.xp,
    required this.nivel,
    this.onXpAtualizado,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final treinoService = TreinoService.instance;
  final treinoDoDiaService = const TreinoDoDiaService();
  final streakService = const StreakService();

  bool carregandoTreinos = true;
  bool atualizandoDadosHoje = false;
  bool atualizandoNotificacoes = false;
  bool treinoConcluidoHoje = false;
  int notificacoesNaoLidas = 0;
  List<HistoricoTreinoModel> historicoTreinos = [];
  IaEvolutivaRecomendacao? recomendacao;
  late Future<List<CoachInsightModel>> _coachInsightsFuture;

  @override
  void initState() {
    super.initState();
    _coachInsightsFuture = const CoachInsightService().gerarInsightsGerais();
    treinoService.addListener(_onTreinosAtualizados);
    _carregarDadosHoje();
    _carregarNotificacoes();
  }

  @override
  void dispose() {
    treinoService.removeListener(_onTreinosAtualizados);
    super.dispose();
  }

  void _onTreinosAtualizados() {
    if (!mounted) return;
    _carregarDadosHoje();
  }

  Future<void> _carregarDadosHoje() async {
    if (atualizandoDadosHoje) return;

    atualizandoDadosHoje = true;

    try {
      final historico = await StorageService.carregarHistoricoTreinos();
      final recomendacaoAtual = await IaEvolutivaService.instance
          .gerarRecomendacao(
            treinosDisponiveis: treinoService.treinos,
            historico: historico,
            xpAtual: widget.xp,
            nivelAtual: widget.nivel,
          );
      final concluiuHoje = treinoDoDiaService.existeTreinoConcluidoHoje(
        historico,
      );
      final coachFuture = const CoachInsightService().gerarInsightsGerais();

      if (!mounted) return;

      setState(() {
        treinoConcluidoHoje = concluiuHoje;
        historicoTreinos = historico;
        recomendacao = recomendacaoAtual;
        _coachInsightsFuture = coachFuture;
        carregandoTreinos = false;
      });
      await _carregarNotificacoes();
    } finally {
      atualizandoDadosHoje = false;
    }
  }

  Future<void> _carregarNotificacoes() async {
    if (atualizandoNotificacoes) return;
    atualizandoNotificacoes = true;

    try {
      final total = await const NotificationService().contarNaoLidas();
      if (!mounted) return;
      setState(() => notificacoesNaoLidas = total);
    } finally {
      atualizandoNotificacoes = false;
    }
  }

  Future<void> _abrirTreino(TreinoModel treino) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TreinoProfissionalPage(
          treino: treino,
          onXpAtualizado: widget.onXpAtualizado,
        ),
      ),
    );

    final atualizarXp = widget.onXpAtualizado;
    if (atualizarXp != null) {
      await atualizarXp();
    }

    await _carregarDadosHoje();
  }

  Future<void> _abrirCriarTreino() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CriarTreinoPage()),
    );

    await _carregarDadosHoje();
  }

  Future<void> _abrirGeradorIa() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIWorkoutPage()),
    );

    await _carregarDadosHoje();
  }

  Future<void> _abrirNotificacoes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificacoesPage(onAbrirAcao: _abrirAcaoNotificacao),
      ),
    );

    await _carregarNotificacoes();
  }

  Future<void> _abrirAcaoNotificacao(FitaiNotificationModel notificacao) async {
    final acao = notificacao.acao;

    if (acao.startsWith('treino:')) {
      final treino = await _buscarTreinoPorId(acao.substring(7));
      if (!mounted) return;
      if (treino != null) {
        await _abrirTreino(treino);
        return;
      }
    }

    if (acao == 'agenda') {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AgendaTreinosPage()),
      );
      return;
    }

    if (acao == 'evolucao') {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EvolucaoPage()),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificacao marcada como lida.')),
    );
  }

  Future<TreinoModel?> _buscarTreinoPorId(String id) async {
    for (final treino in treinoService.treinos) {
      if (treino.id == id) return treino;
    }

    final salvos = await StorageService.carregarTreinos();
    for (final treino in salvos) {
      if (treino.id == id) return treino;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selecaoTreino = treinoDoDiaService.selecionarTreinoDoDiaDetalhado(
      treinoService.treinos,
      historicoTreinos,
    );
    final streak = streakService.calcularStreak(historicoTreinos);
    final treinosSemana = streakService.treinosNaSemana(historicoTreinos);
    final xpSemana = streakService.xpTreinosNaSemana(historicoTreinos);
    final ultimoRecorde = _ultimoRecorde(historicoTreinos);
    final proximoObjetivo = _proximoObjetivo(selecaoTreino, xpSemana);
    const cardGap = 16.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: HeaderHome(
              nome: widget.nome,
              nivel: widget.nivel,
              notificacoesNaoLidas: notificacoesNaoLidas,
              onAbrirNotificacoes: _abrirNotificacoes,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              _horizontalPadding(context),
              0,
              _horizontalPadding(context),
              100,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                AppAnimatedEntrance(
                  index: 0,
                  child: TreinoDoDiaCard(
                    selecao: selecaoTreino,
                    carregandoTreinos: carregandoTreinos,
                    onAbrirTreino: _abrirTreino,
                    onCriarTreino: _abrirCriarTreino,
                    onGerarIa: _abrirGeradorIa,
                  ),
                ),
                const SizedBox(height: cardGap),
                AppAnimatedEntrance(
                  index: 1,
                  child: _HomeQuickActionsPanel(
                    selecao: selecaoTreino,
                    onAbrirTreino: _abrirTreino,
                    onCriarTreino: _abrirCriarTreino,
                    onGerarIa: _abrirGeradorIa,
                  ),
                ),
                const SizedBox(height: cardGap),
                AppAnimatedEntrance(
                  index: 2,
                  child: _HomeEvolutionPanel(
                    xp: widget.xp,
                    nivel: widget.nivel,
                    streak: streak,
                    ultimoRecorde: ultimoRecorde,
                    proximoObjetivo: proximoObjetivo,
                  ),
                ),
                const SizedBox(height: cardGap),
                AppAnimatedEntrance(
                  index: 3,
                  child: FitiaRecomendacaoCard(
                    selecao: selecaoTreino,
                    recomendacao: recomendacao,
                    carregandoTreinos: carregandoTreinos,
                  ),
                ),
                const SizedBox(height: cardGap),
                AppAnimatedEntrance(
                  index: 4,
                  child: _HomeCoachInsightsPanel(future: _coachInsightsFuture),
                ),
                const SizedBox(height: cardGap),
                AppAnimatedEntrance(
                  index: 5,
                  child: HomeStatsRow(
                    distancia: widget.distancia,
                    passos: widget.passos,
                  ),
                ),
                const SizedBox(height: cardGap),
                AppAnimatedEntrance(
                  index: 6,
                  child: MissoesHojeCard(
                    treinoConcluidoHoje: treinoConcluidoHoje,
                    passos: widget.passos,
                    treinosSemana: treinosSemana,
                    xpSemana: xpSemana,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }

  HistoricoTreinoModel? _ultimoRecorde(List<HistoricoTreinoModel> historico) {
    final registros =
        historico.where((item) => item.recordesBatidos > 0).toList()
          ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

    if (registros.isEmpty) return null;
    return registros.first;
  }

  _ObjetivoHome _proximoObjetivo(TreinoDoDiaSelecao selecao, int xpSemana) {
    if (selecao.treino == null) {
      return const _ObjetivoHome(
        titulo: 'Criar plano',
        detalhe: 'Monte sua primeira ficha',
        progresso: 0,
        icon: Icons.add_task_rounded,
        color: AppColors.primary,
      );
    }

    if (!selecao.treinoConcluidoHoje && !selecao.diaDeDescanso) {
      return const _ObjetivoHome(
        titulo: 'Treino do dia',
        detalhe: 'Concluir 1 sessão hoje',
        progresso: 0.35,
        icon: Icons.play_circle_fill_rounded,
        color: AppColors.primary,
      );
    }

    if (widget.passos < 8000) {
      return _ObjetivoHome(
        titulo: '8.000 passos',
        detalhe: '${widget.passos}/8000 hoje',
        progresso: widget.passos / 8000,
        icon: Icons.directions_walk_rounded,
        color: AppColors.accent1,
      );
    }

    if (xpSemana < 200) {
      return _ObjetivoHome(
        titulo: '200 XP semana',
        detalhe: '$xpSemana/200 XP',
        progresso: xpSemana / 200,
        icon: Icons.bolt_rounded,
        color: AppColors.accent2,
      );
    }

    return const _ObjetivoHome(
      titulo: 'Recuperar bem',
      detalhe: 'Sono, mobilidade e constância',
      progresso: 1,
      icon: Icons.self_improvement_rounded,
      color: AppColors.accent3,
    );
  }
}

class _HomeCoachInsightsPanel extends StatelessWidget {
  final Future<List<CoachInsightModel>> future;

  const _HomeCoachInsightsPanel({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CoachInsightModel>>(
      future: future,
      builder: (context, snapshot) {
        final insights = (snapshot.data ?? const <CoachInsightModel>[])
            .take(3)
            .toList();

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppGradientCard(
            child: LinearProgressIndicator(minHeight: 3),
          );
        }

        return CoachInsightsCard(insights: insights);
      },
    );
  }
}

class _HomeQuickActionsPanel extends StatelessWidget {
  final TreinoDoDiaSelecao selecao;
  final Future<void> Function(TreinoModel treino) onAbrirTreino;
  final Future<void> Function() onCriarTreino;
  final Future<void> Function() onGerarIa;

  const _HomeQuickActionsPanel({
    required this.selecao,
    required this.onAbrirTreino,
    required this.onCriarTreino,
    required this.onGerarIa,
  });

  @override
  Widget build(BuildContext context) {
    final treino = selecao.treino;
    final podeIniciar = treino != null && !selecao.diaDeDescanso;

    return AppCard(
      padding: const EdgeInsets.all(18),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.surfaceVariant,
          AppColors.surface,
          AppColors.primary.withAlpha(18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withAlpha(34)),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Central FITAI',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Ações rápidas para continuar sua evolução.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (podeIniciar)
                AppButton.primary(
                  label: 'Iniciar agora',
                  icon: Icons.play_arrow_rounded,
                  compact: true,
                  fullWidth: false,
                  onPressed: () {
                    onAbrirTreino(treino);
                  },
                ),
              AppButton.secondary(
                label: 'Gerar IA',
                icon: Icons.psychology_alt_rounded,
                compact: true,
                fullWidth: false,
                onPressed: () {
                  onGerarIa();
                },
              ),
              AppButton.ghost(
                label: 'Novo plano',
                icon: Icons.add_rounded,
                compact: true,
                fullWidth: false,
                onPressed: () {
                  onCriarTreino();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeEvolutionPanel extends StatelessWidget {
  final int xp;
  final int nivel;
  final StreakResumo streak;
  final HistoricoTreinoModel? ultimoRecorde;
  final _ObjetivoHome proximoObjetivo;

  const _HomeEvolutionPanel({
    required this.xp,
    required this.nivel,
    required this.streak,
    required this.ultimoRecorde,
    required this.proximoObjetivo,
  });

  @override
  Widget build(BuildContext context) {
    final xpParaProximoNivel = XpConfig.xpParaProximoNivel(nivel);
    final xpNoNivel = XpConfig.normalizarXp(
      xp,
    ).clamp(0, xpParaProximoNivel).toInt();

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EVOLUÇÃO DE HOJE',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Seu ritmo, progresso e próximo foco.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppMetricWrap(
            minTileWidth: 136,
            children: [
              _PulseTile(
                icon: Icons.bolt_rounded,
                title: 'XP',
                value: '$xpNoNivel/$xpParaProximoNivel',
                detail: 'Nível $nivel',
                progress: xpNoNivel / xpParaProximoNivel,
                color: AppColors.primary,
              ),
              _PulseTile(
                icon: Icons.local_fire_department_rounded,
                title: 'Sequência',
                value: '${streak.atual} dias',
                detail: 'Melhor: ${streak.melhor}',
                progress: streak.atual <= 0 ? 0 : (streak.atual / 7),
                color: AppColors.accent2,
              ),
              _PulseTile(
                icon: Icons.emoji_events_rounded,
                title: 'Último PR',
                value: ultimoRecorde == null
                    ? 'Sem PR'
                    : '+${ultimoRecorde!.recordesBatidos}',
                detail: ultimoRecorde == null
                    ? 'Registre no treino'
                    : _formatarDataCurta(ultimoRecorde!.dataHora),
                progress: ultimoRecorde == null ? 0 : 1,
                color: AppColors.accent3,
              ),
              _PulseTile(
                icon: proximoObjetivo.icon,
                title: 'Próximo objetivo',
                value: proximoObjetivo.titulo,
                detail: proximoObjetivo.detalhe,
                progress: proximoObjetivo.progresso,
                color: proximoObjetivo.color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatarDataCurta(DateTime data) {
    final local = data.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');

    return '$dia/$mes';
  }
}

class _PulseTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final double progress;
  final Color color;

  const _PulseTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0).toDouble();

    return AnimatedContainer(
      duration: AppMotion.normal,
      curve: AppMotion.curve,
      constraints: const BoxConstraints(minHeight: 138),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 5,
              backgroundColor: Colors.white.withAlpha(18),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjetivoHome {
  final String titulo;
  final String detalhe;
  final double progresso;
  final IconData icon;
  final Color color;

  const _ObjetivoHome({
    required this.titulo,
    required this.detalhe,
    required this.progresso,
    required this.icon,
    required this.color,
  });
}
