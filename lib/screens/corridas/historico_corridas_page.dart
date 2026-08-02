import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';
import '../../models/corrida_model.dart';
import '../../services/storage_service.dart';
import '../widgets/activities/activities_navigation_header.dart';
import '../widgets/activities/activity_page_entrance.dart';
import 'corrida_detalhe_page.dart';

class HistoricoCorridasPage extends StatefulWidget {
  const HistoricoCorridasPage({super.key});

  @override
  State<HistoricoCorridasPage> createState() => _HistoricoCorridasPageState();
}

class _HistoricoCorridasPageState extends State<HistoricoCorridasPage> {
  List<_CorridaHistoricoItem> _corridas = const [];
  var _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final corridas = await StorageService.carregarCorridas();
      final items = [
        for (var index = 0; index < corridas.length; index++)
          _CorridaHistoricoItem(indexOriginal: index, corrida: corridas[index]),
      ].reversed.toList(growable: false);
      if (!mounted) return;
      setState(() => _corridas = items);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(_CorridaHistoricoItem item) async {
    final confirmed = await FitConfirmDialog.show(
      context: context,
      title: 'Excluir corrida?',
      message: 'Essa corrida será removida do histórico e dos totais locais.',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await StorageService.removerCorrida(item.indexOriginal);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Corrida excluída do histórico.')),
    );
    await _loadRuns();
  }

  Future<void> _openDetails(CorridaModel corrida) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CorridaDetalhePage(corrida: corrida)),
    );
    if (mounted) await _loadRuns();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ActivityPageEntrance(
          child: CustomScrollView(
            key: const PageStorageKey('historico-corridas-scroll'),
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    FitSpacing.s20,
                    FitSpacing.s12,
                    FitSpacing.s20,
                    FitSpacing.s24,
                  ),
                  child: ActivitiesNavigationHeader(
                    title: 'Histórico de corridas',
                    subtitle: 'Revise seus dados locais de corrida.',
                  ),
                ),
              ),
              if (_loading)
                const SliverToBoxAdapter(child: FitListSkeleton(itemCount: 4))
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: FitErrorState(
                    title: 'Histórico indisponível',
                    error: 'Não foi possível carregar as corridas salvas.',
                    onRetry: _loadRuns,
                  ),
                )
              else if (_corridas.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: FitEmptyState(
                    icon: Icons.directions_run_rounded,
                    title: 'Nenhuma corrida salva',
                    description:
                        'Finalize uma corrida para encontrá-la aqui, mesmo offline.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    FitSpacing.s20,
                    FitLayout.none,
                    FitSpacing.s20,
                    FitSpacing.s32,
                  ),
                  sliver: SliverList.separated(
                    itemCount: _corridas.length,
                    itemBuilder: (context, index) {
                      final item = _corridas[index];
                      return _CorridaCard(
                        corrida: item.corrida,
                        onOpenDetails: () => _openDetails(item.corrida),
                        onDelete: () => _confirmDelete(item),
                      );
                    },
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: FitSpacing.s12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CorridaCard extends StatelessWidget {
  const _CorridaCard({
    required this.corrida,
    required this.onOpenDetails,
    required this.onDelete,
  });

  final CorridaModel corrida;
  final VoidCallback onOpenDetails;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      variant: FitCardVariant.clickable,
      onTap: onOpenDetails,
      semanticLabel:
          'Abrir detalhes da corrida de ${corrida.distancia.toStringAsFixed(2)} quilômetros',
      title: '${corrida.distancia.toStringAsFixed(2)} km',
      subtitle: _dateLabel(corrida),
      leading: const Icon(Icons.directions_run_rounded),
      trailing: FitIconButton(
        icon: Icons.delete_outline_rounded,
        tooltip: 'Excluir corrida',
        semanticLabel: 'Excluir esta corrida do histórico',
        variant: FitIconButtonVariant.danger,
        onPressed: onDelete,
      ),
      child: Wrap(
        spacing: FitSpacing.s20,
        runSpacing: FitSpacing.s12,
        children: [
          _RunMetric(label: 'Tempo', value: _timeLabel(corrida.segundos)),
          _RunMetric(
            label: 'Velocidade média',
            value: '${corrida.averageSpeed.toStringAsFixed(1)} km/h',
          ),
          _RunMetric(label: 'Ritmo', value: _paceLabel(corrida.pace)),
          if (corrida.hasReliableCalories)
            _RunMetric(
              label: 'Calorias',
              value: '${corrida.calories!.toStringAsFixed(0)} kcal',
            ),
        ],
      ),
    );
  }

  static String _timeLabel(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainder = seconds % 60;
    return hours > 0
        ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  static String _paceLabel(double pace) {
    if (pace <= 0) return '--';
    final seconds = (pace * 60).round();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} min/km';
  }

  static String _dateLabel(CorridaModel corrida) {
    final date = DateTime.tryParse(corrida.endTime ?? corrida.data);
    if (date == null) return 'Corrida salva localmente';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _RunMetric extends StatelessWidget {
  const _RunMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: FitSpacing.s2),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _CorridaHistoricoItem {
  const _CorridaHistoricoItem({
    required this.indexOriginal,
    required this.corrida,
  });

  final int indexOriginal;
  final CorridaModel corrida;
}
