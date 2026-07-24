import 'package:fitai/core/config/dev_fixtures.dart';
import 'package:fitai/features/home/presentation/pages/home_overview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_test_fixtures.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final entry in homeOfficialScreens().entries) {
    testWidgets('${entry.key} abre sem exceções', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(homeTestHost(entry.value()));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('HOME-002 suporta largura pequena e texto ampliado', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = homeFixtureState();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 700),
          textScaler: TextScaler.linear(1.5),
        ),
        child: homeTestHost(
          HomeOverviewPage(
            state: state,
            xp: DevFixtures.user.xp,
            level: DevFixtures.user.level,
            onOpenGoals: () {},
            onOpenProgress: () {},
            onOpenRecords: () {},
            onOpenChallenges: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('HOME-001 suporta largura pequena e texto ampliado', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 700),
          textScaler: TextScaler.linear(1.5),
        ),
        child: homeTestHost(homeOfficialScreens()['HOME-001']!()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
