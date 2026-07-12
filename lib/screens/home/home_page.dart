import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';
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
import '../ai_workout_page.dart';
import '../perfil/agenda_treinos_page.dart';
import '../perfil/evolucao_page.dart';
import '../perfil/notificacoes_page.dart';
import '../treinos/criar_treino_page.dart';
import '../treinos/treino_profissional_page.dart';
import 'widgets/home_dashboard_content.dart';
import 'widgets/home_goal_resolver.dart';

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
    if (atualizarXp != null) await atualizarXp();
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
    final selection = treinoDoDiaService.selecionarTreinoDoDiaDetalhado(
      treinoService.treinos,
      historicoTreinos,
    );
    final streak = streakService.calcularStreak(historicoTreinos);
    final workoutsThisWeek = streakService.treinosNaSemana(historicoTreinos);
    final weeklyXp = streakService.xpTreinosNaSemana(historicoTreinos);
    final lastRecord = HomeGoalResolver.lastRecord(historicoTreinos);

    return Scaffold(
      backgroundColor: FitColors.background,
      body: HomeDashboardContent(
        name: widget.nome,
        level: widget.nivel,
        unreadNotifications: notificacoesNaoLidas,
        selection: selection,
        isLoading: carregandoTreinos,
        distance: widget.distancia,
        steps: widget.passos,
        workoutsThisWeek: workoutsThisWeek,
        weeklyXp: weeklyXp,
        currentStreak: streak.atual,
        rawXp: widget.xp,
        recordCount: lastRecord?.recordesBatidos ?? 0,
        workoutCompletedToday: treinoConcluidoHoje,
        recommendation: recomendacao,
        coachInsightsFuture: _coachInsightsFuture,
        onOpenWorkout: _abrirTreino,
        onCreateWorkout: _abrirCriarTreino,
        onGenerateWithAi: _abrirGeradorIa,
        onOpenNotifications: _abrirNotificacoes,
      ),
    );
  }
}
