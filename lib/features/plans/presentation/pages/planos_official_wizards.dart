import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../models/exercicio_model.dart';
import '../../../../models/treino_model.dart';
import '../../../../screens/ai_workout_page.dart';
import '../../../../screens/exercicios/biblioteca/biblioteca_exercicios_page.dart';
import '../../../../screens/treinos/official/official_plan_editor_page.dart';
import '../../domain/manual_plan_draft.dart';
import 'planos_official_library_page.dart';
import '../widgets/planos_official_primitives.dart';

/// Ponto de entrada nomeado para a criação de planos.
///
/// Mantém a escolha explícita entre IA, criação manual e planos prontos sem
/// redirecionar para os fluxos legados de musculação.
class PlanosCreateChoicePage extends StatelessWidget {
  const PlanosCreateChoicePage({super.key});

  @override
  Widget build(BuildContext context) => PlanosOfficialPage(
    title: 'Criar plano',
    subtitle: 'Escolha como deseja começar',
    onBack: () => Navigator.of(context).maybePop(),
    child: ListView(
      padding: const EdgeInsets.all(FitSpacing.s16),
      children: [
        _option(
          context,
          title: 'Criar com IA',
          description: 'Responda poucas perguntas e receba uma sugestão.',
          icon: FitIcons.ai,
          destination: const PlanosAiGoalPage(),
        ),
        const SizedBox(height: FitSpacing.s12),
        _option(
          context,
          title: 'Criar manualmente',
          description: 'Monte sua ficha com a estrutura que preferir.',
          icon: FitIcons.edit,
          destination: const PlanosManualGoalPage(),
        ),
        const SizedBox(height: FitSpacing.s12),
        _option(
          context,
          title: 'Explorar planos prontos',
          description: 'Comece a partir de um plano disponível.',
          icon: FitIcons.library,
          destination: const PlanosReadyLibraryPage(),
        ),
      ],
    ),
  );

  Widget _option(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Widget destination,
  }) => FitCard(
    variant: FitCardVariant.clickable,
    onTap: () => Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => destination)),
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: FitSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: FitSpacing.s4),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const Icon(FitIcons.forward),
      ],
    ),
  );
}

/// PLAN-002. Primeiro passo do assistente de plano com IA.
class PlanosAiGoalPage extends StatefulWidget {
  const PlanosAiGoalPage({super.key});

  @override
  State<PlanosAiGoalPage> createState() => _PlanosAiGoalPageState();
}

class _PlanosAiGoalPageState extends State<PlanosAiGoalPage> {
  var _goal = 'Hipertrofia';

  @override
  Widget build(BuildContext context) {
    return PlanosOfficialPage(
      title: 'Qual o seu objetivo principal?',
      subtitle: 'Escolha o foco do seu plano',
      onBack: () => Navigator.of(context).maybePop(),
      bottomAction: FitPrimaryButton(
        label: 'Continuar',
        fullWidth: true,
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => PlanosAiPersonalizationPage(goal: _goal),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          const FitStepProgress(currentStep: 1, totalSteps: 4),
          const SizedBox(height: FitSpacing.s24),
          for (final option in _goals) ...[
            PlanosChoiceTile(
              title: option.title,
              description: option.description,
              icon: option.icon,
              selected: _goal == option.title,
              onTap: () => setState(() => _goal = option.title),
            ),
            const SizedBox(height: FitSpacing.s8),
          ],
        ],
      ),
    );
  }
}

/// PLAN-003. Personalizacao exibida antes do gerador real continuar o fluxo.
class PlanosAiPersonalizationPage extends StatefulWidget {
  const PlanosAiPersonalizationPage({super.key, required this.goal});

  final String goal;

  @override
  State<PlanosAiPersonalizationPage> createState() =>
      _PlanosAiPersonalizationPageState();
}

class _PlanosAiPersonalizationPageState
    extends State<PlanosAiPersonalizationPage> {
  var _days = 4;
  var _duration = 60;

  @override
  Widget build(BuildContext context) {
    return PlanosOfficialPage(
      title: 'Personalize seu plano',
      subtitle: 'Para a IA criar o melhor plano para voce',
      onBack: () => Navigator.of(context).maybePop(),
      bottomAction: FitPrimaryButton(
        label: 'Gerar meu plano',
        icon: FitIcons.ai,
        fullWidth: true,
        onPressed: _openGenerator,
      ),
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          const FitStepProgress(currentStep: 2, totalSteps: 4),
          const SizedBox(height: FitSpacing.s24),
          _setting(
            'Dias por semana de treino',
            '$_days dias',
            FitIcons.calendar,
            _pickDays,
          ),
          const SizedBox(height: FitSpacing.s8),
          _setting('Local de treino', 'Academia', FitIcons.workout, () {}),
          const SizedBox(height: FitSpacing.s8),
          _setting(
            'Equipamentos disponiveis',
            'Todos',
            FitIcons.equipment,
            () {},
          ),
          const SizedBox(height: FitSpacing.s8),
          _setting(
            'Duracao media do treino',
            '$_duration min',
            FitIcons.time,
            _pickDuration,
          ),
          const SizedBox(height: FitSpacing.s8),
          _setting(
            'Nivel de experiencia',
            'Intermediario',
            FitIcons.progress,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _setting(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return FitCard(
      variant: FitCardVariant.clickable,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          Text(value, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(width: FitSpacing.s8),
          const Icon(FitIcons.forward),
        ],
      ),
    );
  }

  Future<void> _pickDays() async {
    final selected = await _pickValue('Dias por semana', const [
      3,
      4,
      5,
      6,
    ], _days);
    if (selected != null && mounted) setState(() => _days = selected);
  }

  Future<void> _pickDuration() async {
    final selected = await _pickValue('Duracao do treino', const [
      45,
      60,
      75,
      90,
    ], _duration);
    if (selected != null && mounted) setState(() => _duration = selected);
  }

  Future<int?> _pickValue(String title, List<int> values, int selected) {
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(FitSpacing.s16),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final value in values)
              ListTile(
                title: Text(
                  '$value ${title.startsWith('Duracao') ? 'min' : 'dias'}',
                ),
                trailing: value == selected ? const Icon(FitIcons.check) : null,
                onTap: () => Navigator.of(context).pop(value),
              ),
          ],
        ),
      ),
    );
  }

  void _openGenerator() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PlanosAiGeneratingPage(
          goal: widget.goal,
          days: _days,
          duration: _duration,
        ),
      ),
    );
  }
}

/// PLAN-004. Estado de geracao que encaminha para o fluxo real existente.
class PlanosAiGeneratingPage extends StatefulWidget {
  const PlanosAiGeneratingPage({
    super.key,
    required this.goal,
    required this.days,
    required this.duration,
  });

  final String goal;
  final int days;
  final int duration;

  @override
  State<PlanosAiGeneratingPage> createState() => _PlanosAiGeneratingPageState();
}

class _PlanosAiGeneratingPageState extends State<PlanosAiGeneratingPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_continueToRealGenerator());
  }

  Future<void> _continueToRealGenerator() async {
    await Future<void>.delayed(FitDuration.normal);
    if (!mounted) return;
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AIWorkoutPage()));
    if (!mounted) return;
    if (created == true) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const PlanosAiReadyPage()),
      );
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return PlanosOfficialPage(
      title: 'Gerando seu plano ideal...',
      subtitle: 'Isso pode levar alguns segundos',
      onBack: () => Navigator.of(context).maybePop(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(FitSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: FitLayout.domainProgressRingLarge,
                height: FitLayout.domainProgressRingLarge,
                decoration: const BoxDecoration(
                  gradient: FitGradients.aiGlow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(FitIcons.ai, size: FitLayout.iconSizeState),
              ),
              const SizedBox(height: FitSpacing.s32),
              const FitLoading.inline(label: 'Analisando seu perfil'),
              const SizedBox(height: FitSpacing.s24),
              const _GeneratorChecklist(),
            ],
          ),
        ),
      ),
    );
  }
}

/// PLAN-005. Resumo visual pos-geracao; o plano real segue pelo fluxo de IA.
class PlanosAiReadyPage extends StatelessWidget {
  const PlanosAiReadyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PlanosOfficialPage(
      title: 'Seu plano esta pronto!',
      subtitle: 'Criamos uma rotina para voce',
      onBack: () => Navigator.of(context).maybePop(),
      bottomAction: FitPrimaryButton(
        label: 'Ver meu plano',
        fullWidth: true,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          const FitStepProgress(currentStep: 4, totalSteps: 4),
          const SizedBox(height: FitSpacing.s24),
          const PlanosPlanMedia(label: 'Capa do plano Upper Lower'),
          const SizedBox(height: FitSpacing.s16),
          Text(
            'Upper / Lower',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: FitSpacing.s8),
          const FitChip(label: 'Hipertrofia', selected: true),
          const SizedBox(height: FitSpacing.s16),
          const PlanosMetricRow(
            metrics: [
              PlanosMetricData(
                label: 'Treinos',
                value: '4',
                icon: FitIcons.workout,
              ),
              PlanosMetricData(
                label: 'Exercicios',
                value: '24',
                icon: FitIcons.exercise,
              ),
              PlanosMetricData(
                label: 'Semanas',
                value: '8',
                icon: FitIcons.calendar,
              ),
              PlanosMetricData(
                label: 'Intensidade',
                value: 'Alta',
                icon: FitIcons.progress,
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s16),
          const _PlanAiSummary(),
        ],
      ),
    );
  }
}

/// PLAN-006. Inicio do fluxo manual com um rascunho ainda não persistido.
class PlanosManualGoalPage extends StatefulWidget {
  const PlanosManualGoalPage({super.key});

  @override
  State<PlanosManualGoalPage> createState() => _PlanosManualGoalPageState();
}

class _PlanosManualGoalPageState extends State<PlanosManualGoalPage> {
  var _goal = 'Hipertrofia';

  @override
  Widget build(BuildContext context) => PlanosOfficialPage(
    title: 'Qual o objetivo principal?',
    subtitle: 'Escolha o foco do seu plano',
    onBack: () => Navigator.of(context).maybePop(),
    bottomAction: FitPrimaryButton(
      label: 'Continuar',
      fullWidth: true,
      onPressed: _openStructure,
    ),
    child: ListView(
      padding: const EdgeInsets.all(FitSpacing.s16),
      children: [
        const FitStepProgress(currentStep: 1, totalSteps: 4),
        const SizedBox(height: FitSpacing.s24),
        for (final option in _goals) ...[
          PlanosChoiceTile(
            title: option.title,
            description: option.description,
            icon: option.icon,
            selected: _goal == option.title,
            onTap: () => setState(() => _goal = option.title),
          ),
          const SizedBox(height: FitSpacing.s8),
        ],
      ],
    ),
  );

  void _openStructure() {
    final draft = ManualPlanDraft(
      id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
      goal: _goal,
    );
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => PlanosStructurePage(draft: draft)),
    );
  }
}

/// PLAN-007. A escolha de estrutura passa a compor o mesmo rascunho.
class PlanosStructurePage extends StatefulWidget {
  const PlanosStructurePage({super.key, required this.draft});

  final ManualPlanDraft draft;

  @override
  State<PlanosStructurePage> createState() => _PlanosStructurePageState();
}

class _PlanosStructurePageState extends State<PlanosStructurePage> {
  late String _structure = widget.draft.structure;

  @override
  Widget build(BuildContext context) => PlanosOfficialPage(
    title: 'Estrutura do plano',
    subtitle: 'Defina como será seu treino',
    onBack: () => Navigator.of(context).maybePop(),
    bottomAction: FitPrimaryButton(
      label: 'Continuar',
      fullWidth: true,
      onPressed: _openWorkouts,
    ),
    child: ListView(
      padding: const EdgeInsets.all(FitSpacing.s16),
      children: [
        const FitStepProgress(currentStep: 2, totalSteps: 4),
        const SizedBox(height: FitSpacing.s24),
        _selectionSummary('Objetivo', widget.draft.goal, FitIcons.goal),
        const SizedBox(height: FitSpacing.s16),
        for (final option in _structures) ...[
          PlanosChoiceTile(
            title: option.title,
            description: option.description,
            icon: option.icon,
            selected: _structure == option.title,
            onTap: () => setState(() => _structure = option.title),
          ),
          const SizedBox(height: FitSpacing.s8),
        ],
      ],
    ),
  );

  Widget _selectionSummary(String title, String value, IconData icon) =>
      FitCard(
        padding: const EdgeInsets.all(FitSpacing.s12),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: FitSpacing.s12),
            Expanded(child: Text(title)),
            Text(value, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      );

  void _openWorkouts() {
    widget.draft.structure = _structure;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PlanosBuildWorkoutsPage(draft: widget.draft),
      ),
    );
  }
}

/// PLAN-008. Os treinos são criados pelo usuário e não por uma lista exemplo.
class PlanosBuildWorkoutsPage extends StatefulWidget {
  const PlanosBuildWorkoutsPage({super.key, required this.draft});

  final ManualPlanDraft draft;

  @override
  State<PlanosBuildWorkoutsPage> createState() =>
      _PlanosBuildWorkoutsPageState();
}

class _PlanosBuildWorkoutsPageState extends State<PlanosBuildWorkoutsPage> {
  @override
  Widget build(BuildContext context) => PlanosOfficialPage(
    title: 'Seus treinos',
    subtitle: 'Adicione exercícios do catálogo e configure a prescrição',
    onBack: () => Navigator.of(context).maybePop(),
    bottomAction: FitPrimaryButton(
      label: 'Continuar',
      fullWidth: true,
      onPressed: _openReview,
    ),
    child: ListView(
      padding: const EdgeInsets.all(FitSpacing.s16),
      children: [
        const FitStepProgress(currentStep: 3, totalSteps: 4),
        const SizedBox(height: FitSpacing.s24),
        for (final day in widget.draft.days) ...[
          FitCard(
            variant: FitCardVariant.clickable,
            onTap: () => _editDay(day),
            child: Row(
              children: [
                const Icon(FitIcons.workout),
                const SizedBox(width: FitSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('${day.exercises.length} exercícios configurados'),
                    ],
                  ),
                ),
                if (widget.draft.days.length > 1)
                  IconButton(
                    tooltip: 'Remover treino',
                    onPressed: () =>
                        setState(() => widget.draft.removeDay(day.id)),
                    icon: const Icon(FitIcons.close),
                  )
                else
                  const Icon(FitIcons.forward),
              ],
            ),
          ),
          const SizedBox(height: FitSpacing.s8),
        ],
        FitOutlinedCard(
          onTap: () => setState(widget.draft.addDay),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FitIcons.add),
              SizedBox(width: FitSpacing.s8),
              Text('Adicionar treino'),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _editDay(ManualPlanDraftDay day) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            PlanosEditWorkoutPage(draft: widget.draft, dayId: day.id),
      ),
    );
    if (mounted) setState(() {});
  }

  void _openReview() {
    final error = widget.draft.validate();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => PlanosReviewPage(draft: widget.draft)),
    );
  }
}

/// PLAN-009. Seleciona exercícios reais da Biblioteca e persiste prescrição no draft.
class PlanosEditWorkoutPage extends StatefulWidget {
  const PlanosEditWorkoutPage({
    super.key,
    required this.draft,
    required this.dayId,
  });

  final ManualPlanDraft draft;
  final String dayId;

  @override
  State<PlanosEditWorkoutPage> createState() => _PlanosEditWorkoutPageState();
}

class _PlanosEditWorkoutPageState extends State<PlanosEditWorkoutPage> {
  ManualPlanDraftDay get _day => widget.draft.dayById(widget.dayId)!;

  @override
  Widget build(BuildContext context) => PlanosOfficialPage(
    title: 'Editar treino',
    subtitle: _day.title,
    onBack: () => Navigator.of(context).maybePop(),
    bottomAction: FitPrimaryButton(
      label: 'Concluir treino',
      fullWidth: true,
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    child: ListView(
      padding: const EdgeInsets.all(FitSpacing.s16),
      children: [
        if (_day.exercises.isEmpty)
          const FitEmptyStateCard(
            title: 'Nenhum exercício selecionado',
            description:
                'Adicione exercícios reais da Biblioteca para continuar.',
          )
        else
          for (var index = 0; index < _day.exercises.length; index++) ...[
            _exerciseCard(_day.exercises[index], index),
            const SizedBox(height: FitSpacing.s8),
          ],
        FitOutlinedCard(
          onTap: _openCatalog,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FitIcons.add),
              SizedBox(width: FitSpacing.s8),
              Text('Adicionar exercício'),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _exerciseCard(ExercicioModel exercise, int index) {
    final configured =
        exercise.series > 0 &&
        exercise.repeticoes.trim().isNotEmpty &&
        exercise.descansoSegundos > 0;
    return FitCard(
      child: Row(
        children: [
          Text('${index + 1}', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(width: FitSpacing.s12),
          const SizedBox.square(
            dimension: FitLayout.domainThumbnailSmall,
            child: PlanosPlanMedia(
              compact: true,
              height: FitLayout.domainThumbnailSmall,
            ),
          ),
          const SizedBox(width: FitSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.nome,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  configured
                      ? '${exercise.series} séries | ${exercise.repeticoes} reps | ${exercise.descansoSegundos}s'
                      : 'Prescrição pendente',
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Configurar prescrição',
            onPressed: () => _configure(exercise),
            icon: const Icon(FitIcons.edit),
          ),
          IconButton(
            tooltip: 'Remover exercício',
            onPressed: () => setState(
              () => widget.draft.removeExercise(
                dayId: widget.dayId,
                exerciseId: exercise.id,
              ),
            ),
            icon: const Icon(FitIcons.close),
          ),
        ],
      ),
    );
  }

  Future<void> _openCatalog() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            BibliotecaExerciciosPage(onSelecionar: _addCatalogExercise),
      ),
    );
    if (mounted) setState(() {});
  }

  void _addCatalogExercise(ExercicioModel exercise) {
    final result = widget.draft.addExercise(
      dayId: widget.dayId,
      exercise: exercise,
    );
    final message = switch (result) {
      ManualPlanDraftSelectionResult.added => '${exercise.nome} adicionado.',
      ManualPlanDraftSelectionResult.duplicate =>
        '${exercise.nome} já está neste plano.',
      ManualPlanDraftSelectionResult.missingCatalogId =>
        'Este exercício não possui ID do catálogo.',
      ManualPlanDraftSelectionResult.dayNotFound => 'Treino indisponível.',
    };
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _configure(ExercicioModel exercise) async {
    final prescription =
        await FitBottomSheetContainer.show<_ManualExercisePrescription>(
          context: context,
          title: 'Prescrição',
          subtitle: exercise.nome,
          isScrollControlled: true,
          child: _ManualPrescriptionForm(exercise: exercise),
        );
    if (!mounted || prescription == null) return;
    setState(
      () => widget.draft.updatePrescription(
        dayId: widget.dayId,
        exerciseId: exercise.id,
        sets: prescription.sets,
        reps: prescription.reps,
        restSeconds: prescription.restSeconds,
      ),
    );
  }
}

class _ManualPrescriptionForm extends StatefulWidget {
  const _ManualPrescriptionForm({required this.exercise});

  final ExercicioModel exercise;

  @override
  State<_ManualPrescriptionForm> createState() =>
      _ManualPrescriptionFormState();
}

class _ManualPrescriptionFormState extends State<_ManualPrescriptionForm> {
  late final TextEditingController _sets;
  late final TextEditingController _reps;
  late final TextEditingController _rest;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sets = TextEditingController(
      text: widget.exercise.series > 0 ? '${widget.exercise.series}' : '',
    );
    _reps = TextEditingController(text: widget.exercise.repeticoes);
    _rest = TextEditingController(
      text: widget.exercise.descansoSegundos > 0
          ? '${widget.exercise.descansoSegundos}'
          : '',
    );
  }

  @override
  void dispose() {
    _sets.dispose();
    _reps.dispose();
    _rest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(FitSpacing.s16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _sets,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Séries'),
        ),
        const SizedBox(height: FitSpacing.s12),
        TextField(
          controller: _reps,
          decoration: const InputDecoration(labelText: 'Repetições'),
        ),
        const SizedBox(height: FitSpacing.s12),
        TextField(
          controller: _rest,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Descanso (segundos)'),
        ),
        if (_error != null) ...[
          const SizedBox(height: FitSpacing.s8),
          Text(_error!, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: FitSpacing.s16),
        FitPrimaryButton(
          label: 'Salvar prescrição',
          fullWidth: true,
          onPressed: _submit,
        ),
      ],
    ),
  );

  void _submit() {
    final sets = int.tryParse(_sets.text.trim());
    final rest = int.tryParse(_rest.text.trim());
    final reps = _reps.text.trim();
    if (sets == null ||
        sets <= 0 ||
        rest == null ||
        rest <= 0 ||
        reps.isEmpty) {
      setState(() => _error = 'Informe séries, repetições e descanso válidos.');
      return;
    }
    Navigator.of(context).pop(
      _ManualExercisePrescription(sets: sets, reps: reps, restSeconds: rest),
    );
  }
}

class _ManualExercisePrescription {
  const _ManualExercisePrescription({
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  final int sets;
  final String reps;
  final int restSeconds;
}

/// PLAN-010. A revisão usa apenas dados já presentes no rascunho.
class PlanosReviewPage extends StatelessWidget {
  const PlanosReviewPage({super.key, required this.draft});

  final ManualPlanDraft draft;

  @override
  Widget build(BuildContext context) => PlanosOfficialPage(
    title: 'Revisão do plano',
    onBack: () => Navigator.of(context).maybePop(),
    bottomAction: FitPrimaryButton(
      label: 'Salvar plano',
      fullWidth: true,
      onPressed: () => _openPersistedEditor(context),
    ),
    child: ListView(
      padding: const EdgeInsets.all(FitSpacing.s16),
      children: [
        const PlanosPlanMedia(label: 'Capa do plano manual'),
        const SizedBox(height: FitSpacing.s16),
        Text(draft.structure, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: FitSpacing.s8),
        FitChip(label: draft.goal, selected: true),
        const SizedBox(height: FitSpacing.s16),
        PlanosMetricRow(
          metrics: [
            PlanosMetricData(
              label: 'Treinos',
              value: '${draft.days.length}',
              icon: FitIcons.workout,
            ),
            PlanosMetricData(
              label: 'Exercícios',
              value: '${draft.exerciseCount}',
              icon: FitIcons.exercise,
            ),
            PlanosMetricData(
              label: 'Duração',
              value: '${draft.estimatedMinutes} min',
              icon: FitIcons.time,
            ),
          ],
        ),
        const SizedBox(height: FitSpacing.s16),
        _ReviewRow(title: 'Divisão do treino', value: draft.structure),
        _ReviewRow(title: 'Objetivo', value: draft.goal),
        _ReviewRow(title: 'Dias por semana', value: '${draft.days.length}'),
        for (final day in draft.days)
          _ReviewRow(
            title: day.title,
            value: '${day.exercises.length} exercícios',
          ),
      ],
    ),
  );

  Future<void> _openPersistedEditor(BuildContext context) async {
    final error = draft.validate();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    TreinoModel? savedPlan;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OfficialPlanEditorPage(
          initialPlan: draft.toEditorPlan(),
          saveAsNew: true,
          onSaved: (plan) => savedPlan = plan,
        ),
      ),
    );
    if (!context.mounted || created != true || savedPlan == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => PlanosCreatedPage(plan: savedPlan!)),
    );
  }
}

/// PLAN-011. Confirma apenas a entidade realmente persistida.
class PlanosCreatedPage extends StatelessWidget {
  const PlanosCreatedPage({super.key, required this.plan});

  final TreinoModel plan;

  @override
  Widget build(BuildContext context) => PlanosOfficialPage(
    title: 'Parabéns!',
    subtitle: 'Seu plano foi criado com sucesso!',
    onBack: () => Navigator.of(context).maybePop(),
    bottomAction: FitPrimaryButton(
      label: 'Ir para meus planos',
      fullWidth: true,
      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
    ),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(FitSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              FitIcons.success,
              size: FitLayout.domainProgressRingLarge,
            ),
            const SizedBox(height: FitSpacing.s32),
            FitCard(
              child: Column(
                children: [
                  _ReviewRow(title: 'Nome do plano', value: plan.nome),
                  _ReviewRow(title: 'Objetivo', value: plan.objetivo),
                  _ReviewRow(
                    title: 'Dias por semana',
                    value: '${plan.planoDias.length}',
                  ),
                  _ReviewRow(
                    title: 'Exercícios',
                    value: '${plan.exercicios.length}',
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

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FitSpacing.s8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Flexible(
            child: Text(value, style: Theme.of(context).textTheme.labelMedium),
          ),
        ],
      ),
    );
  }
}

class _GeneratorChecklist extends StatelessWidget {
  const _GeneratorChecklist();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChecklistItem('Analisando seu perfil'),
        _ChecklistItem('Selecionando melhores exercicios'),
        _ChecklistItem('Montando treinos'),
        _ChecklistItem('Ajustando volumes e intensidades'),
        _ChecklistItem('Finalizando seu plano'),
      ],
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FitSpacing.s4),
      child: Row(
        children: [
          Icon(
            FitIcons.check,
            size: FitLayout.iconSizeSmall,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: FitSpacing.s8),
          Text(label),
        ],
      ),
    );
  }
}

class _PlanAiSummary extends StatelessWidget {
  const _PlanAiSummary();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ReviewRow(title: 'Progressao', value: 'Sobrecarga progressiva'),
        _ReviewRow(title: 'Foco principal', value: 'Ganho de massa muscular'),
        _ReviewRow(title: 'Equipamentos', value: 'Todos disponiveis'),
      ],
    );
  }
}

class _PlanOption {
  const _PlanOption(this.title, this.description, this.icon);

  final String title;
  final String description;
  final IconData icon;
}

const _goals = [
  _PlanOption('Hipertrofia', 'Ganho de massa muscular', FitIcons.workout),
  _PlanOption('Emagrecimento', 'Perda de gordura', FitIcons.progress),
  _PlanOption('Definicao', 'Definir e tonificar o corpo', FitIcons.goal),
  _PlanOption('Forca', 'Aumentar forca maxima', FitIcons.achievement),
  _PlanOption('Performance', 'Melhorar desempenho atletico', FitIcons.running),
];

const _structures = [
  _PlanOption('Upper / Lower', '4 dias por semana', FitIcons.workout),
  _PlanOption('Push / Pull / Legs', '6 dias por semana', FitIcons.progress),
  _PlanOption('Full Body', '3 dias por semana', FitIcons.exercise),
  _PlanOption('Personalizada', 'Montar do meu jeito', FitIcons.edit),
];
