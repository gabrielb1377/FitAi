import 'package:flutter/material.dart';

import '../../design_system/fit_design_system.dart';
import '../../models/coach_insight_model.dart';
import '../../models/fitai_meta_model.dart';
import '../../services/coach_insight_service.dart';
import '../../services/metas_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/coach_insights_card.dart';
import 'widgets/meta_category_section.dart';
import 'widgets/metas_coach_card.dart';
import 'widgets/metas_summary_card.dart';

class MetasPage extends StatefulWidget {
  const MetasPage({super.key});

  @override
  State<MetasPage> createState() => _MetasPageState();
}

class _MetasPageState extends State<MetasPage> {
  late Future<FitaiMetasResumo> _future;
  late Future<List<CoachInsightModel>> _coachFuture;

  @override
  void initState() {
    super.initState();
    _future = const MetasService().carregarMetas();
    _coachFuture = const CoachInsightService().gerarInsightsPorTipo('metas');
  }

  Future<void> _recarregar() async {
    final future = const MetasService().carregarMetas();
    final coachFuture = const CoachInsightService().gerarInsightsPorTipo(
      'metas',
    );
    setState(() => _future = future);
    setState(() => _coachFuture = coachFuture);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Metas')),
      body: FutureBuilder<FitaiMetasResumo>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const FitLoading.fullScreen(label: 'Carregando metas');
          }

          final resumo = snapshot.data ?? const FitaiMetasResumo(metas: []);

          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                _horizontalPadding(context),
                16,
                _horizontalPadding(context),
                32,
              ),
              children: [
                MetasSummaryCard(resumo: resumo),
                const SizedBox(height: 16),
                MetasCoachCard(dicas: resumo.dicasCoach),
                const SizedBox(height: 16),
                FutureBuilder<List<CoachInsightModel>>(
                  future: _coachFuture,
                  builder: (context, snapshot) {
                    final insights =
                        snapshot.data ?? const <CoachInsightModel>[];

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const AppGradientCard(
                        child: LinearProgressIndicator(minHeight: 3),
                      );
                    }

                    return CoachInsightsCard(
                      insights: insights.take(3).toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                for (final entry in resumo.porCategoria.entries) ...[
                  MetaCategorySection(categoria: entry.key, metas: entry.value),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return 56;
    if (width >= 700) return 32;
    return 18;
  }
}
