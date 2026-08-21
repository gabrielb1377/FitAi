import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fitai/design_system/design_system.dart';

import '../../../core_journey/presentation/core_journey_scope.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_models.dart';
import '../controllers/profile_controller.dart';
import '../routes/profile_routes.dart';
import '../widgets/profile_dashboard.dart';
import '../widgets/profile_empty_dashboard.dart';
import '../widgets/profile_goal_editor_sheet.dart';
import '../widgets/profile_loading_view.dart';
import 'profile_xp_history_page.dart';

/// Raiz oficial do Perfil baseada exclusivamente no [ProfileSnapshot].
///
/// Os parametros legados permanecem temporariamente para manter a composicao
/// atual do App Router. A interface nao os utiliza como fonte de dados.
class ProfileRootPage extends StatefulWidget {
  const ProfileRootPage({
    super.key,
    required this.name,
    required this.weight,
    required this.height,
    required this.age,
    required this.level,
    required this.firstRunAchievement,
    required this.tenKilometersAchievement,
    this.onProfileUpdated,
    this.controller,
  });

  final String name;
  final String weight;
  final String height;
  final String age;
  final int level;
  final bool firstRunAchievement;
  final bool tenKilometersAchievement;
  final Future<void> Function()? onProfileUpdated;
  final ProfileController? controller;

  @override
  State<ProfileRootPage> createState() => _ProfileRootPageState();
}

class _ProfileRootPageState extends State<ProfileRootPage> {
  late final ProfileController _controller;
  late final bool _ownsController;
  var _isControllerReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isControllerReady) return;
    _ownsController = widget.controller == null;
    final historyLoader = CoreJourneyScope.maybeOf(
      context,
    )?.notifier?.loadPlanWorkoutHistory;
    _controller =
        widget.controller ??
        ProfileController(
          repository: ProfileRepository.local(planHistoryLoader: historyLoader),
        );
    _isControllerReady = true;
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    if (_isControllerReady && _ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isControllerReady) return const ProfileLoadingView();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final state = _controller.state;
            final child = switch (state.status) {
              ProfileLoadStatus.initial || ProfileLoadStatus.loading
                  when !state.hasSnapshot =>
                const ProfileLoadingView(),
              ProfileLoadStatus.error when !state.hasSnapshot => _ErrorView(
                onRetry: _controller.load,
              ),
              _ => _buildContent(state.snapshot!),
            };
            return AnimatedSwitcher(
              duration: FitDuration.fade,
              switchInCurve: FitDuration.enterCurve,
              switchOutCurve: FitDuration.exitCurve,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: child,
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(ProfileSnapshot snapshot) {
    if (_isEmpty(snapshot)) {
      return ProfileEmptyDashboard(
        displayName: widget.name,
        onEdit: _openEdit,
        onSettings: () => _openRoute(ProfileRoutes.settings),
        onPrivacy: () => _openRoute(ProfileRoutes.privacy),
      );
    }
    return ProfileDashboard(
      snapshot: snapshot,
      onRefresh: _controller.refresh,
      onEdit: _openEdit,
      onSettings: () => _openRoute(ProfileRoutes.settings),
      onPrivacy: () => _openRoute(ProfileRoutes.privacy),
      onExport: _showExportPlaceholder,
      onHelp: _showHelp,
      onOpenFavorites: _showFavoritesInfo,
      onOpenAchievements: _showAchievementsInfo,
      onConfigureGoals: () => unawaited(_editGoals(snapshot)),
    );
  }

  bool _isEmpty(ProfileSnapshot snapshot) {
    final stats = snapshot.stats;
    return snapshot.profile.name == null &&
        stats.activeDays == 0 &&
        stats.totalRuns == 0 &&
        stats.totalSteps == 0 &&
        stats.completedWorkouts == 0 &&
        stats.favoriteExercises == 0 &&
        snapshot.progression.events.isEmpty;
  }

  void _openEdit() => unawaited(_openEditAndRefresh());

  Future<void> _openEditAndRefresh() async {
    await Navigator.of(context).pushNamed(ProfileRoutes.edit);
    if (mounted) await _controller.refresh();
  }

  void _openRoute(String route) => Navigator.of(context).pushNamed(route);

  void _showFavoritesInfo() {
    const FitSnackBar(
      message: 'Consulte e gerencie favoritos na aba Biblioteca.',
      tone: FitSnackBarTone.info,
    ).show(context);
  }

  void _showAchievementsInfo() {
    final snapshot = _controller.state.snapshot;
    if (snapshot == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProfileXpHistoryPage(snapshot: snapshot.progression),
      ),
    );
  }

  Future<void> _editGoals(ProfileSnapshot snapshot) async {
    await FitBottomSheet.show<void>(
      context: context,
      title: 'Editar metas',
      subtitle: 'A mudanca preserva o progresso ja registrado.',
      isScrollControlled: true,
      child: ProfileGoalEditorSheet(
        goals: snapshot.progression.activeGoals,
        onSave: (type, target) =>
            _controller.updateGoalTarget(type: type, target: target),
      ),
    );
  }

  Future<void> _showExportPlaceholder() async {
    await FitBottomSheet.show<void>(
      context: context,
      title: 'Exportar dados',
      subtitle: 'Funcionalidade preparada para uma proxima etapa.',
      child: FitActionSheet(
        items: [
          FitActionSheetItem(
            label: 'Exportacao ainda indisponivel',
            description:
                'Nenhum dado sera copiado ou enviado ate existir uma integracao segura.',
            icon: FitIcons.share,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _showHelp() async {
    await FitBottomSheet.show<void>(
      context: context,
      title: 'Ajuda',
      child: FitActionSheet(
        items: [
          FitActionSheetItem(
            label: 'Central de ajuda em preparacao',
            description:
                'Os canais de suporte serao disponibilizados em breve.',
            icon: FitIcons.info,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const FitHeader(title: 'Perfil'),
        Expanded(
          child: FitErrorState(
            error: 'Nao foi possivel carregar os dados locais do Perfil.',
            onRetry: onRetry,
          ),
        ),
      ],
    );
  }
}
