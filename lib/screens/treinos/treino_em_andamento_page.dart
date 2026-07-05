import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/exercicio_model.dart';
import '../../models/treino_model.dart';

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

  final Map<int, Set<int>> _seriesConcluidas = {};
  final Map<int, List<_HistoricoSerieLocal>> _historico = {};
  final Map<int, String> _comentarios = {};

  final _pesoController = TextEditingController(text: '0');
  final _repeticoesController = TextEditingController(text: '12');
  final _comentarioController = TextEditingController();

  Timer? _treinoTimer;
  Timer? _descansoTimer;

  int _exercicioAtual = 0;
  int _segundosTreino = 0;
  int _descansoRestante = 0;
  int _descansoTotal = _descansoPadrao;
  bool _comentarioAberto = false;
  bool _descansoFinalizado = false;

  int get _totalExercicios => widget.treino.exercicios.length;

  ExercicioModel? get _exercicio =>
      _totalExercicios == 0 ? null : widget.treino.exercicios[_exercicioAtual];

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

    debugPrint('Treino: ${widget.treino.nome}');
    debugPrint('Qtd exercícios: ${widget.treino.exercicios.length}');
    debugPrint(widget.treino.exercicios.map((e) => e.nome).toList().toString());

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

    final totalConcluido =
        _seriesConcluidas[_exercicioAtual]?.length ?? serieIndex + 1;

    if (totalConcluido < _seriesPorExercicio) {
      _iniciarDescanso();
      _mostrarMensagem('Série registrada.');
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
      _mostrarMensagem('Treino concluído.');
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
    final exercicio = _exercicio;
    final concluidas = _seriesConcluidas[_exercicioAtual]?.length ?? 0;
    final historicoAtual = _historico[_exercicioAtual] ?? const [];
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
                      onBack: () => Navigator.pop(context),
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
                                const SizedBox(height: 18),
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
                                if (historicoAtual.isNotEmpty) ...[
                                  const SizedBox(height: 18),
                                  _CoachFitiaCard(
                                    entries: historicoAtual,
                                    alvoReps:
                                        int.tryParse(
                                          _texto(_repeticoesController),
                                        ) ??
                                        0,
                                  ),
                                ],
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
      final proximo = widget.treino.exercicios[_exercicioAtual + 1];
      return 'Próximo exercício: ${proximo.nome}';
    }
    return 'Último exercício do treino';
  }

  String _grupoPrincipal() {
    final categorias = {
      for (final exercicio in widget.treino.exercicios)
        if (exercicio.categoria.trim().isNotEmpty) exercicio.categoria,
    }.take(2).toList();

    return categorias.isEmpty ? widget.treino.nome : categorias.join(' + ');
  }
}

class _WorkoutHeader extends StatelessWidget {
  final String title;
  final String time;
  final double progress;
  final VoidCallback onBack;

  const _WorkoutHeader({
    required this.title,
    required this.time,
    required this.progress,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
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
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: const Color(0xFF111820),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00E5C3),
              ),
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
    return Image.asset(
      _gifPath(exercicio.nome),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            Icons.fitness_center_rounded,
            size: 76,
            color: Colors.black.withAlpha(80),
          ),
        );
      },
    );
  }

  static const Map<String, String> _gifMap = {
    'Supino Reto': 'assets/gifs/peito/supino_reto.gif',
    'Puxada Frontal': 'assets/gifs/costas/puxada_frontal.gif',
    'Agachamento Livre': 'assets/gifs/pernas/agachamento_livre.gif',
  };

  static String _gifPath(String nome) {
    return _gifMap[nome] ?? 'assets/gifs/${_slug(nome)}.gif';
  }

  static String _slug(String value) {
    var text = value.toLowerCase();
    const replacements = {
      '\u00e1': 'a',
      '\u00e0': 'a',
      '\u00e3': 'a',
      '\u00e2': 'a',
      '\u00e4': 'a',
      '\u00e9': 'e',
      '\u00ea': 'e',
      '\u00eb': 'e',
      '\u00ed': 'i',
      '\u00ee': 'i',
      '\u00ef': 'i',
      '\u00f3': 'o',
      '\u00f5': 'o',
      '\u00f4': 'o',
      '\u00f6': 'o',
      '\u00fa': 'u',
      '\u00fc': 'u',
      '\u00e7': 'c',
    };
    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    text = text.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    text = text.replaceAll(RegExp(r'_+'), '_');
    return text.replaceAll(RegExp(r'^_|_$'), '');
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
      children: [
        Expanded(
          child: _CircleStat(value: reps, label: 'Repetições'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CircleStat(value: rest, label: 'Repouso'),
        ),
        const SizedBox(width: 12),
        Expanded(
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
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF111820),
          border: Border.all(color: const Color(0xFF233241)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5C3).withAlpha(24),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF00E5C3),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontSize: 11,
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
