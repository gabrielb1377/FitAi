import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/exercicio_model.dart';
import '../../models/treino_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/exercicio_gif_viewer.dart';

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
  final Map<int, List<_SerieRegistro>> _historico = {};
  final Map<int, String> _comentarios = {};

  final TextEditingController _pesoController = TextEditingController(
    text: '0',
  );
  final TextEditingController _repeticoesController = TextEditingController(
    text: '12',
  );
  final TextEditingController _comentarioController = TextEditingController();

  Timer? _treinoTimer;
  Timer? _descansoTimer;

  int _exercicioAtual = 0;
  int _segundosTreino = 0;
  int _descansoRestante = 0;

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

  ExercicioModel? get _proximoExercicio {
    if (_exercicioAtual >= _totalExercicios - 1) return null;
    return widget.treino.exercicios[_exercicioAtual + 1];
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

  void _registrarSerie() {
    final exercicio = _exercicio;
    if (exercicio == null) return;

    final concluidas = _seriesConcluidas[_exercicioAtual] ?? <int>{};
    if (concluidas.length >= _seriesPorExercicio) {
      _avancarDepoisDoExercicio();
      return;
    }

    final serieIndex = concluidas.length;
    final peso = _pesoController.text.trim().isEmpty
        ? '0'
        : _pesoController.text.trim();
    final repeticoes = int.tryParse(_repeticoesController.text.trim()) ?? 0;
    final comentario = _comentarioController.text.trim();

    setState(() {
      _seriesConcluidas[_exercicioAtual] = {...concluidas, serieIndex};
      _comentarios[_exercicioAtual] = comentario;
      _historico
          .putIfAbsent(_exercicioAtual, () => [])
          .insert(
            0,
            _SerieRegistro(
              numero: serieIndex + 1,
              peso: peso,
              repeticoes: repeticoes,
              comentario: comentario,
              data: DateTime.now(),
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
    setState(() {
      _repeticoesController.text = '${atual + 1}';
      _repeticoesController.selection = TextSelection.fromPosition(
        TextPosition(offset: _repeticoesController.text.length),
      );
    });
  }

  void _iniciarDescanso() {
    _descansoTimer?.cancel();
    setState(() => _descansoRestante = _descansoPadrao);

    _descansoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_descansoRestante <= 1) {
        _descansoTimer?.cancel();
        setState(() => _descansoRestante = 0);
        _mostrarMensagem('Descanso finalizado.');
        return;
      }

      setState(() => _descansoRestante--);
    });
  }

  void _avancarDepoisDoExercicio() {
    if (_exercicioAtual < _totalExercicios - 1) {
      _proximoExercicioManual();
      return;
    }

    _mostrarMensagem('Treino concluido.');
  }

  void _proximoExercicioManual() {
    if (_totalExercicios == 0) return;
    _descansoTimer?.cancel();
    setState(() {
      _descansoRestante = 0;
      if (_exercicioAtual < _totalExercicios - 1) {
        _exercicioAtual++;
        _sincronizarComentario();
      }
    });
  }

  void _exercicioAnterior() {
    if (_totalExercicios == 0) return;
    _descansoTimer?.cancel();
    setState(() {
      _descansoRestante = 0;
      if (_exercicioAtual > 0) {
        _exercicioAtual--;
        _sincronizarComentario();
      }
    });
  }

  void _sincronizarComentario() {
    _comentarioController.text = _comentarios[_exercicioAtual] ?? '';
    _comentarioController.selection = TextSelection.fromPosition(
      TextPosition(offset: _comentarioController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercicio = _exercicio;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _topBar(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
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
                    child: _exerciseContent(exercicio),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 10,
        20,
        16,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nomeDia,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _grupoDia,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _tempoFormatado,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
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
                _totalExercicios == 0
                    ? '0/0'
                    : '${_exercicioAtual + 1}/$_totalExercicios',
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

  Widget _exerciseContent(ExercicioModel exercicio) {
    return Column(
      key: ValueKey(exercicio.id),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _gifGrande(exercicio),
        const SizedBox(height: 18),
        _titleBlock(exercicio),
        const SizedBox(height: 18),
        _metricCircles(),
        const SizedBox(height: 18),
        _registroCampos(),
        const SizedBox(height: 18),
        _historicoSection(),
        const SizedBox(height: 18),
        _comentariosSection(),
        const SizedBox(height: 18),
        _registrarButton(),
        const SizedBox(height: 12),
        _nextExercisePanel(),
      ],
    );
  }

  Widget _gifGrande(ExercicioModel exercicio) {
    final imagem = exercicio.imagem.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: imagem.isEmpty
          ? null
          : () => mostrarGifExercicioTelaCheia(
              context,
              imagem: imagem,
              titulo: exercicio.nome,
              subtitulo: exercicio.categoria,
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          constraints: const BoxConstraints(minHeight: 210, maxHeight: 260),
          width: double.infinity,
          color: AppColors.surfaceVariant,
          child: imagem.isEmpty ? _gifFallback(size: 60) : _gifImage(imagem),
        ),
      ),
    );
  }

  Widget _gifImage(String imagem) {
    final isNetwork =
        imagem.startsWith('http://') || imagem.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        imagem,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => _gifFallback(size: 60),
      );
    }

    return Image.asset(
      imagem,
      fit: BoxFit.contain,
      cacheHeight: 620,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, _, _) => _gifFallback(size: 60),
    );
  }

  Widget _gifFallback({required double size}) {
    return Center(
      child: Icon(
        Icons.fitness_center_rounded,
        color: AppColors.primary,
        size: size,
      ),
    );
  }

  Widget _titleBlock(ExercicioModel exercicio) {
    final descricao = exercicio.descricao.trim().isEmpty
        ? 'Execute com controle, respire bem e mantenha a postura durante toda a serie.'
        : exercicio.descricao.trim();

    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercicio.nome,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _smallPill(
                Icons.track_changes_rounded,
                _musculoPrincipal(exercicio),
              ),
              if (exercicio.equipamentos.isNotEmpty)
                _smallPill(
                  Icons.inventory_2_rounded,
                  exercicio.equipamentos.first,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCircles() {
    final seriesConcluidas = _seriesConcluidas[_exercicioAtual]?.length ?? 0;

    return Row(
      children: [
        Expanded(
          child: _CircleMetric(
            label: 'Repeticoes',
            value: _repeticoesController.text.trim().isEmpty
                ? '0'
                : _repeticoesController.text.trim(),
            icon: Icons.format_list_numbered_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CircleMetric(
            label: 'Descanso',
            value: _emDescanso
                ? '${_descansoRestante}s'
                : '${_descansoPadrao}s',
            icon: Icons.hourglass_bottom_rounded,
            highlighted: _emDescanso,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CircleMetric(
            label: 'Series',
            value: '$seriesConcluidas/$_seriesPorExercicio',
            icon: Icons.repeat_rounded,
          ),
        ),
      ],
    );
  }

  Widget _registroCampos() {
    return AppGradientCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registrar carga',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _inputField(
                  controller: _pesoController,
                  label: 'Peso',
                  suffix: 'kg',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _inputField(
                  controller: _repeticoesController,
                  label: 'Repeticoes',
                  suffix: 'reps',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 50,
                height: 56,
                child: ElevatedButton(
                  onPressed: _incrementarRepeticoes,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Icon(Icons.add_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required TextInputType keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w900,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withAlpha(16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withAlpha(16)),
        ),
      ),
    );
  }

  Widget _historicoSection() {
    final historico = _historico[_exercicioAtual] ?? const <_SerieRegistro>[];

    return AppGradientCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historico',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (historico.isEmpty)
            const Text(
              'Nenhuma serie registrada neste exercicio ainda.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            for (var index = 0; index < historico.length; index++) ...[
              _historyRow(historico[index]),
              if (index < historico.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _historyRow(_SerieRegistro registro) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              '${registro.numero}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${registro.peso} kg x ${registro.repeticoes} reps',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            _horaCurta(registro.data),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _comentariosSection() {
    return AppGradientCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comentarios',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comentarioController,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Como foi a serie? Alguma observacao?',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.white.withAlpha(16)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.white.withAlpha(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _registrarButton() {
    final concluidas = _seriesConcluidas[_exercicioAtual]?.length ?? 0;
    final terminouExercicio = concluidas >= _seriesPorExercicio;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: terminouExercicio
            ? _avancarDepoisDoExercicio
            : _registrarSerie,
        icon: Icon(
          terminouExercicio ? Icons.skip_next_rounded : Icons.add_task_rounded,
        ),
        label: Text(
          terminouExercicio ? 'Proximo exercicio' : 'Registrar serie',
        ),
      ),
    );
  }

  Widget _nextExercisePanel() {
    final proximo = _proximoExercicio;

    return Row(
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
            onPressed: proximo == null ? null : _proximoExercicioManual,
            icon: const Icon(Icons.chevron_right_rounded),
            label: Text(proximo == null ? 'Ultimo' : 'Proximo'),
          ),
        ),
      ],
    );
  }

  Widget _smallPill(IconData icon, String label) {
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

  String _horaCurta(DateTime data) {
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
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

class _CircleMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlighted;

  const _CircleMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withAlpha(30)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withAlpha(120)
              : Colors.white.withAlpha(16),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlighted
                  ? AppColors.primary.withAlpha(32)
                  : AppColors.surfaceVariant,
            ),
            child: Icon(icon, color: AppColors.primary, size: 25),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SerieRegistro {
  final int numero;
  final String peso;
  final int repeticoes;
  final String comentario;
  final DateTime data;

  const _SerieRegistro({
    required this.numero,
    required this.peso,
    required this.repeticoes,
    required this.comentario,
    required this.data,
  });
}
