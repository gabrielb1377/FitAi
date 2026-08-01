import 'package:fitai/core/app_router.dart';
import 'package:fitai/core/navigation/app_routes.dart';
import 'package:fitai/core/navigation/app_section.dart';
import 'package:fitai/core/navigation/navigation_controller.dart';
import 'package:fitai/core/navigation/root_router.dart';
import 'package:fitai/core/navigation/section_router.dart';
import 'package:fitai/features/activities/presentation/pages/activities_root_page.dart';
import 'package:fitai/features/home/presentation/pages/home_page.dart';
import 'package:fitai/features/library/presentation/pages/library_root_page.dart';
import 'package:fitai/features/plans/presentation/pages/plans_root_page.dart';
import 'package:fitai/features/profile/presentation/pages/profile_root_page.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_local_store.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_repository.dart';
import 'package:fitai/features/workout_vertical_slice/data/workout_vertical_sync_transport.dart';
import 'package:fitai/features/workout_vertical_slice/domain/workout_vertical_models.dart';
import 'package:fitai/features/workout_vertical_slice/presentation/workout_vertical_slice_page.dart';
import 'package:fitai/features/workout_vertical_slice/presentation/workout_vertical_slice_controller.dart';
import 'package:fitai/screens/dashboard_page.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppRouter resolve somente as raizes oficiais do shell', (
    tester,
  ) async {
    final navigation = NavigationController();
    addTearDown(navigation.dispose);

    final context = await _buildContext(tester);
    final routers = AppRouter.buildSectionRouters(_state(navigation));

    expect(_rootFor(routers, AppShellSection.home, context), isA<HomePage>());
    expect(
      _rootFor(routers, AppShellSection.plans, context),
      isA<PlansRootPage>(),
    );
    expect(
      _rootFor(routers, AppShellSection.activities, context),
      isA<ActivitiesRootPage>(),
    );
    expect(
      _rootFor(routers, AppShellSection.library, context),
      isA<LibraryRootPage>(),
    );
    expect(
      _rootFor(routers, AppShellSection.profile, context),
      isA<ProfileRootPage>(),
    );

    for (final section in AppShellSection.values) {
      navigation.selectSection(section);
      expect(navigation.currentSection, section);
    }
  });

  testWidgets('RootRouter separa a rota oficial da rota debug', (tester) async {
    final context = await _buildContext(tester);
    final officialRoute =
        RootRouter.onGenerateRoute(
              const RouteSettings(name: AppRoutes.appShell),
            )
            as MaterialPageRoute<dynamic>;
    final debugRoute =
        RootRouter.onGenerateRoute(
              const RouteSettings(name: AppRoutes.debugWorkoutVerticalSlice),
            )
            as MaterialPageRoute<dynamic>;

    expect(officialRoute.builder(context), isA<DashboardPage>());
    expect(debugRoute.builder(context), isA<WorkoutVerticalSlicePage>());
    expect(
      officialRoute.settings.name,
      isNot(AppRoutes.debugWorkoutVerticalSlice),
    );
  });

  testWidgets('o teste isolado possui saida para o shell oficial', (
    tester,
  ) async {
    final controller = _workoutController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        routes: {'/app': (_) => const _OfficialShellMarker()},
        home: Builder(
          builder: (context) => WorkoutVerticalSlicePage(
            controller: controller,
            onExit: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/app', (route) => false),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Ambiente de teste'), findsOneWidget);
    expect(find.byType(_OfficialShellMarker), findsNothing);

    await tester.tap(find.byTooltip('Sair do modo de teste'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutVerticalSlicePage), findsNothing);
    expect(find.byType(_OfficialShellMarker), findsOneWidget);
  });
}

Future<BuildContext> _buildContext(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

Widget _rootFor(
  List<SectionRouter> routers,
  AppShellSection section,
  BuildContext context,
) => routers
    .singleWhere((router) => router.section == section)
    .rootBuilder(context);

AppRouteState _state(NavigationController navigation) => AppRouteState(
  nome: 'Gabriel',
  peso: '70 kg',
  altura: '175 cm',
  idade: '18',
  passos: 0,
  distancia: 0,
  velocidadeMedia: 0,
  segundos: 0,
  xp: 0,
  nivel: 1,
  corridaIniciada: false,
  conquistaPrimeiraCorrida: false,
  conquista10Km: false,
  iniciarCorrida: () {},
  pararCorrida: () async {},
  carregarDados: () async {},
  onSelectTab: navigation.selectIndex,
);

class _OfficialShellMarker extends StatelessWidget {
  const _OfficialShellMarker();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Shell oficial')));
}

WorkoutVerticalSliceController _workoutController() {
  final transport = DebugWorkoutSyncTransport();
  return WorkoutVerticalSliceController(
    repository: WorkoutVerticalRepository(
      localStore: _MemoryWorkoutStore(),
      transport: transport,
    ),
    debugTransport: transport,
  );
}

class _MemoryWorkoutStore implements WorkoutVerticalLocalStore {
  WorkoutSliceSnapshot _snapshot = const WorkoutSliceSnapshot.empty();

  @override
  Future<WorkoutSliceSnapshot> read() async => _snapshot;

  @override
  Future<void> write(WorkoutSliceSnapshot snapshot) async {
    _snapshot = WorkoutSliceSnapshot.fromJson(snapshot.toJson());
  }
}
