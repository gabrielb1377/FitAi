import 'dart:async';

import 'package:flutter/material.dart';

import '../models/achievement_model.dart';
import '../models/corrida_model.dart';
import '../models/passos_diarios_model.dart';
import '../services/achievement_service.dart';
import '../services/fitai_coach_service.dart';
import '../services/running_session_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';
import 'corridas/historico_corridas_page.dart';

enum _EstadoCorrida { naoIniciada, contagem, emAndamento, pausada, finalizada }

class AtividadesPage extends StatefulWidget {
  final int passos;
  final double distancia;
  final double velocidadeMedia;
  final int segundos;
  final bool corridaIniciada;
  final VoidCallback iniciarCorrida;
  final VoidCallback pararCorrida;

  const AtividadesPage({
    super.key,
    required this.passos,
    required this.distancia,
    required this.velocidadeMedia,
    required this.segundos,
    required this.corridaIniciada,
    required this.iniciarCorrida,
    required this.pararCorrida,
  });

  @override
  State<AtividadesPage> createState() => _AtividadesPageState();
}

class _AtividadesPageState extends State<AtividadesPage> {
  final runningSession = RunningSessionService.instance;

  int _metaPassosDiaria = 10000;
  int _metaPassosSemanal = 70000;
  int _metaPassosMensal = 300000;
  List<PassosDiariosModel> _historicoPassos = [];
  bool _passosCarregados = false;

  late Future<List<CorridaModel>> _corridasFuture;
  late Future<List<FitAICoachInsight>> _coachInsightsFuture;

  bool _salvandoCorrida = false;

  _EstadoCorrida get _estadoCorrida {
    if (runningSession.countdownActive) return _EstadoCorrida.contagem;
    if (runningSession.isPaused) return _EstadoCorrida.pausada;
    if (runningSession.isRunning) return _EstadoCorrida.emAndamento;
    return _EstadoCorrida.naoIniciada;
  }

  int get _contagemRegressiva => runningSession.countdownSeconds;

  int get _segundosCorrida => runningSession.elapsedSeconds;

  double get _distanciaCorrida => runningSession.distanceKm;

  @override
  void initState() {
    super.initState();
    _corridasFuture = StorageService.carregarCorridas();
    _coachInsightsFuture = _gerarInsightsCoach();
    runningSession.addListener(_onRunningSessionChanged);
    unawaited(runningSession.initialize());
    unawaited(_carregarSistemaPassos());
  }

  @override
  void didUpdateWidget(covariant AtividadesPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.passos != widget.passos) {
      unawaited(_sincronizarPassosDoDia());
    }
  }

  @override
  void dispose() {
    runningSession.removeListener(_onRunningSessionChanged);
    super.dispose();
  }

  void _onRunningSessionChanged() {
    if (!mounted) return;
    setState(() {});
  }

  double get _progressoPassos =>
      (widget.passos / _metaPassosDiaria).clamp(0.0, 1.0);

  double get _distanciaPassosKm => widget.passos * 0.000762;

  double get _caloriasPassos => widget.passos * 0.04;

  int get _tempoAtivoPassosMinutos => (widget.passos / 100).round();

  String get _tempoAtivoPassosFormatado {
    final minutos = _tempoAtivoPassosMinutos;
    if (minutos < 60) return '$minutos min';

    final horas = minutos ~/ 60;
    final resto = minutos % 60;

    if (resto == 0) return '${horas}h';
    return '${horas}h ${resto}min';
  }

  double get _caloriasCorrida => _distanciaCorrida * 60;

  String get _tempoAtivoTotalFormatado {
    final segundosPassos = _tempoAtivoPassosMinutos * 60;
    return _formatarTempo(segundosPassos + _segundosCorrida);
  }

  bool get _corridaEmAndamento => _estadoCorrida == _EstadoCorrida.emAndamento;

  bool get _corridaAtiva =>
      _estadoCorrida == _EstadoCorrida.contagem ||
      _estadoCorrida == _EstadoCorrida.emAndamento ||
      _estadoCorrida == _EstadoCorrida.pausada;

  double get _velocidadeMediaCorrida {
    return runningSession.averageSpeed;
  }

  String get _tempoFormatado => _formatarTempo(_segundosCorrida);

  String get _ritmoFormatado {
    if (_distanciaCorrida <= 0 || _segundosCorrida <= 0) return '--';

    final segundosPorKm = (_segundosCorrida / _distanciaCorrida).round();
    final minutos = segundosPorKm ~/ 60;
    final segundos = segundosPorKm % 60;

    return '$minutos:${segundos.toString().padLeft(2, '0')} min/km';
  }

  String get _statusCorrida {
    return switch (_estadoCorrida) {
      _EstadoCorrida.naoIniciada => 'Pronto para iniciar',
      _EstadoCorrida.contagem => 'Prepare-se',
      _EstadoCorrida.emAndamento =>
        runningSession.gpsConnected ? 'GPS conectado' : 'Buscando GPS',
      _EstadoCorrida.pausada => 'Corrida pausada',
      _EstadoCorrida.finalizada => 'Corrida finalizada',
    };
  }

  String _formatarTempo(int totalSegundos) {
    final h = totalSegundos ~/ 3600;
    final m = (totalSegundos % 3600) ~/ 60;
    final s = totalSegundos % 60;

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }

    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  Future<void> _carregarSistemaPassos() async {
    final metas = await StorageService.carregarMetasPassos();
    final historico = await StorageService.carregarHistoricoPassos();

    if (!mounted) return;

    setState(() {
      _metaPassosDiaria = metas['diaria'] ?? _metaPassosDiaria;
      _metaPassosSemanal = metas['semanal'] ?? _metaPassosSemanal;
      _metaPassosMensal = metas['mensal'] ?? _metaPassosMensal;
      _historicoPassos = historico;
      _passosCarregados = true;
    });

    await _sincronizarPassosDoDia();
  }

  Future<void> _sincronizarPassosDoDia() async {
    await StorageService.salvarPassos(widget.passos);
    await StorageService.salvarHistoricoPassos(_registroPassosDoDia());

    final historico = await StorageService.carregarHistoricoPassos();

    if (!mounted) return;

    setState(() {
      _historicoPassos = historico;
      _passosCarregados = true;
      _coachInsightsFuture = _gerarInsightsCoach(historicoPassos: historico);
    });

    await _avaliarConquistasAtividades();
  }

  Future<List<FitAICoachInsight>> _gerarInsightsCoach({
    List<PassosDiariosModel>? historicoPassos,
  }) {
    return const FitAICoachService().gerarInsights(
      passosHoje: widget.passos,
      metaDiaria: _metaPassosDiaria,
      metaSemanal: _metaPassosSemanal,
      metaMensal: _metaPassosMensal,
      historicoPassos: historicoPassos ?? _historicoPassos,
      distanciaCorridaAtual: _distanciaCorrida,
      segundosCorridaAtual: _segundosCorrida,
    );
  }

  Future<void> _avaliarConquistasAtividades() async {
    final resultado = await const AchievementService().avaliarConquistas();

    if (!mounted || resultado.novas.isEmpty) return;

    _mostrarConquistasDesbloqueadas(resultado.novas);
  }

  void _mostrarConquistasDesbloqueadas(List<AchievementModel> conquistas) {
    final mensagem = conquistas.length == 1
        ? 'Nova conquista: ${conquistas.first.nome}'
        : '${conquistas.length} novas conquistas desbloqueadas';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppColors.rankOuro),
              const SizedBox(width: 10),
              Expanded(child: Text(mensagem)),
            ],
          ),
        ),
      );
  }

  PassosDiariosModel _registroPassosDoDia() {
    // Origem isolada para uma futura leitura por sensor real sem mudar a UI.
    return PassosDiariosModel(
      data: _formatarDataChave(DateTime.now()),
      passos: widget.passos,
      metaDiaria: _metaPassosDiaria,
      distanciaKm: _distanciaPassosKm,
      calorias: _caloriasPassos,
      tempoAtivoMinutos: _tempoAtivoPassosMinutos,
      origem: 'estimado',
    );
  }

  String _formatarDataChave(DateTime data) {
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');

    return '${data.year}-$mes-$dia';
  }

  DateTime? _parseDataChave(String data) {
    final parsed = DateTime.tryParse(data);
    if (parsed == null) return null;

    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  DateTime _inicioSemana(DateTime data) {
    final base = DateTime(data.year, data.month, data.day);
    return base.subtract(Duration(days: base.weekday - 1));
  }

  bool _mesAtual(PassosDiariosModel registro) {
    final data = _parseDataChave(registro.data);
    final agora = DateTime.now();

    return data != null && data.year == agora.year && data.month == agora.month;
  }

  bool _semanaAtual(PassosDiariosModel registro) {
    final data = _parseDataChave(registro.data);
    if (data == null) return false;

    final inicio = _inicioSemana(DateTime.now());
    final fim = inicio.add(const Duration(days: 7));

    return !data.isBefore(inicio) && data.isBefore(fim);
  }

  int get _passosSemana {
    final total = _historicoPassos
        .where(_semanaAtual)
        .fold<int>(0, (soma, item) => soma + item.passos);

    return total > 0 ? total : widget.passos;
  }

  int get _passosMes {
    final total = _historicoPassos
        .where(_mesAtual)
        .fold<int>(0, (soma, item) => soma + item.passos);

    return total > 0 ? total : widget.passos;
  }

  int get _recordePassos {
    final valores = [
      widget.passos,
      ..._historicoPassos.map((registro) => registro.passos),
    ];

    return valores.reduce((a, b) => a > b ? a : b);
  }

  double get _recordeDistancia {
    final valores = [
      _distanciaPassosKm,
      ..._historicoPassos.map((registro) => registro.distanciaKm),
    ];

    return valores.reduce((a, b) => a > b ? a : b);
  }

  int get _sequenciaAtualMetas {
    final porData = {
      for (final registro in _historicoPassos) registro.data: registro,
    };

    var data = DateTime.now();
    var sequencia = 0;

    while (true) {
      final chave = _formatarDataChave(data);
      final registro = porData[chave];

      if (registro == null || !registro.metaAtingida) break;

      sequencia++;
      data = data.subtract(const Duration(days: 1));
    }

    return sequencia;
  }

  int get _melhorSequenciaMetas {
    final datasAtingidas =
        _historicoPassos
            .where((registro) => registro.metaAtingida)
            .map((registro) => _parseDataChave(registro.data))
            .whereType<DateTime>()
            .toList()
          ..sort();

    if (datasAtingidas.isEmpty) return 0;

    var melhor = 1;
    var atual = 1;

    for (var i = 1; i < datasAtingidas.length; i++) {
      final diferenca = datasAtingidas[i]
          .difference(datasAtingidas[i - 1])
          .inDays;

      if (diferenca == 1) {
        atual++;
      } else if (diferenca > 1) {
        atual = 1;
      }

      if (atual > melhor) melhor = atual;
    }

    return melhor;
  }

  String _formatarDataCurta(String data) {
    final parsed = _parseDataChave(data);
    if (parsed == null) return data;

    final dia = parsed.day.toString().padLeft(2, '0');
    final mes = parsed.month.toString().padLeft(2, '0');

    return '$dia/$mes';
  }

  void _iniciarContagemCorrida() {
    unawaited(runningSession.startWithCountdown());
  }

  void _pausarCorrida() {
    unawaited(runningSession.pause());
  }

  void _continuarCorrida() {
    unawaited(runningSession.resume());
  }

  Future<void> _finalizarCorrida() async {
    if (_salvandoCorrida) return;

    setState(() {
      _salvandoCorrida = true;
    });

    final corrida = await runningSession.finish();

    if (!mounted) return;

    setState(() {
      _salvandoCorrida = false;
      _corridasFuture = StorageService.carregarCorridas();
      _coachInsightsFuture = _gerarInsightsCoach();
    });

    if (corrida != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrida salva no historico')),
      );
    }

    await _avaliarConquistasAtividades();
  }

  @override
  Widget build(BuildContext context) {
    final totalDistancia = _distanciaCorrida + _distanciaPassosKm;
    final totalCalorias = _caloriasCorrida + _caloriasPassos;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _buildResumoHoje(context, totalDistancia, totalCalorias),
                const SizedBox(height: 18),
                _buildCoachCard(context),
                const SizedBox(height: 18),
                _buildCardsPrincipais(context),
                const SizedBox(height: 18),
                _buildMetasCard(context),
                const SizedBox(height: 18),
                _buildRecordesCard(context),
                const SizedBox(height: 18),
                _buildHistoricoRecente(context),
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
        eyebrow: _corridaAtiva ? 'Atividade em andamento' : 'Hoje',
        title: 'Atividades',
        subtitle:
            'Passos, corrida, distancia, calorias e historico em um so lugar.',
        icon: Icons.monitor_heart_rounded,
        gradient: _corridaAtiva
            ? AppColors.gradientRun
            : AppColors.gradientSteps,
        trailing: _corridaEmAndamento ? const _LiveBadge() : null,
      ),
    );
  }

  Widget _buildResumoHoje(
    BuildContext context,
    double totalDistancia,
    double totalCalorias,
  ) {
    return AppGradientCard(
      gradient: AppColors.gradientCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo de hoje',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricBox(
                label: 'Passos',
                value: '${widget.passos}',
                icon: Icons.directions_walk_rounded,
                color: AppColors.accent1,
              ),
              _MetricBox(
                label: 'Distancia',
                value: '${totalDistancia.toStringAsFixed(2)} km',
                icon: Icons.route_rounded,
                color: AppColors.primary,
              ),
              _MetricBox(
                label: 'Calorias',
                value: '${totalCalorias.toStringAsFixed(0)} kcal',
                icon: Icons.local_fire_department_rounded,
                color: AppColors.accent2,
              ),
              _MetricBox(
                label: 'Tempo ativo',
                value: _tempoAtivoTotalFormatado,
                icon: Icons.timer_rounded,
                color: AppColors.accent3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoachCard(BuildContext context) {
    return AppGradientCard(
      gradient: AppColors.gradientCard,
      child: FutureBuilder<List<FitAICoachInsight>>(
        future: _coachInsightsFuture,
        builder: (context, snapshot) {
          final insights = snapshot.data ?? const <FitAICoachInsight>[];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.black,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FITAI Coach Local',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColors.primary,
                                letterSpacing: 1,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insights.isEmpty
                              ? 'Analisando sua rotina'
                              : insights.first.titulo,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 3),
                )
              else if (insights.isEmpty)
                Text(
                  'Continue registrando passos e corridas para receber recomendacoes melhores.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                )
              else
                for (int i = 0; i < insights.length; i++) ...[
                  _CoachInsightTile(insight: insights[i]),
                  if (i != insights.length - 1) const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCardsPrincipais(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPassosCard(context)),
              const SizedBox(width: 18),
              Expanded(child: _buildCorridaCard(context)),
            ],
          );
        }

        return Column(
          children: [
            _buildPassosCard(context),
            const SizedBox(height: 18),
            _buildCorridaCard(context),
          ],
        );
      },
    );
  }

  Widget _buildPassosCard(BuildContext context) {
    final faltam = (_metaPassosDiaria - widget.passos).clamp(
      0,
      _metaPassosDiaria,
    );

    return AppGradientCard(
      gradient: AppColors.gradientSteps,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.directions_walk_rounded,
            title: 'Passos',
            subtitle: 'Meta diaria: $_metaPassosDiaria passos',
            action: IconButton(
              tooltip: 'Editar metas',
              onPressed: _abrirEditorMetas,
              icon: const Icon(Icons.tune_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${widget.passos}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  'passos',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PassosMetric(
                label: 'Meta diaria',
                value: '$_metaPassosDiaria',
                icon: Icons.flag_rounded,
              ),
              _PassosMetric(
                label: 'Distancia',
                value: '${_distanciaPassosKm.toStringAsFixed(2)} km',
                icon: Icons.route_rounded,
              ),
              _PassosMetric(
                label: 'Calorias',
                value: '${_caloriasPassos.toStringAsFixed(0)} kcal',
                icon: Icons.local_fire_department_rounded,
              ),
              _PassosMetric(
                label: 'Tempo ativo',
                value: _tempoAtivoPassosFormatado,
                icon: Icons.timer_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _AnimatedProgressBar(
            progress: _progressoPassos,
            color: Colors.white,
            backgroundColor: Colors.black.withAlpha(55),
          ),
          const SizedBox(height: 12),
          Text(
            widget.passos >= _metaPassosDiaria
                ? 'Meta atingida. Excelente consistencia!'
                : '$faltam passos para bater a meta de hoje.',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetasCard(BuildContext context) {
    final progressoDiario = (widget.passos / _metaPassosDiaria).clamp(0.0, 1.0);
    final passosSemana = _passosSemana;
    final passosMes = _passosMes;
    final progressoSemanal = (passosSemana / _metaPassosSemanal).clamp(
      0.0,
      1.0,
    );
    final progressoMensal = (passosMes / _metaPassosMensal).clamp(0.0, 1.0);

    return AppGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.flag_rounded,
            title: 'Metas de passos',
            subtitle: 'Diaria, semanal e mensal',
            darkIcon: false,
            action: IconButton(
              tooltip: 'Editar metas',
              onPressed: _abrirEditorMetas,
              icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          _GoalProgressTile(
            title: 'Hoje',
            value: '${widget.passos} / $_metaPassosDiaria',
            progress: progressoDiario,
            icon: Icons.today_rounded,
          ),
          const SizedBox(height: 12),
          _GoalProgressTile(
            title: 'Semana',
            value: '$passosSemana / $_metaPassosSemanal',
            progress: progressoSemanal,
            icon: Icons.calendar_view_week_rounded,
          ),
          const SizedBox(height: 12),
          _GoalProgressTile(
            title: 'Mes',
            value: '$passosMes / $_metaPassosMensal',
            progress: progressoMensal,
            icon: Icons.calendar_month_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordesCard(BuildContext context) {
    return FutureBuilder<List<CorridaModel>>(
      future: _corridasFuture,
      builder: (context, snapshot) {
        final corridas = snapshot.data ?? const <CorridaModel>[];
        final maiorCorrida = corridas.fold<double>(
          _distanciaCorrida,
          (maior, corrida) =>
              corrida.distancia > maior ? corrida.distancia : maior,
        );
        final maiorTempoCorrida = corridas.fold<int>(
          _segundosCorrida,
          (maior, corrida) =>
              corrida.segundos > maior ? corrida.segundos : maior,
        );

        return AppGradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle(
                icon: Icons.emoji_events_rounded,
                title: 'Recordes',
                subtitle: 'Melhores marcas de passos e corrida',
                darkIcon: false,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _PassosRecordMetric(
                    label: 'Maior dia',
                    value: '$_recordePassos',
                    icon: Icons.directions_walk_rounded,
                    color: AppColors.primary,
                  ),
                  _PassosRecordMetric(
                    label: 'Maior caminhada',
                    value: '${_recordeDistancia.toStringAsFixed(2)} km',
                    icon: Icons.route_rounded,
                    color: AppColors.accent1,
                  ),
                  _PassosRecordMetric(
                    label: 'Streak atual',
                    value: '$_sequenciaAtualMetas dias',
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.accent2,
                  ),
                  _PassosRecordMetric(
                    label: 'Melhor streak',
                    value: '$_melhorSequenciaMetas dias',
                    icon: Icons.auto_graph_rounded,
                    color: AppColors.accent3,
                  ),
                  _PassosRecordMetric(
                    label: 'Maior corrida',
                    value: '${maiorCorrida.toStringAsFixed(2)} km',
                    icon: Icons.directions_run_rounded,
                    color: AppColors.accent2,
                  ),
                  _PassosRecordMetric(
                    label: 'Maior tempo',
                    value: _formatarTempo(maiorTempoCorrida),
                    icon: Icons.timer_rounded,
                    color: AppColors.accent1,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _abrirEditorMetas() async {
    final diariaController = TextEditingController(
      text: _metaPassosDiaria.toString(),
    );
    final semanalController = TextEditingController(
      text: _metaPassosSemanal.toString(),
    );
    final mensalController = TextEditingController(
      text: _metaPassosMensal.toString(),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: Colors.white.withAlpha(18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Editar metas de passos',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _GoalTextField(
                  controller: diariaController,
                  label: 'Meta diaria',
                  hint: 'Ex: 10000',
                ),
                const SizedBox(height: 12),
                _GoalTextField(
                  controller: semanalController,
                  label: 'Meta semanal',
                  hint: 'Ex: 70000',
                ),
                const SizedBox(height: 12),
                _GoalTextField(
                  controller: mensalController,
                  label: 'Meta mensal',
                  hint: 'Ex: 300000',
                ),
                const SizedBox(height: 20),
                AppButton.primary(
                  label: 'Salvar metas',
                  icon: Icons.check_rounded,
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final diaria =
                        int.tryParse(diariaController.text.trim()) ??
                        _metaPassosDiaria;
                    final semanal =
                        int.tryParse(semanalController.text.trim()) ??
                        _metaPassosSemanal;
                    final mensal =
                        int.tryParse(mensalController.text.trim()) ??
                        _metaPassosMensal;

                    setState(() {
                      _metaPassosDiaria = diaria.clamp(1000, 100000);
                      _metaPassosSemanal = semanal.clamp(5000, 700000);
                      _metaPassosMensal = mensal.clamp(20000, 3000000);
                    });

                    await StorageService.salvarMetasPassos(
                      diaria: _metaPassosDiaria,
                      semanal: _metaPassosSemanal,
                      mensal: _metaPassosMensal,
                    );
                    await _sincronizarPassosDoDia();

                    if (!mounted) return;
                    navigator.pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    diariaController.dispose();
    semanalController.dispose();
    mensalController.dispose();
  }

  Widget _buildCorridaCard(BuildContext context) {
    return AppGradientCard(
      gradient: _corridaAtiva ? AppColors.gradientRun : AppColors.gradientCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.directions_run_rounded,
            title: 'Corrida',
            subtitle: _statusCorrida,
          ),
          const SizedBox(height: 18),
          if (_estadoCorrida == _EstadoCorrida.contagem) ...[
            _buildContagemCorrida(context),
            const SizedBox(height: 18),
          ],
          _buildMetricasCorrida(context),
          const SizedBox(height: 18),
          _buildAcoesCorrida(),
          const SizedBox(height: 10),
          AppButton.secondary(
            label: 'Historico de corridas',
            icon: Icons.history_rounded,
            onPressed: _abrirHistoricoCorridas,
          ),
        ],
      ),
    );
  }

  Widget _buildContagemCorrida(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(_contagemRegressiva),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(35),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: Colors.white.withAlpha(18)),
        ),
        child: Column(
          children: [
            Text(
              'Comecando em',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white70,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_contagemRegressiva',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricasCorrida(BuildContext context) {
    final metricas = [
      _CompactStat(label: 'Tempo', value: _tempoFormatado),
      _CompactStat(
        label: 'Distancia',
        value: '${_distanciaCorrida.toStringAsFixed(2)} km',
      ),
      _CompactStat(
        label: 'Vel. media',
        value: '${_velocidadeMediaCorrida.toStringAsFixed(1)} km/h',
      ),
      _CompactStat(
        label: 'Vel. atual',
        value: '${runningSession.currentSpeed.toStringAsFixed(1)} km/h',
      ),
      _CompactStat(label: 'Ritmo', value: _ritmoFormatado),
      _CompactStat(
        label: 'Calorias',
        value: '${_caloriasCorrida.toStringAsFixed(0)} kcal',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 3 : 2;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metrica in metricas)
              SizedBox(width: itemWidth, child: metrica),
          ],
        );
      },
    );
  }

  Widget _buildAcoesCorrida() {
    return switch (_estadoCorrida) {
      _EstadoCorrida.naoIniciada => AppButton.primary(
        label: 'Iniciar corrida',
        icon: Icons.play_arrow_rounded,
        onPressed: _iniciarContagemCorrida,
      ),
      _EstadoCorrida.contagem => AppButton.secondary(
        label: 'Preparando',
        icon: Icons.hourglass_top_rounded,
        onPressed: null,
      ),
      _EstadoCorrida.emAndamento => Row(
        children: [
          Expanded(
            child: AppButton.secondary(
              label: 'Pausar',
              icon: Icons.pause_rounded,
              onPressed: _salvandoCorrida ? null : _pausarCorrida,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton.danger(
              label: 'Finalizar',
              icon: Icons.stop_rounded,
              loading: _salvandoCorrida,
              onPressed: _salvandoCorrida ? null : () => _finalizarCorrida(),
            ),
          ),
        ],
      ),
      _EstadoCorrida.pausada => Row(
        children: [
          Expanded(
            child: AppButton.primary(
              label: 'Continuar',
              icon: Icons.play_arrow_rounded,
              onPressed: _salvandoCorrida ? null : _continuarCorrida,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton.danger(
              label: 'Finalizar',
              icon: Icons.stop_rounded,
              loading: _salvandoCorrida,
              onPressed: _salvandoCorrida ? null : () => _finalizarCorrida(),
            ),
          ),
        ],
      ),
      _EstadoCorrida.finalizada => AppButton.primary(
        label: 'Iniciar nova corrida',
        icon: Icons.replay_rounded,
        onPressed: _iniciarContagemCorrida,
      ),
    };
  }

  void _abrirHistoricoCorridas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoricoCorridasPage()),
    ).then((_) {
      if (mounted) {
        setState(() {
          _corridasFuture = StorageService.carregarCorridas();
        });
      }
    });
  }

  Widget _buildHistoricoRecente(BuildContext context) {
    return FutureBuilder<List<CorridaModel>>(
      future: _corridasFuture,
      builder: (context, snapshot) {
        final corridas = snapshot.data ?? const <CorridaModel>[];
        final recentes = corridas.reversed.take(3).toList();
        final passosRecentes = _historicoPassos.take(3).toList();
        final carregando =
            snapshot.connectionState == ConnectionState.waiting ||
            !_passosCarregados;
        final vazio = recentes.isEmpty && passosRecentes.isEmpty;

        return AppGradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle(
                icon: Icons.timeline_rounded,
                title: 'Historico recente',
                subtitle: 'Passos e corridas salvas',
                darkIcon: false,
              ),
              const SizedBox(height: 14),
              if (carregando)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (vazio)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Caminhe ou finalize uma corrida para preencher o historico.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else ...[
                if (passosRecentes.isNotEmpty) ...[
                  const _HistorySectionTitle(
                    icon: Icons.directions_walk_rounded,
                    label: 'Passos',
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < passosRecentes.length; i++) ...[
                    _PassosHistoryTile(
                      registro: passosRecentes[i],
                      dataFormatada: _formatarDataCurta(passosRecentes[i].data),
                    ),
                    if (i != passosRecentes.length - 1)
                      const AppPremiumDivider(),
                  ],
                ],
                if (passosRecentes.isNotEmpty && recentes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const AppPremiumDivider(),
                  const SizedBox(height: 14),
                ],
                if (recentes.isNotEmpty) ...[
                  const _HistorySectionTitle(
                    icon: Icons.directions_run_rounded,
                    label: 'Corridas',
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < recentes.length; i++) ...[
                    _RunHistoryTile(corrida: recentes[i]),
                    if (i != recentes.length - 1) const AppPremiumDivider(),
                  ],
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: Colors.white.withAlpha(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CoachInsightTile extends StatelessWidget {
  final FitAICoachInsight insight;

  const _CoachInsightTile({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconForType(insight.tipo), color: _colorForType(insight.tipo)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.titulo,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.mensagem,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(FitAICoachTipo tipo) {
    return switch (tipo) {
      FitAICoachTipo.passos => Icons.directions_walk_rounded,
      FitAICoachTipo.corrida => Icons.directions_run_rounded,
      FitAICoachTipo.sequencia => Icons.local_fire_department_rounded,
      FitAICoachTipo.conquista => Icons.emoji_events_rounded,
      FitAICoachTipo.recuperacao => Icons.self_improvement_rounded,
      FitAICoachTipo.treino => Icons.fitness_center_rounded,
      FitAICoachTipo.geral => Icons.auto_awesome_rounded,
    };
  }

  Color _colorForType(FitAICoachTipo tipo) {
    return switch (tipo) {
      FitAICoachTipo.passos => AppColors.accent1,
      FitAICoachTipo.corrida => AppColors.accent2,
      FitAICoachTipo.sequencia => AppColors.primary,
      FitAICoachTipo.conquista => AppColors.rankOuro,
      FitAICoachTipo.recuperacao => AppColors.accent3,
      FitAICoachTipo.treino => AppColors.primary,
      FitAICoachTipo.geral => AppColors.primary,
    };
  }
}

class _HistorySectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HistorySectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _PassosMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PassosMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(32),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _PassosRecordMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PassosRecordMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PassosHistoryTile extends StatelessWidget {
  final PassosDiariosModel registro;
  final String dataFormatada;

  const _PassosHistoryTile({
    required this.registro,
    required this.dataFormatada,
  });

  @override
  Widget build(BuildContext context) {
    final progresso = (registro.passos / registro.metaDiaria).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientSteps,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$dataFormatada - ${registro.passos} passos',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${registro.distanciaKm.toStringAsFixed(2)} km - '
                      '${registro.calorias.toStringAsFixed(0)} kcal - '
                      '${registro.tempoAtivoMinutos} min',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                registro.metaAtingida
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: registro.metaAtingida
                    ? AppColors.primary
                    : AppColors.textHint,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _AnimatedProgressBar(
            progress: progresso,
            color: registro.metaAtingida
                ? AppColors.primary
                : AppColors.accent1,
            backgroundColor: Colors.white.withAlpha(16),
            height: 7,
          ),
        ],
      ),
    );
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double height;

  const _AnimatedProgressBar({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LinearProgressIndicator(
            minHeight: height,
            value: value,
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      },
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;

  const _CompactStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(34),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool darkIcon;
  final Widget? action;

  const _CardTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.darkIcon = true,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = darkIcon ? Colors.black : AppColors.primary;
    final iconBackground = darkIcon
        ? Colors.white.withAlpha(220)
        : AppColors.primary.withAlpha(24);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(icon, color: iconColor, size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 8), action!],
      ],
    );
  }
}

class _GoalProgressTile extends StatelessWidget {
  final String title;
  final String value;
  final double progress;
  final IconData icon;

  const _GoalProgressTile({
    required this.title,
    required this.value,
    required this.progress,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _AnimatedProgressBar(
            progress: progress,
            color: AppColors.primary,
            backgroundColor: Colors.white.withAlpha(16),
            height: 8,
          ),
        ],
      ),
    );
  }
}

class _GoalTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _GoalTextField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.directions_walk_rounded),
      ),
    );
  }
}

class _RunHistoryTile extends StatelessWidget {
  final CorridaModel corrida;

  const _RunHistoryTile({required this.corrida});

  double get _velocidadeMedia {
    if (corrida.segundos <= 0) return 0;
    return corrida.distancia / (corrida.segundos / 3600);
  }

  String get _tempo {
    final h = corrida.segundos ~/ 3600;
    final m = (corrida.segundos % 3600) ~/ 60;
    final s = corrida.segundos % 60;

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }

    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.gradientRun,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              Icons.directions_run_rounded,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${corrida.distancia.toStringAsFixed(2)} km',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$_tempo - ${_velocidadeMedia.toStringAsFixed(1)} km/h',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(35),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Color(0xFFFF1744), size: 10),
          SizedBox(width: 6),
          Text(
            'AO VIVO',
            style: TextStyle(
              color: Colors.white,
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
