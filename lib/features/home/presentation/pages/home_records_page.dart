import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/fitai_recorde_model.dart';
import '../../../../models/historico_treino_model.dart';
import '../../../../services/storage_service.dart';
import '../widgets/home_detail_scaffold.dart';
import '../widgets/home_official_components.dart';

class HomeRecordsPage extends StatefulWidget {
  const HomeRecordsPage({super.key, required this.history, this.loader});

  final List<HistoricoTreinoModel> history;
  final Future<List<FitaiRecordeModel>> Function()? loader;

  @override
  State<HomeRecordsPage> createState() => _HomeRecordsPageState();
}

class _HomeRecordsPageState extends State<HomeRecordsPage> {
  late Future<List<FitaiRecordeModel>> _future = _load();
  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    final seconds = widget.history.fold<int>(
      0,
      (total, item) => total + item.tempoSegundos,
    );
    final calories = widget.history.fold<int>(
      0,
      (total, item) => total + item.caloriasEstimadas,
    );
    final volume = widget.history.fold<double>(
      0,
      (total, item) => total + item.volumeTotal,
    );
    return HomeDetailScaffold(
      title: 'Estatísticas gerais',
      subtitle: '',
      actions: [
        FitIconButton(
          icon: FitIcons.calendar,
          tooltip: 'Atualizar estatísticas',
          onPressed: _reload,
        ),
      ],
      child: HomePageBody(
        onRefresh: () async => _reload(),
        children: [
          HomeFilterStrip(
            labels: const ['Geral', 'Treinos', 'Atividades', 'Corpo'],
            selectedIndex: _selected,
            onSelected: (value) => setState(() => _selected = value),
          ),
          const HomeSectionGap(),
          const FitSectionHeader(title: 'Resumo geral'),
          const SizedBox(height: FitSpacing.s12),
          HomeMetricGrid(
            items: [
              HomeMetricItem(
                label: 'Treinos',
                value: '${widget.history.length}',
                icon: FitIcons.workout,
              ),
              HomeMetricItem(
                label: 'Tempo total',
                value: homeFormatDuration(seconds),
                icon: FitIcons.time,
              ),
              HomeMetricItem(
                label: 'Calorias',
                value: '${homeFormatNumber(calories)} kcal',
                icon: FitIcons.calories,
                color: FitColors.energy,
              ),
              HomeMetricItem(
                label: 'Volume total',
                value: '${homeFormatNumber(volume)} kg',
                icon: FitIcons.weight,
                color: FitColors.xp,
              ),
            ],
          ),
          const HomeSectionGap(),
          HomeChartCard(
            title: 'Evolução semanal',
            points: _weeklyPoints(),
            semanticLabel: 'Tempo de treino nos últimos sete dias',
          ),
          const HomeSectionGap(),
          FutureBuilder<List<FitaiRecordeModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const FitSkeleton(height: 160);
              }
              if (snapshot.hasError) {
                return FitErrorState(
                  error: 'Não foi possível carregar seus recordes.',
                  onRetry: _reload,
                );
              }
              final records = snapshot.data ?? const [];
              return _RecordsContent(records: records);
            },
          ),
        ],
      ),
    );
  }

  Future<List<FitaiRecordeModel>> _load() {
    return (widget.loader ?? StorageService.carregarRecordes)();
  }

  void _reload() => setState(() => _future = _load());

  List<FitChartPoint> _weeklyPoints() {
    final now = DateTime.now();
    const labels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    return List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      final minutes =
          widget.history
              .where((item) {
                final date = item.dataHora.toLocal();
                return date.year == day.year &&
                    date.month == day.month &&
                    date.day == day.day;
              })
              .fold<int>(0, (total, item) => total + item.tempoSegundos) /
          60;
      return FitChartPoint(label: labels[day.weekday - 1], value: minutes);
    });
  }
}

class _RecordsContent extends StatelessWidget {
  const _RecordsContent({required this.records});

  final List<FitaiRecordeModel> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const FitEmptyState(
        icon: FitIcons.achievement,
        title: 'Nenhum recorde registrado',
        description: 'Novas melhores marcas aparecerão aqui após seus treinos.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FitSectionHeader(
          title: 'Recordes pessoais',
          badge: FitBadge(label: '${records.length}'),
        ),
        const SizedBox(height: FitSpacing.s12),
        for (final record in records.take(6)) ...[
          HomeListAction(
            title: record.titulo,
            subtitle: '${record.descricao} · ${homeFormatDate(record.data)}',
            value: record.valorFormatado,
            icon: FitIcons.achievement,
            color: FitColors.achievement,
          ),
          const SizedBox(height: FitSpacing.s8),
        ],
      ],
    );
  }
}
