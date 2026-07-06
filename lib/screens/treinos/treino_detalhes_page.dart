import 'package:flutter/material.dart';

import '../../models/treino_model.dart';
import '../../theme/app_theme.dart';
import 'treino_em_andamento_page.dart';

class TreinoDetalhesPage extends StatelessWidget {
  final TreinoModel treino;

  const TreinoDetalhesPage({super.key, required this.treino});

  @override
  Widget build(BuildContext context) {
    final dias = _montarDivisaoSemanal();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _banner(context)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              _horizontalPadding(context),
              0,
              _horizontalPadding(context),
              120,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Transform.translate(
                  offset: const Offset(0, -34),
                  child: _overviewCard(),
                ),
                const SizedBox(height: 2),
                _descriptionCard(),
                const SizedBox(height: 24),
                _sectionTitle(context),
                const SizedBox(height: 12),
                for (var index = 0; index < dias.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _dayCard(context, dias[index], index),
                  ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(
          _horizontalPadding(context),
          10,
          _horizontalPadding(context),
          18,
        ),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _abrirTreino(context),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('INICIAR TREINO'),
          ),
        ),
      ),
    );
  }

  Widget _banner(BuildContext context) {
    return SizedBox(
      height: 370,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: _bannerGradient())),
          Positioned(
            right: -46,
            top: 84,
            child: Icon(
              _bannerIcon(),
              color: Colors.white.withAlpha(34),
              size: 220,
            ),
          ),
          Positioned(
            left: -70,
            bottom: -90,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(16),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(14),
                  Colors.black.withAlpha(96),
                  AppColors.background.withAlpha(248),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _horizontalPadding(context),
                10,
                _horizontalPadding(context),
                26,
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
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'ATIVO',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    treino.nome,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: .98,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _heroChip(Icons.timer_rounded, '${_tempoSeguro()} min'),
                      _heroChip(Icons.calendar_month_rounded, _diasPorSemana()),
                      _heroChip(Icons.bolt_rounded, treino.nivel),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewCard() {
    return AppGradientCard(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 680;
          final itemWidth = wide
              ? (constraints.maxWidth - 30) / 3
              : (constraints.maxWidth - 10) / 2;

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: itemWidth,
                child: _metricTile(
                  Icons.timer_rounded,
                  'Tempo',
                  '${_tempoSeguro()} min',
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _metricTile(
                  Icons.calendar_month_rounded,
                  'Dias',
                  _diasPorSemana(),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _metricTile(
                  Icons.local_fire_department_rounded,
                  'Intensidade',
                  treino.nivel.trim().isEmpty ? 'Moderada' : treino.nivel,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _descriptionCard() {
    final descricao = treino.descricao.trim().isEmpty
        ? 'Plano estruturado para manter consistencia, evoluir com seguranca e organizar seus treinos da semana.'
        : treino.descricao.trim();

    return AppGradientCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.notes_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Descricao',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            descricao,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Lista dos dias',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          '${_montarDivisaoSemanal().length} dias',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _dayCard(BuildContext context, _DiaTreino dia, int index) {
    final concluido = dia.progresso >= 100;

    return _AnimatedDayCard(
      onTap: () => _abrirDetalheDia(context, dia: dia, index: index),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withAlpha(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(42),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            _dayImage(dia, index),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dia.dia.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: concluido
                              ? AppColors.primary
                              : Colors.white.withAlpha(14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: concluido
                                ? AppColors.primary
                                : Colors.white.withAlpha(28),
                          ),
                        ),
                        child: Icon(
                          concluido ? Icons.check_rounded : Icons.circle,
                          color: concluido ? Colors.black : Colors.transparent,
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    dia.grupo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _miniInfo(
                        Icons.fitness_center_rounded,
                        '${dia.quantidadeExercicios} exercicios',
                      ),
                      _miniInfo(
                        Icons.timer_rounded,
                        '${dia.tempoEstimado} min',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayImage(_DiaTreino dia, int index) {
    final colors = _dayColors(index);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 92,
        height: 104,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -18,
              bottom: -18,
              child: Icon(
                _dayIcon(dia.grupo),
                color: Colors.white.withAlpha(42),
                size: 86,
              ),
            ),
            Positioned(
              left: 10,
              top: 10,
              child: Text(
                (index + 1).toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(92),
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
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(13),
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
              color: AppColors.primary.withAlpha(24),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
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

  Widget _miniInfo(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white60, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _abrirTreino(BuildContext context, {_DiaTreino? dia}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TreinoEmAndamentoPage(
          treino: dia?.treinoDoDia ?? treino,
          nomeDia: dia?.dia,
          grupoDia: dia?.grupo,
        ),
      ),
    );
  }

  void _abrirDetalheDia(
    BuildContext context, {
    required _DiaTreino dia,
    required int index,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _TreinoDiaPage(
          treino: treino,
          dia: dia,
          diaIndex: index,
          bannerGradient: _bannerGradient(),
          dayColors: _dayColors(index),
          dayIcon: _dayIcon(dia.grupo),
        ),
      ),
    );
  }

  List<_DiaTreino> _montarDivisaoSemanal() {
    if (treino.planoDias.isNotEmpty) {
      final diasPlano = [...treino.planoDias]
        ..sort((a, b) => a.ordem.compareTo(b.ordem));

      return diasPlano.map((dia) {
        final treinoDoDia = treino.somenteDia(dia);
        final codigo = dia.codigo.trim();

        return _DiaTreino(
          dia: codigo.isEmpty
              ? 'Dia ${dia.ordem}'
              : 'Dia ${dia.ordem} / $codigo',
          grupo: dia.nome,
          quantidadeExercicios: treinoDoDia.exercicios.length,
          tempoEstimado: _tempoSeguro(),
          progresso: 0,
          treinoDoDia: treinoDoDia,
        );
      }).toList();
    }

    final grupos = _detectarGrupos();
    final quantidade = treino.exercicios.length;
    final tempoBase = _tempoSeguro();

    return [
      _DiaTreino(
        dia: 'Segunda',
        grupo: grupos[0],
        quantidadeExercicios: quantidade,
        tempoEstimado: tempoBase,
        progresso: 0,
        treinoDoDia: treino,
      ),
      _DiaTreino(
        dia: 'Terca',
        grupo: grupos[1],
        quantidadeExercicios: quantidade,
        tempoEstimado: tempoBase,
        progresso: 0,
        treinoDoDia: treino,
      ),
      _DiaTreino(
        dia: 'Quarta',
        grupo: grupos[2],
        quantidadeExercicios: quantidade,
        tempoEstimado: tempoBase,
        progresso: 0,
        treinoDoDia: treino,
      ),
      _DiaTreino(
        dia: 'Quinta',
        grupo: grupos[3],
        quantidadeExercicios: quantidade,
        tempoEstimado: tempoBase,
        progresso: 0,
        treinoDoDia: treino,
      ),
      _DiaTreino(
        dia: 'Sexta',
        grupo: grupos[4],
        quantidadeExercicios: quantidade,
        tempoEstimado: tempoBase,
        progresso: 0,
        treinoDoDia: treino,
      ),
    ];
  }

  List<String> _detectarGrupos() {
    final nome = treino.nome.toLowerCase();
    if (nome.contains('push') || nome.contains('pull')) {
      return ['Push', 'Pull', 'Legs', 'Recuperacao ativa', 'Push + Pull'];
    }
    if (nome.contains('full')) {
      return [
        'Full Body',
        'Cardio leve',
        'Full Body',
        'Mobilidade',
        'Full Body',
      ];
    }

    final categorias = treino.exercicios
        .map((exercicio) => exercicio.categoria)
        .where((categoria) => categoria.trim().isNotEmpty)
        .toSet()
        .toList();

    if (categorias.length >= 5) return categorias.take(5).toList();

    return ['Peito + Triceps', 'Costas + Biceps', 'Perna', 'Ombros', 'Bracos'];
  }

  String _diasPorSemana() {
    if (treino.planoDias.isNotEmpty) return '${treino.planoDias.length} dias';
    if (treino.diasPorSemana > 0) return '${treino.diasPorSemana} dias';

    final nome = treino.nome.toLowerCase();
    if (nome.contains('abcde')) return '5 dias';
    if (nome.contains('abcd')) return '4 dias';
    if (nome.contains('abc') || nome.contains('push')) return '3 dias';
    return '5 dias';
  }

  int _tempoSeguro() {
    return treino.tempoEstimado <= 0 ? 45 : treino.tempoEstimado;
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1080) return 72;
    if (width >= 720) return 36;
    return 20;
  }

  LinearGradient _bannerGradient() {
    final objetivo = treino.objetivo.toLowerCase();
    if (objetivo.contains('cardio') || objetivo.contains('emagrec')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F766E), Color(0xFF111827)],
      );
    }
    if (objetivo.contains('for')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7C2D12), Color(0xFF111827)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1D4ED8), Color(0xFF111827)],
    );
  }

  List<Color> _dayColors(int index) {
    final palettes = [
      [const Color(0xFF2563EB), const Color(0xFF111827)],
      [const Color(0xFF059669), const Color(0xFF111827)],
      [const Color(0xFFDC2626), const Color(0xFF111827)],
      [const Color(0xFF7C3AED), const Color(0xFF111827)],
      [const Color(0xFFEA580C), const Color(0xFF111827)],
    ];

    return palettes[index % palettes.length];
  }

  IconData _bannerIcon() {
    final objetivo = treino.objetivo.toLowerCase();
    if (objetivo.contains('cardio') || objetivo.contains('emagrec')) {
      return Icons.directions_run_rounded;
    }
    if (objetivo.contains('for')) return Icons.bolt_rounded;
    return Icons.fitness_center_rounded;
  }

  IconData _dayIcon(String grupo) {
    final texto = grupo.toLowerCase();
    if (texto.contains('cardio') || texto.contains('run')) {
      return Icons.directions_run_rounded;
    }
    if (texto.contains('perna') || texto.contains('legs')) {
      return Icons.airline_seat_legroom_extra_rounded;
    }
    if (texto.contains('mobilidade') || texto.contains('recuperacao')) {
      return Icons.self_improvement_rounded;
    }
    if (texto.contains('push') || texto.contains('peito')) {
      return Icons.fitness_center_rounded;
    }
    return Icons.local_fire_department_rounded;
  }
}

class _TreinoDiaPage extends StatelessWidget {
  final TreinoModel treino;
  final _DiaTreino dia;
  final int diaIndex;
  final LinearGradient bannerGradient;
  final List<Color> dayColors;
  final IconData dayIcon;

  const _TreinoDiaPage({
    required this.treino,
    required this.dia,
    required this.diaIndex,
    required this.bannerGradient,
    required this.dayColors,
    required this.dayIcon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (dia.progresso / 100).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _header(context, progress)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              _horizontalPadding(context),
              0,
              _horizontalPadding(context),
              120,
            ),
            sliver: dia.treinoDoDia.exercicios.isEmpty
                ? SliverToBoxAdapter(child: _emptyState())
                : SliverList.builder(
                    itemCount: dia.treinoDoDia.exercicios.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ExerciseDayCard(
                          exercicio: dia.treinoDoDia.exercicios[index],
                          index: index,
                          concluido: dia.progresso >= 100,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(
          _horizontalPadding(context),
          10,
          _horizontalPadding(context),
          18,
        ),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _iniciarDia(context),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('INICIAR DIA'),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, double progress) {
    return SizedBox(
      height: 330,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: bannerGradient)),
          Positioned(
            right: -36,
            top: 92,
            child: Icon(dayIcon, color: Colors.white.withAlpha(36), size: 190),
          ),
          Positioned(
            left: -30,
            bottom: -44,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dayColors.first.withAlpha(42),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(18),
                  Colors.black.withAlpha(120),
                  AppColors.background.withAlpha(248),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _horizontalPadding(context),
                10,
                _horizontalPadding(context),
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Spacer(),
                  Text(
                    'Dia ${diaIndex + 1}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dia.grupo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 9,
                            color: AppColors.primary,
                            backgroundColor: Colors.white.withAlpha(34),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${dia.progresso}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${dia.treinoDoDia.exercicios.length} exercicios',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
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

  Widget _emptyState() {
    return AppGradientCard(
      padding: const EdgeInsets.all(22),
      child: const Column(
        children: [
          Icon(
            Icons.fitness_center_rounded,
            color: AppColors.primary,
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'Nenhum exercicio neste dia',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Adicione exercicios ao plano para iniciar este dia.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _iniciarDia(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TreinoEmAndamentoPage(
          treino: dia.treinoDoDia,
          nomeDia: dia.dia,
          grupoDia: dia.grupo,
        ),
      ),
    );
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1080) return 72;
    if (width >= 720) return 36;
    return 20;
  }
}

class _ExerciseDayCard extends StatelessWidget {
  final dynamic exercicio;
  final int index;
  final bool concluido;

  const _ExerciseDayCard({
    required this.exercicio,
    required this.index,
    required this.concluido,
  });

  @override
  Widget build(BuildContext context) {
    final nome = exercicio.nome?.toString() ?? 'Exercicio';
    final grupo = exercicio.categoria?.toString() ?? 'Geral';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withAlpha(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _miniGif(exercicio.imagem?.toString() ?? ''),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(index + 1).toString().padLeft(2, '0')}  $nome',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  grupo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: const [
                    _ExerciseInfoChip(label: '3 series'),
                    _ExerciseInfoChip(label: '8-12 reps'),
                    _ExerciseInfoChip(label: '60s'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                tooltip: 'Opcoes',
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded),
                color: AppColors.textSecondary,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: concluido ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: concluido
                        ? AppColors.primary
                        : Colors.white.withAlpha(28),
                  ),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: concluido ? Colors.black : Colors.white24,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniGif(String imagem) {
    final path = imagem.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 82,
        height: 82,
        color: AppColors.surfaceVariant,
        child: path.isEmpty ? _gifFallback() : _image(path),
      ),
    );
  }

  Widget _image(String path) {
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => _gifFallback(),
      );
    }

    return Image.asset(
      path,
      fit: BoxFit.contain,
      cacheHeight: 220,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, _, _) => _gifFallback(),
    );
  }

  Widget _gifFallback() {
    return const Center(
      child: Icon(
        Icons.fitness_center_rounded,
        color: AppColors.primary,
        size: 30,
      ),
    );
  }
}

class _ExerciseInfoChip extends StatelessWidget {
  final String label;

  const _ExerciseInfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AnimatedDayCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedDayCard({required this.child, required this.onTap});

  @override
  State<_AnimatedDayCard> createState() => _AnimatedDayCardState();
}

class _AnimatedDayCardState extends State<_AnimatedDayCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: _pressed ? .985 : (_hovered ? 1.01 : 1),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: widget.onTap,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiaTreino {
  final String dia;
  final String grupo;
  final int quantidadeExercicios;
  final int tempoEstimado;
  final int progresso;
  final TreinoModel treinoDoDia;

  const _DiaTreino({
    required this.dia,
    required this.grupo,
    required this.quantidadeExercicios,
    required this.tempoEstimado,
    required this.treinoDoDia,
    this.progresso = 0,
  });
}
