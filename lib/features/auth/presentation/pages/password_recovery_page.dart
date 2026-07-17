import 'package:flutter/material.dart';

import '../../../../design_system/components/fit_button.dart';
import '../../../../design_system/components/fit_inputs.dart';
import '../../../../design_system/tokens/fit_colors.dart';
import '../../../../design_system/tokens/fit_radius.dart';
import '../../../../design_system/tokens/fit_spacing.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_inline_message.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/auth_page_title.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final _emailController = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _message = 'Informe um e-mail valido.');
      return;
    }
    setState(() {
      _message =
          'A recuperacao de senha ainda nao esta disponivel neste ambiente.';
    });
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
            const SizedBox(height: FitSpacing.s32),
            Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: FitColors.primaryContainer,
                  borderRadius: FitRadius.xLargeBorder,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: FitColors.primary,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: FitSpacing.s32),
            const AuthPageTitle(
              title: 'Recupere sua senha.',
              subtitle:
                  'Quando este recurso estiver ativo, enviaremos um link seguro para seu e-mail.',
            ),
            const SizedBox(height: FitSpacing.s32),
            FitTextField(
              controller: _emailController,
              label: 'E-mail',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
              onSubmitted: (_) => _submit(),
              onChanged: (_) {
                if (_message != null) setState(() => _message = null);
              },
            ),
            if (_message != null) ...[
              const SizedBox(height: FitSpacing.s16),
              AuthInlineMessage(
                message: _message!,
                tone: AuthInlineMessageTone.info,
              ),
            ],
            const SizedBox(height: FitSpacing.s24),
            FitButton(label: 'Enviar link', expand: true, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
