import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_button.dart';
import '../../../../design_system/components/fit_inputs.dart';
import '../../../../design_system/tokens/fit_spacing.dart';
import '../../data/auth_service.dart';
import '../auth_navigation.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_inline_message.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/auth_page_title.dart';
import '../widgets/auth_terms_consent.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.authService});

  final AuthService? authService;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _message;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final error = _validationError(name, email, password, confirmPassword);
    if (error != null) {
      setState(() => _message = error);
      return;
    }

    setState(() => _message = null);
    try {
      await (widget.authService ?? AuthService()).register(
        name: name,
        email: email,
        password: password,
      );
      if (!mounted) return;
      AuthNavigation.replaceWithApp(context);
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Object {
      if (mounted) {
        setState(() => _message = 'Nao foi possivel criar sua conta agora.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FitSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthBackButton(),
            const SizedBox(height: FitSpacing.s24),
            const AuthPageTitle(
              title: 'Crie sua conta.',
              subtitle: 'Vamos preparar uma experiencia feita para voce.',
            ),
            const SizedBox(height: FitSpacing.s32),
            FitTextField(
              controller: _nameController,
              label: 'Nome',
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.person_outline_rounded),
              onChanged: (_) => _clearMessage(),
            ),
            const SizedBox(height: FitSpacing.s16),
            FitTextField(
              controller: _emailController,
              label: 'E-mail',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
              onChanged: (_) => _clearMessage(),
            ),
            const SizedBox(height: FitSpacing.s16),
            FitPasswordField(
              controller: _passwordController,
              label: 'Senha',
              onChanged: (_) => _clearMessage(),
            ),
            const SizedBox(height: FitSpacing.s16),
            FitPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirmar senha',
              onChanged: (_) => _clearMessage(),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: FitSpacing.s12),
            AuthTermsConsent(
              value: _acceptedTerms,
              onChanged: (accepted) {
                setState(() {
                  _acceptedTerms = accepted;
                  _message = null;
                });
              },
            ),
            if (_message != null) ...[
              const SizedBox(height: FitSpacing.s12),
              AuthInlineMessage(message: _message!),
            ],
            const SizedBox(height: FitSpacing.s24),
            FitButton(
              label: 'Criar conta',
              expand: true,
              onPressedAsync: _submit,
            ),
            const SizedBox(height: FitSpacing.s20),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Ja possui uma conta?'),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: const Text('Entrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _validationError(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) {
    if (name.length < 2) return 'Informe seu nome completo.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Informe um e-mail valido.';
    }
    if (password.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';
    if (password != confirmPassword) return 'As senhas precisam ser iguais.';
    if (!_acceptedTerms) return 'Aceite os termos para criar sua conta.';
    return null;
  }

  void _clearMessage() {
    if (_message != null) setState(() => _message = null);
  }
}
