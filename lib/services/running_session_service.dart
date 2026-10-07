import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/corrida_model.dart';
import '../models/running_session_model.dart';
import '../core/auth/local_account_data_boundary.dart';
import '../features/activities/data/activity_sync_service.dart';
import '../features/progression/progression.dart';
import 'running_location_source.dart';
import 'storage_service.dart';

class RunningSessionService extends ChangeNotifier {
  RunningSessionService._({
    DateTime Function()? clock,
    this._trackGps = true,
    ProgressionEngine? progressionEngine,
    RunningLocationSource? locationSource,
    bool listenAccountChanges = false,
  }) : _clock = clock ?? DateTime.now,
       _progressionEngine = progressionEngine ?? ProgressionEngine.instance,
       _locationSource =
           locationSource ?? const GeolocatorRunningLocationSource() {
    _listenAccountChanges = listenAccountChanges;
    if (_listenAccountChanges) {
      AccountSessionLifecycle.revision.addListener(_onAccountChanged);
    }
  }

  static final RunningSessionService instance = RunningSessionService._(
    listenAccountChanges: true,
  );

  @visibleForTesting
  factory RunningSessionService.forTesting({
    DateTime Function()? clock,
    ProgressionEngine? progressionEngine,
    RunningLocationSource? locationSource,
    bool listenAccountChanges = false,
  }) => RunningSessionService._(
    clock: clock,
    trackGps: locationSource != null,
    progressionEngine: progressionEngine,
    locationSource: locationSource,
    listenAccountChanges: listenAccountChanges,
  );

  static const int _defaultCountdownSeconds = 3;
  static const double _maxAcceptedSpeedKmh = 36;
  static const double _maxAcceptedAccuracyMeters = 60;

  final DateTime Function() _clock;
  final bool _trackGps;
  final ProgressionEngine _progressionEngine;
  final RunningLocationSource _locationSource;
  late final bool _listenAccountChanges;
  final Set<String> _syncingRunIds = <String>{};
  Timer? _timer;
  Timer? _countdownTimer;
  StreamSubscription<RunningLocationSample>? _positionSubscription;
  RunningSessionModel? _session;
  String? _sessionOwnerUserId;
  bool _initialized = false;
  bool _initializing = false;
  int _accountRevision = 0;
  int _initializationToken = 0;
  bool _saving = false;
  bool _disposed = false;
  bool _gpsConnected = false;
  bool _startingGpsStream = false;
  bool _countdownActive = false;
  int _countdownSeconds = _defaultCountdownSeconds;
  RunningLocationSample? _lastAcceptedSample;
  DateTime? _lastAcceptedTimestamp;
  bool _requiresLocationSegmentStart = true;
  RunningLocationStatus _locationStatus = RunningLocationStatus.idle;

  bool get initialized => _initialized;
  bool get saving => _saving;
  bool get gpsConnected => _gpsConnected;
  RunningLocationStatus get locationStatus => _locationStatus;
  bool get countdownActive => _countdownActive;
  int get countdownSeconds => _countdownSeconds;
  RunningSessionModel? get session => _session;
  bool get hasActiveSession => _session != null && !_session!.finished;
  bool get isFinalizing => hasActiveSession && _session!.finalizing;
  bool get isRunning =>
      hasActiveSession &&
      !_session!.paused &&
      !isFinalizing &&
      !_countdownActive;
  bool get isPaused => hasActiveSession && _session!.paused && !isFinalizing;
  bool get isFinished => _session?.finished == true;
  int get elapsedSeconds => _session?.elapsedSeconds ?? 0;
  double get distanceKm => _session?.distanceKm ?? 0;
  double get currentSpeed => _session?.currentSpeed ?? 0;
  double get averageSpeed => _session?.averageSpeed ?? 0;
  double get pace => _session?.pace ?? 0;
  double? get calories => _session?.calories;
  List<RunningRoutePointModel> get route => _session?.route ?? const [];

  Future<void> initialize() async {
    final owner = _ownerUserId;
    if (_initialized && _sessionOwnerUserId == owner) return;
    if (_initializing) return;

    _initializing = true;
    final revision = _accountRevision;
    final token = ++_initializationToken;

    try {
      final restored = await StorageService.carregarRunningSessionAtiva();
      if (revision != _accountRevision || owner != _ownerUserId) return;
      _sessionOwnerUserId = owner;

      if (restored != null && !restored.finished) {
        _session = _restoreElapsedTime(restored);
        _resetLocationSegment(
          lastTimestamp: _lastRouteTimestamp(_session!.route),
        );

        if (_session!.finalizing) {
          try {
            await _commitFinalization(_session!, owner);
            _log('finalizacao recuperada');
          } catch (error) {
            _log('finalizacao pendente: $error');
          }
        } else if (!_session!.paused) {
          _ensureTimer();
          unawaited(_ensureGpsStream());
          await _persistSession();
        }

        _log('sessao restaurada');
      }

      if (revision != _accountRevision || owner != _ownerUserId) return;
      _initialized = true;
      ActivitySyncService.instance.registerUser(owner);
      notifyListeners();
      unawaited(_syncPendingRuns(owner));
    } finally {
      if (token == _initializationToken) _initializing = false;
      if (revision != _accountRevision) unawaited(initialize());
    }
  }

  Future<void> startWithCountdown({
    int seconds = _defaultCountdownSeconds,
  }) async {
    await initialize();

    if (hasActiveSession || _countdownActive) {
      _log('inicio ignorado: ja existe corrida ativa');
      return;
    }

    _countdownTimer?.cancel();
    _countdownSeconds = math.max(1, seconds);
    _countdownActive = true;
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds <= 1) {
        timer.cancel();
        _countdownActive = false;
        unawaited(start());
        return;
      }

      _countdownSeconds -= 1;
      notifyListeners();
    });
  }

  Future<void> start() async {
    await initialize();

    if (hasActiveSession) {
      _log('inicio ignorado: ja existe corrida ativa');
      return;
    }

    final now = _clock();
    _session = RunningSessionModel.start(
      id: 'run_${now.microsecondsSinceEpoch}',
      startTime: now,
    );
    _sessionOwnerUserId = _ownerUserId;
    if (!await StorageService.carregarPrimeiraCorrida()) {
      await StorageService.salvarPrimeiraCorrida(true);
    }
    _resetLocationSegment();
    _countdownActive = false;
    _countdownTimer?.cancel();

    await _persistSession();
    _ensureTimer();
    unawaited(_ensureGpsStream());
    _log('corrida iniciada');
    notifyListeners();
  }

  Future<void> pause() async {
    final session = _session;
    if (session == null ||
        session.finished ||
        session.paused ||
        session.finalizing) {
      return;
    }

    final now = _clock();
    _timer?.cancel();
    _timer = null;
    await _stopGpsStream();
    _resetLocationSegment(lastTimestamp: _lastRouteTimestamp(session.route));

    _session = _advanceSessionTo(session, now).copyWith(
      paused: true,
      pausedAt: now,
      currentSpeed: 0,
      lastUpdatedAt: now,
    );
    await _persistSession();
    _log('corrida pausada');
    notifyListeners();
  }

  Future<void> resume() async {
    final session = _session;
    if (session == null ||
        session.finished ||
        !session.paused ||
        session.finalizing) {
      return;
    }

    final now = _clock();
    _session = session.copyWith(
      paused: false,
      clearPausedAt: true,
      accumulatedPausedSeconds:
          session.accumulatedPausedSeconds + _pausedSeconds(session, now),
      lastUpdatedAt: now,
    );
    _resetLocationSegment(lastTimestamp: _lastRouteTimestamp(_session!.route));
    await _persistSession();
    _ensureTimer();
    unawaited(_ensureGpsStream());
    _log('corrida retomada');
    notifyListeners();
  }

  Future<CorridaModel?> finish() async {
    if (_saving) return null;

    final session = _session;
    final owner = _sessionOwnerUserId;
    if (session == null ||
        owner == null ||
        owner != _ownerUserId ||
        session.finished ||
        session.finalizing) {
      return null;
    }

    _saving = true;
    notifyListeners();

    try {
      _timer?.cancel();
      _timer = null;
      _countdownTimer?.cancel();
      _countdownActive = false;
      await _stopGpsStream();

      final now = _clock();
      final finalizingSession = _advanceSessionTo(session, now).copyWith(
        endTime: now,
        paused: false,
        clearPausedAt: true,
        accumulatedPausedSeconds:
            session.accumulatedPausedSeconds + _pausedSeconds(session, now),
        finalizing: true,
        finished: false,
        currentSpeed: 0,
        lastUpdatedAt: now,
      );
      _session = finalizingSession;
      await _persistSession();
      return await _commitFinalization(finalizingSession, owner);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> discardActiveSession() async {
    if (_sessionOwnerUserId != null && _sessionOwnerUserId != _ownerUserId) {
      return;
    }
    if (_session?.finalizing == true) {
      _log('cancelamento ignorado: finalizacao pendente');
      return;
    }
    _timer?.cancel();
    _timer = null;
    _countdownTimer?.cancel();
    _countdownActive = false;
    await _stopGpsStream();
    await StorageService.limparCorridaAtiva();
    _session = null;
    _sessionOwnerUserId = null;
    _resetLocationSegment();
    notifyListeners();
  }

  void _ensureTimer() {
    if (_timer?.isActive ?? false) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = _session;
      if (session == null ||
          session.finished ||
          session.paused ||
          session.finalizing) {
        return;
      }

      final now = _clock();
      _session = _advanceSessionTo(session, now);

      if (elapsedSeconds % 5 == 0) {
        unawaited(_persistSession());
      }

      notifyListeners();
    });
  }

  Future<void> _ensureGpsStream() async {
    if (_trackGps &&
        _positionSubscription == null &&
        !_startingGpsStream &&
        _canTrackLocation) {
      _startingGpsStream = true;
      try {
        final status = await _locationSource.ensureReady();
        if (status != RunningLocationStatus.available) {
          _setLocationStatus(status);
          return;
        }
        if (!_canTrackLocation || _positionSubscription != null) return;

        _positionSubscription = _locationSource.samples.listen(
          _recordLocation,
          onError: (Object error) =>
              unawaited(_handleLocationStreamError(error)),
        );
        _setLocationStatus(RunningLocationStatus.available);
        _log('GPS conectado');
      } on Object catch (error) {
        _log('GPS perdido: $error');
        _setLocationStatus(RunningLocationStatus.unavailable);
      } finally {
        _startingGpsStream = false;
      }
    }
  }

  /// Test-only location seam for the local running core.
  ///
  /// Production samples are provided by [GeolocatorRunningLocationSource].
  /// Keeping the metric update below independent of the plugin makes offline
  /// recovery and invalid-point handling verifiable without a native device.
  @visibleForTesting
  void recordLocationForTesting({
    required double latitude,
    required double longitude,
    required DateTime recordedAt,
    double accuracy = 5,
    double altitude = 0,
    double speedMps = 0,
  }) {
    _recordLocation(
      RunningLocationSample(
        latitude: latitude,
        longitude: longitude,
        timestamp: recordedAt,
        accuracy: accuracy,
        altitude: altitude,
        speedMps: speedMps,
      ),
    );
  }

  void _recordLocation(RunningLocationSample sample) {
    final session = _session;
    if (session == null ||
        session.finished ||
        session.paused ||
        session.finalizing) {
      return;
    }

    if (!_isValidLocationSample(sample)) {
      return;
    }

    final now = _clock();
    final currentSession = _advanceSessionTo(session, now);

    var distanceKm = currentSession.distanceKm;
    var currentSpeed = _speedMpsToKmh(sample.speedMps ?? 0);
    final previous = _lastAcceptedSample;

    if (previous != null && !_requiresLocationSegmentStart) {
      final meters = _distanceMeters(previous, sample);
      final seconds =
          sample.timestamp.difference(previous.timestamp).inMilliseconds /
          Duration.millisecondsPerSecond;
      final segmentSpeed = seconds <= 0 ? 0.0 : (meters / seconds) * 3.6;

      if (meters < 0 || segmentSpeed > _maxAcceptedSpeedKmh) {
        return;
      }

      if (meters >= 1) {
        distanceKm += meters / 1000;
        if (currentSpeed <= 0) {
          currentSpeed = segmentSpeed;
        }
      }
    }

    final startsSegment = _requiresLocationSegmentStart;
    // A session recovered from an older build cannot reconstruct past active
    // samples. Keep its route legacy rather than publish a partial timeline.
    final hasCanonicalProgress =
        (currentSession.route.isNotEmpty || currentSession.distanceKm == 0) &&
        currentSession.route.every(
          (point) =>
              point.cumulativeDistanceKm != null &&
              point.activeElapsedSeconds != null,
        );
    _lastAcceptedSample = sample;
    _lastAcceptedTimestamp = sample.timestamp;
    _requiresLocationSegmentStart = false;
    final route = [
      ...currentSession.route,
      RunningRoutePointModel(
        latitude: sample.latitude,
        longitude: sample.longitude,
        accuracy: sample.accuracy ?? 0,
        altitude: sample.altitude ?? 0,
        speed: currentSpeed,
        timestamp: sample.timestamp.toIso8601String(),
        cumulativeDistanceKm: hasCanonicalProgress ? distanceKm : null,
        activeElapsedSeconds: hasCanonicalProgress
            ? currentSession.elapsedSeconds
            : null,
        startsSegment: hasCanonicalProgress ? startsSegment : null,
      ),
    ];

    _session = _withUpdatedMetrics(
      currentSession.copyWith(
        distanceKm: distanceKm,
        currentSpeed: currentSpeed,
        route: route,
        lastUpdatedAt: now,
      ),
    );
    unawaited(_persistSession());
    notifyListeners();
  }

  bool get _canTrackLocation {
    final session = _session;
    return !_disposed &&
        session != null &&
        !session.finished &&
        !session.paused &&
        !session.finalizing;
  }

  bool _isValidLocationSample(RunningLocationSample sample) {
    final accuracy = sample.accuracy;
    final altitude = sample.altitude;
    final speed = sample.speedMps;
    final lastTimestamp = _lastAcceptedTimestamp;
    final latestAllowed = _clock().add(const Duration(minutes: 5));

    return sample.latitude.isFinite &&
        sample.longitude.isFinite &&
        sample.latitude >= -90 &&
        sample.latitude <= 90 &&
        sample.longitude >= -180 &&
        sample.longitude <= 180 &&
        (accuracy == null ||
            (accuracy.isFinite &&
                accuracy >= 0 &&
                accuracy <= _maxAcceptedAccuracyMeters)) &&
        (altitude == null || altitude.isFinite) &&
        (speed == null || speed.isFinite) &&
        !sample.timestamp.isAfter(latestAllowed) &&
        (lastTimestamp == null || sample.timestamp.isAfter(lastTimestamp));
  }

  double _distanceMeters(RunningLocationSample from, RunningLocationSample to) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _radians(to.latitude - from.latitude);
    final longitudeDelta = _radians(to.longitude - from.longitude);
    final startLatitude = _radians(from.latitude);
    final endLatitude = _radians(to.latitude);
    final haversine =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(startLatitude) *
            math.cos(endLatitude) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    final boundedHaversine = haversine.clamp(0.0, 1.0).toDouble();
    final angularDistance =
        2 *
        math.atan2(
          math.sqrt(boundedHaversine),
          math.sqrt(1 - boundedHaversine),
        );
    return earthRadiusMeters * angularDistance;
  }

  double _radians(double value) => value * math.pi / 180;

  DateTime? _lastRouteTimestamp(List<RunningRoutePointModel> route) {
    if (route.isEmpty) return null;
    return DateTime.tryParse(route.last.timestamp);
  }

  void _resetLocationSegment({DateTime? lastTimestamp}) {
    _lastAcceptedSample = null;
    _lastAcceptedTimestamp = lastTimestamp;
    _requiresLocationSegmentStart = true;
  }

  Future<void> _handleLocationStreamError(Object error) async {
    _log('GPS perdido: $error');
    await _stopGpsStream(status: RunningLocationStatus.unavailable);
  }

  RunningSessionModel _restoreElapsedTime(RunningSessionModel session) {
    return _advanceSessionTo(session, _clock());
  }

  /// Usa o timestamp persistido como fonte do cronômetro. O timer apenas
  /// solicita repintura; não é a origem da duração da corrida.
  RunningSessionModel _advanceSessionTo(
    RunningSessionModel session,
    DateTime now,
  ) {
    if (session.finished || session.paused || session.finalizing) {
      return session;
    }
    final delta = now.difference(session.lastUpdatedAt).inSeconds;
    if (delta <= 0) {
      return session;
    }
    return _withUpdatedMetrics(
      session.copyWith(
        elapsedSeconds: session.elapsedSeconds + delta,
        lastUpdatedAt: now,
      ),
    );
  }

  int _pausedSeconds(RunningSessionModel session, DateTime now) {
    final pausedAt = session.pausedAt;
    if (pausedAt == null) return 0;
    final seconds = now.difference(pausedAt).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  RunningSessionModel _withUpdatedMetrics(RunningSessionModel session) {
    final distance = math.max(0.0, session.distanceKm);
    final elapsed = math.max(0, session.elapsedSeconds);
    final averageSpeed = elapsed <= 0 ? 0.0 : distance / (elapsed / 3600);
    final pace = distance <= 0 || elapsed <= 0
        ? 0.0
        : (elapsed / 60) / distance;

    return session.copyWith(
      distanceKm: distance,
      elapsedSeconds: elapsed,
      averageSpeed: averageSpeed,
      pace: pace,
    );
  }

  Future<void> _persistSession() async {
    final session = _session;
    if (session == null || _sessionOwnerUserId != _ownerUserId) return;

    await StorageService.salvarRunningSessionAtiva(session);
  }

  /// Conclui uma sessão que já foi marcada e persistida como finalizando.
  /// Se o processo cair antes desta etapa, [initialize] tenta novamente com o
  /// mesmo identificador, e o upsert evita duplicar a corrida.
  Future<CorridaModel> _commitFinalization(
    RunningSessionModel finalizingSession,
    String ownerUserId,
  ) async {
    final corrida = CorridaModel.fromSession(
      finalizingSession,
      userId: ownerUserId,
    );
    var persisted = false;
    if (corrida.segundos > 0 || corrida.distancia > 0) {
      persisted = true;
      final inserted = await StorageService.salvarCorrida(corrida);
      if (inserted) await _addTotals(corrida);
      if (corrida.distancia >= 10) await StorageService.salvar10Km(true);
      await _updateProgressionWithoutBlocking(corrida);
      _log('sincronizacao enviada');
    }

    await StorageService.limparCorridaAtiva();
    _session = null;
    _sessionOwnerUserId = null;
    _resetLocationSegment();
    if (persisted) unawaited(_syncRun(corrida));
    return corrida;
  }

  Future<void> _updateProgressionWithoutBlocking(CorridaModel corrida) async {
    try {
      final history = await StorageService.carregarCorridas(
        userId: corrida.userId,
      );
      await _progressionEngine.recordRunCompletion(
        runId: corrida.id,
        completedAt: _runCompletedAt(corrida),
        durationSeconds: corrida.segundos,
        distanceKm: corrida.distancia,
        sources: ProgressionSourceData(
          runs: [for (final item in history) _toProgressionRun(item)],
          workoutsAvailable: false,
          stepsAvailable: false,
          favoritesAvailable: false,
        ),
      );
    } on Object catch (error) {
      _log('progresso local pendente: $error');
    }
  }

  ProgressionRunSource _toProgressionRun(CorridaModel corrida) =>
      ProgressionRunSource(
        id: corrida.id,
        completedAt: _runCompletedAt(corrida),
        durationSeconds: corrida.segundos,
        distanceKm: corrida.distancia,
      );

  DateTime _runCompletedAt(CorridaModel corrida) {
    for (final value in [corrida.endTime, corrida.data, corrida.startTime]) {
      final parsed = DateTime.tryParse(value ?? '');
      if (parsed != null) return parsed.toLocal();
    }
    return _clock().toLocal();
  }

  Future<void> _syncPendingRuns(String ownerUserId) async {
    ActivitySyncService.instance.registerUser(ownerUserId);
    await ActivitySyncService.instance.syncUser(ownerUserId);
    await _progressionEngine.syncRemote(userId: ownerUserId);
  }

  Future<void> _syncRun(CorridaModel corrida) async {
    if (!_syncingRunIds.add(corrida.id)) return;

    try {
      await StorageService.atualizarCorrida(
        corrida.copyWith(syncStatus: RunningSyncStatus.queued),
      );
      await ActivitySyncService.instance.syncUser(corrida.userId);
      final current = (await StorageService.carregarCorridas(
        userId: corrida.userId,
        includeDeleted: true,
      )).where((item) => item.id == corrida.id);
      final status = current.isEmpty
          ? RunningSyncStatus.queued
          : current.first.syncStatus;
      if (status == RunningSyncStatus.synced) {
        await _progressionEngine.syncRemote();
      }
      _log('corrida ${corrida.id} sincronizacao=${status.storageValue}');
    } catch (error) {
      await StorageService.atualizarCorrida(
        corrida.copyWith(syncStatus: RunningSyncStatus.queued),
      );
      _log('sincronizacao pendente: $error');
    } finally {
      _syncingRunIds.remove(corrida.id);
      notifyListeners();
    }
  }

  String get _ownerUserId => AccountSessionLifecycle.activeUserId ?? 'local';

  void _onAccountChanged() {
    _accountRevision++;
    _initializationToken++;
    _initialized = false;
    _initializing = false;
    _session = null;
    _sessionOwnerUserId = null;
    _timer?.cancel();
    _timer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownActive = false;
    _resetLocationSegment();
    unawaited(_stopGpsStream());
    notifyListeners();
  }

  Future<void> _stopGpsStream({
    RunningLocationStatus status = RunningLocationStatus.idle,
  }) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _setLocationStatus(status);
  }

  Future<void> _addTotals(CorridaModel corrida) async {
    final distanciaTotal = await StorageService.carregarDistanciaTotal();
    final tempoTotal = await StorageService.carregarTempoTotal();
    final totalCorridas = await StorageService.carregarTotalCorridas();

    await StorageService.salvarDistanciaTotal(
      distanciaTotal + math.max(0.0, corrida.distancia),
    );
    await StorageService.salvarTempoTotal(
      tempoTotal + math.max(0, corrida.segundos),
    );
    await StorageService.salvarTotalCorridas(totalCorridas + 1);
  }

  double _speedMpsToKmh(double speed) {
    if (speed.isNaN || speed.isInfinite || speed <= 0) return 0;

    return speed * 3.6;
  }

  void _setLocationStatus(RunningLocationStatus value) {
    final connected = value == RunningLocationStatus.available;
    if (_locationStatus == value && _gpsConnected == connected) return;

    _locationStatus = value;
    _gpsConnected = connected;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_listenAccountChanges) {
      AccountSessionLifecycle.revision.removeListener(_onAccountChanged);
    }
    _timer?.cancel();
    _countdownTimer?.cancel();
    unawaited(_positionSubscription?.cancel() ?? Future<void>.value());
    _positionSubscription = null;
    _gpsConnected = false;
    _locationStatus = RunningLocationStatus.idle;
    super.dispose();
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[RunningSessionService] $message');
    }
  }
}
