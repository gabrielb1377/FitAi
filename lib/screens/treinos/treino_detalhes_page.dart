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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _metricas(context),
                const SizedBox(height: 24),
                Text(
                  'Divisao dos dias',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                for (final dia in dias)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _diaCard(context, dia),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _abrirTreino(context),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('INICIAR TREINO'),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 320,
          decoration: BoxDecoration(gradient: _bannerGradient()),
        ),
        Container(
          height: 320,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(40),
                AppColors.background.withAlpha(235),
              ],
            ),
          ),
        ),
        Positioned(
          right: -34,
          top: 74,
          child: Icon(
            _bannerIcon(),
            color: Colors.white.withAlpha(34),
            size: 190,
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(height: 54),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'PLANO ATIVO',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  treino.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  treino.descricao.trim().isEmpty
                      ? 'Plano personalizado para manter consistencia e evoluir com seguranca.'
                      : treino.descricao,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricas(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -28),
      child: AppGradientCard(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _metricPill(
              Icons.timer_rounded,
              'Tempo medio',
              '${treino.tempoEstimado} min',
            ),
            _metricPill(
              Icons.calendar_month_rounded,
              'Dias por semana',
              _diasPorSemana(),
            ),
            _metricPill(Icons.flag_rounded, 'Objetivo', treino.objetivo),
            _metricPill(Icons.trending_up_rounded, 'Dificuldade', treino.nivel),
          ],
        ),
      ),
    );
  }

  Widget _metricPill(IconData icon, String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 19),
          const SizedBox(width: 9),
          Flexible(
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
                    fontSize: 13,
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

  Widget _diaCard(BuildContext context, _DiaTreino dia) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _abrirTreino(context),
        child: AppGradientCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(28),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dia.dia,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dia.grupo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _smallChip(
                    Icons.fitness_center_rounded,
                    '${dia.quantidadeExercicios} exercicios',
                  ),
                  _smallChip(Icons.timer_rounded, '${dia.tempoEstimado} min'),
                  _smallChip(Icons.show_chart_rounded, '${dia.progresso}%'),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: dia.progresso / 100,
                  minHeight: 8,
                  color: AppColors.primary,
                  backgroundColor: AppColors.surfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(18)),
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

  void _abrirTreino(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TreinoEmAndamentoPage(treino: treino)),
    );
  }

  List<_DiaTreino> _montarDivisaoSemanal() {
    final grupos = _detectarGrupos();
    final quantidade = treino.exercicios.length;
    final tempoBase = treino.tempoEstimado <= 0 ? 45 : treino.tempoEstimado;

    return [
      _DiaTreino(
        dia: 'Segunda',
        grupo: grupos[0],
        quantidadeExercicios: quantidade,
        tempoEstimado: tempoBase,
        progresso: 0,
      ),
      _DiaTreino(
        dia: 'Terca',
        grupo: grupos[1],
        quantidadeExercicios: quantidade,
        tempoEstimado: tempoBase,
        progresso: 0,
      ),
      _DiaTreino(
        dia: 'Quarta',
        grupo: grupos[2],
        quantidadeExercicios: quantidade,
        tempoEstimado: tempoBase,
        progresso: 0,
      ),
      _DiaTreino(
        dia: 'Quinta',
        grupo: grupos[3],
        quantidadeExercicios: quantidade,
        tempoEstimado: tempoBase,
        progresso: 0,
      ),
      _DiaTreino(
        dia: 'Sexta',
        grupo: grupos[4],
        quantidadeExercicios: quantidade,
        tempoEstimado: tempoBase,
        progresso: 0,
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
    final nome = treino.nome.toLowerCase();
    if (nome.contains('abcde')) return '5 dias';
    if (nome.contains('abcd')) return '4 dias';
    if (nome.contains('abc') || nome.contains('push')) return '3 dias';
    return '5 dias';
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

  IconData _bannerIcon() {
    final objetivo = treino.objetivo.toLowerCase();
    if (objetivo.contains('cardio') || objetivo.contains('emagrec')) {
      return Icons.directions_run_rounded;
    }
    if (objetivo.contains('for')) return Icons.bolt_rounded;
    return Icons.fitness_center_rounded;
  }
}

class _DiaTreino {
  final String dia;
  final String grupo;
  final int quantidadeExercicios;
  final int tempoEstimado;
  final int progresso;

  const _DiaTreino({
    required this.dia,
    required this.grupo,
    required this.quantidadeExercicios,
    required this.tempoEstimado,
    this.progresso = 0,
  });
}
