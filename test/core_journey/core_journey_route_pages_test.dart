import 'package:fitai/core/navigation/app_section.dart';
import 'package:fitai/core/navigation/app_routes.dart';
import 'package:fitai/core/navigation/deep_link.dart';
import 'package:fitai/features/core_journey/presentation/core_journey_route_pages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extrai IDs dos caminhos web e fitia do Core V1', () {
    final appPlan = AppDeepLinkTarget(
      uri: Uri.parse('fitia://plans/plan-1'),
      section: AppShellSection.plans,
      routeName: AppRoutes.corePlanDetail,
    );
    final webWorkout = AppDeepLinkTarget(
      uri: Uri.parse('/workout/session-1/summary'),
      section: AppShellSection.plans,
      routeName: AppRoutes.coreWorkoutSummary,
    );
    final history = AppDeepLinkTarget(
      uri: Uri.parse('/activities/workout/session-2'),
      section: AppShellSection.activities,
      routeName: AppRoutes.coreWorkoutHistory,
    );

    expect(coreJourneyRouteId(appPlan), 'plan-1');
    expect(coreJourneyRouteId(webWorkout), 'session-1');
    expect(coreJourneyRouteId(history), 'session-2');
  });
}
