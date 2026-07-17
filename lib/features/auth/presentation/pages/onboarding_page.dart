import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_button.dart';
import '../../../../design_system/tokens/fit_spacing.dart';
import '../../data/auth_service.dart';
import '../auth_navigation.dart';
import '../widgets/auth_inline_message.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/auth_page_title.dart';
import '../widgets/onboarding_illustration.dart';
import '../widgets/onboarding_progress.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.authService});

  final AuthService? authService;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _steps = [
    _OnboardingContent(
      title: 'Seu treino, do seu jeito.',
      subtitle:
          'Planos personalizados com inteligencia artificial para a sua rotina.',
    ),
    _OnboardingContent(
      title: 'Tudo em um so lugar.',
      subtitle: 'Treinos, corridas, passos e evolucao organizados para voce.',
    ),
    _OnboardingContent(
      title: 'Comece sua evolucao hoje.',
      subtitle: 'Defina metas e deixe a FitIA cuidar dos proximos passos.',
    ),
  ];

  int _step = 0;
  String? _error;

  Future<void> _complete() async {
    setState(() => _error = null);
    try {
      await (widget.authService ?? AuthService()).completeOnboarding();
      if (!mounted) return;
      AuthNavigation.replaceAll(context, const LoginPage());
    } on Object {
      if (mounted) {
        setState(() => _error = 'Nao foi possivel salvar esta etapa.');
      }
    }
  }

  void _next() {
    if (_step == _steps.length - 1) {
      _complete();
      return;
    }
    setState(() => _step += 1);
  }

  @override
  Widget build(BuildContext context) {
    final content = _steps[_step];
    return AuthPageScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FitSpacing.s20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AuthLogo(compact: true),
                TextButton(onPressed: _complete, child: const Text('Pular')),
              ],
            ),
            const SizedBox(height: FitSpacing.s32),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: OnboardingIllustration(key: ValueKey(_step), step: _step),
            ),
            const SizedBox(height: FitSpacing.s24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: AuthPageTitle(
                key: ValueKey('title-$_step'),
                title: content.title,
                subtitle: content.subtitle,
              ),
            ),
            const SizedBox(height: FitSpacing.s24),
            OnboardingProgress(currentStep: _step),
            if (_error != null) ...[
              const SizedBox(height: FitSpacing.s16),
              AuthInlineMessage(message: _error!),
            ],
            const SizedBox(height: FitSpacing.s32),
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
                    label: _step == _steps.length - 1 ? 'Comecar' : 'Proximo',
                    expand: true,
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingContent {
  const _OnboardingContent({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}
