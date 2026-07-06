import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/xp/xp_config.dart';
import '../../models/exercicio_model.dart';
import '../../models/historico_treino_model.dart';
import '../../models/treino_model.dart';
import '../../services/storage_service.dart';
import '../../widgets/exercicio_gif_viewer.dart';
import '../exercicios/biblioteca_exercicios_page.dart';
import 'treino_finalizado_page.dart';

class TreinoEmAndamentoPage extends StatefulWidget {
  final TreinoModel treino;
  final String? nomeDia;
  final String? grupoDia;
  final Future<void> Function()? onXpAtualizado;

  const TreinoEmAndamentoPage({
    super.key,
    required this.treino,
    this.nomeDia,
    this.grupoDia,
    this.onXpAtualizado,
  });

  @override
  State<TreinoEmAndamentoPage> createState() => _TreinoEmAndamentoPageState();
}

class _TreinoEmAndamentoPageState extends State<TreinoEmAndamentoPage> {
  static const int _seriesPorExercicio = 3;
  static const int _descansoPadrao = 60;

  late final List<ExercicioModel> _exercicios;

  final Map<int, Set<int>> _seriesConcluidas = {};
  final Map<int, List<_HistoricoSerieLocal>> _historico = {};
  final Map<int, String> _comentarios = {};
  final Set<int> _exerciciosPulados = {};
  final List<_XpVisualHistoryEntry> _xpVisualHistorico = [];

  final _pesoController = TextEditingController(text: '0');
  final _repeticoesController = TextEditingController(text: '12');
  final _comentarioController = TextEditingController();

  Timer? _treinoTimer;
  Timer? _descansoTimer;

  int _exercicioAtual = 0;
  int _segundosTreino = 0;
  int _descansoRestante = 0;
  int _descansoTotal = _descansoPadrao;
  int _xpVisualSessao = 0;
  int _xpVisualEvento = 0;
  int _xpVisualKey = 0;
  bool _comentarioAberto = false;
  bool _descansoFinalizado = false;
  bool _treinoFinalizadoVisual = false;
  bool _finalizacaoEmAndamento = false;
  String _xpVisualTitulo = '';

  int get _totalExercicios => _exercicios.length;

  ExercicioModel? get _exercicio =>
      _totalExercicios == 0 ? null : _exercicios[_exercicioAtual];

  bool get _emDescanso => _descansoRestante > 0;

  String get _grupoDia => widget.grupoDia ?? _grupoPrincipal();

  String get _tempoFormatado {
    final minutos = (_segundosTreino ~/ 60).toString().padLeft(2, '0');
    final segundos = (_segundosTreino % 60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }

  String get _headerTitle {
    if (_totalExercicios == 0) return '0/0 $_grupoDia';
    return '${_exercicioAtual + 1}/$_totalExercicios $_grupoDia';
  }

  @override
  void initState() {
    super.initState();
    _exercicios = List<ExercicioModel>.of(widget.treino.exercicios);

    debugPrint('Treino: ${widget.treino.nome}');
    debugPrint('Qtd exercícios: ${_exercicios.length}');
    debugPrint(_exercicios.map((e) => e.nome).toList().toString());

    _iniciarCronometro();
  }

  @override
  void dispose() {
    _treinoTimer?.cancel();
    _descansoTimer?.cancel();
    _pesoController.dispose();
    _repeticoesController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  void _iniciarCronometro() {
    _treinoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _segundosTreino++);
    });
  }

  // ignore: unused_element
  void _registrarSerie() {
    final exercicio = _exercicio;
    if (exercicio == null) return;

    final concluidas = _seriesConcluidas[_exercicioAtual] ?? <int>{};
    if (concluidas.length >= _seriesPorExercicio) {
      _avancarDepoisDoExercicio();
      return;
    }

    final serieIndex = concluidas.length;
    final peso = _texto(_pesoController);
    final repeticoes = int.tryParse(_texto(_repeticoesController)) ?? 0;
    final comentario = _comentarioController.text.trim();

    setState(() {
      _descansoFinalizado = false;
      _exerciciosPulados.remove(_exercicioAtual);
      _seriesConcluidas[_exercicioAtual] = {...concluidas, serieIndex};
      _comentarios[_exercicioAtual] = comentario;
      (_historico[_exercicioAtual] ??= []).insert(
        0,
        _HistoricoSerieLocal(
          numero: serieIndex + 1,
          peso: peso,
          repeticoes: repeticoes,
          data: DateTime.now(),
        ),
      );
    });
    _adicionarXpVisual(XpConfig.treinoSerieConcluida, 'Série registrada');

    final totalConcluido =
        _seriesConcluidas[_exercicioAtual]?.length ?? serieIndex + 1;

    if (totalConcluido < _seriesPorExercicio) {
      _iniciarDescanso();
      _mostrarMensagem('Série registrada.');
      return;
    }

    final ultimoExercicio = _exercicioAtual >= _totalExercicios - 1;

    Future.delayed(const Duration(milliseconds: 260), () {
      if (mounted) {
        _adicionarXpVisual(
          XpConfig.treinoExercicioConcluido,
          '🏅 Exercício concluído',
        );
      }
    });

    if (ultimoExercicio) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) _finalizarTreino();
      });
      return;
    }

    _mostrarMensagem('${exercicio.nome} concluído. Próximo exercício.');
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) _avancarDepoisDoExercicio();
    });
  }

  void _iniciarDescanso() {
    _descansoTimer?.cancel();
    setState(() {
      _descansoTotal = _descansoPadrao;
      _descansoRestante = _descansoPadrao;
      _descansoFinalizado = false;
    });

    _descansoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_descansoRestante <= 1) {
        timer.cancel();
        setState(() {
          _descansoRestante = 0;
          _descansoFinalizado = true;
        });
        _mostrarMensagem('Hora da próxima série!');
      } else {
        setState(() => _descansoRestante--);
      }
    });
  }

  void _pularDescanso() {
    _descansoTimer?.cancel();
    setState(() {
      _descansoRestante = 0;
      _descansoFinalizado = true;
    });
    _mostrarMensagem('Hora da próxima série!');
  }

  void _ajustarDescanso(int seconds) {
    if (!_emDescanso) return;
    final novoTempo = (_descansoRestante + seconds).clamp(0, 999).toInt();
    setState(() {
      _descansoRestante = novoTempo;
      if (seconds > 0) _descansoTotal += seconds;
      if (_descansoTotal < _descansoRestante) {
        _descansoTotal = _descansoRestante;
      }
      _descansoFinalizado = novoTempo == 0;
    });
    if (novoTempo == 0) {
      _descansoTimer?.cancel();
      _mostrarMensagem('Hora da próxima série!');
    }
  }

  void _avancarDepoisDoExercicio() {
    if (_exercicioAtual < _totalExercicios - 1) {
      _mudarExercicio(_exercicioAtual + 1);
    } else {
      _finalizarTreino();
    }
  }

  void _proximoExercicioManual() {
    if (_exercicioAtual < _totalExercicios - 1) {
      _mudarExercicio(_exercicioAtual + 1);
    }
  }

  void _exercicioAnterior() {
    if (_exercicioAtual > 0) _mudarExercicio(_exercicioAtual - 1);
  }

  void _mudarExercicio(int index) {
    _descansoTimer?.cancel();
    setState(() {
      _descansoRestante = 0;
      _descansoFinalizado = false;
      _exercicioAtual = index;
      _sincronizarComentario();
    });
  }

  Future<ExercicioModel?> _selecionarExercicioDaBiblioteca() async {
    ExercicioModel? selecionado;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BibliotecaExerciciosPage(
          onSelecionar: (exercicio) {
            selecionado = exercicio;
          },
        ),
      ),
    );

    if (!mounted) return null;
    return selecionado;
  }

  List<_ExerciseSessionSlot> _snapshotSlots() {
    return List<_ExerciseSessionSlot>.generate(_exercicios.length, (index) {
      return _ExerciseSessionSlot(
        exercicio: _exercicios[index],
        series: Set<int>.from(_seriesConcluidas[index] ?? const <int>{}),
        historico: List<_HistoricoSerieLocal>.from(
          _historico[index] ?? const <_HistoricoSerieLocal>[],
        ),
        comentario: _comentarios[index] ?? '',
        pulado: _exerciciosPulados.contains(index),
      );
    });
  }

  void _restoreSlots(List<_ExerciseSessionSlot> slots) {
    _exercicios
      ..clear()
      ..addAll(slots.map((slot) => slot.exercicio));
    _seriesConcluidas.clear();
    _historico.clear();
    _comentarios.clear();
    _exerciciosPulados.clear();

    for (var index = 0; index < slots.length; index++) {
      final slot = slots[index];
      if (slot.series.isNotEmpty) {
        _seriesConcluidas[index] = Set<int>.from(slot.series);
      }
      if (slot.historico.isNotEmpty) {
        _historico[index] = List<_HistoricoSerieLocal>.from(slot.historico);
      }
      if (slot.comentario.isNotEmpty) {
        _comentarios[index] = slot.comentario;
      }
      if (slot.pulado) {
        _exerciciosPulados.add(index);
      }
    }
  }

  void _resetarEstadoDoExercicioAtual() {
    _descansoTimer?.cancel();
    _seriesConcluidas.remove(_exercicioAtual);
    _historico.remove(_exercicioAtual);
    _comentarios.remove(_exercicioAtual);
    _exerciciosPulados.remove(_exercicioAtual);
    _comentarioController.clear();
    _comentarioAberto = false;
    _descansoRestante = 0;
    _descansoFinalizado = false;
  }

  Future<void> _adicionarExercicioDepoisAtual() async {
    final selecionado = await _selecionarExercicioDaBiblioteca();
    if (!mounted || selecionado == null) return;

    setState(() {
      final slots = _snapshotSlots();
      final insertIndex = _totalExercicios == 0 ? 0 : _exercicioAtual + 1;
      slots.insert(insertIndex, _ExerciseSessionSlot(exercicio: selecionado));
      _restoreSlots(slots);
    });

    _mostrarMensagem('Exercício adicionado.');
  }

  Future<void> _trocarExercicioAtual() async {
    final exercicioAtual = _exercicio;
    if (exercicioAtual == null) return;

    final selecionado = await _selecionarExercicioDaBiblioteca();

    if (!mounted || selecionado == null) return;

    if (_mesmoExercicio(exercicioAtual, selecionado)) return;

    setState(() {
      _exercicios[_exercicioAtual] = selecionado;
      _resetarEstadoDoExercicioAtual();
    });

    _mostrarMensagem('Exercício substituído.');
  }

  Future<void> _removerExercicioAtual() async {
    if (_totalExercicios <= 1) {
      _mostrarMensagem('O treino precisa ter pelo menos um exercício.');
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1218),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF233241)),
          ),
          title: const Text(
            'Remover exercício?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Somente o exercício atual será removido. O restante do treino continua igual.',
            style: TextStyle(color: Colors.white.withAlpha(180), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Remover',
                style: TextStyle(color: Color(0xFFFF6B6B)),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmar != true) return;

    setState(() {
      _descansoTimer?.cancel();
      final slots = _snapshotSlots()..removeAt(_exercicioAtual);
      _restoreSlots(slots);
      if (_exercicioAtual >= _totalExercicios) {
        _exercicioAtual = _totalExercicios - 1;
      }
      _descansoRestante = 0;
      _descansoFinalizado = false;
      _sincronizarComentario();
    });

    _mostrarMensagem('Exercício removido.');
  }

  void _reordenarExercicios(int oldIndex, int newIndex) {
    final slots = _snapshotSlots();
    final currentSlot = slots[_exercicioAtual];

    final moved = slots.removeAt(oldIndex);
    slots.insert(newIndex, moved);
    _restoreSlots(slots);
    _exercicioAtual = slots.indexOf(currentSlot);
    _sincronizarComentario();
  }

  Future<void> _abrirReordenarExercicios() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return _ReorderExercisesSheet(
              exercicios: _exercicios,
              currentIndex: _exercicioAtual,
              pulados: _exerciciosPulados,
              seriesConcluidas: _seriesConcluidas,
              onReorder: (oldIndex, newIndex) {
                setState(() => _reordenarExercicios(oldIndex, newIndex));
                modalSetState(() {});
              },
            );
          },
        );
      },
    );
  }

  void _pularExercicioAtual() {
    if (_exercicioAtual >= _totalExercicios - 1) {
      _mostrarMensagem('Não há próximo exercício.');
      return;
    }

    setState(() => _exerciciosPulados.add(_exercicioAtual));
    _mudarExercicio(_exercicioAtual + 1);
    _mostrarMensagem('Exercício pulado.');
  }

  void _reiniciarExercicioAtual() {
    setState(() => _resetarEstadoDoExercicioAtual());
    _mostrarMensagem('Exercício reiniciado.');
  }

  void _abrirMenuEdicaoTreino() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _WorkoutEditMenuSheet(
          onAddExercise: () {
            Navigator.pop(sheetContext);
            _adicionarExercicioDepoisAtual();
          },
          onSwapExercise: () {
            Navigator.pop(sheetContext);
            _trocarExercicioAtual();
          },
          onRemoveExercise: () {
            Navigator.pop(sheetContext);
            _removerExercicioAtual();
          },
          onReorderExercises: () {
            Navigator.pop(sheetContext);
            _abrirReordenarExercicios();
          },
          onSkipExercise: () {
            Navigator.pop(sheetContext);
            _pularExercicioAtual();
          },
          onRestartExercise: () {
            Navigator.pop(sheetContext);
            _reiniciarExercicioAtual();
          },
        );
      },
    );
  }

  bool _mesmoExercicio(ExercicioModel a, ExercicioModel b) {
    return _exercicioKey(a) == _exercicioKey(b);
  }

  String _exercicioKey(ExercicioModel exercicio) {
    final id = exercicio.id.trim();
    return id.isEmpty ? exercicio.nome.trim() : id;
  }

  void _sincronizarComentario() {
    final comentario = _comentarios[_exercicioAtual] ?? '';
    _comentarioController.text = comentario;
    _comentarioController.selection = TextSelection.collapsed(
      offset: comentario.length,
    );
    _comentarioAberto = comentario.isNotEmpty;
  }

  void _adicionarXpVisual(int xp, String titulo) {
    setState(() {
      _xpVisualSessao += xp;
      _xpVisualEvento = xp;
      _xpVisualTitulo = titulo;
      _xpVisualKey++;
      _xpVisualHistorico.insert(
        0,
        _XpVisualHistoryEntry(
          title: titulo,
          xp: xp,
          totalXp: _xpVisualSessao,
          data: DateTime.now(),
        ),
      );
    });
  }

  void _abrirXpSheet() {
    _abrirInfoSheet(
      title: 'XP da sessao',
      icon: Icons.bolt_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _XpSessionCard(
            totalXp: _xpVisualSessao,
            eventXp: _xpVisualEvento,
            eventTitle: _xpVisualTitulo,
            eventKey: _xpVisualKey,
          ),
          const SizedBox(height: 12),
          _XpHistoryCard(entries: _xpVisualHistorico),
        ],
      ),
    );
  }

  void _abrirCoachSheet(List<_HistoricoSerieLocal> entries) {
    _abrirInfoSheet(
      title: 'Coach FitIA',
      icon: Icons.auto_awesome_rounded,
      child: entries.isEmpty
          ? const _InfoEmptyCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Coach aguardando',
              text:
                  'Registre uma serie para ver volume, melhores marcas e sugestao para a proxima serie.',
            )
          : _CoachFitiaCard(
              entries: entries,
              alvoReps: int.tryParse(_texto(_repeticoesController)) ?? 0,
            ),
    );
  }

  void _abrirPerformanceSheet({
    required List<_HistoricoSerieLocal> entries,
    required List<_HistoricoSerieLocal> sessionEntries,
    required int exerciciosConcluidos,
  }) {
    _abrirInfoSheet(
      title: 'Performance',
      icon: Icons.query_stats_rounded,
      child: _PerformanceCard(
        entries: entries,
        sessionEntries: sessionEntries,
        exerciciosConcluidos: exerciciosConcluidos,
      ),
    );
  }

  void _abrirInfoSheet({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.78;

        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                constraints: BoxConstraints(maxHeight: maxHeight),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF070B10),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border.all(color: const Color(0xFF1D2A35)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(130),
                      blurRadius: 34,
                      offset: const Offset(0, -16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5C3).withAlpha(22),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF00E5C3).withAlpha(80),
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: const Color(0xFF00E5C3),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white70,
                          tooltip: 'Fechar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _volumeSerie(_HistoricoSerieLocal entry) {
    final peso = double.tryParse(entry.peso.replaceAll(',', '.')) ?? 0;
    return peso * entry.repeticoes;
  }

  String _formatarVolume(double value) {
    final text = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write('.');
      buffer.write(text[i]);
    }

    return buffer.toString();
  }

  int _seriesConcluidasTotal() {
    return _seriesConcluidas.values.fold<int>(
      0,
      (total, series) => total + series.length,
    );
  }

  int _exerciciosConcluidosTotal() {
    return _seriesConcluidas.values
        .where((series) => series.length >= _seriesPorExercicio)
        .length;
  }

  double _volumeSessaoTotal() {
    return _historico.values
        .expand<_HistoricoSerieLocal>((entries) => entries)
        .fold<double>(0, (total, entry) => total + _volumeSerie(entry));
  }

  int _calcularXpGanho({
    required int seriesConcluidas,
    required int exerciciosConcluidos,
  }) {
    final treinoPerfeito =
        _totalExercicios > 0 && exerciciosConcluidos >= _totalExercicios;

    return (seriesConcluidas * XpConfig.treinoSerieConcluida) +
        (exerciciosConcluidos * XpConfig.treinoExercicioConcluido) +
        XpConfig.treinoConcluido +
        (treinoPerfeito ? XpConfig.treinoPerfeitoBonus : 0);
  }

  int _caloriasEstimadas({
    required int seriesConcluidas,
    required double volumeTotal,
  }) {
    final porTempo = (_segundosTreino / 60) * 4;
    final porSeries = seriesConcluidas * 6;
    final porVolume = volumeTotal / 120;

    return (porTempo + porSeries + porVolume).round().clamp(0, 9999);
  }

  Future<void> _finalizarTreino() async {
    if (_finalizacaoEmAndamento) return;

    _finalizacaoEmAndamento = true;
    _treinoTimer?.cancel();
    _descansoTimer?.cancel();

    if (!_treinoFinalizadoVisual && mounted) {
      setState(() => _treinoFinalizadoVisual = true);
      _adicionarXpVisual(XpConfig.treinoConcluido, 'Treino finalizado');
    }

    final seriesConcluidas = _seriesConcluidasTotal();
    final exerciciosConcluidos = _exerciciosConcluidosTotal();
    final volumeTotal = _volumeSessaoTotal();
    final xpGanho = _calcularXpGanho(
      seriesConcluidas: seriesConcluidas,
      exerciciosConcluidos: exerciciosConcluidos,
    );
    final calorias = _caloriasEstimadas(
      seriesConcluidas: seriesConcluidas,
      volumeTotal: volumeTotal,
    );
    final agora = DateTime.now();
    final historico = HistoricoTreinoModel(
      id: '${agora.microsecondsSinceEpoch}_${widget.treino.nome.hashCode}',
      nomeTreino: widget.treino.nome,
      dataHora: agora,
      tempoSegundos: _segundosTreino,
      tempoFormatado: _tempoFormatado,
      exerciciosTotais: _totalExercicios,
      exerciciosConcluidos: exerciciosConcluidos,
      xpGanho: xpGanho,
      caloriasEstimadas: calorias,
      objetivo: _grupoDia,
      nivel: 'FITAI',
      seriesConcluidas: seriesConcluidas,
      volumeTotal: volumeTotal,
      recordesBatidos: 0,
    );

    try {
      await StorageService.salvarHistoricoTreino(historico);
      await StorageService.adicionarXp(xpGanho);
      await widget.onXpAtualizado?.call();
    } catch (erro) {
      _finalizacaoEmAndamento = false;
      if (!mounted) return;

      _mostrarMensagem('Não foi possível salvar o treino. Tente novamente.');
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TreinoFinalizadoPage(
          nomeTreino: widget.treino.nome,
          tempo: _tempoFormatado,
          exerciciosConcluidos: exerciciosConcluidos,
          seriesConcluidas: seriesConcluidas,
          volume: '${_formatarVolume(volumeTotal)} kg',
          xp: xpGanho,
          recordes: historico.recordesBatidos,
          resumoIa:
              'Treino salvo no histórico. Você concluiu $exerciciosConcluidos exercícios e movimentou ${_formatarVolume(volumeTotal)} kg.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercicio = _exercicio;
    final concluidas = _seriesConcluidas[_exercicioAtual]?.length ?? 0;
    final historicoAtual = _historico[_exercicioAtual] ?? const [];
    final historicoSessao = _historico.values
        .expand<_HistoricoSerieLocal>((entries) => entries)
        .toList();
    final exerciciosConcluidos = _exerciciosConcluidosTotal();
    final seriesConcluidasTotal = _seriesConcluidasTotal();
    final totalSeries = _totalExercicios * _seriesPorExercicio;
    final volumeSessao = _volumeSessaoTotal();
    final progresso = _totalExercicios == 0
        ? 0.0
        : ((_exercicioAtual + (concluidas / _seriesPorExercicio)) /
                  _totalExercicios)
              .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF05070A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > 430
                ? 430.0
                : constraints.maxWidth;

            return Center(
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    _WorkoutHeader(
                      title: _headerTitle,
                      time: _tempoFormatado,
                      progress: progresso,
                      exerciciosConcluidos: exerciciosConcluidos,
                      totalExercicios: _totalExercicios,
                      seriesConcluidas: seriesConcluidasTotal,
                      totalSeries: totalSeries,
                      tempoMinutos: '${_segundosTreino ~/ 60} min',
                      volume: '${_formatarVolume(volumeSessao)} kg',
                      onBack: () => Navigator.pop(context),
                      onMenu: _abrirMenuEdicaoTreino,
                    ),
                    Expanded(
                      child: exercicio == null
                          ? const _EmptyWorkoutState()
                          : ListView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                14,
                                18,
                                110,
                              ),
                              children: [
                                _ExerciseHeroCard(exercicio: exercicio),
                                const SizedBox(height: 18),
                                _ExerciseTitleBlock(
                                  nome: exercicio.nome,
                                  categoria: exercicio.categoria,
                                ),
                                const SizedBox(height: 12),
                                _QuickActionsRow(
                                  onSwap: _trocarExercicioAtual,
                                  onXp: _abrirXpSheet,
                                  onCoach: () =>
                                      _abrirCoachSheet(historicoAtual),
                                  onPerformance: () => _abrirPerformanceSheet(
                                    entries: historicoAtual,
                                    sessionEntries: historicoSessao,
                                    exerciciosConcluidos: exerciciosConcluidos,
                                  ),
                                ),
                                if (_exerciciosPulados.contains(
                                  _exercicioAtual,
                                )) ...[
                                  const SizedBox(height: 12),
                                  const _SkippedExerciseBanner(),
                                ],
                                const SizedBox(height: 14),
                                _StatsCircles(
                                  reps: _texto(_repeticoesController),
                                  rest: _emDescanso
                                      ? '${_descansoRestante}s'
                                      : '${_descansoPadrao}s',
                                  series: '$concluidas/$_seriesPorExercicio',
                                ),
                                if (_emDescanso) ...[
                                  const SizedBox(height: 18),
                                  _RestCard(
                                    seconds: _descansoRestante,
                                    totalSeconds: _descansoTotal,
                                    nextLabel: _proximoDescansoLabel(),
                                    onSkip: _pularDescanso,
                                    onAddTime: () => _ajustarDescanso(15),
                                    onRemoveTime: () => _ajustarDescanso(-15),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                _InputsRow(
                                  pesoController: _pesoController,
                                  repeticoesController: _repeticoesController,
                                  onAddReps: _registrarSerie,
                                  highlightRegister: _descansoFinalizado,
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 12),
                                _CommentBox(
                                  controller: _comentarioController,
                                  isOpen: _comentarioAberto,
                                  onToggle: () => setState(
                                    () =>
                                        _comentarioAberto = !_comentarioAberto,
                                  ),
                                  onChanged: (value) {
                                    _comentarios[_exercicioAtual] = value
                                        .trim();
                                  },
                                ),
                                const SizedBox(height: 18),
                                _HistoryCard(entries: historicoAtual),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _SecondaryActionButton(
                                        label: 'Anterior',
                                        icon: Icons.chevron_left_rounded,
                                        onTap: _exercicioAnterior,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _SecondaryActionButton(
                                        label: 'Próximo',
                                        icon: Icons.chevron_right_rounded,
                                        onTap: _proximoExercicioManual,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );
  }

  String _texto(TextEditingController controller) =>
      controller.text.trim().isEmpty ? '0' : controller.text.trim();

  String _proximoDescansoLabel() {
    final concluidas = _seriesConcluidas[_exercicioAtual]?.length ?? 0;
    if (concluidas < _seriesPorExercicio) {
      return 'Próxima série: ${concluidas + 1}/$_seriesPorExercicio';
    }
    if (_exercicioAtual < _totalExercicios - 1) {
      final proximo = _exercicios[_exercicioAtual + 1];
      return 'Próximo exercício: ${proximo.nome}';
    }
    return 'Último exercício do treino';
  }

  String _grupoPrincipal() {
    final categorias = {
      for (final exercicio in _exercicios)
        if (exercicio.categoria.trim().isNotEmpty) exercicio.categoria,
    }.take(2).toList();

    return categorias.isEmpty ? widget.treino.nome : categorias.join(' + ');
  }
}

class _ExerciseSessionSlot {
  final ExercicioModel exercicio;
  final Set<int> series;
  final List<_HistoricoSerieLocal> historico;
  final String comentario;
  final bool pulado;

  _ExerciseSessionSlot({
    required this.exercicio,
    Set<int>? series,
    List<_HistoricoSerieLocal>? historico,
    this.comentario = '',
    this.pulado = false,
  }) : series = series ?? <int>{},
       historico = historico ?? <_HistoricoSerieLocal>[];
}

class _WorkoutEditMenuSheet extends StatelessWidget {
  final VoidCallback onAddExercise;
  final VoidCallback onSwapExercise;
  final VoidCallback onRemoveExercise;
  final VoidCallback onReorderExercises;
  final VoidCallback onSkipExercise;
  final VoidCallback onRestartExercise;

  const _WorkoutEditMenuSheet({
    required this.onAddExercise,
    required this.onSwapExercise,
    required this.onRemoveExercise,
    required this.onReorderExercises,
    required this.onSkipExercise,
    required this.onRestartExercise,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1218),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF233241)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(70),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Editar treino',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _EditMenuAction(
              icon: Icons.add_circle_outline_rounded,
              label: 'Adicionar exercício',
              onTap: onAddExercise,
            ),
            _EditMenuAction(
              icon: Icons.swap_horiz_rounded,
              label: 'Trocar exercício atual',
              onTap: onSwapExercise,
            ),
            _EditMenuAction(
              icon: Icons.delete_outline_rounded,
              label: 'Remover exercício',
              color: const Color(0xFFFF6B6B),
              onTap: onRemoveExercise,
            ),
            _EditMenuAction(
              icon: Icons.drag_indicator_rounded,
              label: 'Reordenar exercícios',
              onTap: onReorderExercises,
            ),
            _EditMenuAction(
              icon: Icons.skip_next_rounded,
              label: 'Pular exercício',
              onTap: onSkipExercise,
            ),
            _EditMenuAction(
              icon: Icons.restart_alt_rounded,
              label: 'Reiniciar exercício atual',
              onTap: onRestartExercise,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditMenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _EditMenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: const Color(0xFF111820),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color == Colors.white
                      ? const Color(0xFF00E5C3)
                      : color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withAlpha(90),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReorderExercisesSheet extends StatelessWidget {
  final List<ExercicioModel> exercicios;
  final int currentIndex;
  final Set<int> pulados;
  final Map<int, Set<int>> seriesConcluidas;
  final ReorderCallback onReorder;

  const _ReorderExercisesSheet({
    required this.exercicios,
    required this.currentIndex,
    required this.pulados,
    required this.seriesConcluidas,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.78,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1218),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF233241)),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(70),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Reordenar exercícios',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ReorderableListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: exercicios.length,
                  onReorderItem: onReorder,
                  itemBuilder: (context, index) {
                    final exercicio = exercicios[index];
                    return _ReorderExerciseTile(
                      key: ValueKey('${exercicio.id}_${exercicio.nome}_$index'),
                      index: index,
                      exercicio: exercicio,
                      isCurrent: index == currentIndex,
                      isSkipped: pulados.contains(index),
                      completedSeries: seriesConcluidas[index]?.length ?? 0,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReorderExerciseTile extends StatelessWidget {
  final int index;
  final ExercicioModel exercicio;
  final bool isCurrent;
  final bool isSkipped;
  final int completedSeries;

  const _ReorderExerciseTile({
    super.key,
    required this.index,
    required this.exercicio,
    required this.isCurrent,
    required this.isSkipped,
    required this.completedSeries,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isCurrent
        ? const Color(0xFF00E5C3)
        : const Color(0xFF233241);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111820),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withAlpha(isCurrent ? 170 : 255)),
      ),
      child: Row(
        children: [
          Text(
            (index + 1).toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Color(0xFF00E5C3),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercicio.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercicio.categoria} • $completedSeries série(s)'
                  '${isSkipped ? ' • Pulado' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.drag_indicator_rounded,
            color: Colors.white.withAlpha(130),
          ),
        ],
      ),
    );
  }
}

class _SkippedExerciseBanner extends StatelessWidget {
  const _SkippedExerciseBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC857).withAlpha(18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFC857).withAlpha(90)),
      ),
      child: const Row(
        children: [
          Icon(Icons.redo_rounded, color: Color(0xFFFFC857), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Exercício pulado. Você pode voltar e concluir quando quiser.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutHeader extends StatelessWidget {
  final String title;
  final String time;
  final double progress;
  final int exerciciosConcluidos;
  final int totalExercicios;
  final int seriesConcluidas;
  final int totalSeries;
  final String tempoMinutos;
  final String volume;
  final VoidCallback onBack;
  final VoidCallback onMenu;

  const _WorkoutHeader({
    required this.title,
    required this.time,
    required this.progress,
    required this.exerciciosConcluidos,
    required this.totalExercicios,
    required this.seriesConcluidas,
    required this.totalSeries,
    required this.tempoMinutos,
    required this.volume,
    required this.onBack,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).clamp(0, 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: Colors.white,
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF101820),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF233241)),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF00E5C3),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onMenu,
                icon: const Icon(Icons.more_vert_rounded),
                color: Colors.white,
                tooltip: 'Editar treino',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1218),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF1D2A35)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5C3).withAlpha(18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: progress,
                          backgroundColor: const Color(0xFF16212B),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00E5C3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        '$percent%',
                        key: ValueKey<int>(percent),
                        style: const TextStyle(
                          color: Color(0xFF00E5C3),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _HeaderMetric(
                        label: 'Exercícios',
                        value: '$exerciciosConcluidos/$totalExercicios',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeaderMetric(
                        label: 'Séries',
                        value: '$seriesConcluidas/$totalSeries',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _HeaderMetric(
                        label: 'Tempo',
                        value: tempoMinutos,
                        icon: Icons.timer_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeaderMetric(
                        label: 'Volume',
                        value: volume,
                        icon: Icons.monitor_weight_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _HeaderMetric({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFF00E5C3), size: 16),
            const SizedBox(width: 7),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withAlpha(130),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseHeroCard extends StatelessWidget {
  final ExercicioModel exercicio;

  const _ExerciseHeroCard({required this.exercicio});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4F6),
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: _ExerciseGif(exercicio: exercicio)),
          Positioned(left: 18, top: 18, child: _MiniBadge(label: 'GIF')),
          Positioned(
            right: 18,
            top: 18,
            child: _MiniBadge(label: exercicio.categoria),
          ),
        ],
      ),
    );
  }
}

class _ExerciseGif extends StatelessWidget {
  final ExercicioModel exercicio;

  const _ExerciseGif({required this.exercicio});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ExercicioGifImage(
        imagem: exercicio.imagem,
        titulo: exercicio.nome,
        gifPath: exercicio.gifPath,
        fit: BoxFit.contain,
        placeholder: Center(
          child: Icon(
            Icons.fitness_center_rounded,
            size: 76,
            color: Colors.black.withAlpha(80),
          ),
        ),
      ),
    );
  }
}

class _ExerciseTitleBlock extends StatelessWidget {
  final String nome;
  final String categoria;

  const _ExerciseTitleBlock({required this.nome, required this.categoria});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          nome,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Peso recomendado: mantenha execução controlada e registre cada série.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withAlpha(165),
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onSwap;
  final VoidCallback onXp;
  final VoidCallback onCoach;
  final VoidCallback onPerformance;

  const _QuickActionsRow({
    required this.onSwap,
    required this.onXp,
    required this.onCoach,
    required this.onPerformance,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            label: 'Trocar',
            icon: Icons.swap_horiz_rounded,
            onTap: onSwap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            label: 'XP',
            icon: Icons.bolt_rounded,
            onTap: onXp,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            label: 'Coach',
            icon: Icons.auto_awesome_rounded,
            onTap: onCoach,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            label: 'Perf.',
            icon: Icons.query_stats_rounded,
            onTap: onPerformance,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF101820),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF233241)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF00E5C3), size: 17),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withAlpha(170),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsCircles extends StatelessWidget {
  final String reps;
  final String rest;
  final String series;

  const _StatsCircles({
    required this.reps,
    required this.rest,
    required this.series,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 88,
          child: _CircleStat(value: reps, label: 'Repetições'),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 88,
          child: _CircleStat(value: rest, label: 'Repouso'),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 88,
          child: _CircleStat(value: series, label: 'Séries'),
        ),
      ],
    );
  }
}

class _CircleStat extends StatelessWidget {
  final String value;
  final String label;

  const _CircleStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF111820),
          border: Border.all(color: const Color(0xFF233241)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5C3).withAlpha(24),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF00E5C3),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _XpSessionCard extends StatelessWidget {
  final int totalXp;
  final int eventXp;
  final int eventKey;
  final String eventTitle;

  const _XpSessionCard({
    required this.totalXp,
    required this.eventXp,
    required this.eventKey,
    required this.eventTitle,
  });

  @override
  Widget build(BuildContext context) {
    final hasEvent = eventXp > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1218),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00E5C3).withAlpha(72)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5C3).withAlpha(hasEvent ? 30 : 14),
            blurRadius: hasEvent ? 28 : 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5C3).withAlpha(22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF00E5C3).withAlpha(80),
                  ),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFF00E5C3),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'XP da sessão',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasEvent
                          ? 'Ganho visual deste treino'
                          : 'Registre uma série para ganhar XP visual',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withAlpha(145),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '+$totalXp',
                style: const TextStyle(
                  color: Color(0xFF00E5C3),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Container(
              key: ValueKey<int>(eventKey),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: hasEvent
                    ? const Color(0xFF00E5C3).withAlpha(18)
                    : Colors.white.withAlpha(7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: hasEvent
                      ? const Color(0xFF00E5C3).withAlpha(70)
                      : Colors.white.withAlpha(18),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasEvent ? eventTitle : 'Pronto para começar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasEvent
                            ? Colors.white
                            : Colors.white.withAlpha(150),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    hasEvent ? '+$eventXp XP' : '+0 XP',
                    style: TextStyle(
                      color: hasEvent
                          ? const Color(0xFF00E5C3)
                          : Colors.white.withAlpha(120),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _XpHistoryCard extends StatelessWidget {
  final List<_XpVisualHistoryEntry> entries;

  const _XpHistoryCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _InfoEmptyCard(
        icon: Icons.bolt_rounded,
        title: 'Nenhum XP visual ainda',
        text: 'Registre series para acompanhar os ganhos desta sessao.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1218),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1D2A35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historico de XP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < entries.length; index++) ...[
            _XpHistoryItem(entry: entries[index]),
            if (index < entries.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _XpHistoryItem extends StatelessWidget {
  final _XpVisualHistoryEntry entry;

  const _XpHistoryItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    final hora = entry.data.hour.toString().padLeft(2, '0');
    final minuto = entry.data.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111820),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF233241)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5C3).withAlpha(22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Color(0xFF00E5C3),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$hora:$minuto | total +${entry.totalXp} XP',
                  style: TextStyle(
                    color: Colors.white.withAlpha(135),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${entry.xp}',
            style: const TextStyle(
              color: Color(0xFF00E5C3),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoEmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InfoEmptyCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1218),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1D2A35)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00E5C3), size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(145),
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputsRow extends StatelessWidget {
  final TextEditingController pesoController;
  final TextEditingController repeticoesController;
  final VoidCallback onAddReps;
  final bool highlightRegister;
  final ValueChanged<String> onChanged;

  const _InputsRow({
    required this.pesoController,
    required this.repeticoesController,
    required this.onAddReps,
    this.highlightRegister = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DarkInput(
            controller: pesoController,
            label: 'Quilos',
            suffix: 'kg',
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DarkInput(
            controller: repeticoesController,
            label: 'Repetições',
            suffix: 'rep',
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onAddReps,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: highlightRegister
                  ? const Color(0xFF7CFF6B)
                  : const Color(0xFF00E5C3),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: highlightRegister ? Colors.white : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (highlightRegister
                              ? const Color(0xFF7CFF6B)
                              : const Color(0xFF00E5C3))
                          .withAlpha(highlightRegister ? 120 : 70),
                  blurRadius: highlightRegister ? 34 : 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.black, size: 32),
          ),
        ),
      ],
    );
  }
}

class _DarkInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final ValueChanged<String> onChanged;

  const _DarkInput({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: const Color(0xFF111820),
        labelStyle: TextStyle(
          color: Colors.white.withAlpha(145),
          fontWeight: FontWeight.w700,
        ),
        suffixStyle: TextStyle(
          color: Colors.white.withAlpha(145),
          fontWeight: FontWeight.w800,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(19),
          borderSide: const BorderSide(color: Color(0xFF233241)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(19),
          borderSide: const BorderSide(color: Color(0xFF00E5C3), width: 1.6),
        ),
      ),
    );
  }
}

class _CommentBox extends StatelessWidget {
  final TextEditingController controller;
  final bool isOpen;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  const _CommentBox({
    required this.controller,
    required this.isOpen,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton.icon(
          onPressed: onToggle,
          icon: const Icon(Icons.mode_comment_outlined),
          label: Text(isOpen ? 'Ocultar comentário' : 'Adicionar comentário'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF00E5C3),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: isOpen
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ex: boa execução, subir carga na próxima...',
                hintStyle: TextStyle(color: Colors.white.withAlpha(100)),
                filled: true,
                fillColor: const Color(0xFF111820),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFF233241)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFF233241)),
                ),
              ),
            ),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final List<_HistoricoSerieLocal> entries;

  const _HistoryCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final melhorSerie = _melhorSerieDoDia();
    final volumeTotal = entries.fold<double>(
      0,
      (total, entry) => total + _volume(entry),
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1218),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1D2A35)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, color: Color(0xFF00E5C3)),
              SizedBox(width: 8),
              Text(
                'Histórico do exercício',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111820),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF233241)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_chart_rounded,
                    color: const Color(0xFF00E5C3).withAlpha(190),
                    size: 34,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Nenhuma série registrada ainda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Registre sua primeira série para acompanhar carga, repetições e volume.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withAlpha(135),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _MetricPill(
                    label: 'Volume total',
                    value: '${_formatarNumero(volumeTotal)} kg',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricPill(
                    label: 'Séries',
                    value: '${entries.length}',
                  ),
                ),
              ],
            ),
            if (melhorSerie != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5C3).withAlpha(20),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF00E5C3).withAlpha(90),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFF00E5C3),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Melhor série de hoje',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Série ${melhorSerie.numero} • ${melhorSerie.peso} kg × ${melhorSerie.repeticoes} reps',
                            style: TextStyle(
                              color: Colors.white.withAlpha(150),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            ...entries.take(5).map(_HistorySeriesTile.new),
          ],
        ],
      ),
    );
  }

  _HistoricoSerieLocal? _melhorSerieDoDia() {
    _HistoricoSerieLocal? melhor;
    for (final entry in entries) {
      if (melhor == null || _volume(entry) > _volume(melhor)) {
        melhor = entry;
      }
    }
    return melhor;
  }

  static double _volume(_HistoricoSerieLocal entry) {
    final peso = double.tryParse(entry.peso.replaceAll(',', '.')) ?? 0;
    return peso * entry.repeticoes;
  }

  static String _formatarNumero(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  static String _hora(DateTime data) {
    final h = data.hour.toString().padLeft(2, '0');
    final m = data.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111820),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF233241)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(130),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00E5C3),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySeriesTile extends StatelessWidget {
  final _HistoricoSerieLocal entry;

  const _HistorySeriesTile(this.entry);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111820),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF233241)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1218),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${entry.numero}',
                style: const TextStyle(
                  color: Color(0xFF00E5C3),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Série ${entry.numero}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.peso} kg × ${entry.repeticoes} reps',
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _HistoryCard._hora(entry.data),
            style: TextStyle(
              color: Colors.white.withAlpha(120),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachFitiaCard extends StatelessWidget {
  final List<_HistoricoSerieLocal> entries;
  final int alvoReps;

  const _CoachFitiaCard({required this.entries, required this.alvoReps});

  @override
  Widget build(BuildContext context) {
    final ultima = entries.first;
    final volumeSerie = _volume(ultima);
    final melhorCarga = _melhorCarga();
    final melhorVolume = _melhorVolume();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1218),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00E5C3).withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5C3).withAlpha(18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFF00E5C3)),
              SizedBox(width: 8),
              Text(
                'Coach FitIA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CoachMetric(
            label: '🏋 Volume da série',
            value:
                '${ultima.peso} kg × ${ultima.repeticoes} reps = ${_formatarNumero(volumeSerie)} kg',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CoachMetric(
                  label: '🏆 Melhor carga',
                  value: '${_formatarNumero(melhorCarga)} kg',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CoachMetric(
                  label: '🔥 Melhor volume',
                  value: '${_formatarNumero(melhorVolume)} kg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CoachMetric(
            label: '📈 Sugestão para próxima série',
            value: _sugestao(ultima),
            highlighted: true,
          ),
        ],
      ),
    );
  }

  double _melhorCarga() {
    var best = 0.0;
    for (final entry in entries) {
      final peso = _peso(entry);
      if (peso > best) best = peso;
    }
    return best;
  }

  double _melhorVolume() {
    var best = 0.0;
    for (final entry in entries) {
      final volume = _volume(entry);
      if (volume > best) best = volume;
    }
    return best;
  }

  String _sugestao(_HistoricoSerieLocal entry) {
    final pesoAtual = _peso(entry);
    if (alvoReps <= 0) return 'Mantenha a carga e priorize execução.';
    if (entry.repeticoes > alvoReps) {
      return '+2,5 kg: tente ${_formatarNumero(pesoAtual + 2.5)} kg.';
    }
    if (entry.repeticoes == alvoReps) {
      return 'Manter: repita ${_formatarNumero(pesoAtual)} kg.';
    }
    final novaCarga = (pesoAtual - 2.5).clamp(0.0, double.infinity);
    return 'Reduzir 2,5 kg: tente ${_formatarNumero(novaCarga)} kg.';
  }

  static double _peso(_HistoricoSerieLocal entry) {
    return double.tryParse(entry.peso.replaceAll(',', '.')) ?? 0;
  }

  static double _volume(_HistoricoSerieLocal entry) {
    return _peso(entry) * entry.repeticoes;
  }

  static String _formatarNumero(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

class _CoachMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _CoachMetric({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFF00E5C3).withAlpha(22)
            : const Color(0xFF111820),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF00E5C3).withAlpha(90)
              : const Color(0xFF233241),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(145),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final List<_HistoricoSerieLocal> entries;
  final List<_HistoricoSerieLocal> sessionEntries;
  final int exerciciosConcluidos;

  const _PerformanceCard({
    required this.entries,
    required this.sessionEntries,
    required this.exerciciosConcluidos,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _decoration(),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PerformanceTitle(),
            SizedBox(height: 12),
            _PerformanceEmptyState(),
          ],
        ),
      );
    }

    final maiorCarga = _maiorCarga(entries);
    final maiorVolume = _maiorVolume(entries);
    final maiorReps = _maiorReps(entries);
    final volumeSessao = sessionEntries.fold<double>(
      0,
      (total, entry) => total + _volume(entry),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PerformanceTitle(),
          const SizedBox(height: 14),
          const _PerformanceSectionTitle('🏆 Recorde pessoal'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PerformanceMetric(
                  label: 'Maior carga',
                  value: '${_formatarNumero(maiorCarga)} kg',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PerformanceMetric(
                  label: 'Maior volume',
                  value: '${_formatarNumero(maiorVolume)} kg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PerformanceMetric(
            label: 'Maior número de repetições',
            value: '$maiorReps reps',
          ),
          const SizedBox(height: 14),
          const _PerformanceSectionTitle('📈 Sessão atual'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PerformanceMetric(
                  label: 'Volume total',
                  value: '${_formatarNumero(volumeSessao)} kg',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PerformanceMetric(
                  label: 'Séries concluídas',
                  value: '${sessionEntries.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PerformanceMetric(
            label: 'Exercícios concluídos',
            value: '$exerciciosConcluidos',
          ),
          const SizedBox(height: 14),
          const _PerformanceSectionTitle('💪 Evolução'),
          const SizedBox(height: 10),
          _EvolutionComparison(entries: entries),
        ],
      ),
    );
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      color: const Color(0xFF0D1218),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFF1D2A35)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(45),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }

  static double _maiorCarga(List<_HistoricoSerieLocal> entries) {
    return entries.fold<double>(0, (best, entry) {
      final peso = _peso(entry);
      return peso > best ? peso : best;
    });
  }

  static double _maiorVolume(List<_HistoricoSerieLocal> entries) {
    return entries.fold<double>(0, (best, entry) {
      final volume = _volume(entry);
      return volume > best ? volume : best;
    });
  }

  static int _maiorReps(List<_HistoricoSerieLocal> entries) {
    return entries.fold<int>(0, (best, entry) {
      return entry.repeticoes > best ? entry.repeticoes : best;
    });
  }

  static double _peso(_HistoricoSerieLocal entry) {
    return double.tryParse(entry.peso.replaceAll(',', '.')) ?? 0;
  }

  static double _volume(_HistoricoSerieLocal entry) {
    return _peso(entry) * entry.repeticoes;
  }

  static String _formatarNumero(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

class _PerformanceTitle extends StatelessWidget {
  const _PerformanceTitle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.query_stats_rounded, color: Color(0xFF00E5C3)),
        SizedBox(width: 8),
        Text(
          'Performance',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PerformanceEmptyState extends StatelessWidget {
  const _PerformanceEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111820),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF233241)),
      ),
      child: Text(
        'Primeira execução deste exercício.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withAlpha(150),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PerformanceSectionTitle extends StatelessWidget {
  final String text;

  const _PerformanceSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  final String label;
  final String value;

  const _PerformanceMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111820),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF233241)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(130),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00E5C3),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionComparison extends StatelessWidget {
  final List<_HistoricoSerieLocal> entries;

  const _EvolutionComparison({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return const _PerformanceEmptyState();
    }

    final atual = entries.first;
    final anterior = entries[1];
    final cargaDelta = _peso(atual) - _peso(anterior);
    final repsDelta = atual.repeticoes - anterior.repeticoes;
    final volumeAnterior = _volume(anterior);
    final volumeDelta = _volume(atual) - volumeAnterior;
    final volumePercent = volumeAnterior == 0
        ? 0.0
        : (volumeDelta / volumeAnterior) * 100;

    return Row(
      children: [
        Expanded(
          child: _EvolutionPill(
            value: '${_signal(cargaDelta)}${_formatarNumero(cargaDelta)} kg',
            color: _color(cargaDelta),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _EvolutionPill(
            value: '${_signalInt(repsDelta)}$repsDelta repetições',
            color: _color(repsDelta.toDouble()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _EvolutionPill(
            value:
                '${_signal(volumePercent)}${_formatarNumero(volumePercent)}%',
            color: _color(volumePercent),
          ),
        ),
      ],
    );
  }

  static double _peso(_HistoricoSerieLocal entry) {
    return double.tryParse(entry.peso.replaceAll(',', '.')) ?? 0;
  }

  static double _volume(_HistoricoSerieLocal entry) {
    return _peso(entry) * entry.repeticoes;
  }

  static Color _color(double value) {
    if (value > 0) return const Color(0xFF39E58C);
    if (value < 0) return const Color(0xFFFF5C5C);
    return const Color(0xFFFFC857);
  }

  static String _signal(double value) => value > 0 ? '+' : '';
  static String _signalInt(int value) => value > 0 ? '+' : '';

  static String _formatarNumero(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

class _EvolutionPill extends StatelessWidget {
  final String value;
  final Color color;

  const _EvolutionPill({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RestCard extends StatelessWidget {
  final int seconds;
  final int totalSeconds;
  final String nextLabel;
  final VoidCallback onSkip;
  final VoidCallback onAddTime;
  final VoidCallback onRemoveTime;

  const _RestCard({
    required this.seconds,
    required this.totalSeconds,
    required this.nextLabel,
    required this.onSkip,
    required this.onAddTime,
    required this.onRemoveTime,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds <= 0
        ? 0.0
        : (seconds / totalSeconds).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101820),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00E5C3).withAlpha(70)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 74,
                height: 74,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 7,
                      backgroundColor: const Color(0xFF233241),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00E5C3),
                      ),
                    ),
                    Text(
                      '$seconds',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descanso',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$seconds segundos restantes',
                      style: TextStyle(
                        color: Colors.white.withAlpha(140),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF00E5C3),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _RestActionButton(label: '-15s', onTap: onRemoveTime),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RestActionButton(
                  label: 'Pular',
                  onTap: onSkip,
                  primary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RestActionButton(label: '+15s', onTap: onAddTime),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _RestActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: primary ? const Color(0xFF00E5C3) : const Color(0xFF111820),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primary ? const Color(0xFF00E5C3) : const Color(0xFF233241),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: primary ? Colors.black : Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _PrimaryRegisterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PrimaryRegisterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFF00E5C3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5C3).withAlpha(80),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Registrar série',
            style: TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF233241)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;

  const _MiniBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(145),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyWorkoutState extends StatelessWidget {
  const _EmptyWorkoutState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Este treino não possui exercícios.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withAlpha(160),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HistoricoSerieLocal {
  final int numero;
  final String peso;
  final int repeticoes;
  final DateTime data;

  const _HistoricoSerieLocal({
    required this.numero,
    required this.peso,
    required this.repeticoes,
    required this.data,
  });
}

class _XpVisualHistoryEntry {
  final String title;
  final int xp;
  final int totalXp;
  final DateTime data;

  const _XpVisualHistoryEntry({
    required this.title,
    required this.xp,
    required this.totalXp,
    required this.data,
  });
}
