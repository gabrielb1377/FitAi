import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/exercicio_model.dart';
import '../../models/treino_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/descanso_timer.dart';
import '../../widgets/exercicio_gif_viewer.dart';
import '../../widgets/serie_card.dart';

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

  Timer? _treinoTimer;
  Timer? _descansoTimer;

  int _exercicioAtual = 0;
  int _segundosTreino = 0;
  int _descansoRestante = 0;
  int _descansoTotal = _descansoPadrao;

  @override
  void initState() {
    super.initState();
    _iniciarCronometro();
  }

  @override
  void dispose() {
    _treinoTimer?.cancel();
    _descansoTimer?.cancel();
    super.dispose();
  }

  int get _totalExercicios => widget.treino.exercicios.length;

  int get _totalSeries => _totalExercicios * _seriesPorExercicio;

  int get _seriesFeitas {
    return _seriesConcluidas.values.fold<int>(
      0,
      (total, series) => total + series.length,
    );
  }

  double get _progresso {
    if (_totalSeries == 0) return 0;
    return (_seriesFeitas / _totalSeries).clamp(0, 1).toDouble();
  }

  bool get _emDescanso => _descansoRestante > 0;

  ExercicioModel? get _exercicio {
    if (_totalExercicios == 0) return null;
    return widget.treino.exercicios[_exercicioAtual];
  }

  String get _nomeDia => widget.nomeDia ?? 'Treino de hoje';

  String get _grupoDia => widget.grupoDia ?? _grupoPrincipal();

  String get _tempoFormatado {
    final minutes = _segundosTreino ~/ 60;
    final seconds = _segundosTreino % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void _iniciarCronometro() {
    _treinoTimer?.cancel();
    _treinoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _segundosTreino++);
    });
  }

  void _concluirSerie() {
    if (_exercicio == null) return;

    final concluidas = _seriesConcluidas[_exercicioAtual] ?? <int>{};
    if (concluidas.length >= _seriesPorExercicio) {
      _proximoExercicio();
      return;
    }

    final proxima = concluidas.length;
    setState(() {
      _seriesConcluidas[_exercicioAtual] = {...concluidas, proxima};
    });

    if ((_seriesConcluidas[_exercicioAtual]?.length ?? 0) <
        _seriesPorExercicio) {
      _iniciarDescanso();
    } else if (_exercicioAtual < _totalExercicios - 1) {
      Future.delayed(const Duration(milliseconds: 260), () {
        if (mounted) _proximoExercicio();
      });
    } else {
      _mostrarMensagem('Treino concluido.');
    }
  }

  void _toggleSerie(int serie) {
    setState(() {
      final atuais = _seriesConcluidas[_exercicioAtual] ?? <int>{};
      if (atuais.contains(serie)) {
        atuais.remove(serie);
      } else {
        atuais.add(serie);
      }
      _seriesConcluidas[_exercicioAtual] = {...atuais};
    });
  }

  void _iniciarDescanso() {
    _descansoTimer?.cancel();
    setState(() {
      _descansoTotal = _descansoPadrao;
      _descansoRestante = _descansoPadrao;
    });

    _descansoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_descansoRestante <= 1) {
        _pularDescanso(mensagem: 'Descanso finalizado.');
        return;
      }

      setState(() => _descansoRestante--);
    });
  }

  void _pularDescanso({String? mensagem}) {
    _descansoTimer?.cancel();
    if (!mounted) return;
    setState(() => _descansoRestante = 0);
    if (mensagem != null) _mostrarMensagem(mensagem);
  }

  void _ajustarDescanso(int delta) {
    if (!_emDescanso) return;
    setState(() {
      _descansoRestante = (_descansoRestante + delta).clamp(0, 300);
      _descansoTotal = (_descansoTotal + delta).clamp(15, 300);
    });
    if (_descansoRestante == 0) _pularDescanso();
  }

  void _proximoExercicio() {
    if (_totalExercicios == 0) return;
    _descansoTimer?.cancel();
    setState(() {
      _descansoRestante = 0;
      if (_exercicioAtual < _totalExercicios - 1) _exercicioAtual++;
    });
  }

  void _exercicioAnterior() {
    if (_totalExercicios == 0) return;
    _descansoTimer?.cancel();
    setState(() {
      _descansoRestante = 0;
      if (_exercicioAtual > 0) _exercicioAtual--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercicio = _exercicio;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _topo(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 124),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (exercicio == null)
                  _emptyState()
                else ...[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _exercicioAtualCard(exercicio),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _emDescanso
                        ? DescansoTimer(
                            key: const ValueKey('descanso'),
                            totalSeconds: _descansoTotal,
                            remainingSeconds: _descansoRestante,
                            onSkip: _pularDescanso,
                            onAdd15: () => _ajustarDescanso(15),
                            onRemove15: () => _ajustarDescanso(-15),
                          )
                        : _seriesSection(key: const ValueKey('series')),
                  ),
                  const SizedBox(height: 16),
                  _acoes(),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topo(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 10,
        20,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF092D29)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _nomeDia,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _tempoFormatado,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _grupoDia,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _totalExercicios == 0
                ? 'Nenhum exercicio'
                : 'Exercicio ${_exercicioAtual + 1} / $_totalExercicios',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _progresso),
                    duration: const Duration(milliseconds: 260),
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 9,
                        color: AppColors.primary,
                        backgroundColor: Colors.white.withAlpha(32),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(_progresso * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _exercicioAtualCard(ExercicioModel exercicio) {
    return AppGradientCard(
      key: ValueKey(exercicio.id),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _gifGrande(exercicio),
          const SizedBox(height: 16),
          Text(
            exercicio.nome,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _musculoPrincipal(exercicio),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (exercicio.equipamentos.isNotEmpty) ...[
            const SizedBox(height: 12),
            _infoPill(Icons.inventory_2_rounded, exercicio.equipamentos.first),
          ],
        ],
      ),
    );
  }

  Widget _gifGrande(ExercicioModel exercicio) {
    final imagem = exercicio.imagem.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: imagem.isEmpty
          ? null
          : () => mostrarGifExercicioTelaCheia(
              context,
              imagem: imagem,
              titulo: exercicio.nome,
              subtitulo: exercicio.categoria,
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 180, maxHeight: 220),
          width: double.infinity,
          color: AppColors.surfaceVariant,
          child: imagem.isEmpty
              ? const Center(
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.primary,
                    size: 52,
                  ),
                )
              : Image.asset(
                  imagem,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (_, _, _) {
                    return const Center(
                      child: Icon(
                        Icons.fitness_center_rounded,
                        color: AppColors.primary,
                        size: 52,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _seriesSection({required Key key}) {
    final concluidas = _seriesConcluidas[_exercicioAtual] ?? <int>{};

    return AppGradientCard(
      key: key,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Series',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < _seriesPorExercicio; index++) ...[
            SerieCard(
              numero: index + 1,
              peso: '0 kg',
              repeticoes: '12',
              concluida: concluidas.contains(index),
              onToggle: () => _toggleSerie(index),
            ),
            if (index < _seriesPorExercicio - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _acoes() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _concluirSerie,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Concluir serie'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _iniciarDescanso,
            icon: const Icon(Icons.hourglass_bottom_rounded),
            label: const Text('Descanso'),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exercicioAtual > 0 ? _exercicioAnterior : null,
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Anterior'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exercicioAtual < _totalExercicios - 1
                    ? _proximoExercicio
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Proximo'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white60, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return AppGradientCard(
      child: const Text(
        'Nenhum exercicio cadastrado para este treino.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );
  }

  String _grupoPrincipal() {
    final categorias = widget.treino.exercicios
        .map((exercicio) => exercicio.categoria)
        .where((categoria) => categoria.trim().isNotEmpty)
        .toSet()
        .take(2)
        .toList();

    if (categorias.isEmpty) return widget.treino.nome;
    return categorias.join(' + ');
  }

  String _musculoPrincipal(ExercicioModel exercicio) {
    if (exercicio.musculos.isNotEmpty) return exercicio.musculos.first;
    return exercicio.categoria;
  }
}
