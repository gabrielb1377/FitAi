import 'package:fitai/core/app_router.dart';
import 'package:fitai/core/app_shell.dart';
import 'package:fitai/design_system/components/fit_bottom_navigation.dart';
import 'package:fitai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = ['Home', 'Planos', 'Biblioteca', 'Atividades', 'Perfil'];

void main() {
  test('router define a ordem oficial das cinco abas', () {
    expect(
      AppRouter.destinations.map((destination) => destination.label),
      _labels,
    );
  });

  testWidgets('shell renderiza as cinco abas oficiais e troca o item ativo', (
    tester,
  ) async {
    final selectionChanges = <int>[];
    await tester.pumpWidget(
      _ShellHost(onSelectionChanged: selectionChanges.add),
    );

    expect(find.text('Conteudo Home'), findsOneWidget);
    expect(find.byType(FitBottomNavigation), findsOneWidget);
    for (final label in _labels) {
      expect(find.text(label), findsOneWidget);
    }

    for (var index = 1; index < _labels.length; index++) {
      await tester.tap(find.text(_labels[index]));
      await tester.pumpAndSettle();

      expect(find.text('Conteudo ${_labels[index]}'), findsOneWidget);
      expect(
        tester
            .widget<FitBottomNavigation>(find.byType(FitBottomNavigation))
            .selectedIndex,
        index,
      );
    }

    expect(selectionChanges, [1, 2, 3, 4]);
  });

  testWidgets('shell preserva estado local da aba no IndexedStack', (
    tester,
  ) async {
    await tester.pumpWidget(const _ShellHost());

    expect(find.text('Contador Home: 0'), findsOneWidget);
    final incrementButton = find.ancestor(
      of: find.byIcon(Icons.add),
      matching: find.byType(IconButton),
    );
    tester.widget<IconButton>(incrementButton).onPressed!();
    await tester.pump();
    expect(find.text('Contador Home: 1'), findsOneWidget);

    await tester.tap(find.text('Planos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Contador Home: 1'), findsOneWidget);
  });

  testWidgets('voltar em uma aba raiz retorna para Home antes de fechar', (
    tester,
  ) async {
    await tester.pumpWidget(const _ShellHost());

    await tester.tap(find.text('Atividades'));
    await tester.pumpAndSettle();
    expect(find.text('Conteudo Atividades'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Conteudo Home'), findsOneWidget);
  });
}

class _ShellHost extends StatefulWidget {
  const _ShellHost({this.onSelectionChanged});

  final ValueChanged<int>? onSelectionChanged;

  @override
  State<_ShellHost> createState() => _ShellHostState();
}

class _ShellHostState extends State<_ShellHost> {
  var _selectedIndex = 0;

  static const _destinations = [
    AppRouteDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    AppRouteDestination(
      label: 'Planos',
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
    ),
    AppRouteDestination(
      label: 'Biblioteca',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view,
    ),
    AppRouteDestination(
      label: 'Atividades',
      icon: Icons.directions_run_outlined,
      selectedIcon: Icons.directions_run,
    ),
    AppRouteDestination(
      label: 'Perfil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  final _pages = const [
    _CounterTab(label: 'Home'),
    _StaticTab(label: 'Planos'),
    _StaticTab(label: 'Biblioteca'),
    _StaticTab(label: 'Atividades'),
    _StaticTab(label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: AppNavigationFrame(
        selectedIndex: _selectedIndex,
        destinations: _destinations,
        pages: _pages,
        onDestinationSelected: (index) {
          widget.onSelectionChanged?.call(index);
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

class _StaticTab extends StatelessWidget {
  const _StaticTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Center(child: Text('Conteudo $label'));
}

class _CounterTab extends StatefulWidget {
  const _CounterTab({required this.label});

  final String label;

  @override
  State<_CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<_CounterTab> {
  var _count = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Conteudo ${widget.label}'),
          Text('Contador ${widget.label}: $_count'),
          IconButton(
            tooltip: 'Incrementar ${widget.label}',
            onPressed: () => setState(() => _count++),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
