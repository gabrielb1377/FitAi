import 'package:fitai/core/config/dev_fixtures.dart';
import 'package:fitai/features/home/presentation/pages/home_recent_activity_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'home_test_fixtures.dart';

void main() {
  testWidgets('mantem as atividades diarias e o historico visiveis', (
    tester,
  ) async {
    final state = homeFixtureState();
    await tester.pumpWidget(
      homeTestHost(
        HomeRecentActivityPage(
          history: state.history,
          steps: DevFixtures.steps,
          distance: DevFixtures.running.distanceKm,
          onOpenWorkout: (_) {},
          onOpenRunning: () {},
          onOpenSteps: () {},
        ),
      ),
    );

    expect(find.text('Upper A'), findsOneWidget);
    expect(find.text('Lower A'), findsOneWidget);
    expect(find.text('Corrida ao ar livre'), findsOneWidget);
    expect(find.text('7.542 passos'), findsOneWidget);

    expect(
      tester.getTopLeft(find.text('Corrida ao ar livre')).dy,
      lessThan(tester.getTopLeft(find.text('7.542 passos')).dy),
    );
  });
}
