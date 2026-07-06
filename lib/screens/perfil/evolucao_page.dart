import 'package:flutter/material.dart';

import '../../services/evolucao_dashboard_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';
import 'widgets/evolucao_dashboard_widgets.dart';

class EvolucaoPage extends StatefulWidget {
  const EvolucaoPage({super.key});

  @override
  State<EvolucaoPage> createState() => _EvolucaoPageState();
}

class _EvolucaoPageState extends State<EvolucaoPage> {
  late Future<EvolucaoDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = const EvolucaoDashboardService().carregar();
  }

  Future<void> _recarregar() async {
    final future = const EvolucaoDashboardService().carregar();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Evolução')),
      body: FutureBuilder<EvolucaoDashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: AppLoading(message: 'Carregando evolução...'),
            );
          }

          final dados = snapshot.data;

          if (snapshot.hasError || dados == null) {
            return const EvolucaoEmptyState();
          }

          if (!dados.possuiDados) {
            return RefreshIndicator(
              onRefresh: _recarregar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [EvolucaoEmptyState()],
              ),
            );
          }

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
                EvolucaoHero(dados: dados),
                const SizedBox(height: 24),
                const EvolucaoSectionTitle(
                  icon: Icons.check_circle_rounded,
                  title: 'Resumo da semana',
                ),
                const SizedBox(height: 12),
                SemanaResumoCard(semana: dados.semanaAtual),
                const SizedBox(height: 24),
                const EvolucaoSectionTitle(
                  icon: Icons.show_chart_rounded,
                  title: 'Evolução de carga',
                ),
                const SizedBox(height: 12),
                CargaEvolucaoCard(carga: dados.carga),
                const SizedBox(height: 24),
                const EvolucaoSectionTitle(
                  icon: Icons.emoji_events_rounded,
                  title: 'Recordes pessoais',
                ),
                const SizedBox(height: 12),
                RecordesPessoaisCard(recordes: dados.recordes),
                const SizedBox(height: 24),
                const EvolucaoSectionTitle(
                  icon: Icons.calendar_month_rounded,
                  title: 'Frequência',
                ),
                const SizedBox(height: 12),
                FrequenciaCard(frequencia: dados.frequencia),
                const SizedBox(height: 24),
                const EvolucaoSectionTitle(
                  icon: Icons.fitness_center_rounded,
                  title: 'Músculos treinados',
                ),
                const SizedBox(height: 12),
                MusculosTreinadosCard(musculos: dados.musculos),
                const SizedBox(height: 24),
                const EvolucaoSectionTitle(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Coach FitIA',
                ),
                const SizedBox(height: 12),
                CoachFitiaCard(insights: dados.insights),
              ],
            ),
          );
        },
      ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 72;
    if (width >= 760) return 36;
    return 20;
  }
}
