import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/auth/local_account_data_boundary.dart';
import '../core/config/dev_config.dart';
import '../core/config/dev_fixtures.dart';
import '../features/activities/domain/steps_day_policy.dart';
import '../features/activities/domain/steps_data_source.dart';
import '../features/activities/domain/steps_metrics.dart';
import '../features/activities/data/activity_sync_service.dart';
import '../features/progression/progression.dart';
import '../models/daily_steps_model.dart';
import '../models/passos_diarios_model.dart';
import 'health_steps_reader.dart';
import 'storage_service.dart';

typedef StepsUserIdResolver = Future<String> Function();

/// Fonte unica local-first para o agregado diario de passos.
class StepsService extends ChangeNotifier {
  StepsService._({
    DateTime Function()? now,
    StepsDataSource? seedDataSource,
    StepsHealthSource? healthSource,
    StepsDayPolicy? dayPolicy,
    StepsUserIdResolver? userIdResolver,
    bool? seedEnabled,
    this._allowSync = true,
    bool listenAccountChanges = false,
    ProgressionEngine? progressionEngine,
  }) : _now = now ?? DateTime.now,
       _seedDataSource =
           seedDataSource ??
           const SeedStepsDataSource(steps: DevFixtures.steps),
       _healthSource = healthSource ?? PlatformStepsHealthSource(),
       _dayPolicy = dayPolicy ?? const StepsDayPolicy(),
       _userIdResolver = userIdResolver ?? _resolveCurrentUserId,
       _seedEnabled = seedEnabled ?? (DevConfig.enabled && DevConfig.fakeSteps),
       _progressionEngine = progressionEngine ?? ProgressionEngine.instance {
    _listenAccountChanges = listenAccountChanges;
    if (_listenAccountChanges) {
      AccountSessionLifecycle.revision.addListener(_onAccountChanged);
    }
  }

  static final StepsService instance = StepsService._(
    listenAccountChanges: true,
  );

  @visibleForTesting
  factory StepsService.forTesting({
    DateTime Function()? now,
    StepsDataSource? seedDataSource,
    StepsHealthSource? healthSource,
    StepsDayPolicy? dayPolicy,
    StepsUserIdResolver? userIdResolver,
    bool seedEnabled = false,
    bool allowSync = false,
    ProgressionEngine? progressionEngine,
  }) {
    return StepsService._(
      now: now,
      seedDataSource: seedDataSource,
      healthSource: healthSource,
      dayPolicy: dayPolicy,
      userIdResolver:
          userIdResolver ?? () async => DailyStepsModel.defaultUserId,
      seedEnabled: seedEnabled,
      allowSync: allowSync,
      progressionEngine: progressionEngine,
    );
  }

  static const int minDailyGoal = 1000;
  static const int maxDailyGoal = 100000;

  final DateTime Function() _now;
  final StepsDataSource _seedDataSource;
  final StepsHealthSource _healthSource;
  final StepsDayPolicy _dayPolicy;
  final StepsUserIdResolver _userIdResolver;
  final bool _seedEnabled;
  final bool _allowSync;
  late final bool _listenAccountChanges;
  final ProgressionEngine _progressionEngine;

  bool _initialized = false;
  bool _syncing = false;
  bool _lastHealthReadSucceeded = false;
  String _statusMessage = 'Carregando dados locais de passos.';
  String _ownerUserId = DailyStepsModel.defaultUserId;
  List<DailyStepsModel> _history = const [];
  int _dailyGoal = 10000;
  int _weeklyGoal = 70000;
  int _monthlyGoal = 300000;
  StepsHealthStatus _healthStatus = const StepsHealthStatus.notSupported();
  Future<void> _initializationQueue = Future<void>.value();
  Future<StepsHealthReadResult>? _healthRefresh;

  bool get initialized => _initialized;
  bool get syncing => _syncing;
  String get ownerUserId => _ownerUserId;
  StepsHealthStatus get healthStatus => _healthStatus;
  bool get platformSupported => _healthStatus.platformSupported;
  bool get healthConnectAvailable =>
      _healthStatus.provider == StepsHealthProvider.healthConnect &&
      _healthStatus.available;
  bool get healthKitAvailable =>
      _healthStatus.provider == StepsHealthProvider.healthKit &&
      _healthStatus.available;
  bool get permissionGranted =>
      _healthStatus.permission == StepsHealthPermissionState.granted ||
      _lastHealthReadSucceeded;
  bool get usingHealthConnect =>
      todayRecord?.sourceKind == DailyStepsSource.healthConnect;
  bool get usingHealthKit =>
      todayRecord?.sourceKind == DailyStepsSource.healthKit;
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
          userId: _ownerUserId,
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
  StepsStreakResult get streak => StepsMetrics.streak(_history, now: _now());

  int get activeStreak => streak.days;

  StepsDayComparison get dayComparison =>
      StepsMetrics.dayComparison(_history, now: _now());

  int get comparisonWithYesterday => dayComparison.difference ?? 0;

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

  Future<void> initialize() {
    final result = _initializationQueue.then((_) => _initializeCurrentOwner());
    _initializationQueue = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }

  Future<void> _initializeCurrentOwner() async {
    final owner = await _userIdResolver();
    final normalizedOwner = owner.trim().isEmpty
        ? DailyStepsModel.defaultUserId
        : owner.trim();
    if (_initialized && normalizedOwner == _ownerUserId) return;
    _ownerUserId = normalizedOwner;
    _history = const [];
    final goals = await StorageService.carregarMetasPassos(
      userId: _ownerUserId,
    );
    _dailyGoal = _validDailyGoal(goals['diaria'] ?? _dailyGoal);
    _weeklyGoal = _validWeeklyGoal(goals['semanal'] ?? _weeklyGoal);
    _monthlyGoal = _validMonthlyGoal(goals['mensal'] ?? _monthlyGoal);
    _history = await _loadLocalHistory();

    if (_history.isEmpty && _seedEnabled) {
      final seeded = await _seedDataSource.read(
        StepsDataQuery(
          from: _day(_now()).subtract(const Duration(days: 6)),
          to: _day(_now()),
          userId: _ownerUserId,
          goal: _dailyGoal,
        ),
      );
      _history = _onlyCurrentOwner(
        await StorageService.salvarDailyStepsHistory(seeded),
      );
      _statusMessage = 'Dados de demonstração ativos somente no debug.';
    } else if (_history.isEmpty) {
      _statusMessage = 'Nenhum dado de passos disponível neste dispositivo.';
    } else {
      _statusMessage = '${today.sourceLabel} atualizados localmente.';
    }

    try {
      _healthStatus = await _healthSource.checkStatus();
    } on Object {
      _healthStatus = const StepsHealthStatus(
        provider: StepsHealthProvider.none,
        platformSupported: false,
        available: false,
        permission: StepsHealthPermissionState.unavailable,
        message:
            'Fonte de saude indisponivel. Os dados locais foram preservados.',
      );
    }

    _initialized = true;
    notifyListeners();
    if (_allowSync) unawaited(_syncPendingRecords());
  }

  /// Atualiza somente o cache local, sem solicitar permissao nativa.
  Future<void> refreshLocal() async {
    await initialize();
    _history = await _loadLocalHistory();
    _statusMessage = _history.isEmpty
        ? 'Nenhum dado de passos disponível neste dispositivo.'
        : '${today.sourceLabel} atualizados localmente.';
    notifyListeners();
  }

  Future<void> syncNow({bool requestPermission = false}) async {
    await initialize();
    await refreshFromHealth(requestPermission: requestPermission);
    await _syncPendingRecords();
  }

  /// Imports the provider's absolute total for the current local day.
  /// Repeated imports replace the snapshot and never add deltas.
  Future<StepsHealthReadResult> refreshFromHealth({
    bool requestPermission = false,
  }) {
    final inFlight = _healthRefresh;
    if (inFlight != null) return inFlight;

    final refresh = () async {
      await initialize();
      return _readHealthSnapshot(requestPermission: requestPermission);
    }();
    _healthRefresh = refresh;
    return refresh.whenComplete(() {
      if (identical(_healthRefresh, refresh)) _healthRefresh = null;
    });
  }

  Future<StepsHealthReadResult> _readHealthSnapshot({
    required bool requestPermission,
  }) async {
    final range = _dayPolicy.rangeFor(_now());
    StepsHealthReadResult result;
    try {
      result = await _healthSource.readDailyTotal(
        start: range.start,
        end: range.end,
        requestPermission: requestPermission,
      );
    } on Object {
      result = StepsHealthReadResult(
        status: StepsHealthStatus(
          provider: _healthStatus.provider,
          platformSupported: _healthStatus.platformSupported,
          available: _healthStatus.available,
          permission: _healthStatus.permission,
          message:
              'Falha temporaria ao ler passos. O ultimo valor foi mantido.',
        ),
        readAt: _now(),
      );
    }

    _healthStatus = result.status;
    if (!result.hasSnapshot) {
      _lastHealthReadSucceeded = false;
      _statusMessage = result.status.message;
      notifyListeners();
      return result;
    }

    _lastHealthReadSucceeded = true;
    final total = result.totalSteps!.clamp(0, 1 << 30).toInt();
    final source = switch (result.status.provider) {
      StepsHealthProvider.healthConnect => DailyStepsModel.sourceHealthConnect,
      StepsHealthProvider.healthKit => DailyStepsModel.sourceHealthKit,
      StepsHealthProvider.none => DailyStepsModel.sourceDevice,
    };
    final current = _recordFor(range.dayKey);
    if (current != null && current.steps == total && current.source == source) {
      _statusMessage = '${current.sourceLabel} atualizados localmente.';
      notifyListeners();
      return result;
    }

    final now = _now();
    await _save(
      DailyStepsModel(
        id: current?.recordId,
        userId: _ownerUserId,
        date: range.dayKey,
        steps: total,
        goal: current?.goal ?? _dailyGoal,
        source: source,
        estimatedDistanceMeters: current?.estimatedDistanceMeters,
        estimatedCalories: current?.estimatedCalories,
        recordedAt: current?.recordedAt ?? result.readAt,
        updatedAt: now,
        syncStatus: DailyStepsSyncStatus.pending,
        version: (current?.version ?? 0) + 1,
      ),
    );
    _statusMessage = '${today.sourceLabel} atualizados localmente.';
    notifyListeners();
    return result;
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
      userId: _ownerUserId,
      syncRemote: _allowSync,
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
    String? userId,
  }) async {
    if (steps < 0) {
      throw ArgumentError.value(
        steps,
        'steps',
        'Passos não podem ser negativos.',
      );
    }
    await initialize();
    final owner = userId?.trim().isNotEmpty == true
        ? userId!.trim()
        : _ownerUserId;
    if (owner != _ownerUserId) {
      throw StateError('Nao e permitido registrar passos para outra conta.');
    }
    final now = _now();
    final key = _dateKey(date ?? now);
    final current = _recordFor(key, userId: owner);
    final record = DailyStepsModel(
      id: current?.recordId,
      userId: owner,
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
    if (requestPermission) {
      await refreshFromHealth(requestPermission: true);
    }
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
    records = _onlyCurrentOwner(records);
    if (records.isNotEmpty) return records;

    if (!await _canImportLegacyForOwner()) return const [];
    final legacySteps = await StorageService.carregarPassos();
    if (legacySteps <= 0) return const [];
    final now = _now();
    final imported = DailyStepsModel(
      userId: _ownerUserId,
      date: _dateKey(now),
      steps: legacySteps,
      goal: _dailyGoal,
      source: DailyStepsModel.sourceLocal,
      recordedAt: now,
      updatedAt: now,
      syncStatus: DailyStepsSyncStatus.local,
    );
    return _onlyCurrentOwner(
      await StorageService.salvarDailyStepsHistory([imported]),
    );
  }

  Future<void> _save(DailyStepsModel record) async {
    _history = _onlyCurrentOwner(
      await StorageService.salvarDailyStepsHistory([record]),
    );
    if (record.sourceKind != DailyStepsSource.seed) {
      await _awardDailyGoalXpIfNeeded(_recordFor(record.date) ?? record);
    }
  }

  Future<void> _syncPendingRecords() async {
    if (_syncing || !_allowSync) return;
    _syncing = true;
    notifyListeners();
    try {
      ActivitySyncService.instance.registerUser(_ownerUserId);
      await ActivitySyncService.instance.syncUser(_ownerUserId);
      _history = _onlyCurrentOwner(
        await StorageService.carregarDailyStepsHistory(),
      );
      if (!_history.any(
        (record) =>
            record.sourceKind != DailyStepsSource.seed &&
            record.syncStatus != DailyStepsSyncStatus.synced,
      )) {
        await _progressionEngine.syncRemote();
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
    _history = _onlyCurrentOwner(
      await StorageService.salvarDailyStepsHistory([record]),
    );
  }

  Future<void> _awardDailyGoalXpIfNeeded(DailyStepsModel current) async {
    if (!current.goalCompleted || current.sourceKind == DailyStepsSource.seed) {
      return;
    }
    await _progressionEngine.recordDailyStepsGoal(
      steps: _toProgressionSteps(current),
      sources: ProgressionSourceData(
        steps: [
          for (final record in _history)
            if (record.userId == current.userId) _toProgressionSteps(record),
        ],
        workoutsAvailable: false,
        runsAvailable: false,
        favoritesAvailable: false,
      ),
    );
  }

  ProgressionStepsSource _toProgressionSteps(DailyStepsModel record) =>
      ProgressionStepsSource(
        userId: record.userId,
        date: _dayPolicy.dateForDayKey(record.date),
        steps: record.steps,
        goal: record.goal,
        isSeed: record.sourceKind == DailyStepsSource.seed,
      );

  DailyStepsModel? _recordFor(String date, {String? userId}) {
    final key = DailyStepsModel.normalizeDateKey(date, fallback: _now());
    final owner = userId ?? _ownerUserId;
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

  @visibleForTesting
  String dayKeyFor(DateTime value) => _dateKey(value);

  String _dateKey(DateTime value) => _dayPolicy.dayKey(value);

  DateTime _day(DateTime value) {
    return _dayPolicy.dateForDayKey(_dayPolicy.dayKey(value));
  }

  List<DailyStepsModel> _onlyCurrentOwner(Iterable<DailyStepsModel> records) =>
      records
          .where((record) => record.userId == _ownerUserId)
          .toList(growable: false);

  Future<bool> _canImportLegacyForOwner() async {
    if (_ownerUserId == DailyStepsModel.defaultUserId ||
        _ownerUserId == 'debug-gabriel') {
      return true;
    }
    if (AccountSessionLifecycle.activeUserId != _ownerUserId) return false;
    final owner = await LocalAccountDataBoundary().activeOwner();
    return owner == LocalAccountDataBoundary.scopeForUser(_ownerUserId);
  }

  void _onAccountChanged() {
    _initialized = false;
    _history = const [];
    _ownerUserId = DailyStepsModel.defaultUserId;
    _statusMessage = 'Carregando dados locais de passos.';
    notifyListeners();
  }

  static Future<String> _resolveCurrentUserId() async {
    final active = AccountSessionLifecycle.activeUserId;
    if (active != null) return active;
    return DevConfig.enabled && DevConfig.fakeUser
        ? 'debug-gabriel'
        : DailyStepsModel.defaultUserId;
  }

  @override
  void dispose() {
    if (_listenAccountChanges) {
      AccountSessionLifecycle.revision.removeListener(_onAccountChanged);
    }
    unawaited(_healthSource.dispose());
    super.dispose();
  }
}
