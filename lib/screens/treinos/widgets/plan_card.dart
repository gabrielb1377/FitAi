import 'package:flutter/material.dart';

import '../../../models/treino_model.dart';
import '../../../theme/app_theme.dart';

class PlanCard extends StatefulWidget {
  final TreinoModel treino;
  final String ultimaExecucao;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const PlanCard({
    super.key,
    required this.treino,
    required this.ultimaExecucao,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final treino = widget.treino;
    final progress = _progressFor(treino);

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
          scale: _pressed ? 0.985 : (_hovered ? 1.012 : 1),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 306,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(_hovered ? 96 : 54),
                      blurRadius: _hovered ? 30 : 20,
                      offset: Offset(0, _hovered ? 18 : 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _background(treino),
                      Container(color: Colors.black.withAlpha(118)),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(34),
                              Colors.black.withAlpha(202),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _activeBadge(),
                                const Spacer(),
                                if (widget.onDelete != null)
                                  _iconButton(
                                    icon: Icons.delete_outline_rounded,
                                    onTap: widget.onDelete!,
                                  ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              treino.objetivo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              treino.nome,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MetricPill(
                                  icon: Icons.check_circle_rounded,
                                  label:
                                      "Treinos realizados: ${widget.ultimaExecucao}",
                                ),
                                _MetricPill(
                                  icon: Icons.calendar_month_rounded,
                                  label: _diasPorSemana(treino),
                                ),
                                _MetricPill(
                                  icon: Icons.trending_up_rounded,
                                  label: treino.nivel,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${treino.exercicios.length} exercicios - ${treino.tempoEstimado} min",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "${(progress * 100).round()}%",
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 7,
                                color: AppColors.primary,
                                backgroundColor: Colors.white.withAlpha(36),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppColors.gradientPrimary,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withAlpha(54),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Abrir",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.black,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _background(TreinoModel treino) {
    final colors = _backgroundColors(treino);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        ),
        Positioned(
          right: -34,
          top: 18,
          child: Icon(
            _backgroundIcon(treino),
            color: Colors.white.withAlpha(38),
            size: 150,
          ),
        ),
        Positioned(
          left: -28,
          bottom: -26,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _activeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        "ATIVO",
        style: TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(90),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  List<Color> _backgroundColors(TreinoModel treino) {
    final objetivo = treino.objetivo.toLowerCase();
    if (objetivo.contains("cardio") || objetivo.contains("emagrec")) {
      return [const Color(0xFF0F766E), const Color(0xFF111827)];
    }
    if (objetivo.contains("for")) {
      return [const Color(0xFF7C2D12), const Color(0xFF111827)];
    }
    return [const Color(0xFF1D4ED8), const Color(0xFF111827)];
  }

  IconData _backgroundIcon(TreinoModel treino) {
    final objetivo = treino.objetivo.toLowerCase();
    if (objetivo.contains("cardio") || objetivo.contains("emagrec")) {
      return Icons.directions_run_rounded;
    }
    if (objetivo.contains("for")) return Icons.bolt_rounded;
    return Icons.fitness_center_rounded;
  }

  String _diasPorSemana(TreinoModel treino) {
    final nome = treino.nome.toLowerCase();
    if (nome.contains("abcde")) return "5 dias/sem";
    if (nome.contains("abcd")) return "4 dias/sem";
    if (nome.contains("abc") || nome.contains("push")) return "3 dias/sem";
    return "3 dias/sem";
  }

  double _progressFor(TreinoModel treino) {
    if (treino.exercicios.isEmpty) return 0;
    return 0.0;
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
