class HealthStepsAvailability {
  const HealthStepsAvailability({
    required this.platformSupported,
    required this.available,
    required this.message,
  });

  final bool platformSupported;
  final bool available;
  final String message;
}

class PlatformHealthStepsReader {
  Future<HealthStepsAvailability> checkAvailability() async {
    return const HealthStepsAvailability(
      platformSupported: false,
      available: false,
      message: 'Health Connect indisponivel nesta plataforma.',
    );
  }

  Future<bool> ensureStepsPermission({required bool requestPermission}) async {
    return false;
  }

  Future<int> readSteps({
    required DateTime start,
    required DateTime end,
  }) async {
    return 0;
  }
}
