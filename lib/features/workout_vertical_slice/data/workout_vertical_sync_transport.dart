import '../domain/workout_vertical_models.dart';

/// Contrato que o backend devera atender antes de substituir o transporte debug.
abstract interface class WorkoutVerticalSyncTransport {
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event);
}

/// Transporte deterministico e sem rede, exclusivo para demonstracao em debug.
class DebugWorkoutSyncTransport implements WorkoutVerticalSyncTransport {
  bool online = true;
  bool failNextDispatch = false;
  bool conflictNextDispatch = false;
  final List<String> receivedIdempotencyKeys = [];

  @override
  Future<SyncDispatchResult> dispatch(OutboxEventLocal event) async {
    if (!online) throw StateError('Sem conexao.');
    if (failNextDispatch) {
      failNextDispatch = false;
      throw StateError('Falha de sincronizacao simulada.');
    }
    if (conflictNextDispatch) {
      conflictNextDispatch = false;
      return const SyncDispatchResult.conflict();
    }
    if (!receivedIdempotencyKeys.contains(event.idempotencyKey)) {
      receivedIdempotencyKeys.add(event.idempotencyKey);
    }
    return const SyncDispatchResult.confirmed();
  }
}
