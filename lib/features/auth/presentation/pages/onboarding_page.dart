import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_button.dart';
import '../../../../design_system/tokens/fit_colors.dart';
import '../../../../design_system/tokens/fit_icons.dart';
import '../../../../design_system/tokens/fit_layout.dart';
import '../../../../design_system/tokens/fit_spacing.dart';
import '../../data/auth_service.dart';
import '../auth_navigation.dart';
import '../widgets/auth_inline_message.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/auth_page_title.dart';
import '../widgets/onboarding_progress.dart';
import 'login_page.dart';

/// Onboarding Core V1: quatro escolhas que afetam o primeiro plano.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.authService});

  final AuthService? authService;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _step = 0;
  bool _loading = true;
  String? _error;
  OnboardingDraft _draft = const OnboardingDraft();

  AuthService get _service => widget.authService ?? AuthService();

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    try {
      final draft = await _service.loadOnboardingDraft();
      if (mounted) {
        setState(() => _draft = draft);
      }
    } on Object {
      if (mounted) {
        setState(() => _error = 'Nao foi possivel restaurar suas respostas.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _next() async {
    final validation = _validationForCurrentStep();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() => _error = null);
    if (_step == 3) {
      try {
        await _service.completeOnboarding(_draft);
        if (!mounted) {
          return;
        }
        AuthNavigation.replaceAll(context, const LoginPage());
      } on Object {
        if (mounted) {
          setState(() => _error = 'Nao foi possivel salvar esta etapa.');
        }
      }
      return;
    }
    try {
      await _service.saveOnboardingDraft(_draft);
      if (mounted) {
        setState(() => _step += 1);
      }
    } on Object {
      if (mounted) {
        setState(() => _error = 'Nao foi possivel salvar esta etapa.');
      }
    }
  }

  String? _validationForCurrentStep() {
    if (_step == 0 && _draft.objective == null) {
      return 'Escolha um objetivo para continuar.';
    }
    if (_step == 1 && (_draft.experience == null || _draft.frequency == null)) {
      return 'Escolha sua experiencia e frequencia semanal.';
    }
    if (_step == 2 && _draft.location == null) {
      return 'Escolha onde voce treina.';
    }
    return null;
  }

  void _update(OnboardingDraft draft) => setState(() {
    _draft = draft;
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FitSpacing.s20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthLogo(compact: true),
                  const SizedBox(height: FitSpacing.s24),
                  OnboardingProgress(currentStep: _step, totalSteps: 4),
                  const SizedBox(height: FitSpacing.s32),
                  _stepContent(context),
                  if (_error != null) ...[
                    const SizedBox(height: FitSpacing.s16),
                    AuthInlineMessage(message: _error!),
                  ],
                  const SizedBox(height: FitSpacing.s40),
                  Row(
                    children: [
                      Expanded(
                        child: _step == 0
                            ? const SizedBox(height: 48)
                            : FitButton(
                                label: 'Voltar',
                                variant: FitButtonVariant.ghost,
                                expand: true,
                                onPressed: () => setState(() => _step -= 1),
                              ),
                      ),
                      const SizedBox(width: FitSpacing.s12),
                      Expanded(
                        child: FitButton(
                          label: _step == 3 ? 'Entrar no FitIA' : 'Proximo',
                          expand: true,
                          trailingIcon: Icons.arrow_forward_rounded,
                          onPressedAsync: _next,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _stepContent(BuildContext context) {
    return switch (_step) {
      0 => _ChoiceStep(
        title: 'Qual e seu objetivo principal?',
        subtitle: 'Usaremos esta escolha para priorizar seu primeiro plano.',
        options: const ['Hipertrofia', 'Emagrecimento', 'Forca', 'Saude'],
        selected: _draft.objective,
        onSelected: (value) => _update(_draft.copyWith(objective: value)),
      ),
      1 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthPageTitle(
            title: 'Como voce treina?',
            subtitle: 'A experiencia e a frequencia definem o ritmo inicial.',
          ),
          const SizedBox(height: FitSpacing.s20),
          _ChipChoices(
            label: 'Experiencia',
            options: const ['Iniciante', 'Intermediario', 'Avancado'],
            selected: _draft.experience,
            onSelected: (value) => _update(_draft.copyWith(experience: value)),
          ),
          const SizedBox(height: FitSpacing.s20),
          _ChipChoices(
            label: 'Dias por semana',
            options: const ['2', '3', '4', '5'],
            selected: _draft.frequency?.toString(),
            onSelected: (value) =>
                _update(_draft.copyWith(frequency: int.tryParse(value))),
          ),
        ],
      ),
      2 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChoiceStep(
            title: 'Onde voce treina?',
            subtitle: 'Mostraremos exercicios compativeis com sua rotina.',
            options: const ['Academia', 'Casa', 'Ar livre'],
            selected: _draft.location,
            onSelected: (value) => _update(_draft.copyWith(location: value)),
          ),
          const SizedBox(height: FitSpacing.s20),
          _ChipChoices(
            label: 'Equipamentos (opcional)',
            options: const ['Barra', 'Halteres', 'Maquinas', 'Nenhum'],
            selectedMany: _draft.equipment.toSet(),
            onSelectedMany: (value) => _update(
              _draft.copyWith(equipment: value.toList(growable: false)),
            ),
          ),
        ],
      ),
      _ => _OnboardingReview(draft: _draft),
    };
  }
}

class _ChoiceStep extends StatelessWidget {
  const _ChoiceStep({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AuthPageTitle(title: title, subtitle: subtitle),
      const SizedBox(height: FitSpacing.s20),
      for (final option in options) ...[
        Semantics(
          selected: selected == option,
          button: true,
          label: option,
          onTap: () => onSelected(option),
          child: SizedBox(
            width: double.infinity,
            height: FitLayout.buttonHeightLarge,
            child: ExcludeSemantics(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  backgroundColor: selected == option
                      ? FitColors.primaryContainer
                      : FitColors.surface,
                  foregroundColor: selected == option
                      ? FitColors.primary
                      : FitColors.textPrimary,
                  side: BorderSide(
                    color: selected == option
                        ? FitColors.primary
                        : FitColors.borderSubtle,
                  ),
                ),
                onPressed: () => onSelected(option),
                child: Row(
                  children: [
                    Icon(
                      _iconForOption(option),
                      size: FitLayout.iconSizeButton,
                    ),
                    const SizedBox(width: FitSpacing.s12),
                    Expanded(child: Text(option)),
                    if (selected == option)
                      const Icon(
                        FitIcons.check,
                        size: FitLayout.iconSizeButton,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: FitSpacing.s12),
      ],
    ],
  );

  IconData _iconForOption(String option) => switch (option) {
    'Hipertrofia' || 'Forca' => FitIcons.workout,
    'Emagrecimento' => FitIcons.progress,
    'Saude' => FitIcons.heart,
    'Academia' => FitIcons.equipment,
    'Casa' => FitIcons.homeOutlined,
    'Ar livre' => FitIcons.activitiesOutlined,
    _ => FitIcons.goal,
  };
}

class _ChipChoices extends StatelessWidget {
  const _ChipChoices({
    required this.label,
    required this.options,
    this.selected,
    this.selectedMany,
    this.onSelected,
    this.onSelectedMany,
  });

  final String label;
  final List<String> options;
  final String? selected;
  final Set<String>? selectedMany;
  final ValueChanged<String>? onSelected;
  final ValueChanged<Set<String>>? onSelectedMany;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: FitSpacing.s8),
      Wrap(
        spacing: FitSpacing.s8,
        runSpacing: FitSpacing.s8,
        children: [
          for (final option in options)
            SizedBox(
              height: FitLayout.minimumTouchTarget,
              child: ChoiceChip(
                label: Text(option),
                selected:
                    selected == option ||
                    (selectedMany?.contains(option) ?? false),
                onSelected: (_) {
                  final many = selectedMany;
                  if (many == null) {
                    onSelected?.call(option);
                    return;
                  }
                  final updated = {...many};
                  if (!updated.add(option)) updated.remove(option);
                  onSelectedMany?.call(updated);
                },
              ),
            ),
        ],
      ),
    ],
  );
}

class _OnboardingReview extends StatelessWidget {
  const _OnboardingReview({required this.draft});

  final OnboardingDraft draft;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const AuthPageTitle(
        title: 'Seu ponto de partida.',
        subtitle: 'Voce podera ajustar tudo depois nas configuracoes.',
      ),
      const SizedBox(height: FitSpacing.s24),
      _ReviewRow(label: 'Objetivo', value: draft.objective ?? '-'),
      _ReviewRow(label: 'Experiencia', value: draft.experience ?? '-'),
      _ReviewRow(
        label: 'Frequencia',
        value: '${draft.frequency ?? '-'} dias/semana',
      ),
      _ReviewRow(label: 'Local', value: draft.location ?? '-'),
      _ReviewRow(
        label: 'Equipamentos',
        value: draft.equipment.isEmpty
            ? 'Nao informado'
            : draft.equipment.join(', '),
      ),
    ],
  );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: FitSpacing.s12),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}
