import 'package:flutter/material.dart';

import '../../models/exercicio_model.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/exercicio_gif_viewer.dart';

class ExercicioDetalhePage extends StatelessWidget {
  final ExercicioModel exercicio;
  final bool permitirAdicionar;
  final void Function(ExercicioModel exercicio)? onAdicionar;

  const ExercicioDetalhePage({
    super.key,
    required this.exercicio,
    this.permitirAdicionar = true,
    this.onAdicionar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _hero(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _quickInfo(),
                const SizedBox(height: 16),
                _muscleSection(),
                const SizedBox(height: 16),
                _executionSection(),
                const SizedBox(height: 16),
                _mistakesSection(),
                const SizedBox(height: 16),
                _fitiaTipsSection(),
                const SizedBox(height: 16),
                _similarSection(),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: permitirAdicionar
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _adicionar(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Adicionar ao treino'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _hero(BuildContext context) {
    return SizedBox(
      height: 462,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.surface, AppColors.background],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      _FavoriteExerciseButton(exercicio: exercicio),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _heroBadge(),
                  const SizedBox(height: 14),
                  ExercicioGifViewer(
                    canonicalExerciseId:
                        exercicio.canonicalExerciseId.trim().isNotEmpty
                        ? exercicio.canonicalExerciseId
                        : exercicio.id,
                    titulo: exercicio.nome,
                    subtitulo: exercicio.categoria,
                    height: 246,
                    borderRadius: 28,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    exercicio.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _grupoMuscular(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
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

  Widget _quickInfo() {
    return AppGradientCard(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _metric(Icons.groups_rounded, 'Grupo', exercicio.categoria),
          _metric(Icons.fitness_center_rounded, 'Equipamento', _equipamento()),
          _metric(Icons.bolt_rounded, 'Dificuldade', exercicio.dificuldade),
        ],
      ),
    );
  }

  Widget _muscleSection() {
    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Músculos trabalhados',
            Icons.accessibility_new_rounded,
          ),
          const SizedBox(height: 14),
          _chipGroup('Primários', exercicio.musculos),
          const SizedBox(height: 12),
          _chipGroup('Secundários', exercicio.musculosSecundarios),
        ],
      ),
    );
  }

  Widget _executionSection() {
    final steps = _splitInstruction(exercicio.comoExecutar);
    final fallbackSteps = [
      'Ajuste postura, apoio e amplitude antes de iniciar.',
      'Execute a fase principal com controle e sem impulso.',
      'Retorne devagar mantendo tensão no músculo alvo.',
      'Finalize mantendo respiração e alinhamento.',
    ];
    final items = (steps.isEmpty ? fallbackSteps : steps).take(4).toList();

    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Como executar', Icons.format_list_numbered_rounded),
          const SizedBox(height: 14),
          for (var index = 0; index < items.length; index++) ...[
            _stepTile(index + 1, items[index]),
            if (index != items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _mistakesSection() {
    final mistakes = _splitInstruction(exercicio.cuidados);
    final items =
        (mistakes.isEmpty
                ? [
                    'Usar carga alta antes de dominar a técnica.',
                    'Perder o alinhamento durante a repetição.',
                    'Acelerar demais e reduzir a amplitude.',
                  ]
                : mistakes)
            .take(4)
            .toList();

    return _bulletSection(
      title: 'Erros comuns',
      icon: Icons.warning_amber_rounded,
      items: items,
      color: Colors.amber,
    );
  }

  Widget _fitiaTipsSection() {
    final dificuldade = exercicio.dificuldade.trim();
    final items = [
      'Priorize sentir ${_grupoMuscular().toLowerCase()} antes de aumentar carga.',
      'Use ${_equipamento().toLowerCase()} com ritmo controlado nas fases de ida e volta.',
      if (dificuldade.isNotEmpty)
        'Nível $dificuldade: mantenha 1 a 2 repetições de reserva nas primeiras séries.',
      'Registre carga, repetições e observações para acompanhar evolução.',
    ];

    return _bulletSection(
      title: 'Dicas FitIA',
      icon: Icons.auto_awesome_rounded,
      items: items,
      color: AppColors.primary,
    );
  }

  Widget _similarSection() {
    final similares = <_SimilarItem>[
      _SimilarItem(Icons.groups_rounded, 'Mesmo grupo', exercicio.categoria),
      _SimilarItem(
        Icons.fitness_center_rounded,
        'Mesmo equipamento',
        _equipamento(),
      ),
      _SimilarItem(
        Icons.bolt_rounded,
        'Mesma dificuldade',
        exercicio.dificuldade,
      ),
      for (final musculo in exercicio.musculos.take(2))
        _SimilarItem(Icons.accessibility_new_rounded, 'Músculo alvo', musculo),
    ].where((item) => item.value.trim().isNotEmpty).toList();

    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Exercícios semelhantes', Icons.hub_rounded),
          const SizedBox(height: 12),
          if (similares.isEmpty)
            _similarTile(
              const _SimilarItem(
                Icons.hub_rounded,
                'Sugestão',
                'Mesmo grupo muscular',
              ),
            )
          else
            ...similares.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _similarTile(item),
              ),
            ),
        ],
      ),
    );
  }

  Widget _heroBadge() {
    return _miniPill(Icons.info_outline_rounded, 'Detalhe do exercício');
  }

  Widget _miniPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(90),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepTile(int number, String text) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletSection({
    required String title,
    required IconData icon,
    required List<String> items,
    required Color color,
  }) {
    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, icon),
          const SizedBox(height: 12),
          for (final item in items) _bulletItem(item, color),
        ],
      ),
    );
  }

  Widget _bulletItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.42,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _similarTile(_SimilarItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipGroup(String label, List<String> items) {
    final values = items.where((item) => item.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.isEmpty
              ? [_chip('Não informado')]
              : values.map(_chip).toList(),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(16)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _grupoMuscular() {
    if (exercicio.musculos.isNotEmpty) return exercicio.musculos.first;
    return exercicio.categoria.trim().isEmpty
        ? 'Grupo muscular'
        : exercicio.categoria;
  }

  String _equipamento() {
    if (exercicio.equipamentos.isEmpty) return 'Peso corporal';
    return exercicio.equipamentos.first;
  }

  List<String> _splitInstruction(String value) {
    return value
        .split(RegExp(r'[\n.;]+'))
        .map((item) => item.trim())
        .where((item) => item.length > 8)
        .toList();
  }

  void _adicionar(BuildContext context) {
    onAdicionar?.call(exercicio);
    Navigator.pop(context, exercicio);
  }
}

class _SimilarItem {
  final IconData icon;
  final String label;
  final String value;

  const _SimilarItem(this.icon, this.label, this.value);
}

class _FavoriteExerciseButton extends StatefulWidget {
  final ExercicioModel exercicio;

  const _FavoriteExerciseButton({required this.exercicio});

  @override
  State<_FavoriteExerciseButton> createState() =>
      _FavoriteExerciseButtonState();
}

class _FavoriteExerciseButtonState extends State<_FavoriteExerciseButton> {
  bool favorito = false;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarFavorito();
  }

  Future<void> _carregarFavorito() async {
    final favoritos = await StorageService.carregarFavoritosExercicios();

    if (!mounted) return;

    setState(() {
      favorito = favoritos.contains(widget.exercicio.id);
      widget.exercicio.favorito = favorito;
      carregando = false;
    });
  }

  Future<void> _alternarFavorito() async {
    setState(() => carregando = true);

    final novoEstado = await StorageService.alternarFavoritoExercicio(
      widget.exercicio.id,
    );

    if (!mounted) return;

    setState(() {
      favorito = novoEstado;
      widget.exercicio.favorito = novoEstado;
      carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: carregando ? null : _alternarFavorito,
      tooltip: favorito ? 'Remover favorito' : 'Favoritar',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: carregando
            ? const SizedBox(
                key: ValueKey('loading'),
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                favorito ? Icons.star_rounded : Icons.star_border_rounded,
                key: ValueKey(favorito),
                color: favorito ? AppColors.accent2 : AppColors.textPrimary,
              ),
      ),
    );
  }
}
