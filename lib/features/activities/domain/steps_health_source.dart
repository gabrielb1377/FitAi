enum StepsHealthProvider { none, healthConnect, healthKit }

enum StepsHealthPermissionState {
  unknown,
  granted,
  denied,
  permanentlyDenied,
  unavailable,
  notSupported,
}

class StepsHealthStatus {
  const StepsHealthStatus({
    required this.provider,
    required this.platformSupported,
    required this.available,
    required this.permission,
    required this.message,
  });

  const StepsHealthStatus.notSupported()
    : provider = StepsHealthProvider.none,
      platformSupported = false,
      available = false,
      permission = StepsHealthPermissionState.notSupported,
      message = 'Fonte de saude indisponivel nesta plataforma.';

  final StepsHealthProvider provider;
  final bool platformSupported;
  final bool available;
  final StepsHealthPermissionState permission;
  final String message;

  bool get canAttemptRead =>
      available &&
      (permission == StepsHealthPermissionState.granted ||
          (provider == StepsHealthProvider.healthKit &&
              permission == StepsHealthPermissionState.unknown));
}

class StepsHealthReadResult {
  const StepsHealthReadResult({
    required this.status,
    required this.readAt,
    this.totalSteps,
  });

  final StepsHealthStatus status;
  final DateTime readAt;
  final int? totalSteps;

  bool get hasSnapshot => totalSteps != null;
}

/// Boundary between the daily-steps domain and native health providers.
///
/// A read returns an absolute aggregate for the requested interval. It is not
/// a delta and must never be added to the previous local value.
abstract interface class StepsHealthSource {
  Future<StepsHealthStatus> checkStatus({bool requestPermission = false});

  Future<StepsHealthReadResult> readDailyTotal({
    required DateTime start,
    required DateTime end,
    bool requestPermission = false,
  });

  Future<void> dispose();
}

/// Deterministic source for domain tests and Developer Mode harnesses.
class FakeStepsHealthSource implements StepsHealthSource {
  FakeStepsHealthSource({
    StepsHealthStatus? status,
    int? totalSteps,
    this.error,
  }) : currentStatus =
           status ??
           const StepsHealthStatus(
             provider: StepsHealthProvider.healthConnect,
             platformSupported: true,
             available: true,
             permission: StepsHealthPermissionState.granted,
             message: 'Fonte de saude fake disponivel.',
           ),
       totalSteps = totalSteps == null ? null : _nonNegative(totalSteps);

  StepsHealthStatus currentStatus;
  int? totalSteps;
  Object? error;
  int statusChecks = 0;
  int reads = 0;
  int disposals = 0;

  @override
  Future<StepsHealthStatus> checkStatus({
    bool requestPermission = false,
  }) async {
    statusChecks += 1;
    return currentStatus;
  }

  @override
  Future<StepsHealthReadResult> readDailyTotal({
    required DateTime start,
    required DateTime end,
    bool requestPermission = false,
  }) async {
    reads += 1;
    final failure = error;
    if (failure != null) throw failure;
    return StepsHealthReadResult(
      status: currentStatus,
      readAt: end,
      totalSteps: !currentStatus.canAttemptRead || totalSteps == null
          ? null
          : _nonNegative(totalSteps!),
    );
  }

  @override
  Future<void> dispose() async {
    disposals += 1;
  }

  static int _nonNegative(int value) => value < 0 ? 0 : value;
}
