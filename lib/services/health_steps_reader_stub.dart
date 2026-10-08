import '../features/activities/domain/steps_health_source.dart';

class PlatformStepsHealthSource implements StepsHealthSource {
  @override
  Future<StepsHealthStatus> checkStatus({
    bool requestPermission = false,
  }) async => const StepsHealthStatus.notSupported();

  @override
  Future<StepsHealthReadResult> readDailyTotal({
    required DateTime start,
    required DateTime end,
    bool requestPermission = false,
  }) async {
    return StepsHealthReadResult(
      status: const StepsHealthStatus.notSupported(),
      readAt: end,
    );
  }

  @override
  Future<void> dispose() async {}
}

typedef PlatformHealthStepsReader = PlatformStepsHealthSource;
