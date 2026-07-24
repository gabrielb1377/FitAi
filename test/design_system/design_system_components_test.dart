import 'package:fitai/design_system/fit_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) {
  return MaterialApp(
    theme: FitTheme.dark(),
    home: Scaffold(body: SafeArea(child: child)),
  );
}

void main() {
  test('tokens preservam papeis semanticos oficiais', () {
    expect(FitColors.ai, isNot(FitColors.info));
    expect(FitColors.energy, FitColors.running);
    expect(FitColors.achievement, isNot(FitColors.primary));
    expect(FitElevation.level1, FitShadows.low);
    expect(FitDuration.transition, FitDuration.normal);
  });

  testWidgets('catalogo de cards renderiza em largura mobile', (tester) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          padding: const EdgeInsets.all(FitSpacing.s20),
          child: Column(
            children: [
              const FitHeroCard(
                title: 'Resumo principal',
                subtitle: 'Contexto curto e acionavel.',
                icon: FitIcons.home,
              ),
              const SizedBox(height: FitSpacing.s12),
              const FitWorkoutHero(
                title: 'Treino A',
                subtitle: 'Peito e triceps',
                progress: .5,
              ),
              const SizedBox(height: FitSpacing.s12),
              const FitWorkoutCard(name: 'Treino A', subtitle: '4 exercicios'),
              const SizedBox(height: FitSpacing.s12),
              const FitPlanCard(name: 'Plano ABC', objective: 'Hipertrofia'),
              const SizedBox(height: FitSpacing.s12),
              const FitCoachInsightCard(
                title: 'Insight do Coach',
                insight: 'Mantenha a consistencia desta semana.',
              ),
              const SizedBox(height: FitSpacing.s12),
              const FitActivityCard(
                title: 'Corridas',
                subtitle: 'Ultima atividade ontem',
                icon: FitIcons.running,
              ),
              const SizedBox(height: FitSpacing.s12),
              const FitExerciseCard(name: 'Supino reto', category: 'Peito'),
              const SizedBox(height: FitSpacing.s12),
              const FitMetricCard(
                label: 'Passos',
                value: '8.240',
                icon: FitIcons.steps,
              ),
              const SizedBox(height: FitSpacing.s12),
              const FitProgressCard(
                title: 'Meta semanal',
                value: '3 de 5',
                progress: .6,
                icon: FitIcons.progress,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Resumo principal'), findsOneWidget);
    expect(find.text('Plano ABC'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('componentes compactos e estruturais respondem ao tema', (
    tester,
  ) async {
    var taps = 0;
    final searchController = TextEditingController();
    addTearDown(searchController.dispose);

    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          padding: const EdgeInsets.all(FitSpacing.s20),
          child: Column(
            children: [
              const FitProfileHeader(name: 'Gabriel', subtitle: 'Nivel 4'),
              const SizedBox(height: FitSpacing.s16),
              const FitSectionHeader(
                title: 'Evolucao',
                subtitle: 'Resumo da semana',
              ),
              const SizedBox(height: FitSpacing.s16),
              FitQuickActionCard(
                label: 'Criar com IA',
                description: 'Gerar um plano',
                icon: FitIcons.ai,
                onTap: () => taps++,
              ),
              const SizedBox(height: FitSpacing.s16),
              const FitHorizontalMetric(
                label: 'Distancia',
                value: '5,2 km',
                icon: FitIcons.running,
              ),
              const SizedBox(height: FitSpacing.s16),
              const FitStatChip(label: 'dias', value: '4'),
              const SizedBox(height: FitSpacing.s16),
              FitActionTile(
                title: 'Notificacoes',
                description: 'Preferencias do aplicativo',
                icon: Icons.notifications_rounded,
                onTap: () => taps++,
              ),
              const SizedBox(height: FitSpacing.s16),
              FitSearchField(controller: searchController),
              const SizedBox(height: FitSpacing.s16),
              const FitSkeleton(height: 48),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Criar com IA'));
    await tester.tap(find.text('Notificacoes'));
    expect(taps, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navegacao, dialog e bottom sheet expoem contratos controlados', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: FitTheme.dark(),
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: const SizedBox.shrink(),
              bottomNavigationBar: FitBottomNavigation(
                selectedIndex: selected,
                destinations: const [
                  FitNavigationDestination(label: 'Home', icon: FitIcons.home),
                  FitNavigationDestination(
                    label: 'Planos',
                    icon: FitIcons.plans,
                  ),
                ],
                onSelected: (value) => setState(() => selected = value),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Planos'));
    await tester.pump();
    expect(selected, 1);

    await tester.pumpWidget(
      _app(const FitDialog(title: 'Confirmar', message: 'Deseja continuar?')),
    );
    expect(find.byType(FitDialog), findsOneWidget);

    await tester.pumpWidget(
      _app(const FitBottomSheet(title: 'Filtros', child: Text('Conteudo'))),
    );
    expect(find.byType(FitBottomSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
