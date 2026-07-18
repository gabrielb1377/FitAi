import 'package:flutter/material.dart';

import '../../core/xp/xp_config.dart';
import '../../design_system/fit_design_system.dart';
import '../../services/storage_service.dart';

class TreinoFinalizadoPage extends StatefulWidget {
  const TreinoFinalizadoPage({
    super.key,
    this.nomeTreino = 'Treino',
    required this.tempo,
    required this.volume,
    required this.xp,
    this.exerciciosConcluidos = 0,
    this.seriesConcluidas = 0,
    this.recordes = 0,
    this.conquistas = 0,
    this.resumoIa =
        'Treino concluido com sucesso. Mantenha a consistencia para continuar evoluindo.',
    this.onVoltar,
    this.onVerHistorico,
    this.onCompartilhar,
  });

  final String nomeTreino;
  final String tempo;
  final String volume;
  final int xp;
  final int exerciciosConcluidos;
  final int seriesConcluidas;
  final int recordes;
  final int conquistas;
  final String resumoIa;
  final VoidCallback? onVoltar;
  final VoidCallback? onVerHistorico;
  final VoidCallback? onCompartilhar;

  @override
  State<TreinoFinalizadoPage> createState() => _TreinoFinalizadoPageState();
}

class _TreinoFinalizadoPageState extends State<TreinoFinalizadoPage> {
  late final Future<_XpSnapshot> _xpFuture = _loadXp();

  Future<_XpSnapshot> _loadXp() async {
    final values = await Future.wait<int>([
      StorageService.carregarXp(),
      StorageService.carregarNivel(),
    ]);
    return _XpSnapshot(xp: values[0], level: values[1]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                FitSpacing.s20,
                FitSpacing.s32,
                FitSpacing.s20,
                FitSpacing.s32,
              ),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Treino concluido!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: FitSpacing.s8),
                Text(
                  'Otimo trabalho. Sua evolucao foi salva.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: FitSpacing.s24),
                const _CompletionRing(),
                const SizedBox(height: FitSpacing.s24),
                Row(
                  children: [
                    Expanded(
                      child: _CompletionMetric(
                        value: widget.tempo,
                        label: 'Tempo total',
                      ),
                    ),
                    const SizedBox(width: FitSpacing.s8),
                    Expanded(
                      child: _CompletionMetric(
                        value: '${widget.exerciciosConcluidos}',
                        label: 'Exercicios',
                      ),
                    ),
                    const SizedBox(width: FitSpacing.s8),
                    Expanded(
                      child: _CompletionMetric(
                        value: widget.volume,
                        label: 'Volume total',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FitSpacing.s16),
                FitCard(
                  variant: FitCardVariant.outlined,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '+${widget.xp}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(width: FitSpacing.s8),
                      Text(
                        'XP',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: FitColors.primary,
                        ),
                      ),
                      const SizedBox(width: FitSpacing.s8),
                      Text(
                        'ganhos',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: FitSpacing.s20),
                FutureBuilder<_XpSnapshot>(
                  future: _xpFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const FitSkeleton(height: 76);
                    }
                    return _LevelProgress(snapshot: snapshot.data!);
                  },
                ),
                const SizedBox(height: FitSpacing.s24),
                FitButton(
                  label: 'Ver resumo',
                  onPressed: widget.onVerHistorico ?? _showSummary,
                  expand: true,
                ),
                const SizedBox(height: FitSpacing.s12),
                FitButton(
                  label: 'Compartilhar',
                  leadingIcon: Icons.ios_share_rounded,
                  variant: FitButtonVariant.outlined,
                  onPressed: widget.onCompartilhar ?? _showSummary,
                  expand: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSummary() async {
    await FitBottomSheet.show<void>(
      context: context,
      title: widget.nomeTreino,
      subtitle: 'Resumo da sessao concluida',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SummaryRow(
            label: 'Series concluidas',
            value: '${widget.seriesConcluidas}',
          ),
          const FitDivider(),
          _SummaryRow(label: 'Recordes pessoais', value: '${widget.recordes}'),
          const FitDivider(),
          _SummaryRow(label: 'Conquistas', value: '${widget.conquistas}'),
          const SizedBox(height: FitSpacing.s16),
          Align(alignment: Alignment.centerLeft, child: Text(widget.resumoIa)),
          const SizedBox(height: FitSpacing.s20),
          FitButton(
            label: 'Voltar para Planos',
            onPressed: () {
              Navigator.pop(context);
              (widget.onVoltar ?? _returnToPlans).call();
            },
            expand: true,
          ),
        ],
      ),
    );
  }

  void _returnToPlans() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _CompletionRing extends StatelessWidget {
  const _CompletionRing();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Treino 100 por cento concluido',
        child: SizedBox.square(
          dimension: 210,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CircularProgressIndicator(
                value: 1,
                strokeWidth: 14,
                strokeCap: StrokeCap.round,
                color: FitColors.primary,
                backgroundColor: FitColors.surfaceVariant,
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '100%',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: FitSpacing.s4),
                    Text(
                      'Concluido',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionMetric extends StatelessWidget {
  const _CompletionMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      variant: FitCardVariant.outlined,
      padding: const EdgeInsets.symmetric(
        horizontal: FitSpacing.s8,
        vertical: FitSpacing.s16,
      ),
      child: SizedBox(
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(height: FitSpacing.s4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelProgress extends StatelessWidget {
  const _LevelProgress({required this.snapshot});

  final _XpSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final target = XpConfig.xpParaProximoNivel(snapshot.level);
    final progress = target <= 0 ? 0.0 : snapshot.xp / target;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text('Nivel ${snapshot.level}')),
            Text('Nivel ${snapshot.level + 1}'),
          ],
        ),
        const SizedBox(height: FitSpacing.s8),
        FitProgress(value: progress),
        const SizedBox(height: FitSpacing.s8),
        Text(
          '${snapshot.xp} / $target XP',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _XpSnapshot {
  const _XpSnapshot({required this.xp, required this.level});

  final int xp;
  final int level;
}
