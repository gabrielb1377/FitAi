import 'package:flutter/material.dart';

import '../../models/fitai_meta_model.dart';
import '../../services/metas_service.dart';
import '../../theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _future = const MetasService().carregarMetas();
  }

  Future<void> _recarregar() async {
    final future = const MetasService().carregarMetas();
    setState(() => _future = future);
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
            return const Center(child: CircularProgressIndicator());
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
