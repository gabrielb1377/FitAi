import '../../../core/auth/local_account_data_boundary.dart';
import '../../../services/storage_service.dart';
import '../../../models/corrida_model.dart';
import '../domain/running_metrics.dart';

/// Reads the existing per-user history; no second store or sync/XP writer.
class RunningMetricsRepository {
  const RunningMetricsRepository({this.metrics = const RunningMetrics()});
  final RunningMetrics metrics;
  String get userId => AccountSessionLifecycle.activeUserId ?? 'local';

  Future<List<CorridaModel>> history() async {
    final owner = userId;
    final runs = await StorageService.carregarCorridas(userId: owner);
    return owner == userId ? metrics.history(runs, owner) : const [];
  }

  Future<RunningPostRunSummary?> summary(CorridaModel run) async {
    final owner = userId;
    if (run.userId != owner) return null;
    final runs = await StorageService.carregarCorridas(
      userId: owner,
      includeDeleted: true,
    );
    if (owner != userId) return null;
    return metrics.summary(
      [...runs, if (!runs.any((item) => item.id == run.id)) run],
      owner,
      run.id,
    );
  }
}
