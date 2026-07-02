import 'package:flutter/material.dart';

import '../../models/corrida_model.dart';
import '../../models/passos_diarios_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';

class _MetricData {
  final String titulo;
  final String valor;
  final IconData icon;
  final Color color;

  const _MetricData({
    required this.titulo,
    required this.valor,
    required this.icon,
    required this.color,
  });
}

class _ChartData {
  final String label;
  final double value;

  const _ChartData({required this.label, required this.value});
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool carregando = true;

  List<CorridaModel> corridas = [];
  List<PassosDiariosModel> historicoPassos = [];

  int passosHoje = 0;
  int metaPassosDiaria = 10000;
  double distanciaTotalSalva = 0;
  int tempoTotalSalvo = 0;
  int totalCorridasSalvo = 0;

  @override
  void initState() {
    super.initState();
    carregarStats();
  }

  Future<void> carregarStats() async {
    final corridasSalvas = await StorageService.carregarCorridas();
    final passos = await StorageService.carregarPassos();
    final historico = await StorageService.carregarHistoricoPassos();
    final metas = await StorageService.carregarMetasPassos();
    final distancia = await StorageService.carregarDistanciaTotal();
    final tempo = await StorageService.carregarTempoTotal();
    final totalCorridas = await StorageService.carregarTotalCorridas();

    if (!mounted) return;

    setState(() {
      corridas = corridasSalvas;
      historicoPassos = historico;
      passosHoje = passos;
      metaPassosDiaria = metas['diaria'] ?? 10000;
      distanciaTotalSalva = distancia;
      tempoTotalSalvo = tempo;
      totalCorridasSalvo = totalCorridas;
      carregando = false;
    });
  }

  List<PassosDiariosModel> get _historicoPassosComHoje {
    final porData = {
      for (final registro in historicoPassos) registro.data: registro,
    };

    final hoje = DateTime.now();
    final chaveHoje = _formatarDataChave(hoje);

    porData.putIfAbsent(
      chaveHoje,
      () => PassosDiariosModel(
        data: chaveHoje,
        passos: passosHoje,
        metaDiaria: metaPassosDiaria,
        distanciaKm: passosHoje * 0.000762,
        calorias: passosHoje * 0.04,
        tempoAtivoMinutos: (passosHoje / 100).round(),
      ),
    );

    final lista = porData.values.toList()
      ..sort((a, b) => b.data.compareTo(a.data));

    return lista;
  }

  int get _totalCorridas {
    return corridas.isNotEmpty ? corridas.length : totalCorridasSalvo;
  }

  double get _distanciaCorridas {
    if (corridas.isEmpty) return distanciaTotalSalva;
    return corridas.fold<double>(0, (total, item) => total + item.distancia);
  }

  int get _tempoCorridas {
    if (corridas.isEmpty) return tempoTotalSalvo;
    return corridas.fold<int>(0, (total, item) => total + item.segundos);
  }

  double get _caloriasCorridas => _distanciaCorridas * 60;

  double get _velocidadeMediaGeral {
    if (_tempoCorridas <= 0) return 0;
    return _distanciaCorridas / (_tempoCorridas / 3600);
  }

  double get _maiorDistanciaCorrida {
    if (corridas.isEmpty) return 0;
    return corridas.fold<double>(
      0,
      (maior, item) => item.distancia > maior ? item.distancia : maior,
    );
  }

  int? get _melhorRitmoSegundosPorKm {
    final ritmos = corridas
        .where((item) => item.distancia > 0 && item.segundos > 0)
        .map((item) => (item.segundos / item.distancia).round())
        .toList();

    if (ritmos.isEmpty) return null;

    ritmos.sort();
    return ritmos.first;
  }

  int get _totalPassos {
    return _historicoPassosComHoje.fold<int>(
      0,
      (total, item) => total + item.passos,
    );
  }

  int get _mediaDiariaPassos {
    final historico = _historicoPassosComHoje;
    if (historico.isEmpty) return 0;
    return (_totalPassos / historico.length).round();
  }

  int get _mediaSemanalPassos {
    final grupos = <String, int>{};

    for (final registro in _historicoPassosComHoje) {
      final data = _parseDataChave(registro.data);
      if (data == null) continue;

      final semana = _formatarDataChave(_inicioSemana(data));
      grupos.update(
        semana,
        (valor) => valor + registro.passos,
        ifAbsent: () => registro.passos,
      );
    }

    if (grupos.isEmpty) return 0;

    final total = grupos.values.fold<int>(0, (soma, item) => soma + item);
    return (total / grupos.length).round();
  }

  int get _mediaMensalPassos {
    final grupos = <String, int>{};

    for (final registro in _historicoPassosComHoje) {
      final data = _parseDataChave(registro.data);
      if (data == null) continue;

      final chave = '${data.year}-${data.month.toString().padLeft(2, '0')}';
      grupos.update(
        chave,
        (valor) => valor + registro.passos,
        ifAbsent: () => registro.passos,
      );
    }

    if (grupos.isEmpty) return 0;

    final total = grupos.values.fold<int>(0, (soma, item) => soma + item);
    return (total / grupos.length).round();
  }

  int get _recordeDiarioPassos {
    if (_historicoPassosComHoje.isEmpty) return 0;

    return _historicoPassosComHoje.fold<int>(
      0,
      (maior, item) => item.passos > maior ? item.passos : maior,
    );
  }

  int get _metasAtingidas {
    return _historicoPassosComHoje.where((item) => item.metaAtingida).length;
  }

  int get _sequenciaAtual {
    final porData = {
      for (final registro in _historicoPassosComHoje) registro.data: registro,
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

  int get _passosSemanaAtual {
    final inicio = _inicioSemana(DateTime.now());
    return _totalPassosNoIntervalo(inicio, inicio.add(const Duration(days: 7)));
  }

  int get _passosSemanaAnterior {
    final inicioSemanaAtual = _inicioSemana(DateTime.now());
    final inicioSemanaAnterior = inicioSemanaAtual.subtract(
      const Duration(days: 7),
    );

    return _totalPassosNoIntervalo(inicioSemanaAnterior, inicioSemanaAtual);
  }

  String get _evolucaoSemanalTexto {
    final anterior = _passosSemanaAnterior;
    final atual = _passosSemanaAtual;

    if (anterior <= 0 && atual <= 0) return 'Sem dados';
    if (anterior <= 0) return '+100%';

    final variacao = ((atual - anterior) / anterior) * 100;
    final prefixo = variacao > 0 ? '+' : '';

    return '$prefixo${variacao.toStringAsFixed(0)}%';
  }

  Color get _evolucaoSemanalCor {
    if (_passosSemanaAtual >= _passosSemanaAnterior) return AppColors.primary;
    return const Color(0xFFCF6679);
  }

  int _totalPassosNoIntervalo(DateTime inicio, DateTime fim) {
    return _historicoPassosComHoje.fold<int>(0, (total, registro) {
      final data = _parseDataChave(registro.data);
      if (data == null) return total;

      final dentro = !data.isBefore(inicio) && data.isBefore(fim);
      return dentro ? total + registro.passos : total;
    });
  }

  List<_ChartData> get _ultimos7Dias {
    final porData = {
      for (final registro in _historicoPassosComHoje) registro.data: registro,
    };
    final hoje = DateTime.now();

    return List.generate(7, (index) {
      final data = hoje.subtract(Duration(days: 6 - index));
      final chave = _formatarDataChave(data);
      final registro = porData[chave];

      return _ChartData(
        label:
            '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}',
        value: (registro?.passos ?? 0).toDouble(),
      );
    });
  }

  List<_ChartData> get _ultimas4Semanas {
    final inicioAtual = _inicioSemana(DateTime.now());

    return List.generate(4, (index) {
      final inicio = inicioAtual.subtract(Duration(days: (3 - index) * 7));
      final fim = inicio.add(const Duration(days: 7));

      return _ChartData(
        label: 'S${index + 1}',
        value: _totalPassosNoIntervalo(inicio, fim).toDouble(),
      );
    });
  }

  List<_ChartData> get _ultimos12MesesCorrida {
    final agora = DateTime.now();

    return List.generate(12, (index) {
      final mes = DateTime(agora.year, agora.month - (11 - index), 1);
      final total = corridas.fold<double>(0, (soma, corrida) {
        final data = DateTime.tryParse(corrida.data);
        if (data == null) return soma;

        if (data.year == mes.year && data.month == mes.month) {
          return soma + corrida.distancia;
        }

        return soma;
      });

      return _ChartData(label: _mesCurto(mes.month), value: total);
    });
  }

  @override
  Widget build(BuildContext context) {
    final semDados = !carregando && _totalCorridas == 0 && _totalPassos == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: carregarStats,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                _horizontalPadding(context),
                0,
                _horizontalPadding(context),
                110,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  if (carregando)
                    const AppLoading(message: 'Carregando estatisticas...')
                  else if (semDados)
                    const AppEmptyState(
                      icon: Icons.insights_rounded,
                      title: 'Sem dados ainda',
                      message:
                          'Registre passos ou finalize uma corrida para ver sua evolucao.',
                    )
                  else ...[
                    _buildResumoGeral(context),
                    const SizedBox(height: 18),
                    _buildCorridaSection(),
                    const SizedBox(height: 18),
                    _buildPassosSection(),
                    const SizedBox(height: 18),
                    _buildSequenciaCard(context),
                    const SizedBox(height: 18),
                    _buildGraficosSection(),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        _horizontalPadding(context),
        MediaQuery.of(context).padding.top + 20,
        _horizontalPadding(context),
        24,
      ),
      child: const AppPremiumHeader(
        eyebrow: 'Evolucao',
        title: 'Estatisticas',
        subtitle: 'Corrida, passos, metas e tendencias em um painel unico.',
        icon: Icons.query_stats_rounded,
      ),
    );
  }

  Widget _buildResumoGeral(BuildContext context) {
    return AppCard(
      gradient: AppColors.gradientPrimary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(28),
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: const Icon(
              Icons.monitor_heart_rounded,
              color: Colors.black,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PAINEL ESPORTIVO',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_distanciaCorridas.toStringAsFixed(1)} km corridos',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_totalPassos passos registrados e $_metasAtingidas metas atingidas.',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorridaSection() {
    final metricas = [
      _MetricData(
        titulo: 'Total de corridas',
        valor: '$_totalCorridas',
        icon: Icons.flag_rounded,
        color: AppColors.primary,
      ),
      _MetricData(
        titulo: 'Total de km',
        valor: '${_distanciaCorridas.toStringAsFixed(2)} km',
        icon: Icons.route_rounded,
        color: AppColors.accent2,
      ),
      _MetricData(
        titulo: 'Tempo correndo',
        valor: _formatarTempo(_tempoCorridas),
        icon: Icons.timer_rounded,
        color: AppColors.accent1,
      ),
      _MetricData(
        titulo: 'Calorias',
        valor: '${_caloriasCorridas.toStringAsFixed(0)} kcal',
        icon: Icons.local_fire_department_rounded,
        color: AppColors.accent2,
      ),
      _MetricData(
        titulo: 'Melhor ritmo',
        valor: _formatarRitmo(_melhorRitmoSegundosPorKm),
        icon: Icons.speed_rounded,
        color: AppColors.primary,
      ),
      _MetricData(
        titulo: 'Maior distancia',
        valor: '${_maiorDistanciaCorrida.toStringAsFixed(2)} km',
        icon: Icons.emoji_events_rounded,
        color: AppColors.accent3,
      ),
      _MetricData(
        titulo: 'Vel. media geral',
        valor: '${_velocidadeMediaGeral.toStringAsFixed(1)} km/h',
        icon: Icons.trending_up_rounded,
        color: AppColors.accent1,
      ),
    ];

    return _StatsSection(
      title: 'Corrida',
      subtitle: 'Volume, ritmo e consistencia',
      child: _metricGrid(metricas),
    );
  }

  Widget _buildPassosSection() {
    final metricas = [
      _MetricData(
        titulo: 'Passos hoje',
        valor: '$passosHoje',
        icon: Icons.today_rounded,
        color: AppColors.primary,
      ),
      _MetricData(
        titulo: 'Media diaria',
        valor: '$_mediaDiariaPassos',
        icon: Icons.calendar_view_day_rounded,
        color: AppColors.accent1,
      ),
      _MetricData(
        titulo: 'Media semanal',
        valor: '$_mediaSemanalPassos',
        icon: Icons.calendar_view_week_rounded,
        color: AppColors.accent2,
      ),
      _MetricData(
        titulo: 'Media mensal',
        valor: '$_mediaMensalPassos',
        icon: Icons.calendar_month_rounded,
        color: AppColors.accent3,
      ),
      _MetricData(
        titulo: 'Recorde diario',
        valor: '$_recordeDiarioPassos',
        icon: Icons.emoji_events_rounded,
        color: AppColors.primary,
      ),
      _MetricData(
        titulo: 'Total de passos',
        valor: '$_totalPassos',
        icon: Icons.directions_walk_rounded,
        color: AppColors.accent1,
      ),
    ];

    return _StatsSection(
      title: 'Passos',
      subtitle: 'Medias, recordes e total acumulado',
      child: _metricGrid(metricas),
    );
  }

  Widget _buildSequenciaCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Consistencia',
            subtitle: 'Sequencia, metas e evolucao semanal',
            icon: Icons.local_fire_department_rounded,
          ),
          const SizedBox(height: 16),
          AppMetricWrap(
            children: [
              AppMetricCard(
                label: 'Sequencia atual',
                value: '$_sequenciaAtual dias',
                icon: Icons.local_fire_department_rounded,
                color: AppColors.accent2,
              ),
              AppMetricCard(
                label: 'Metas atingidas',
                value: '$_metasAtingidas',
                icon: Icons.check_circle_rounded,
                color: AppColors.primary,
              ),
              AppMetricCard(
                label: 'Evolucao semanal',
                value: _evolucaoSemanalTexto,
                icon: Icons.show_chart_rounded,
                color: _evolucaoSemanalCor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WeeklyComparisonBar(
            atual: _passosSemanaAtual,
            anterior: _passosSemanaAnterior,
          ),
        ],
      ),
    );
  }

  Widget _buildGraficosSection() {
    return Column(
      children: [
        _BarChartCard(
          title: 'Ultimos 7 dias',
          subtitle: 'Passos por dia',
          data: _ultimos7Dias,
          color: AppColors.primary,
          valueSuffix: ' passos',
          compactValues: true,
        ),
        const SizedBox(height: 18),
        _BarChartCard(
          title: 'Ultimas 4 semanas',
          subtitle: 'Total de passos por semana',
          data: _ultimas4Semanas,
          color: AppColors.accent1,
          valueSuffix: ' passos',
          compactValues: true,
        ),
        const SizedBox(height: 18),
        _BarChartCard(
          title: 'Ultimos 12 meses',
          subtitle: 'Quilometros corridos por mes',
          data: _ultimos12MesesCorrida,
          color: AppColors.accent2,
          valueSuffix: ' km',
        ),
      ],
    );
  }

  Widget _metricGrid(List<_MetricData> metricas) {
    return AppMetricWrap(
      children: [
        for (final metrica in metricas)
          AppMetricCard(
            label: metrica.titulo,
            value: metrica.valor,
            icon: metrica.icon,
            color: metrica.color,
          ),
      ],
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
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

  String _formatarTempo(int segundos) {
    if (segundos <= 0) return '0 min';
    if (segundos < 60) return '<1 min';

    final horas = segundos ~/ 3600;
    final minutos = (segundos % 3600) ~/ 60;

    if (horas > 0) return '${horas}h ${minutos}min';

    return '${minutos}min';
  }

  String _formatarRitmo(int? segundosPorKm) {
    if (segundosPorKm == null || segundosPorKm <= 0) return '--';

    final minutos = segundosPorKm ~/ 60;
    final segundos = segundosPorKm % 60;

    return '$minutos:${segundos.toString().padLeft(2, '0')} min/km';
  }

  String _mesCurto(int mes) {
    const meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    return meses[(mes - 1).clamp(0, 11)];
  }
}

class _StatsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StatsSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: title,
            subtitle: subtitle,
            icon: Icons.insights_rounded,
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(26),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
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
      ],
    );
  }
}

class _WeeklyComparisonBar extends StatelessWidget {
  final int atual;
  final int anterior;

  const _WeeklyComparisonBar({required this.atual, required this.anterior});

  @override
  Widget build(BuildContext context) {
    final maior = [atual, anterior, 1].reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ComparisonRow(
          label: 'Semana atual',
          value: atual,
          max: maior,
          color: AppColors.primary,
        ),
        const SizedBox(height: 10),
        _ComparisonRow(
          label: 'Semana anterior',
          value: anterior,
          max: maior,
          color: AppColors.accent1,
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;

  const _ComparisonRow({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 118,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: Colors.white.withAlpha(16),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 64,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_ChartData> data;
  final Color color;
  final String valueSuffix;
  final bool compactValues;

  const _BarChartCard({
    required this.title,
    required this.subtitle,
    required this.data,
    required this.color,
    required this.valueSuffix,
    this.compactValues = false,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<double>(
      0,
      (maior, item) => item.value > maior ? item.value : maior,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: title,
            subtitle: subtitle,
            icon: Icons.bar_chart_rounded,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final item in data) ...[
                    _ChartBar(
                      item: item,
                      maxValue: maxValue,
                      color: color,
                      valueSuffix: valueSuffix,
                      compactValues: compactValues,
                    ),
                    const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final _ChartData item;
  final double maxValue;
  final Color color;
  final String valueSuffix;
  final bool compactValues;

  const _ChartBar({
    required this.item,
    required this.maxValue,
    required this.color,
    required this.valueSuffix,
    required this.compactValues,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxValue <= 0
        ? 0.0
        : (item.value / maxValue).clamp(0.0, 1.0);
    final barHeight = 18 + (112 * progress);

    return SizedBox(
      width: 46,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            _formatValue(item.value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 18, end: barHeight),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, height, _) {
              return Container(
                width: 28,
                height: height,
                decoration: BoxDecoration(
                  color: color.withAlpha(210),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (compactValues) {
      if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
      return value.round().toString();
    }

    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }
}
