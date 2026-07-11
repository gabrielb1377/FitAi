import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/xp/xp_config.dart';
import '../models/daily_steps_model.dart';
import '../models/passos_diarios_model.dart';
import 'health_steps_reader.dart';
import 'storage_service.dart';
import 'sync_service.dart';

class StepsService extends ChangeNotifier {
  StepsService._();

  static final StepsService instance = StepsService._();

  bool _initialized = false;
  bool _initializing = false;
  bool _syncing = false;
  bool _platformSupported = false;
  bool _healthConnectAvailable = false;
  bool _permissionGranted = false;
  String _statusMessage = 'Usando cache local de passos.';
  List<DailyStepsModel> _history = [];
  int _dailyGoal = 10000;
  int _weeklyGoal = 70000;
  int _monthlyGoal = 300000;
  final PlatformHealthStepsReader _healthReader = PlatformHealthStepsReader();

  bool get initialized => _initialized;

  bool get syncing => _syncing;

  bool get platformSupported => _platformSupported;

  bool get healthConnectAvailable => _healthConnectAvailable;

  bool get permissionGranted => _permissionGranted;

  bool get usingHealthConnect =>
      _platformSupported && _healthConnectAvailable && _permissionGranted;

  String get statusMessage => _statusMessage;

  int get dailyGoal => _dailyGoal;

  int get weeklyGoal => _weeklyGoal;

  int get monthlyGoal => _monthlyGoal;

  DailyStepsModel get today {
    final key = _dateKey(DateTime.now());
    for (final item in _history) {
      if (item.date == key) return item;
    }

    return DailyStepsModel(
      date: key,
      steps: 0,
      goal: _dailyGoal,
      source: DailyStepsModel.sourceLocal,
      updatedAt: DateTime.now(),
    );
  }

  int get stepsToday => today.steps;

  int get remainingSteps => today.remainingSteps;

  double get progressToday => today.progress;

  double get estimatedDistanceKm => today.estimatedDistanceKm;

  double get estimatedCalories => today.estimatedCalories;

  int get estimatedActiveMinutes => today.estimatedActiveMinutes;

  List<DailyStepsModel> get history => List.unmodifiable(_history);

  List<PassosDiariosModel> get legacyHistory {
    return _history.map(_toLegacy).toList(growable: false);
  }

  int get weeklySteps => _recordsSince(7).fold(0, _sumSteps);

  int get monthlySteps => _recordsSince(30).fold(0, _sumSteps);

  int get weeklyAverage {
    final records = _recordsSince(7);
    if (records.isEmpty) return 0;

    return (records.fold<int>(0, _sumSteps) / records.length).round();
  }

  int get monthlyAverage {
    final records = _recordsSince(30);
    if (records.isEmpty) return 0;

    return (records.fold<int>(0, _sumSteps) / records.length).round();
  }

  DailyStepsModel? get bestDayThisWeek {
    final records = _recordsSince(7);
    if (records.isEmpty) return null;

    return records.reduce(
      (best, item) => item.steps > best.steps ? item : best,
    );
  }

  int get completedGoalDaysLast30 {
    return _recordsSince(30).where((item) => item.goalCompleted).length;
  }

  int get activeStreak {
    final byDate = {for (final item in _history) item.date: item};
    var day = DateTime.now();
    var streak = 0;

    while (true) {
      final record = byDate[_dateKey(day)];
      if (record == null || !record.goalCompleted) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<void> initialize() async {
    if (_initialized || _initializing) return;
    _initializing = true;

    final metas = await StorageService.carregarMetasPassos();
    _dailyGoal = metas['diaria'] ?? _dailyGoal;
    _weeklyGoal = metas['semanal'] ?? _weeklyGoal;
    _monthlyGoal = metas['mensal'] ?? _monthlyGoal;
    _platformSupported = _isAndroid;
    _history = await _loadLocalHistoryWithToday();
    _statusMessage = _platformSupported
        ? 'Health Connect pronto para permissao.'
        : 'Plataforma sem Health Connect. Usando fallback local.';

    _initialized = true;
    _initializing = false;
    notifyListeners();

    if (_platformSupported) {
      unawaited(syncNow(requestPermission: false));
    } else {
      _log('plataforma nao suportada para Health Connect; cache usado');
    }
  }

  Future<void> syncNow({bool requestPermission = true}) async {
    await initialize();
    if (_syncing) return;

    _syncing = true;
    notifyListeners();

    try {
      final healthRecords = await _tryReadHealthConnect(
        requestPermission: requestPermission,
      );
      final records = healthRecords.isEmpty
          ? await _loadLocalHistoryWithToday()
          : healthRecords;

      _history = await StorageService.salvarDailyStepsHistory(records);
      await _awardDailyGoalXpIfNeeded();
      unawaited(_syncWithBackend(_history.take(30).toList()));
      _log('passos lidos hoje=$stepsToday source=${today.source}');
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<List<DailyStepsModel>> readStepsRange({
    required DateTime from,
    required DateTime to,
    bool requestPermission = false,
  }) async {
    await initialize();

    if (_isAndroid) {
      final available = await _ensureHealthConnectAvailable();
      if (available) {
        final granted = await _ensureHealthPermission(
          requestPermission: requestPermission,
        );
        if (granted) {
          return _readHealthConnectRange(from: from, to: to);
        }
      }
    }

    final fromDate = _dateOnly(from);
    final toDate = _dateOnly(to);
    return _history
        .where((item) {
          final date = DateTime.tryParse(item.date);
          if (date == null) return false;
          final base = _dateOnly(date);
          return !base.isBefore(fromDate) && !base.isAfter(toDate);
        })
        .toList(growable: false);
  }

  Future<void> updateGoals({
    required int daily,
    required int weekly,
    required int monthly,
  }) async {
    _dailyGoal = daily.clamp(1000, 100000);
    _weeklyGoal = weekly.clamp(5000, 700000);
    _monthlyGoal = monthly.clamp(20000, 3000000);
    await StorageService.salvarMetasPassos(
      diaria: _dailyGoal,
      semanal: _weeklyGoal,
      mensal: _monthlyGoal,
    );

    _history = await StorageService.salvarDailyStepsHistory(
      _history.map((item) => item.copyWith(goal: _dailyGoal)).toList(),
    );
    await _awardDailyGoalXpIfNeeded();
    unawaited(_syncWithBackend(_history.take(30).toList()));
    notifyListeners();
  }

  Future<List<DailyStepsModel>> _tryReadHealthConnect({
    required bool requestPermission,
  }) async {
    if (!_isAndroid) {
      _statusMessage = 'Fallback local ativo nesta plataforma.';
      return const [];
    }

    final available = await _ensureHealthConnectAvailable();
    if (!available) return const [];

    final granted = await _ensureHealthPermission(
      requestPermission: requestPermission,
    );
    if (!granted) return const [];

    final end = DateTime.now();
    final start = _dateOnly(end).subtract(const Duration(days: 29));

    try {
      final records = await _readHealthConnectRange(from: start, to: end);
      _statusMessage = 'Passos sincronizados via Health Connect.';
      _log('Health Connect passos lidos dias=${records.length}');
      return records;
    } catch (error) {
      _statusMessage =
          'Nao foi possivel ler Health Connect. Cache local usado.';
      _log('erro leitura Health Connect: $error');
      return const [];
    }
  }

  Future<bool> _ensureHealthConnectAvailable() async {
    try {
      final availability = await _healthReader.checkAvailability();
      _platformSupported = availability.platformSupported;
      _healthConnectAvailable = availability.available;
      _log(
        'Health Connect suporte=$_platformSupported disponivel=$_healthConnectAvailable',
      );

      if (!_platformSupported || !_healthConnectAvailable) {
        _statusMessage = availability.message;
      }

      return _platformSupported && _healthConnectAvailable;
    } catch (error) {
      _platformSupported = false;
      _healthConnectAvailable = false;
      _statusMessage = 'Health Connect indisponivel. Fallback local ativo.';
      _log('Health Connect indisponivel: $error');
      return false;
    }
  }

  Future<bool> _ensureHealthPermission({
    required bool requestPermission,
  }) async {
    try {
      final granted = await _healthReader.ensureStepsPermission(
        requestPermission: requestPermission,
      );

      if (granted) {
        _permissionGranted = true;
        _log('permissao Health Connect concedida');
        return true;
      }

      if (!requestPermission) {
        _permissionGranted = false;
        _statusMessage = 'Conceda permissao para ler passos reais.';
        _log('permissao Health Connect ainda nao solicitada');
        return false;
      }

      _permissionGranted = false;
      _statusMessage = 'Permissao negada. Fallback local ativo.';
      _log('permissao negada');
      return false;
    } catch (error) {
      _permissionGranted = false;
      _statusMessage = 'Permissao indisponivel. Fallback local ativo.';
      _log('erro permissao Health Connect: $error');
      return false;
    }
  }

  Future<List<DailyStepsModel>> _readHealthConnectRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final records = <DailyStepsModel>[];
    var day = _dateOnly(from);
    final lastDay = _dateOnly(to);

    while (!day.isAfter(lastDay)) {
      final start = day;
      final end = day.isAtSameMomentAs(lastDay)
          ? to
          : day.add(const Duration(days: 1));
      final steps = await _readHealthConnectSteps(start: start, end: end);

      records.add(
        DailyStepsModel(
          date: _dateKey(day),
          steps: steps,
          goal: _dailyGoal,
          source: DailyStepsModel.sourceHealthConnect,
          updatedAt: DateTime.now(),
        ),
      );
      day = day.add(const Duration(days: 1));
    }

    return records;
  }

  Future<int> _readHealthConnectSteps({
    required DateTime start,
    required DateTime end,
  }) async {
    return _healthReader.readSteps(start: start, end: end);
  }

  Future<List<DailyStepsModel>> _loadLocalHistoryWithToday() async {
    final history = await StorageService.carregarDailyStepsHistory();
    final byDate = {
      for (final item in history)
        if (item.date.trim().isNotEmpty) item.date: item,
    };
    final todayKey = _dateKey(DateTime.now());
    final savedSteps = await StorageService.carregarPassos();

    byDate.putIfAbsent(
      todayKey,
      () => DailyStepsModel(
        date: todayKey,
        steps: savedSteps,
        goal: _dailyGoal,
        source: DailyStepsModel.sourceLocal,
        updatedAt: DateTime.now(),
      ),
    );

    final records = byDate.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return records;
  }

  Future<void> _awardDailyGoalXpIfNeeded() async {
    final current = today;
    if (!current.goalCompleted) return;

    final alreadyAwarded = await StorageService.passosMetaDiariaXpConcedido(
      current.date,
    );
    if (alreadyAwarded) return;

    await StorageService.adicionarXp(XpConfig.passosMetaDiaria);
    await StorageService.marcarPassosMetaDiariaXpConcedido(current.date);
    _log('XP de passos concedido date=${current.date}');
  }

  Future<void> _syncWithBackend(List<DailyStepsModel> records) async {
    if (records.isEmpty) return;

    await SyncService.instance.syncSteps(
      records.map((record) => record.toJson()).toList(),
    );
    _log('sincronizacao enviada passos=${records.length}');
  }

  List<DailyStepsModel> _recordsSince(int days) {
    final start = _dateOnly(DateTime.now().subtract(Duration(days: days - 1)));

    return _history
        .where((item) {
          final parsed = DateTime.tryParse(item.date);
          if (parsed == null) return false;

          return !_dateOnly(parsed).isBefore(start);
        })
        .toList(growable: false);
  }

  PassosDiariosModel _toLegacy(DailyStepsModel record) {
    return PassosDiariosModel(
      data: record.date,
      passos: record.steps,
      metaDiaria: record.goal,
      distanciaKm: record.estimatedDistanceKm,
      calorias: record.estimatedCalories,
      tempoAtivoMinutos: record.estimatedActiveMinutes,
      origem: record.source,
    );
  }

  int _sumSteps(int total, DailyStepsModel record) => total + record.steps;

  bool get _isAndroid {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _dateKey(DateTime value) {
    final local = _dateOnly(value);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');

    return '${local.year}-$month-$day';
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[StepsService] $message');
    }
  }
}
