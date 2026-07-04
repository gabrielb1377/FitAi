import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/exercicio_model.dart';
import '../../models/treino_model.dart';
import 'widgets/exercise_history.dart';
import 'widgets/workout_mobile_focus_layout.dart';

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
  static const int _seriesPorExercicio = 3, _descansoPadrao = 60;

  final Map<int, Set<int>> _seriesConcluidas = {};
  final Map<int, List<ExerciseHistoryEntry>> _historico = {};
  final Map<int, String> _comentarios = {};
  final _pesoController = TextEditingController(text: '0');
  final _repeticoesController = TextEditingController(text: '12');
  final _comentarioController = TextEditingController();
  Timer? _treinoTimer, _descansoTimer;
  int _exercicioAtual = 0, _segundosTreino = 0, _descansoRestante = 0;
  bool _comentarioAberto = false;

  int get _totalExercicios => widget.treino.exercicios.length;
  ExercicioModel? get _exercicio =>
      _totalExercicios == 0 ? null : widget.treino.exercicios[_exercicioAtual];
  bool get _emDescanso => _descansoRestante > 0;
  String get _grupoDia => widget.grupoDia ?? _grupoPrincipal();
  String get _tempoFormatado =>
      '${(_segundosTreino ~/ 60).toString().padLeft(2, '0')}:'
      '${(_segundosTreino % 60).toString().padLeft(2, '0')}';

  String get _headerTitle => _totalExercicios == 0
      ? '0/0 $_grupoDia'
      : '${_exercicioAtual + 1}/$_totalExercicios $_grupoDia';

  @override
  void initState() {
    super.initState();
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

  void _iniciarCronometro() =>
      _treinoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _segundosTreino++);
      });

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
      _seriesConcluidas[_exercicioAtual] = {...concluidas, serieIndex};
      _comentarios[_exercicioAtual] = comentario;
      (_historico[_exercicioAtual] ??= []).insert(
        0,
        ExerciseHistoryEntry(
          number: serieIndex + 1,
          weight: peso,
          repetitions: repeticoes,
          date: DateTime.now(),
        ),
      );
    });

    final totalConcluido =
        _seriesConcluidas[_exercicioAtual]?.length ?? serieIndex + 1;
    if (totalConcluido < _seriesPorExercicio) {
      _iniciarDescanso();
      _mostrarMensagem('Serie registrada.');
      return;
    }

    _mostrarMensagem('${exercicio.nome} concluido. Proximo exercicio.');
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) _avancarDepoisDoExercicio();
    });
  }

  void _incrementarRepeticoes() {
    final atual = int.tryParse(_repeticoesController.text.trim()) ?? 0;
    setState(() => _repeticoesController.text = '${atual + 1}');
  }

  void _iniciarDescanso() {
    _descansoTimer?.cancel();
    setState(() => _descansoRestante = _descansoPadrao);
    _descansoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_descansoRestante <= 1) {
        timer.cancel();
        setState(() => _descansoRestante = 0);
        _mostrarMensagem('Descanso finalizado.');
      } else {
        setState(() => _descansoRestante--);
      }
    });
  }

  void _avancarDepoisDoExercicio() => _exercicioAtual < _totalExercicios - 1
      ? _mudarExercicio(_exercicioAtual + 1)
      : _mostrarMensagem('Treino concluido.');

  void _proximoExercicioManual() => _exercicioAtual < _totalExercicios - 1
      ? _mudarExercicio(_exercicioAtual + 1)
      : null;

  void _exercicioAnterior() {
    if (_exercicioAtual > 0) _mudarExercicio(_exercicioAtual - 1);
  }

  void _mudarExercicio(int index) {
    _descansoTimer?.cancel();
    setState(() {
      _descansoRestante = 0;
      _exercicioAtual = index;
      _sincronizarComentario();
    });
  }

  void _sincronizarComentario() {
    final comentario = _comentarios[_exercicioAtual] ?? '';
    _comentarioController.text = comentario;
    _comentarioController.selection = TextSelection.collapsed(
      offset: comentario.length,
    );
    _comentarioAberto = comentario.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final concluidas = _seriesConcluidas[_exercicioAtual]?.length ?? 0;
    return WorkoutMobileFocusLayout(
      exercicio: _exercicio,
      title: _headerTitle,
      elapsedTime: _tempoFormatado,
      restText: _emDescanso ? '${_descansoRestante}s' : '${_descansoPadrao}s',
      seriesText: '$concluidas/$_seriesPorExercicio',
      pesoController: _pesoController,
      repeticoesController: _repeticoesController,
      comentarioController: _comentarioController,
      commentOpen: _comentarioAberto,
      historyEntries: _historico[_exercicioAtual] ?? const [],
      onBack: () => Navigator.pop(context),
      onRegister: _registrarSerie,
      onAddReps: _incrementarRepeticoes,
      onToggleComment: () =>
          setState(() => _comentarioAberto = !_comentarioAberto),
      onPrevious: _exercicioAnterior,
      onNext: _proximoExercicioManual,
      onValueChanged: (_) => setState(() {}),
    );
  }

  void _mostrarMensagem(String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
      );

  String _texto(TextEditingController controller) =>
      controller.text.trim().isEmpty ? '0' : controller.text.trim();

  String _grupoPrincipal() {
    final categorias = {
      for (final exercicio in widget.treino.exercicios)
        if (exercicio.categoria.trim().isNotEmpty) exercicio.categoria,
    }.take(2).toList();
    return categorias.isEmpty ? widget.treino.nome : categorias.join(' + ');
  }
}
