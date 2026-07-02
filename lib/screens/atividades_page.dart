import 'package:flutter/material.dart';

import '../models/corrida_model.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';
import 'corridas/historico_corridas_page.dart';

class AtividadesPage extends StatefulWidget {
  final int passos;
  final double distancia;
  final double velocidadeMedia;
  final int segundos;
  final bool corridaIniciada;
  final VoidCallback iniciarCorrida;
  final VoidCallback pararCorrida;

  const AtividadesPage({
    super.key,
    required this.passos,
    required this.distancia,
    required this.velocidadeMedia,
    required this.segundos,
    required this.corridaIniciada,
    required this.iniciarCorrida,
    required this.pararCorrida,
  });

  @override
  State<AtividadesPage> createState() => _AtividadesPageState();
}

class _AtividadesPageState extends State<AtividadesPage> {
  int _metaPassosDiaria = 10000;
  int _metaPassosSemanal = 70000;
  int _metaPassosMensal = 300000;
  late Future<List<CorridaModel>> _corridasFuture;

  @override
  void initState() {
    super.initState();
    _corridasFuture = StorageService.carregarCorridas();
  }

  double get _progressoPassos =>
      (widget.passos / _metaPassosDiaria).clamp(0.0, 1.0);

  double get _distanciaPassosKm => widget.passos * 0.000762;

  double get _caloriasPassos => widget.passos * 0.04;

  double get _caloriasCorrida =>
      widget.distancia * 60; // estimativa simples: ~60 kcal/km

  String get _tempoFormatado {
    final h = widget.segundos ~/ 3600;
    final m = (widget.segundos % 3600) ~/ 60;
    final s = widget.segundos % 60;

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }

    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalDistancia = widget.distancia + _distanciaPassosKm;
    final totalCalorias = _caloriasCorrida + _caloriasPassos;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _buildResumoHoje(context, totalDistancia, totalCalorias),
                const SizedBox(height: 18),
                _buildPassosCard(context),
                const SizedBox(height: 18),
                _buildMetasCard(context),
                const SizedBox(height: 18),
                _buildCorridaCard(context),
                const SizedBox(height: 18),
                _buildHistoricoRecente(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 20,
        20,
        24,
      ),
      child: AppPremiumHeader(
        eyebrow: widget.corridaIniciada ? 'Atividade em andamento' : 'Hoje',
        title: 'Atividades',
        subtitle: 'Passos, corrida, distância, calorias e histórico em um só lugar.',
        icon: Icons.monitor_heart_rounded,
        gradient: widget.corridaIniciada
            ? AppColors.gradientRun
            : AppColors.gradientSteps,
        trailing: widget.corridaIniciada ? const _LiveBadge() : null,
      ),
    );
  }

  Widget _buildResumoHoje(
    BuildContext context,
    double totalDistancia,
    double totalCalorias,
  ) {
    return AppGradientCard(
      gradient: AppColors.gradientCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo de hoje',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricBox(
                label: 'Passos',
                value: '${widget.passos}',
                icon: Icons.directions_walk_rounded,
                color: AppColors.accent1,
              ),
              _MetricBox(
                label: 'Distância',
                value: '${totalDistancia.toStringAsFixed(2)} km',
                icon: Icons.route_rounded,
                color: AppColors.primary,
              ),
              _MetricBox(
                label: 'Calorias',
                value: '${totalCalorias.toStringAsFixed(0)} kcal',
                icon: Icons.local_fire_department_rounded,
                color: AppColors.accent2,
              ),
              _MetricBox(
                label: 'Tempo ativo',
                value: _tempoFormatado,
                icon: Icons.timer_rounded,
                color: AppColors.accent3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassosCard(BuildContext context) {
    final faltam = (_metaPassosDiaria - widget.passos).clamp(0, _metaPassosDiaria);

    return AppGradientCard(
      gradient: AppColors.gradientSteps,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.directions_walk_rounded,
            title: 'Passos',
            subtitle: 'Meta diária: $_metaPassosDiaria passos',
            action: IconButton(
              tooltip: 'Editar metas',
              onPressed: _abrirEditorMetas,
              icon: const Icon(Icons.tune_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${widget.passos}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  'passos',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: _progressoPassos,
              backgroundColor: Colors.black.withAlpha(55),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.passos >= _metaPassosDiaria
                ? 'Meta atingida. Excelente consistência!'
                : '$faltam passos para bater a meta de hoje.',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMetasCard(BuildContext context) {
    final progressoDiario = (widget.passos / _metaPassosDiaria).clamp(0.0, 1.0);
    final passosSemanaEstimado = widget.passos * 7;
    final passosMesEstimado = widget.passos * 30;
    final progressoSemanal = (passosSemanaEstimado / _metaPassosSemanal).clamp(0.0, 1.0);
    final progressoMensal = (passosMesEstimado / _metaPassosMensal).clamp(0.0, 1.0);

    return AppGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.flag_rounded,
            title: 'Metas de passos',
            subtitle: 'Diária, semanal e mensal',
            darkIcon: false,
            action: IconButton(
              tooltip: 'Editar metas',
              onPressed: _abrirEditorMetas,
              icon: const Icon(
                Icons.edit_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _GoalProgressTile(
            title: 'Hoje',
            value: '${widget.passos} / $_metaPassosDiaria',
            progress: progressoDiario,
            icon: Icons.today_rounded,
          ),
          const SizedBox(height: 12),
          _GoalProgressTile(
            title: 'Semana',
            value: '$passosSemanaEstimado / $_metaPassosSemanal',
            progress: progressoSemanal,
            icon: Icons.calendar_view_week_rounded,
          ),
          const SizedBox(height: 12),
          _GoalProgressTile(
            title: 'Mês',
            value: '$passosMesEstimado / $_metaPassosMensal',
            progress: progressoMensal,
            icon: Icons.calendar_month_rounded,
          ),
        ],
      ),
    );
  }

  Future<void> _abrirEditorMetas() async {
    final diariaController = TextEditingController(text: _metaPassosDiaria.toString());
    final semanalController = TextEditingController(text: _metaPassosSemanal.toString());
    final mensalController = TextEditingController(text: _metaPassosMensal.toString());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: Colors.white.withAlpha(18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Editar metas de passos',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _GoalTextField(
                  controller: diariaController,
                  label: 'Meta diária',
                  hint: 'Ex: 10000',
                ),
                const SizedBox(height: 12),
                _GoalTextField(
                  controller: semanalController,
                  label: 'Meta semanal',
                  hint: 'Ex: 70000',
                ),
                const SizedBox(height: 12),
                _GoalTextField(
                  controller: mensalController,
                  label: 'Meta mensal',
                  hint: 'Ex: 300000',
                ),
                const SizedBox(height: 20),
                AppButton.primary(
                  label: 'Salvar metas',
                  icon: Icons.check_rounded,
                  onPressed: () {
                    final diaria = int.tryParse(diariaController.text.trim()) ?? _metaPassosDiaria;
                    final semanal = int.tryParse(semanalController.text.trim()) ?? _metaPassosSemanal;
                    final mensal = int.tryParse(mensalController.text.trim()) ?? _metaPassosMensal;

                    setState(() {
                      _metaPassosDiaria = diaria.clamp(1000, 100000);
                      _metaPassosSemanal = semanal.clamp(5000, 700000);
                      _metaPassosMensal = mensal.clamp(20000, 3000000);
                    });

                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    diariaController.dispose();
    semanalController.dispose();
    mensalController.dispose();
  }

  Widget _buildCorridaCard(BuildContext context) {
    return AppGradientCard(
      gradient: widget.corridaIniciada
          ? AppColors.gradientRun
          : AppColors.gradientCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.directions_run_rounded,
            title: 'Corrida',
            subtitle: widget.corridaIniciada
                ? 'Sessão em andamento'
                : 'Pronto para iniciar',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _CompactStat(
                  label: 'Distância',
                  value: '${widget.distancia.toStringAsFixed(2)} km',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CompactStat(
                  label: 'Tempo',
                  value: _tempoFormatado,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CompactStat(
                  label: 'Ritmo',
                  value: '${widget.velocidadeMedia.toStringAsFixed(1)} km/h',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          widget.corridaIniciada
              ? AppButton.danger(
                  label: 'Parar corrida',
                  icon: Icons.stop_rounded,
                  onPressed: widget.pararCorrida,
                )
              : AppButton.primary(
                  label: 'Iniciar corrida',
                  icon: Icons.play_arrow_rounded,
                  onPressed: widget.iniciarCorrida,
                ),
          const SizedBox(height: 10),
          AppButton.secondary(
            label: 'Histórico de corridas',
            icon: Icons.history_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoricoCorridasPage(),
                ),
              ).then((_) {
                if (mounted) {
                  setState(() {
                    _corridasFuture = StorageService.carregarCorridas();
                  });
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricoRecente(BuildContext context) {
    return FutureBuilder<List<CorridaModel>>(
      future: _corridasFuture,
      builder: (context, snapshot) {
        final corridas = snapshot.data ?? const <CorridaModel>[];
        final recentes = corridas.reversed.take(3).toList();

        return AppGradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle(
                icon: Icons.timeline_rounded,
                title: 'Histórico recente',
                subtitle: 'Últimas corridas salvas',
                darkIcon: false,
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (recentes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Finalize sua primeira corrida para preencher o histórico.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                for (int i = 0; i < recentes.length; i++) ...[
                  _RunHistoryTile(corrida: recentes[i]),
                  if (i != recentes.length - 1) const AppPremiumDivider(),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: Colors.white.withAlpha(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 3),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;

  const _CompactStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(34),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool darkIcon;
  final Widget? action;

  const _CardTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.darkIcon = true,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = darkIcon ? Colors.black : AppColors.primary;
    final iconBackground =
        darkIcon ? Colors.white.withAlpha(220) : AppColors.primary.withAlpha(24);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(icon, color: iconColor, size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 8),
          action!,
        ],
      ],
    );
  }
}


class _GoalProgressTile extends StatelessWidget {
  final String title;
  final String value;
  final double progress;
  final IconData icon;

  const _GoalProgressTile({
    required this.title,
    required this.value,
    required this.progress,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: Colors.white.withAlpha(16),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _GoalTextField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.directions_walk_rounded),
      ),
    );
  }
}

class _RunHistoryTile extends StatelessWidget {
  final CorridaModel corrida;

  const _RunHistoryTile({required this.corrida});

  String get _tempo {
    final m = (corrida.segundos % 3600) ~/ 60;
    final s = corrida.segundos % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: AppColors.gradientRun,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: const Icon(Icons.directions_run_rounded, color: Colors.black),
      ),
      title: Text(
        '${corrida.distancia.toStringAsFixed(2)} km',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text('${corrida.data} • $_tempo'),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(35),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Color(0xFFFF1744), size: 10),
          SizedBox(width: 6),
          Text(
            'AO VIVO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
