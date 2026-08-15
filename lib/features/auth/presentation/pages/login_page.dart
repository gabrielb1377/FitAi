import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_button.dart';
import '../../../../design_system/components/fit_inputs.dart';
import '../../../../design_system/tokens/fit_spacing.dart';
import '../../data/auth_service.dart';
import '../auth_navigation.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_inline_message.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/auth_page_title.dart';
import 'password_recovery_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.authService, this.onAuthenticated});

  final AuthService? authService;
  final VoidCallback? onAuthenticated;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailError = _isEmail(email) ? null : 'Informe um e-mail valido.';
    final passwordError = password.isEmpty ? 'Informe sua senha.' : null;
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _message = null;
    });
    if (emailError != null || passwordError != null) return;

    try {
      await (widget.authService ?? AuthService()).login(
        email: email,
        password: password,
      );
      if (!mounted) return;
      final onAuthenticated = widget.onAuthenticated;
      if (onAuthenticated != null) {
        onAuthenticated();
        return;
      }
      AuthNavigation.replaceWithApp(context);
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Object {
      if (mounted) {
        setState(() => _message = 'Nao foi possivel entrar agora.');
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
            const Align(
              alignment: Alignment.centerLeft,
              child: AuthLogo(compact: true),
            ),
            const SizedBox(height: FitSpacing.s40),
            const AuthPageTitle(
              title: 'Bem-vindo de volta.',
              subtitle: 'Entre para continuar sua evolucao.',
              centered: false,
            ),
            const SizedBox(height: FitSpacing.s32),
            FitTextField(
              controller: _emailController,
              label: 'E-mail',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              errorText: _emailError,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
              onChanged: (_) => _clearFieldError(email: true),
            ),
            const SizedBox(height: FitSpacing.s16),
            FitPasswordField(
              controller: _passwordController,
              label: 'Senha',
              errorText: _passwordError,
              onChanged: (_) => _clearFieldError(password: true),
              onSubmitted: (_) => _submit(),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(alignment: Alignment.centerRight),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PasswordRecoveryPage(),
                  ),
                ),
                child: const Text(
                  'Esqueci minha senha',
                  textAlign: TextAlign.end,
                ),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: FitSpacing.s8),
              AuthInlineMessage(message: _message!),
            ],
            const SizedBox(height: FitSpacing.s24),
            FitButton(label: 'Entrar', expand: true, onPressedAsync: _submit),
            const SizedBox(height: FitSpacing.s20),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ainda nao tem uma conta?',
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text('Criar conta'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _clearFieldError({bool email = false, bool password = false}) {
    if ((email && _emailError == null) ||
        (password && _passwordError == null)) {
      return;
    }
    setState(() {
      if (email) _emailError = null;
      if (password) _passwordError = null;
    });
  }

  bool _isEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
}
