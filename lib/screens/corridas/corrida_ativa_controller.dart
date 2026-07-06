import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/corrida_model.dart';
import '../../services/storage_service.dart';

class CorridaAtivaController extends ChangeNotifier {
  CorridaAtivaController._();

  static final CorridaAtivaController instance = CorridaAtivaController._();

  static const double _velocidadeSimuladaKmh = 8.0;

  Timer? _timer;
  bool _inicializado = false;
  bool _inicializando = false;
  bool _corridaIniciada = false;
  DateTime? _inicioCorrida;
  int _segundos = 0;
  double _distancia = 0;
  double _velocidadeMedia = 0;

  bool get inicializado => _inicializado;
  bool get corridaIniciada => _corridaIniciada;
  DateTime? get inicioCorrida => _inicioCorrida;
  int get segundos => _segundos;
  double get distancia => _distancia;
  double get velocidadeMedia => _velocidadeMedia;

  Future<void> inicializar() async {
    if (_inicializado || _inicializando) return;

    _inicializando = true;
    final dados = await StorageService.carregarCorridaAtiva();

    _corridaIniciada = dados['corridaIniciada'] == true;
    _inicioCorrida = DateTime.tryParse(
      dados['inicioCorrida']?.toString() ?? '',
    );
    _segundos = _intValue(dados['segundos']);
    _distancia = _doubleValue(dados['distancia']);
    _velocidadeMedia = _doubleValue(dados['velocidadeMedia']);

    if (_corridaIniciada) {
      _inicioCorrida ??= DateTime.now().subtract(Duration(seconds: _segundos));
      _recalcularMetricas();
      _garantirTimer();
      _persistirEstado();
    }

    _inicializado = true;
    _inicializando = false;
    notifyListeners();
  }

  void iniciar() {
    if (_corridaIniciada) return;

    _inicioCorrida = DateTime.now();
    _segundos = 0;
    _distancia = 0;
    _velocidadeMedia = 0;
    _corridaIniciada = true;
    _garantirTimer();
    _persistirEstado();
    notifyListeners();
  }

  Future<CorridaModel?> parar() async {
    if (!_corridaIniciada) return null;

    _recalcularMetricas();
    final corrida = CorridaModel(
      distancia: _distancia,
      segundos: _segundos,
      data: DateTime.now().toIso8601String(),
    );

    _timer?.cancel();
    _timer = null;
    _corridaIniciada = false;

    await StorageService.salvarCorrida(corrida);
    await _somarEstatisticas(corrida);
    await StorageService.limparCorridaAtiva();

    notifyListeners();
    return corrida;
  }

  void _garantirTimer() {
    if (_timer?.isActive ?? false) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_corridaIniciada) return;

      _recalcularMetricas();

      if (_segundos % 5 == 0) {
        _persistirEstado();
      }

      notifyListeners();
    });
  }

  void _recalcularMetricas() {
    final inicio = _inicioCorrida;
    if (inicio == null) return;

    _segundos = DateTime.now().difference(inicio).inSeconds.clamp(0, 1 << 31);
    final horas = _segundos / 3600;
    _distancia = horas * _velocidadeSimuladaKmh;
    _velocidadeMedia = _segundos <= 0 ? 0 : _distancia / horas;
  }

  void _persistirEstado() {
    unawaited(
      StorageService.salvarCorridaAtiva(
        corridaIniciada: _corridaIniciada,
        inicioCorrida: _inicioCorrida,
        segundos: _segundos,
        distancia: _distancia,
        velocidadeMedia: _velocidadeMedia,
      ),
    );
  }

  Future<void> _somarEstatisticas(CorridaModel corrida) async {
    final distanciaTotal = await StorageService.carregarDistanciaTotal();
    final tempoTotal = await StorageService.carregarTempoTotal();
    final totalCorridas = await StorageService.carregarTotalCorridas();

    await StorageService.salvarDistanciaTotal(
      distanciaTotal + corrida.distancia,
    );
    await StorageService.salvarTempoTotal(tempoTotal + corrida.segundos);
    await StorageService.salvarTotalCorridas(totalCorridas + 1);
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _doubleValue(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
