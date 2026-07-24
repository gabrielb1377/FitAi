import 'dart:io';

import 'package:fitai/debug/design_system_showcase/pages/domain_showcase_pages.dart';
import 'package:fitai/design_system/fit_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {double textScale = 1, double width = 420}) {
    return MaterialApp(
      theme: FitTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 900),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(FitSpacing.s16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('DS3 M04 · catálogo público', () {
    testWidgets('renderiza os componentes representativos obrigatórios', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              FitPlanCard(name: 'Plano A', objective: 'Hipertrofia'),
              SizedBox(height: FitSpacing.s8),
              FitSeriesRow(
                data: FitSeriesDisplayData(
                  index: 1,
                  repetitions: '10',
                  weight: 50,
                ),
              ),
              SizedBox(height: FitSpacing.s8),
              FitRestTimerWidget(remainingLabel: '00:45', progress: .75),
              SizedBox(height: FitSpacing.s8),
              FitWorkoutMiniPlayer(title: 'Upper A', progress: .4),
              SizedBox(height: FitSpacing.s8),
              FitActivityCard(title: 'Corrida', icon: FitIcons.running),
              SizedBox(height: FitSpacing.s8),
              FitRunControlBar(active: false),
              SizedBox(height: FitSpacing.s8),
              FitStepsProgressRing(progress: .72, stepsLabel: '7.240'),
              SizedBox(height: FitSpacing.s8),
              FitExerciseCard(name: 'Supino reto', category: 'Peito'),
              SizedBox(height: FitSpacing.s8),
              FitNutritionSummaryCard(
                metrics: [
                  FitMetricData(
                    label: 'Calorias',
                    value: '1.820',
                    icon: FitIcons.calories,
                  ),
                ],
              ),
              SizedBox(height: FitSpacing.s8),
              FitProfileHeader(name: 'Gabriel', subtitle: 'Nível 18'),
              SizedBox(height: FitSpacing.s8),
              FitSubscriptionPlanCard(name: 'Anual', priceLabel: 'R\$ 149,90'),
              SizedBox(height: FitSpacing.s8),
              FitSettingsTile(title: 'Tema', icon: FitIcons.settings),
            ],
          ),
        ),
      );

      expect(find.byType(FitPlanCard), findsOneWidget);
      expect(find.byType(FitSeriesRow), findsOneWidget);
      expect(find.byType(FitRestTimerWidget), findsOneWidget);
      expect(find.byType(FitWorkoutMiniPlayer), findsOneWidget);
      expect(find.byType(FitActivityCard), findsOneWidget);
      expect(find.byType(FitRunControlBar), findsOneWidget);
      expect(find.byType(FitStepsProgressRing), findsOneWidget);
      expect(find.byType(FitExerciseCard), findsOneWidget);
      expect(find.byType(FitNutritionSummaryCard), findsOneWidget);
      expect(find.byType(FitProfileHeader), findsOneWidget);
      expect(find.byType(FitSubscriptionPlanCard), findsOneWidget);
      expect(find.byType(FitSettingsTile), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('propaga callbacks sem manter lógica de negócio', (
      tester,
    ) async {
      var planTaps = 0;
      var seriesToggles = 0;
      var pauseTaps = 0;
      var skipTaps = 0;
      var addTaps = 0;
      var runStarts = 0;
      var settingsTaps = 0;

      await tester.pumpWidget(
        host(
          Column(
            children: [
              FitPlanCard(name: 'Plano acionável', onTap: () => planTaps++),
              FitSeriesRow(
                data: const FitSeriesDisplayData(index: 1, repetitions: '12'),
                onToggleCompleted: (_) => seriesToggles++,
              ),
              FitRestTimerWidget(
                remainingLabel: '00:30',
                progress: .5,
                onTogglePause: () => pauseTaps++,
                onSkip: () => skipTaps++,
                onAddTime: () => addTaps++,
              ),
              FitRunControlBar(active: false, onStart: () => runStarts++),
              FitSettingsTile(
                title: 'Abrir preferências',
                onTap: () => settingsTaps++,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Plano acionável'));
      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.text('Pausar'));
      await tester.tap(find.text('Pular'));
      await tester.tap(find.text('Adicionar tempo'));
      await tester.tap(find.text('Iniciar corrida'));
      await tester.tap(find.text('Abrir preferências'));
      await tester.pump();

      expect(planTaps, 1);
      expect(seriesToggles, 1);
      expect(pauseTaps, 1);
      expect(skipTaps, 1);
      expect(addTaps, 1);
      expect(runStarts, 1);
      expect(settingsTaps, 1);
    });

    testWidgets('respeita loading e disabled controlados externamente', (
      tester,
    ) async {
      var disabledTaps = 0;
      await tester.pumpWidget(
        host(
          Column(
            children: [
              const FitNutritionSummaryCard(metrics: [], loading: true),
              FitSubscriptionPlanCard(
                name: 'Plano indisponível',
                priceLabel: 'R\$ 0,00',
                enabled: false,
                onTap: () => disabledTaps++,
              ),
              const FitSettingsTile(
                title: 'Configuração bloqueada',
                enabled: false,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(FitLoadingCard), findsOneWidget);
      await tester.tap(find.text('Plano indisponível'));
      await tester.tap(find.text('Configuração bloqueada'));
      expect(disabledTaps, 0);
    });

    testWidgets('mantém Semantics útil no tema escuro', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        host(
          const Column(
            children: [
              FitStepsProgressRing(progress: .5, stepsLabel: '5.000 passos'),
              FitSubscriptionPlanCard(
                name: 'Anual',
                priceLabel: 'R\$ 149,90',
                selected: true,
              ),
              FitSettingsTile(
                title: 'Privacidade',
                semanticLabel: 'Abrir configurações de privacidade',
              ),
            ],
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(RegExp('Progresso de passos, 5.000 passos, 50%')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Anual, R\$ 149,90, selecionado')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Abrir configurações de privacidade'),
        findsOneWidget,
      );
      expect(
        Theme.of(tester.element(find.text('Anual'))).brightness,
        Brightness.dark,
      );
      semantics.dispose();
    });

    testWidgets('texto longo e escala ampliada não geram overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        host(
          const Column(
            children: [
              FitPlanCompactCard(
                name:
                    'Plano de hipertrofia avançado com nomenclatura excepcionalmente longa',
                subtitle:
                    'Descrição extensa para validar quebra, truncamento e escala do sistema',
              ),
              FitWorkoutMiniPlayer(
                title: 'Treino de membros superiores com título muito extenso',
                subtitle: 'Exercício atual com contexto adicional',
                progress: .8,
              ),
              FitSettingsNavigationTile(
                title: 'Preferência com nome muito extenso',
                description:
                    'Descrição detalhada que deve continuar legível sem sobreposição',
                valueLabel: 'Valor longo',
              ),
            ],
          ),
          textScale: 2,
          width: 320,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('showcase percorre os onze domínios em largura estreita', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const cases = <(Widget, String)>[
        (HomeDomainShowcasePage(), 'Home vazia'),
        (PlansDomainShowcasePage(), 'Sem planos'),
        (WorkoutDomainShowcasePage(), 'Treino sem dados'),
        (ActivitiesDomainShowcasePage(), 'Sem atividades'),
        (RunningDomainShowcasePage(), 'Sem corridas'),
        (StepsDomainShowcasePage(), 'Sem passos'),
        (LibraryDomainShowcasePage(), 'Biblioteca vazia'),
        (NutritionDomainShowcasePage(), 'Sem dados nutricionais'),
        (ProfileDomainShowcasePage(), 'Perfil sem dados'),
        (PremiumDomainShowcasePage(), 'Sem ofertas'),
        (SettingsDomainShowcasePage(), 'Sem configurações'),
      ];

      for (final (page, finalLabel) in cases) {
        await tester.pumpWidget(
          MaterialApp(theme: FitTheme.dark(), home: page),
        );
        await tester.pump();
        await tester.scrollUntilVisible(
          find.text(finalLabel),
          600,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow ou erro em ${page.runtimeType}',
        );
      }
    });
  });

  group('DS3 M04 · fronteiras arquiteturais', () {
    test('arquivos de domínio não importam serviços ou plataforma', () {
      final root = Directory('lib/core/design_system/components/domain');
      expect(root.existsSync(), isTrue);

      final forbidden = RegExp(
        r'''(services/|providers/|repositories/|geolocator|camera|health_connector|dart:async|dart:io)''',
      );
      final violations = <String>[];

      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (forbidden.hasMatch(entity.readAsStringSync())) {
          violations.add(entity.path);
        }
      }

      expect(violations, isEmpty);
    });

    test('barrels de todos os domínios estão disponíveis', () {
      const domains = [
        'activities',
        'home',
        'library',
        'nutrition',
        'plans',
        'premium',
        'profile',
        'running',
        'settings',
        'steps',
        'workout',
      ];
      for (final domain in domains) {
        expect(
          File(
            'lib/core/design_system/components/domain/$domain/$domain.dart',
          ).existsSync(),
          isTrue,
          reason: 'Barrel ausente para $domain',
        );
      }
    });
  });
}
