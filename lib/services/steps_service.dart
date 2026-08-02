import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/config/dev_config.dart';
import '../core/config/dev_fixtures.dart';
import '../core/xp/xp_config.dart';
import '../features/activities/domain/steps_data_source.dart';
import '../features/activities/domain/steps_metrics.dart';
import '../models/daily_steps_model.dart';
import '../models/passos_diarios_model.dart';
import 'storage_service.dart';
import 'sync_service.dart';

/// Fonte única local-first para o agregado diário de passos.
///
/// Integrações de sensor e plataformas de saúde não são acionadas por este
/// serviço nesta etapa. Registros já persistidos continuam legíveis e exibem
/// sua origem corretamente.
class StepsService extends ChangeNotifier {
  StepsService._({
    DateTime Function()? now,
    StepsDataSource? seedDataSource,
    bool? seedEnabled,
    this._allowSync = true,
  }) : _now = now ?? DateTime.now,
       _seedDataSource =
           seedDataSource ??
           const SeedStepsDataSource(steps: DevFixtures.steps),
       _seedEnabled = seedEnabled ?? (DevConfig.enabled && DevConfig.fakeSteps);

  static final StepsService instance = StepsService._();

  @visibleForTesting
  factory StepsService.forTesting({
    DateTime Function()? now,
    StepsDataSource? seedDataSource,
    bool seedEnabled = false,
    bool allowSync = false,
  }) {
    return StepsService._(
      now: now,
      seedDataSource: seedDataSource,
      seedEnabled: seedEnabled,
      allowSync: allowSync,
    );
  }

  static const int minDailyGoal = 1000;
  static const int maxDailyGoal = 100000;

  final DateTime Function() _now;
  final StepsDataSource _seedDataSource;
  final bool _seedEnabled;
  final bool _allowSync;

  bool _initialized = false;
  bool _initializing = false;
  bool _syncing = false;
  String _statusMessage = 'Carregando dados locais de passos.';
  List<DailyStepsModel> _history = const [];
  int _dailyGoal = 10000;
  int _weeklyGoal = 70000;
  int _monthlyGoal = 300000;

  bool get initialized => _initialized;
  bool get syncing => _syncing;
  bool get platformSupported => false;
  bool get healthConnectAvailable => false;
  bool get permissionGranted => false;
  bool get usingHealthConnect =>
      todayRecord?.sourceKind == DailyStepsSource.healthConnect;
  bool get isOffline => _history.any(
    (record) =>
        record.syncStatus == DailyStepsSyncStatus.pending ||
        record.syncStatus == DailyStepsSyncStatus.failed,
  );
  bool get hasTodayRecord => todayRecord != null;
  bool get hasConfiguredGoal => _dailyGoal > 0;
  bool get usesSeedData => todayRecord?.sourceKind == DailyStepsSource.seed;

  String get statusMessage => _statusMessage;
  int get dailyGoal => _dailyGoal;
  int get weeklyGoal => _weeklyGoal;
  int get monthlyGoal => _monthlyGoal;

  DailyStepsModel? get todayRecord => _recordFor(_dateKey(_now()));

  /// Compatibilidade para consumidores legados. A ausência de registro é
  /// representada por zero apenas nesta projeção, sem persistir dado falso.
  DailyStepsModel get today {
    return todayRecord ??
        DailyStepsModel(
          userId: DailyStepsModel.defaultUserId,
          date: _dateKey(_now()),
          steps: 0,
          goal: _dailyGoal,
          source: DailyStepsModel.sourceLocal,
          recordedAt: _now(),
          updatedAt: _now(),
        );
  }

  int get stepsToday => today.steps;
  int get remainingSteps => today.remainingSteps;
  double get progressToday => today.progress;
  double? get estimatedDistanceKm => today.estimatedDistanceMeters == null
      ? null
      : today.estimatedDistanceMeters! / 1000;
  double? get estimatedCalories => today.estimatedCalories;
  int? get estimatedActiveMinutes => null;

  List<DailyStepsModel> get history => List.unmodifiable(_history);
  List<PassosDiariosModel> get legacyHistory =>
      _history.map(_toLegacy).toList(growable: false);

  List<DailyStepsModel> recordsForLastDays(int days) {
    if (days <= 0) return const [];
    final last = _day(_now());
    final first = last.subtract(Duration(days: days - 1));
    return _history
        .where((record) => _isInRange(record, first, last))
        .toList(growable: false);
  }

  int get weeklySteps => _weeklySummary.total;
  int get monthlySteps => _monthlySummary.total;
  int get weeklyAverage => _weeklySummary.average;
  int get monthlyAverage => _monthlySummary.average;
  DailyStepsModel? get bestDayThisWeek => _weeklySummary.bestDay;
  int get completedGoalDaysLast30 => _monthlySummary.goalReachedDays;
  int get activeStreak => StepsMetrics.activeStreak(_history, now: _now());
  int get comparisonWithYesterday =>
      StepsMetrics.comparisonWithYesterday(_history, now: _now());

  StepsPeriodSummary get _weeklySummary => StepsMetrics.summarize(
    _history,
    from: _day(_now()).subtract(const Duration(days: 6)),
    to: _day(_now()),
  );

  StepsPeriodSummary get _monthlySummary => StepsMetrics.summarize(
    _history,
    from: _day(_now()).subtract(const Duration(days: 29)),
    to: _day(_now()),
  );

  Future<void> initialize() async {
    if (_initialized || _initializing) return;
    _initializing = true;
    try {
      final goals = await StorageService.carregarMetasPassos();
      _dailyGoal = _validDailyGoal(goals['diaria'] ?? _dailyGoal);
      _weeklyGoal = _validWeeklyGoal(goals['semanal'] ?? _weeklyGoal);
      _monthlyGoal = _validMonthlyGoal(goals['mensal'] ?? _monthlyGoal);
      _history = await _loadLocalHistory();

      if (_history.isEmpty && _seedEnabled) {
        final seeded = await _seedDataSource.read(
          StepsDataQuery(
            from: _day(_now()).subtract(const Duration(days: 6)),
            to: _day(_now()),
            userId: DailyStepsModel.defaultUserId,
            goal: _dailyGoal,
          ),
        );
        _history = await StorageService.salvarDailyStepsHistory(seeded);
        _statusMessage = 'Dados de demonstração ativos somente no debug.';
      } else if (_history.isEmpty) {
        _statusMessage = 'Nenhum dado de passos disponível neste dispositivo.';
      } else {
        _statusMessage = '${today.sourceLabel} atualizados localmente.';
      }

      _initialized = true;
      notifyListeners();
      if (_allowSync) unawaited(_syncPendingRecords());
    } finally {
      _initializing = false;
    }
  }

  /// Atualiza somente o cache local. Não solicita permissões nem ativa uma
  /// integração de plataforma.
  Future<void> refreshLocal() async {
    await initialize();
    _history = await _loadLocalHistory();
    _statusMessage = _history.isEmpty
        ? 'Nenhum dado de passos disponível neste dispositivo.'
        : '${today.sourceLabel} atualizados localmente.';
    notifyListeners();
  }

  /// Mantém a assinatura legada sem acionar Health Connect. A sincronização
  /// de registros reais/manuais usa a outbox já existente quando habilitada.
  Future<void> syncNow({bool requestPermission = false}) async {
    await initialize();
    await _syncPendingRecords();
  }

  Future<void> updateDailyGoal(int daily) {
    return updateGoals(
      daily: daily,
      weekly: _weeklyGoal,
      monthly: _monthlyGoal,
    );
  }

  /// A configuração nova só vale para registros futuros. A meta guardada no
  /// registro diário conserva o contexto histórico daquele dia.
  Future<void> updateGoals({
    required int daily,
    required int weekly,
    required int monthly,
  }) async {
    if (daily < minDailyGoal || daily > maxDailyGoal) {
      throw ArgumentError.value(
        daily,
        'daily',
        'A meta diária deve ficar entre $minDailyGoal e $maxDailyGoal passos.',
      );
    }
    _dailyGoal = daily;
    _weeklyGoal = _validWeeklyGoal(weekly);
    _monthlyGoal = _validMonthlyGoal(monthly);
    await StorageService.salvarMetasPassos(
      diaria: _dailyGoal,
      semanal: _weeklyGoal,
      mensal: _monthlyGoal,
    );
    final today = todayRecord;
    if (today != null) {
      await _saveWithoutXp(
        today.copyWith(
          goal: _dailyGoal,
          updatedAt: _now(),
          syncStatus: DailyStepsSyncStatus.pending,
          version: today.version + 1,
        ),
      );
    }
    _statusMessage = 'Nova meta aplicada a hoje e aos próximos registros.';
    notifyListeners();
  }

  /// Entrada explícita para uma futura UI manual. Não é chamada pela tela
  /// atual, mas preserva o contrato local e permite testes sem sensor.
  Future<void> recordManualSteps({
    required int steps,
    DateTime? date,
    String userId = DailyStepsModel.defaultUserId,
  }) async {
    if (steps < 0) {
      throw ArgumentError.value(
        steps,
        'steps',
        'Passos não podem ser negativos.',
      );
    }
    await initialize();
    final now = _now();
    final key = _dateKey(date ?? now);
    final current = _recordFor(key, userId: userId);
    final record = DailyStepsModel(
      id: current?.recordId,
      userId: userId,
      date: key,
      steps: steps,
      goal: current?.goal ?? _dailyGoal,
      source: DailyStepsModel.sourceManual,
      estimatedDistanceMeters: current?.estimatedDistanceMeters,
      estimatedCalories: current?.estimatedCalories,
      recordedAt: current?.recordedAt ?? now,
      updatedAt: now,
      syncStatus: DailyStepsSyncStatus.pending,
      version: (current?.version ?? 0) + 1,
    );
    await _save(record);
    _statusMessage = 'Registro manual salvo neste dispositivo.';
    notifyListeners();
    if (_allowSync) unawaited(_syncPendingRecords());
  }

  Future<List<DailyStepsModel>> readStepsRange({
    required DateTime from,
    required DateTime to,
    bool requestPermission = false,
  }) async {
    await initialize();
    return _history
        .where((record) => _isInRange(record, from, to))
        .toList(growable: false);
  }

  Future<List<DailyStepsModel>> _loadLocalHistory() async {
    var records = await StorageService.carregarDailyStepsHistory();
    if (!_seedEnabled &&
        records.any((record) => record.sourceKind == DailyStepsSource.seed)) {
      records = await StorageService.removerDailyStepsPorFonte(
        DailyStepsModel.sourceSeed,
      );
    }
    if (records.isNotEmpty) return records;

    final legacySteps = await StorageService.carregarPassos();
    if (legacySteps <= 0) return const [];
    final now = _now();
    final imported = DailyStepsModel(
      userId: DailyStepsModel.defaultUserId,
      date: _dateKey(now),
      steps: legacySteps,
      goal: _dailyGoal,
      source: DailyStepsModel.sourceLocal,
      recordedAt: now,
      updatedAt: now,
      syncStatus: DailyStepsSyncStatus.local,
    );
    return StorageService.salvarDailyStepsHistory([imported]);
  }

  Future<void> _save(DailyStepsModel record) async {
    _history = await StorageService.salvarDailyStepsHistory([record]);
    if (record.sourceKind != DailyStepsSource.seed) {
      await _awardDailyGoalXpIfNeeded(_recordFor(record.date) ?? record);
    }
  }

  Future<void> _syncPendingRecords() async {
    if (_syncing || !_allowSync) return;
    final pending = _history
        .where(
          (record) =>
              record.sourceKind != DailyStepsSource.seed &&
              record.syncStatus != DailyStepsSyncStatus.synced,
        )
        .toList(growable: false);
    if (pending.isEmpty) return;

    _syncing = true;
    notifyListeners();
    try {
      for (final record in pending) {
        final syncingRecord = record.copyWith(
          syncStatus: DailyStepsSyncStatus.syncing,
          updatedAt: _now(),
        );
        await _saveWithoutXp(syncingRecord);
        final result = await SyncService.instance.syncSteps([
          syncingRecord.toJson(),
        ]);
        final now = _now();
        final synced = result == StepsSyncDispatchResult.delivered;
        await _saveWithoutXp(
          syncingRecord.copyWith(
            syncStatus: synced
                ? DailyStepsSyncStatus.synced
                : DailyStepsSyncStatus.pending,
            syncedAt: synced ? now : null,
            clearSyncedAt: !synced,
            updatedAt: now,
          ),
        );
      }
      _statusMessage = isOffline
          ? 'Dados locais aguardando sincronização.'
          : 'Dados locais sincronizados.';
    } catch (_) {
      _statusMessage =
          'Dados locais preservados; a sincronização será tentada novamente.';
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> _saveWithoutXp(DailyStepsModel record) async {
    _history = await StorageService.salvarDailyStepsHistory([record]);
  }

  Future<void> _awardDailyGoalXpIfNeeded(DailyStepsModel current) async {
    if (!current.goalCompleted || current.sourceKind == DailyStepsSource.seed) {
      return;
    }
    final alreadyAwarded = await StorageService.passosMetaDiariaXpConcedido(
      current.date,
    );
    if (alreadyAwarded) return;
    await StorageService.adicionarXp(XpConfig.passosMetaDiaria);
    await StorageService.marcarPassosMetaDiariaXpConcedido(current.date);
  }

  DailyStepsModel? _recordFor(String date, {String? userId}) {
    final key = DailyStepsModel.normalizeDateKey(date, fallback: _now());
    final owner = userId ?? DailyStepsModel.defaultUserId;
    for (final record in _history) {
      if (record.date == key && record.userId == owner) return record;
    }
    return null;
  }

  bool _isInRange(DailyStepsModel record, DateTime from, DateTime to) {
    final date = DateTime.tryParse(record.date);
    if (date == null) return false;
    final day = _day(date);
    return !day.isBefore(_day(from)) && !day.isAfter(_day(to));
  }

  int _validDailyGoal(int value) =>
      value.clamp(minDailyGoal, maxDailyGoal).toInt();
  int _validWeeklyGoal(int value) => value.clamp(5000, 700000).toInt();
  int _validMonthlyGoal(int value) => value.clamp(20000, 3000000).toInt();

  PassosDiariosModel _toLegacy(DailyStepsModel record) {
    return PassosDiariosModel(
      data: record.date,
      passos: record.steps,
      metaDiaria: record.goal,
      distanciaKm: record.estimatedDistanceMeters == null
          ? 0
          : record.estimatedDistanceMeters! / 1000,
      calorias: record.estimatedCalories ?? 0,
      tempoAtivoMinutos: 0,
      origem: record.source,
    );
  }

  String _dateKey(DateTime value) => DailyStepsModel.normalizeDateKey(
    value.toIso8601String(),
    fallback: value,
  );

  DateTime _day(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
