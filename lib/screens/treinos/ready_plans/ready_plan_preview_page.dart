import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/fitai_memory_model.dart';
import '../../../models/ready_plan_day_model.dart';
import '../../../models/ready_plan_exercise_model.dart';
import '../../../models/ready_plan_model.dart';
import '../../../services/fitai_memory_service.dart';
import '../../../services/ready_plan_favorites_service.dart';
import '../../../services/ready_plan_mapper.dart';
import '../../../services/ready_plan_recommendation_reason_service.dart';
import '../../../services/ready_plans_service.dart';
import '../../../services/sync_service.dart';
import '../../../services/treino_service.dart';
import '../../../theme/app_theme.dart';
import 'widgets/ready_plans_empty_state.dart';
import 'widgets/ready_plans_header.dart';
import 'widgets/ready_plans_loading.dart';

class ReadyPlanPreviewPage extends StatefulWidget {
  final ReadyPlanModel plan;

  const ReadyPlanPreviewPage({super.key, required this.plan});

  @override
  State<ReadyPlanPreviewPage> createState() => _ReadyPlanPreviewPageState();
}

class _ReadyPlanPreviewPageState extends State<ReadyPlanPreviewPage> {
  final _service = ReadyPlansService();
  final _favoritesService = ReadyPlanFavoritesService.instance;
  final _memoryService = const FitAIMemoryService();
  final _recommendationService = const ReadyPlanRecommendationReasonService();

  ReadyPlanModel? _plan;
  FitAIMemoryModel _memory = const FitAIMemoryModel();
  bool _loading = true;
  bool _hasError = false;
  bool _adding = false;
  bool _added = false;

  @override
  void initState() {
    super.initState();
    _favoritesService.addListener(_onFavoritesChanged);
    unawaited(_favoritesService.loadFavoriteIds());
    unawaited(_loadDetails());
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  Future<void> _loadDetails() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _hasError = false;
      });
    }

    try {
      final plan = await _service.getPlanDetails(widget.plan.id);
      FitAIMemoryModel memory = const FitAIMemoryModel();
      try {
        memory = await _memoryService.carregarMemoria();
      } catch (_) {
        // Sem perfil, os motivos permanecem neutros e seguros.
      }
      final alreadyAdded = await TreinoService.instance.contemPlanoPronto(
        plan.id,
      );

      if (!mounted) return;
      setState(() {
        _plan = plan;
        _memory = memory;
        _loading = false;
        _added = alreadyAdded;
      });
    } on ReadyPlansException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  bool get _canAdd =>
      !_loading && !_hasError && _plan != null && !_adding && !_added;

  Future<void> _addPlan() async {
    final plan = _plan;
    if (plan == null || !_canAdd) return;
    setState(() => _adding = true);

    try {
      final clientId = await SyncService.instance.getClientId();
      final copied = await _service.copyReadyPlan(plan.id, clientId: clientId);
      await TreinoService.instance.adicionarTreinoComPersistencia(
        ReadyPlanMapper.toTreino(
          plan,
          workoutId: copied.workoutId,
          source: 'ready_plan',
        ),
      );
      if (!mounted) return;
      setState(() {
        _adding = false;
        _added = true;
      });
      Navigator.pop(context, true);
    } on ReadyPlansException catch (error) {
      if (error.isNetworkUnavailable) {
        await _saveOffline(plan);
        return;
      }
      if (!mounted) return;
      setState(() {
        _adding = false;
        _added = error.statusCode == 409;
      });
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _adding = false);
      _showMessage('Não foi possível adicionar o plano agora.');
    }
  }

  Future<void> _saveOffline(ReadyPlanModel plan) async {
    try {
      await TreinoService.instance.adicionarTreinoComPersistencia(
        ReadyPlanMapper.toTreino(
          plan,
          workoutId: 'ready_plan_${plan.id}',
          source: 'ready_plan_offline',
        ),
      );
      if (!mounted) return;
      setState(() {
        _adding = false;
        _added = true;
      });
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _adding = false);
      _showMessage('Não foi possível salvar o plano localmente.');
    }
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final favorite = _favoritesService.isFavorite(widget.plan.id);
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: FilledButton(
          onPressed: _canAdd ? _addPlan : null,
          child: SizedBox(
            height: 48,
            child: Center(
              child: _adding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _added ? 'Já adicionado' : 'Adicionar aos meus planos',
                    ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ReadyPlansHeader(
              title: widget.plan.name,
              subtitle: 'Prévia do plano',
              trailing: IconButton(
                tooltip: favorite ? 'Remover dos favoritos' : 'Favoritar plano',
                onPressed: () =>
                    unawaited(_favoritesService.toggleFavorite(widget.plan.id)),
                icon: Icon(
                  favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: favorite
                      ? const Color(0xFFE57373)
                      : AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const ReadyPlansLoading();
    }
    if (_hasError) {
      return ReadyPlansEmptyState(isError: true, onRetry: _loadDetails);
    }
    final plan = _plan;
    if (plan == null) {
      return ReadyPlansEmptyState(isError: true, onRetry: _loadDetails);
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        if (plan.description.isNotEmpty) ...[
          Text(
            plan.description,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 20),
        ],
        _buildWhyThisPlan(plan),
        const SizedBox(height: 18),
        _buildStats(plan),
        const SizedBox(height: 18),
        _buildFacts(plan),
        const SizedBox(height: 26),
        Text('Dias do plano', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ...plan.days.map(_buildDay),
      ],
    );
  }

  Widget _buildWhyThisPlan(ReadyPlanModel plan) {
    final reasons = _recommendationService.evaluate(plan, _memory).reasons;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Por que este plano?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        ...reasons.map(
          (reason) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reason,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(ReadyPlanModel plan) {
    final duration = plan.durationWeeks > 0
        ? '${plan.durationWeeks} semanas'
        : 'Não definida';
    final equipment = plan.allEquipment.take(4).join(', ');
    final groups = plan.primaryMuscleGroups.take(4).join(', ');
    final values = [
      'Total de dias: ${plan.days.length}',
      'Exercícios: ${plan.totalExercises}',
      'Média por dia: ${plan.averageExercisesPerDay.toStringAsFixed(1)}',
      'Duração: $duration',
      if (equipment.isNotEmpty) 'Equipamentos: $equipment',
      if (groups.isNotEmpty) 'Grupos principais: $groups',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        children: values
            .map(
              (item) =>
                  Text(item, style: Theme.of(context).textTheme.bodySmall),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFacts(ReadyPlanModel plan) {
    final values = [
      _Fact(Icons.flag_outlined, 'Objetivo', plan.goal),
      _Fact(Icons.workspace_premium_outlined, 'Nível', plan.level),
      _Fact(Icons.account_tree_outlined, 'Divisão', plan.split),
      _Fact(
        Icons.calendar_today_outlined,
        'Frequência',
        '${plan.daysPerWeek} dias/semana',
      ),
      _Fact(
        Icons.schedule_outlined,
        'Tempo médio',
        '${plan.estimatedMinutes} min',
      ),
      _Fact(Icons.location_on_outlined, 'Local', plan.location),
    ].where((item) => item.value.trim().isNotEmpty).toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values
          .map(
            (fact) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - 50) / 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: AppColors.outlineSoft),
                ),
                child: Row(
                  children: [
                    Icon(fact.icon, size: 17, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${fact.label}\n${fact.value}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDay(ReadyPlanDayModel day) {
    final title = day.title.isEmpty ? day.name : day.title;
    final subtitle = [
      day.weekday,
      day.muscleGroup,
      '${day.exercises.length} exercícios',
    ].where((value) => value.trim().isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.outlineSoft),
        ),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondary,
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: day.exercises.map(_buildExercise).toList(),
        ),
      ),
    );
  }

  Widget _buildExercise(ReadyPlanExerciseModel exercise) {
    final details = [
      if (exercise.sets > 0) '${exercise.sets} séries',
      if (exercise.reps.isNotEmpty) exercise.reps,
      if (exercise.restSeconds > 0) '${exercise.restSeconds}s descanso',
      if (exercise.rir.isNotEmpty) 'RIR ${exercise.rir}',
      if (exercise.cadence.isNotEmpty) 'Cadência ${exercise.cadence}',
      if (exercise.notes.isNotEmpty) exercise.notes,
    ].join(' · ');
    return ListTile(
      contentPadding: const EdgeInsets.only(top: 4, bottom: 4),
      title: Text(
        exercise.exerciseName,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: details.isEmpty ? null : Text(details),
      leading: CircleAvatar(
        radius: 13,
        backgroundColor: AppColors.primary.withAlpha(24),
        foregroundColor: AppColors.primary,
        child: Text(
          '${exercise.order}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _Fact {
  final IconData icon;
  final String label;
  final String value;

  const _Fact(this.icon, this.label, this.value);
}
