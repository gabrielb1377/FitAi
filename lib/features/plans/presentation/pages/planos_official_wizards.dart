import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../design_system/fit_design_system.dart';
import '../../../../screens/ai_workout_page.dart';
import '../../../../screens/treinos/official/official_plan_editor_page.dart';
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

/// PLAN-006. Inicio do fluxo manual.
class PlanosManualGoalPage extends StatefulWidget {
  const PlanosManualGoalPage({super.key});

  @override
  State<PlanosManualGoalPage> createState() => _PlanosManualGoalPageState();
}

class _PlanosManualGoalPageState extends State<PlanosManualGoalPage> {
  var _goal = 'Hipertrofia';

  @override
  Widget build(BuildContext context) {
    return PlanosOfficialPage(
      title: 'Qual o objetivo principal?',
      subtitle: 'Escolha o foco do seu plano',
      onBack: () => Navigator.of(context).maybePop(),
      bottomAction: FitPrimaryButton(
        label: 'Continuar',
        fullWidth: true,
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => PlanosStructurePage(goal: _goal)),
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

/// PLAN-007. Definicao da estrutura de treino.
class PlanosStructurePage extends StatefulWidget {
  const PlanosStructurePage({super.key, required this.goal});

  final String goal;

  @override
  State<PlanosStructurePage> createState() => _PlanosStructurePageState();
}

class _PlanosStructurePageState extends State<PlanosStructurePage> {
  var _structure = 'Upper / Lower';

  @override
  Widget build(BuildContext context) {
    return PlanosOfficialPage(
      title: 'Estrutura do plano',
      subtitle: 'Defina como sera seu treino',
      onBack: () => Navigator.of(context).maybePop(),
      bottomAction: FitPrimaryButton(
        label: 'Continuar',
        fullWidth: true,
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => PlanosBuildWorkoutsPage(
              goal: widget.goal,
              structure: _structure,
            ),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          const FitStepProgress(currentStep: 2, totalSteps: 4),
          const SizedBox(height: FitSpacing.s24),
          _configSummary(
            'Nivel de experiencia',
            'Intermediario',
            FitIcons.progress,
          ),
          _configSummary('Dias por semana', '4 dias', FitIcons.calendar),
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
  }

  Widget _configSummary(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FitSpacing.s8),
      child: FitCard(
        padding: const EdgeInsets.all(FitSpacing.s12),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: FitSpacing.s12),
            Expanded(child: Text(title)),
            Text(value, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

/// PLAN-008. Lista dos treinos que compoem a rotina manual.
class PlanosBuildWorkoutsPage extends StatelessWidget {
  const PlanosBuildWorkoutsPage({
    super.key,
    required this.goal,
    required this.structure,
  });

  final String goal;
  final String structure;

  @override
  Widget build(BuildContext context) {
    final days = const [
      ('Segunda', 'Upper A'),
      ('Terca', 'Lower A'),
      ('Quinta', 'Upper B'),
      ('Sexta', 'Lower B'),
    ];
    return PlanosOfficialPage(
      title: 'Seus treinos',
      subtitle: 'Organize e adicione os treinos',
      onBack: () => Navigator.of(context).maybePop(),
      bottomAction: FitPrimaryButton(
        label: 'Continuar',
        fullWidth: true,
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => PlanosEditWorkoutPage(
              goal: goal,
              structure: structure,
              title: days.first.$2,
            ),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          const FitStepProgress(currentStep: 3, totalSteps: 4),
          const SizedBox(height: FitSpacing.s24),
          for (final day in days) ...[
            FitCard(
              variant: FitCardVariant.clickable,
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => PlanosEditWorkoutPage(
                    goal: goal,
                    structure: structure,
                    title: day.$2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(FitIcons.workout),
                  const SizedBox(width: FitSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${day.$1} - ${day.$2}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Text('5 exercicios'),
                      ],
                    ),
                  ),
                  const Icon(FitIcons.forward),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s8),
          ],
          FitOutlinedCard(
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const OfficialPlanEditorPage()),
            ),
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
  }
}

/// PLAN-009. Editor de um treino manual antes da revisao.
class PlanosEditWorkoutPage extends StatelessWidget {
  const PlanosEditWorkoutPage({
    super.key,
    required this.goal,
    required this.structure,
    required this.title,
  });

  final String goal;
  final String structure;
  final String title;

  @override
  Widget build(BuildContext context) {
    const exercises = [
      'Supino reto',
      'Remada curvada',
      'Desenvolvimento com halteres',
      'Elevacao lateral',
      'Triceps testa',
    ];
    return PlanosOfficialPage(
      title: 'Editar treino',
      subtitle: title,
      onBack: () => Navigator.of(context).maybePop(),
      bottomAction: FitPrimaryButton(
        label: 'Continuar',
        fullWidth: true,
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => PlanosReviewPage(goal: goal, structure: structure),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          for (var index = 0; index < exercises.length; index++) ...[
            FitCard(
              child: Row(
                children: [
                  Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
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
                          exercises[index],
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Text('4 series  |  8-12 reps  |  60s'),
                      ],
                    ),
                  ),
                  const Icon(Icons.drag_handle_rounded),
                ],
              ),
            ),
            const SizedBox(height: FitSpacing.s8),
          ],
          FitOutlinedCard(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FitIcons.add),
                SizedBox(width: FitSpacing.s8),
                Text('Adicionar exercicio'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// PLAN-010. Revisao do fluxo manual, sem persistir dados inventados.
class PlanosReviewPage extends StatelessWidget {
  const PlanosReviewPage({
    super.key,
    required this.goal,
    required this.structure,
  });

  final String goal;
  final String structure;

  @override
  Widget build(BuildContext context) {
    return PlanosOfficialPage(
      title: 'Revisao do plano',
      onBack: () => Navigator.of(context).maybePop(),
      bottomAction: FitPrimaryButton(
        label: 'Continuar',
        fullWidth: true,
        onPressed: () => _openPersistedEditor(context),
      ),
      child: ListView(
        padding: const EdgeInsets.all(FitSpacing.s16),
        children: [
          const PlanosPlanMedia(label: 'Capa do plano manual'),
          const SizedBox(height: FitSpacing.s16),
          Text(structure, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: FitSpacing.s8),
          FitChip(label: goal, selected: true),
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
                value: '20',
                icon: FitIcons.exercise,
              ),
              PlanosMetricData(
                label: 'Semanas',
                value: '8',
                icon: FitIcons.calendar,
              ),
            ],
          ),
          const SizedBox(height: FitSpacing.s16),
          _ReviewRow(title: 'Divisao do treino', value: structure),
          _ReviewRow(title: 'Nivel', value: 'Intermediario'),
          _ReviewRow(title: 'Equipamentos', value: 'Todos'),
          _ReviewRow(title: 'Duracao media do treino', value: '60 min'),
        ],
      ),
    );
  }

  Future<void> _openPersistedEditor(BuildContext context) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const OfficialPlanEditorPage()),
    );
    if (!context.mounted || created != true) return;
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const PlanosCreatedPage()));
  }
}

/// PLAN-011. Confirmacao visual do fluxo manual.
class PlanosCreatedPage extends StatelessWidget {
  const PlanosCreatedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PlanosOfficialPage(
      title: 'Parabens!',
      subtitle: 'Seu plano foi criado com sucesso!',
      onBack: () => Navigator.of(context).maybePop(),
      bottomAction: FitPrimaryButton(
        label: 'Ir para meus planos',
        fullWidth: true,
        onPressed: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
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
              const FitCard(
                child: Column(
                  children: [
                    _ReviewRow(title: 'Nome do plano', value: 'Upper / Lower'),
                    _ReviewRow(title: 'Objetivo', value: 'Hipertrofia'),
                    _ReviewRow(title: 'Duracao', value: '8 semanas'),
                    _ReviewRow(title: 'Dias por semana', value: '4 dias'),
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
