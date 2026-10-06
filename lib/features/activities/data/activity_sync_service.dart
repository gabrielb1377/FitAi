import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/corrida_model.dart';
import '../../../models/daily_steps_model.dart';
import '../../../models/running_session_model.dart';
import '../../../services/storage_service.dart';
import '../../../services/sync_service.dart';
import 'activity_sync_gateway.dart';

typedef ActivityUserIdResolver = Future<String?> Function();

/// Coordenador offline-first de Corridas e Passos.
///
/// Os próprios registros locais (`syncStatus`) são a outbox de domínio. Este
/// serviço usa o transporte autenticado existente e nunca concede XP.
class ActivitySyncService {
  ActivitySyncService._({ActivitySyncGateway? gateway, SyncService? transport})
    : _gateway = gateway ?? HttpActivitySyncGateway(syncService: transport),
      _transport = transport ?? SyncService.instance;

  static final ActivitySyncService instance = ActivitySyncService._();

  @visibleForTesting
  factory ActivitySyncService.forTesting({
    required ActivitySyncGateway gateway,
    SyncService? transport,
  }) => ActivitySyncService._(gateway: gateway, transport: transport);

  final ActivitySyncGateway _gateway;
  final SyncService _transport;
  final Set<String> _syncingUsers = <String>{};
  final Set<String> _registeredUsers = <String>{};

  void registerUser(String userId) {
    final owner = userId.trim();
    if (owner.isEmpty || !_registeredUsers.add(owner)) return;
    _transport.registerDomainFlusher(
      'activity-sync-v2:$owner',
      () => syncUser(owner),
    );
  }

  Future<void> syncUser(String userId) async {
    final owner = userId.trim();
    if (owner.isEmpty || !_syncingUsers.add(owner)) return;
    registerUser(owner);
    try {
      final cursor = await StorageService.carregarActivitySyncCursor(owner);
      final pendingRuns = await StorageService.carregarCorridasPendentes(
        userId: owner,
      );
      final pendingSteps = (await StorageService.carregarDailyStepsHistory())
          .where(
            (record) =>
                record.userId == owner &&
                record.sourceKind != DailyStepsSource.seed &&
                record.syncStatus != DailyStepsSyncStatus.synced,
          )
          .toList(growable: false);
      Map<String, dynamic>? response;
      if (pendingRuns.isNotEmpty || pendingSteps.isNotEmpty) {
        response = await _gateway.push(
          userId: owner,
          deviceId: await _transport.getClientId(),
          afterRevision: cursor,
          runs: pendingRuns.map(_runPayload).toList(growable: false),
          steps: pendingSteps.map(_stepsPayload).toList(growable: false),
        );
      } else {
        response = await _gateway.pull(userId: owner, afterRevision: cursor);
      }
      if (response == null) return;
      await _applyAck(owner, response['ack']);
      await _applyState(owner, response['state']);
    } finally {
      _syncingUsers.remove(owner);
    }
  }

  Map<String, dynamic> _runPayload(CorridaModel run) => {
    'mutationId': run.mutationId,
    'runId': run.id,
    'startedAt': run.startTime,
    'finishedAt': run.endTime ?? run.data,
    'durationSeconds': run.segundos,
    'distanceKm': run.distancia,
    'averageSpeed': run.averageSpeed,
    'paceMinutesPerKm': run.pace,
    'route': run.route.map((point) => point.toJson()).toList(growable: false),
    'calories': run.hasReliableCalories ? run.calories : null,
    'steps': run.steps,
    'deletedAt': run.deletedAt,
  };

  Map<String, dynamic> _stepsPayload(DailyStepsModel record) => {
    'mutationId': record.mutationId,
    'dayKey': record.date,
    'steps': record.steps,
    'goal': record.goal,
    'source': record.sourceKind.storageValue,
    'observedAt': record.updatedAt.toUtc().toIso8601String(),
    'clientVersion': record.version,
  };

  Future<void> _applyAck(String userId, Object? rawAck) async {
    final ack = _map(rawAck);
    final successful = <String>{
      for (final bucket in const ['accepted', 'alreadyApplied', 'updated'])
        for (final item in _list(ack[bucket]))
          if (_map(item)['mutationId'] case final String id) id,
    };
    final rejected = <String>{
      for (final item in _list(ack['rejected']))
        if (_map(item)['mutationId'] case final String id) id,
    };
    final runs = await StorageService.carregarCorridas(
      userId: userId,
      includeDeleted: true,
    );
    for (final run in runs) {
      if (successful.contains(run.mutationId)) {
        await StorageService.atualizarCorrida(
          run.copyWith(syncStatus: RunningSyncStatus.synced),
        );
      } else if (rejected.contains(run.mutationId)) {
        await StorageService.atualizarCorrida(
          run.copyWith(syncStatus: RunningSyncStatus.conflict),
        );
      }
    }
    final steps = await StorageService.carregarDailyStepsHistory();
    for (final record in steps.where((item) => item.userId == userId)) {
      if (successful.contains(record.mutationId)) {
        await StorageService.salvarDailyStepsRemoto(
          record.copyWith(
            syncStatus: DailyStepsSyncStatus.synced,
            syncedAt: DateTime.now(),
          ),
        );
      } else if (rejected.contains(record.mutationId)) {
        await StorageService.salvarDailyStepsRemoto(
          record.copyWith(syncStatus: DailyStepsSyncStatus.conflict),
        );
      }
    }
  }

  Future<void> _applyState(String userId, Object? rawState) async {
    final state = _map(rawState);
    for (final item in _list(state['runs'])) {
      final remote = _remoteRun(userId, _map(item));
      if (remote == null) continue;
      final localRuns = await StorageService.carregarCorridas(
        userId: userId,
        includeDeleted: true,
      );
      CorridaModel? local;
      for (final candidate in localRuns) {
        if (candidate.id == remote.id) {
          local = candidate;
          break;
        }
      }
      if (local != null &&
          local.syncStatus != RunningSyncStatus.synced &&
          !_sameRun(local, remote)) {
        await StorageService.atualizarCorrida(
          local.copyWith(syncStatus: RunningSyncStatus.conflict),
        );
        continue;
      }
      await StorageService.salvarCorridaRemota(remote);
    }
    for (final item in _list(state['steps'])) {
      final remote = _remoteSteps(userId, _map(item));
      if (remote == null) continue;
      final records = await StorageService.carregarDailyStepsHistory();
      DailyStepsModel? local;
      for (final candidate in records) {
        if (candidate.recordId == remote.recordId) {
          local = candidate;
          break;
        }
      }
      if (local == null ||
          _revision(remote.remoteRevision) >= _revision(local.remoteRevision)) {
        await StorageService.salvarDailyStepsRemoto(
          remote.copyWith(version: local?.version ?? remote.version),
        );
      }
    }
    final revision = state['revision']?.toString() ?? '';
    if (RegExp(r'^\d+$').hasMatch(revision)) {
      await StorageService.salvarActivitySyncCursor(userId, revision);
    }
  }

  CorridaModel? _remoteRun(String userId, Map<String, dynamic> json) {
    if (json['runId'] == null || json['revision'] == null) return null;
    return CorridaModel.fromJson({
      'id': json['runId'],
      'userId': userId,
      'distanceKm': json['distanceKm'],
      'durationSeconds': json['durationSeconds'],
      'startTime': json['startedAt'],
      'endTime': json['finishedAt'],
      'data': json['finishedAt'],
      'averageSpeed': json['averageSpeed'],
      'pace': json['paceMinutesPerKm'],
      'route': json['route'],
      'calories': json['calories'],
      'steps': json['steps'],
      'syncStatus': RunningSyncStatus.synced.storageValue,
      'remoteRevision': json['revision'].toString(),
      'updatedAt': json['finishedAt'],
      'deletedAt': json['deletedAt'],
      'finished': true,
    });
  }

  DailyStepsModel? _remoteSteps(String userId, Map<String, dynamic> json) {
    final dayKey = json['dayKey']?.toString() ?? '';
    final observedAt = DateTime.tryParse(json['observedAt']?.toString() ?? '');
    if (dayKey.isEmpty || observedAt == null || json['revision'] == null) {
      return null;
    }
    return DailyStepsModel.fromJson({
      'id': DailyStepsModel.naturalId(userId: userId, date: dayKey),
      'userId': userId,
      'date': dayKey,
      'steps': json['steps'],
      'goal': json['goal'],
      'source': json['source'],
      'recordedAt': observedAt.toIso8601String(),
      'updatedAt': observedAt.toIso8601String(),
      'syncedAt': DateTime.now().toIso8601String(),
      'syncStatus': DailyStepsSyncStatus.synced.storageValue,
      'version': 1,
      'remoteRevision': json['revision'].toString(),
    });
  }

  bool _sameRun(CorridaModel left, CorridaModel right) =>
      left.id == right.id &&
      left.distancia == right.distancia &&
      left.segundos == right.segundos &&
      left.startTime == right.startTime &&
      left.endTime == right.endTime &&
      left.deletedAt == right.deletedAt;

  static int _revision(String value) => int.tryParse(value) ?? 0;
  static Map<String, dynamic> _map(Object? value) => value is Map
      ? Map<String, dynamic>.from(value)
      : const <String, dynamic>{};
  static List<Object?> _list(Object? value) =>
      value is List ? List<Object?>.from(value) : const <Object?>[];
}
