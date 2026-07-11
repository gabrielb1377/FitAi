import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../ai_workout_page.dart';
import '../../services/treino_service.dart';
import 'criar_treino_page.dart';
import 'historico_treinos_page.dart';
import 'ready_plans/ready_plans_library_page.dart';
import 'widgets/create_plan_bottomsheet.dart';
import 'widgets/plan_card.dart';
import 'treino_detalhes_page.dart';

class TreinosPage extends StatefulWidget {
  final Future<void> Function()? onXpAtualizado;

  const TreinosPage({super.key, this.onXpAtualizado});

  @override
  State<TreinosPage> createState() => _TreinosPageState();
}

class _TreinosPageState extends State<TreinosPage> {
  final treinoService = TreinoService.instance;

  @override
  void initState() {
    super.initState();
    _carregarTreinos();
  }

  Future<void> _carregarTreinos() async {
    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _carregarTreinos,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildActionButtons(context),
                  const SizedBox(height: 24),
                  _buildTreinos(),
                ]),
              ),
            ),
          ],
        ),
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Meus Planos",
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          _headerAction(
            icon: Icons.notifications_none_rounded,
            tooltip: "Historico de treinos",
            onTap: _abrirHistoricoTreinos,
          ),
        ],
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: primary ? AppColors.gradientPrimary : null,
              color: primary ? null : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primary
                    ? Colors.transparent
                    : AppColors.primary.withAlpha(40),
              ),
            ),
            child: Icon(
              icon,
              color: primary ? Colors.black : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;

        final prontoButton = _PlanActionButton(
          label: "Adicionar treino pronto",
          icon: Icons.add_circle_outline_rounded,
          onTap: _abrirTreinoPronto,
        );
        final criarButton = _PlanActionButton(
          label: "Criar plano",
          icon: Icons.add_rounded,
          primary: true,
          onTap: _abrirCriacaoPlano,
        );

        if (compact) {
          return Column(
            children: [prontoButton, const SizedBox(height: 12), criarButton],
          );
        }

        return Row(
          children: [
            Expanded(child: prontoButton),
            const SizedBox(width: 12),
            Expanded(child: criarButton),
          ],
        );
      },
    );
  }

  Future<void> _abrirTreinoPronto() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ReadyPlansLibraryPage()),
    );

    if (!mounted) return;

    await _carregarTreinos();

    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plano adicionado aos seus planos.')),
      );
    }
  }

  Future<void> _abrirHistoricoTreinos() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoricoTreinosPage()),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _abrirCriacaoPlano() async {
    final action = await showModalBottomSheet<CreatePlanAction>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const CreatePlanBottomSheet(),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case CreatePlanAction.ia:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIWorkoutPage()),
        );
        break;
      case CreatePlanAction.manual:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CriarTreinoPage()),
        );
        break;
    }

    if (!mounted) return;

    await _carregarTreinos();
  }

  // ignore: unused_element
  Widget _buildAcoesCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIWorkoutPage()),
        );

        if (!mounted) return;

        await _carregarTreinos();
      },
      child: AppGradientCard(
        gradient: AppColors.gradientPrimary,
        child: Row(
          children: const [
            Icon(Icons.auto_awesome, color: Colors.black),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                "Gerar treino com IA",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.black),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCriarManualCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CriarTreinoPage()),
        );

        if (!mounted) return;

        await _carregarTreinos();
      },
      child: AppGradientCard(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                "Criar treino manual",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildHistoricoTreinosCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoricoTreinosPage()),
        );

        if (!mounted) return;

        setState(() {});
      },
      child: AppGradientCard(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: AppColors.accent1,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Histórico de treinos",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "Sessões finalizadas, XP e calorias",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCategorias(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _categoriaCard(
            titulo: "Hipertrofia",
            icon: Icons.fitness_center,
            gradient: AppColors.gradientWorkout,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _categoriaCard(
            titulo: "Cardio",
            icon: Icons.directions_run,
            gradient: AppColors.gradientRun,
          ),
        ),
      ],
    );
  }

  Widget _categoriaCard({
    required String titulo,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return AppGradientCard(
      gradient: gradient,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 18),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreinos() {
    final treinos = treinoService.treinos
        .where((treino) => treino.isPlanoPrincipal)
        .toList();

    if (treinos.isEmpty) {
      return AppGradientCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(28),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Nenhum plano criado ainda.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Crie seu primeiro plano para comecar.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 760;
            final cardWidth = twoColumns
                ? (constraints.maxWidth - 14) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final treino in treinos)
                  SizedBox(
                    width: cardWidth,
                    child: PlanCard(
                      treino: treino,
                      ultimaExecucao: "0 realizados",
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TreinoDetalhesPage(treino: treino),
                          ),
                        );

                        if (!mounted) return;
                        setState(() {});
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PlanActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  const _PlanActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  @override
  State<_PlanActionButton> createState() => _PlanActionButtonState();
}

class _PlanActionButtonState extends State<_PlanActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final foreground = widget.primary ? Colors.black : AppColors.textPrimary;
    final background = widget.primary ? null : AppColors.surfaceVariant;
    final borderColor = widget.primary
        ? Colors.transparent
        : AppColors.primary.withAlpha(_hovered ? 90 : 42);

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
          scale: _pressed ? .985 : (_hovered ? 1.01 : 1),
          duration: const Duration(milliseconds: 160),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  gradient: widget.primary ? AppColors.gradientPrimary : null,
                  color: background,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(_hovered ? 72 : 38),
                      blurRadius: _hovered ? 24 : 16,
                      offset: Offset(0, _hovered ? 14 : 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: foreground),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
