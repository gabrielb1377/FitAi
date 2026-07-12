import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';
import '../../models/fitai_recorde_model.dart';
import '../../services/recorde_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/recorde_category_section.dart';
import 'widgets/recorde_filter_bar.dart';
import 'widgets/recordes_summary_card.dart';

class RecordesPage extends StatefulWidget {
  const RecordesPage({super.key});

  @override
  State<RecordesPage> createState() => _RecordesPageState();
}

class _RecordesPageState extends State<RecordesPage> {
  late Future<List<FitaiRecordeModel>> _future;
  String _filtro = RecordeFilterBar.todos;

  @override
  void initState() {
    super.initState();
    _future = const RecordeService().carregarRecordes();
  }

  Future<void> _recarregar() async {
    final future = const RecordeService().carregarRecordes();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Recordes Pessoais')),
      body: FutureBuilder<List<FitaiRecordeModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const FitLoading.fullScreen(label: 'Carregando recordes');
          }

          final recordes = snapshot.data ?? const <FitaiRecordeModel>[];

          if (recordes.isEmpty) {
            return RefreshIndicator(
              onRefresh: _recarregar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: const [_RecordesEmptyState()],
              ),
            );
          }

          final filtrados = _filtrar(recordes);
          final grupos = _agrupar(filtrados);

          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                _horizontalPadding(context),
                18,
                _horizontalPadding(context),
                36,
              ),
              children: [
                RecordesSummaryCard(recordes: recordes),
                const SizedBox(height: 18),
                RecordeFilterBar(
                  filtroAtual: _filtro,
                  onChanged: (value) => setState(() => _filtro = value),
                ),
                const SizedBox(height: 22),
                if (filtrados.isEmpty)
                  const _RecordesEmptyState()
                else
                  for (final categoria in FitaiRecordeCategoria.todas) ...[
                    if (grupos[categoria]?.isNotEmpty ?? false) ...[
                      RecordeCategorySection(
                        categoria: categoria,
                        recordes: grupos[categoria]!,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<FitaiRecordeModel> _filtrar(List<FitaiRecordeModel> recordes) {
    if (_filtro == RecordeFilterBar.todos) return recordes;
    return recordes.where((recorde) => recorde.categoria == _filtro).toList();
  }

  Map<String, List<FitaiRecordeModel>> _agrupar(
    List<FitaiRecordeModel> recordes,
  ) {
    final grupos = {
      for (final categoria in FitaiRecordeCategoria.todas)
        categoria: <FitaiRecordeModel>[],
    };

    for (final recorde in recordes) {
      grupos.putIfAbsent(recorde.categoria, () => <FitaiRecordeModel>[]);
      grupos[recorde.categoria]!.add(recorde);
    }

    return grupos;
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return (width - 560) / 2;
    return 20;
  }
}

class _RecordesEmptyState extends StatelessWidget {
  const _RecordesEmptyState();

  @override
  Widget build(BuildContext context) {
    return AppGradientCard(
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(24),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Nenhum recorde ainda',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Finalize treinos ou corridas para registrar suas melhores marcas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }
}
